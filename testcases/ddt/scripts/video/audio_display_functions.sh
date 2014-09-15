#! /bin/bash
# 
# Copyright (C) 2011 Texas Instruments Incorporated - http://www.ti.com/
#  
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as 
# published by the Free Software Foundation version 2.
# 
# This program is distributed "as is" WITHOUT ANY WARRANTY of any
# kind, whether express or implied; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 

# search for USB audio devices

source "common.sh"
source "st_log.sh"
source "functions.sh"

#Function to obtain the hw id of the hdmi audio device 
get_hdmi_audio_devnode()
{
  # Get ALSA HDMI devices 
  local SOUND_CARD=`aplay -l | grep -i hdmi | cut -f 2,8 -d ' ' | cut -c 1`
  local SOUND_DEVICE=`aplay -l | grep -i hdmi | cut -f 2,8 -d ' ' | cut -c 4`

  if test "$SOUND_CARD" = " "
  then
	  echo "No HDMI sound card found"
	  exit 1
  fi
  if test "$SOUND_DEVICE" = " "
  then
	  eval echo "No HDMI sound device found"
	  exit 2
  fi
  echo "hw:$SOUND_CARD,$SOUND_DEVICE"
}

#Function to obtain the connector ids and modes supported by a connector.
#This function will only return information of connectors with connected
#status
#Inputs:
#  $1: the connector type hdmi, unknown
#  $2: (Optional) a mode regex to look for, i.e, 1920x1080, 720x480. If 
#      this parameter is not specified the list will contain all the
#      modes supported by each connector
#Output:
#a list whose element comply with format <connector id>:<mode>,
#i.e 5:1920x1080-60 5:720x480-30
get_video_connector_info()
{
  assert [ ${#} -eq 1 -o ${#} -eq 2 ]
  local info=$(modetest)
  local dss_info
  local conn_inf
  local conn_ids
  local modes_inf
  local conn_vals
  local val_inf
  local mode_regex="^[0-9][0-9][0-9]"
  local result=()
  local c_mode
  local c_id
  local conn_type=$1
  if [ ${#} -gt 1 ]; then
    mode_regex="$2"
  fi
  get_sections "^[A-Za-z]*:" "$info" "~" dss_info
  local connectors=$(get_section_val "Connectors:" dss_info[@] "~")
  get_sections "^[0-9].*" "$connectors" "~" conn_inf
  get_sections_keys conn_inf[@] "~" conn_ids  
  for conn in "${conn_ids[@]}"
  do
    info=$(echo -e "$conn" | grep -i $'\t'connected$'\t'$conn_type)
    if [ $? -eq 0 ]; then
      c_id=$(echo "$conn" | cut -d $'\t' -f 1)
      val_inf=$(get_section_val "$conn" conn_inf[@] "~")
      get_sections "^  [A-Za-z].*:" "$val_inf" "~" conn_vals
      modes_inf=$(get_section_val "  modes:" conn_vals[@] "~")
      local old_ifs=$IFS
      IFS=$'\n'
      for mode in $modes_inf
      do
        c_mode=$(echo $mode | cut -d ' ' -f 3,4)
        c_mode=${c_mode/ /-}
        if [[ "$c_mode" =~ $mode_regex ]]; then
          result[${#result[@]}]="$c_id:$c_mode"
        fi
      done
      IFS=$old_ifs
    fi
  done
  echo "${result[@]}"
}

#Function to run a display test with modetest with the option to
#simultaneously play and audio file.
#Inputs:
#  $1: string containing the type of connector, i.e hdmi
#  $2: list of modes to run. the format of the elements in the list must
#      comply with <connector id>:<mode>, i.e 5:1280x720-60
#  $3: time is sec the test should last
#  $4 and $5: (Optional) the sampling rate and audio device id. At least
#             $4 has to be specified for the function to also test audio
#Returns
#  0 if the frame rate printed is within 1 Hz of the expected frame rate
#  for the mode and the audio test rc is 0; 1 otherwise
disp_audio_test()
{
  assert [ ${#} -gt 2 ]
  local alsa_test_cmd="sleep $3"
  local conn_type=$1
  local modes=( $2 )
  local expected_fr
  local freqs
  local result=0
  local fr_delta
  local alsa_rc
  local fmt_freqs
  local fr_length
  assert [ ${#modes[@]} -gt 0 ]
  if [ ${#} -gt 3 ]; then
    alsa_test_cmd="alsa_tests.sh -d $3 -t playback -r $4"
  fi
  if [ ${#} -gt 4 ]; then
    alsa_test_cmd="$alsa_test_cmd -D $5"
  fi
  for mode in ${modes[@]}; do
    expected_fr=$(echo $mode | cut -d '-' -f 2)
    echo "Expected frequency $expected_fr"
    echo "modetest -t -v -s $mode &>mode_test_log.txt & mt_pid=$! ; $alsa_test_cmd ; alsa_rc=$? ; kill -9 $mt_pid"
    modetest -t -v -s $mode &>mode_test_log.txt & mt_pid=$!; $alsa_test_cmd ; alsa_rc=$? ; kill -9 $mt_pid
    freqs=( $(cat mode_test_log.txt | grep freq: | cut -d ' ' -f 2) )
    fmt_freqs=( $(cat mode_test_log.txt | grep freq: | cut -d ' ' -f 2 | cut -d '.' -f 1) )
    fr_length=$((${#freqs[@]} - 2))
    old_IFS=$IFS
    IFS=$'\n'
    test_print_trc " MODE_FREQS | $conn_type-$mode = ${freqs[@]:1:$fr_length}"
    IFS=$old_IFS
    if [ $fr_length -lt 1 ]; then
      result=2
    fi
    for fr in ${fmt_freqs[@]:1:$fr_length}
    do
      fr_delta=$((expected_fr-fr))
      if [ $((fr_delta*fr_delta)) -gt 1 ]; then
        echo "Display test failed for mode $mode"
        result=1
      fi
      if [  $alsa_rc -ne 0 ]; then
        echo "Audio test failed with mode $mode"
        result=1
      fi
    done
  done
  exit $result
}

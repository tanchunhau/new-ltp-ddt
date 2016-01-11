#!/bin/sh
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

# Test video functionality using gstreamer
# Input: File to be downloaded and test file name
# Output: Make the input stream available for running test

source "common.sh"

get_data()
{
	echo -e "$2" | grep -i -o $1':[^,]*' | grep -o '[0-9\.]*'
}

get_secs()
{
  local __time

  __time=( $(echo -e "$1" | grep -i -e 'Duration: ' -e 'Execution ended after' | grep -o '[0-9]*' ) )
  echo $((10#${__time[0]}*3600 + 10#${__time[1]}*60 + 10#${__time[2]}))
}

print_opp()
{
  local __old_ifs=$IFS
  IFS=$'\n'
  local __opp_info=( `omapconf show opp | grep '^|'` )
  local __opp_cols
  local __line_ifs
  local __line_idx=0
  local __col_names
  local __m_name
  local __c_name
  local __c_val

  if [ ${#__opp_info[@]} -gt 3 ]
  then
    for opp_line in ${__opp_info[@]}
    do
      __line_ifs=$IFS
      IFS='|'
      __opp_cols=( $opp_line )
      __line_idx=$((__line_idx + 1 ))
      if [ $__line_idx -lt 3 -o ${#__opp_cols[@]} -lt 5 ]
      then
        [[ $__line_idx -eq 2 ]] && __col_names=( $opp_line )
        continue
      fi
      for i in `seq -s '|' 0 $((${#__col_names[@]} - 1))`
      do
        __c_name=${__col_names[$i]// /}
        __c_val=${__opp_cols[$i]// /}
        if [ "$__c_val" != "" -a "$__c_name" == "" ]
        then
          __m_name=$__c_val
        elif [ "$__c_val" != "" ]
        then
          test_print_trc "$__m_name $__c_name | $__c_val "
        fi
      done
      IFS=$__line_ifs
    done
  fi

  IFS=$__old_ifs
}

print_opp
test_print_trc " CMD | gst_dec.sh $* "
perf_string=$(gst_dec.sh $*)
FILE=$(echo "$*" | grep -o '\-f\s*[^( -)]*')
stream_info=$(gst-discoverer-1.0 -v ${FILE:2})
parsed_perfs=( $(echo "$stream_info" | grep -i 'Frame rate' | grep -o '[0-9\/]*') )
expected_perf=$((100*${parsed_perfs[0]}))
for f in ${a[@]:1};
do
  [[ $((f)) -lt $expected_perf ]] && expected_perf=$((f))
done
expected_duration=$(get_secs "$stream_info")
measured_duration=$(get_secs "$perf_string")
if [ $expected_perf -lt 1 ]
then
  test_print_trc " MEASURED_DURATION | $measured_duration secs"
  test_print_trc " MAXREQ_DURATION | $expected_duration secs"
else
  num_frames=$((expected_perf*expected_duration))
  measured_fps=$((num_frames/measured_duration))
  eperf_l=$((${#expected_perf}-2))
  mperf_l=$((${#measured_fps}-2))
  test_print_trc " CAPT_FREQS | ${measured_fps:0:${mperf_l}}.${measured_fps:${mperf_l}:2} "
  test_print_trc " MINREQ_FREQ | ${expected_perf:0:${eperf_l}}.${expected_perf:${eperf_l}:2} "
  fps_test=0
fi

[[ $measured_duration -le $((expected_duration + 1)) ]] || die "measured fps lower than expected $measured_duration > $expected_duration"

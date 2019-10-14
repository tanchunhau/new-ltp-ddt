#! /bin/sh
# 
# Copyright (C) 2019 Texas Instruments Incorporated - http://www.ti.com/
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

source "common.sh"  # Import do_cmd(), die() and other functions

#Function to obtain the default value of a parameter based on the capabilities string
#  $1 capability string to parse
#  $2 parameter string to look for
#  $3 (optional), if the parameter allow a value in a range, this function returns 
#     the first value in the range, if this parameter is specified the function will
#     return the last value in the range
get_default_val()
{
  local result=`echo "$1" | grep -w "$2:" | tr -s " " | cut -d " " -f 2,3 | cut -d "[" -f 2 | cut -d "(" -f 2 | cut -d "]" -f 1 | cut -d ")" -f 1`
  local value_range=($result)
  if [ $# -gt 2 ] ; then
    echo ${value_range[${#value_range[@]} - 1]}
  else
    echo ${value_range[0]}
  fi
}

check_buffer_time()
{
 BUFFERTIME=$BUFFERSIZE
 TIME=$(aplay -v -D "$DEVICE" -f "$SAMPLEFORMAT" $FILE -d1 --disable-resample -r "$SAMPLERATE" -f "$SAMPLEFORMAT" -c "$CHANNEL" "$ACCESSTYPEARG" "$OPMODEARG" --buffer-time=$BUFFERTIME 2>&1 | grep 'rate         :\|buffer_size' | cut -d':' -f2 | tr '\n' ' ' | awk '{print ($2*1000000) / $1}')
 [ $? != 0 ] && exit 1
 test_print_trc "Buffer Time : $TIME us"
 [ $(bc  <<< "$BUFFERTIME * 0.75 < $TIME") == 0 ] && test_print_trc "buffer is too short" && exit 1
 [ $(bc  <<< "$TIME < $BUFFERTIME *1.25") == 0 ] && test_print_trc "buffer is too long" && exit 1
 return 0
}

#Function to dump the hardware parameter of an alsa device
#  $1 type of device "play" or "record"
#  $2 device id, i.e hw:0,0
#Returns: the alsa hw dump for the device 
dump_hw_params()
{
  a${1} -D ${2} --dump-hw-params -d 1 /dev/zero 2>&1
}

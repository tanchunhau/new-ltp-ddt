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
# Performs dd read test from mtd device and prints out throughput 
# Inputs: 
# $1 - device node, example /dev/mtd5
# $2 - block size for dd command, example 1M
# $3 - number of blocks, example 1
# Output: None

source "common.sh"
source "st_log.sh"

device_name=$1
block_size=$2
block_count=$3
iomode=$4
if [[ -z $iomode ]]; then
  iomode='read'
fi

if [[ "$iomode" == "write" ]]; then
  do_cmd "time -p dd if=/dev/urandom of=$device_name bs=$block_size count=$block_count 2> raw_perf.log"
else
  do_cmd "time -p dd if=$device_name of=/dev/null bs=$block_size count=$block_count 2> raw_perf.log"
fi

output=`cat raw_perf.log`
while read line                                               
do                                                            
    if [[ "${line}" == *real* ]]; then
    time=$( echo "$line"|awk -F'real ' '{print $2;}' )                 
    echo $time
  fi                                                 
done <<< "$output" 
bytes_transferred=$((block_size * block_count))
throughput=`echo "scale=3; $bytes_transferred/$time" | bc` 
throughput=`echo "scale=3; $throughput/1048576" | bc` 
test_print_trc "|BYTES:"`printf '%.2f' $bytes_transferred`" B|"
test_print_trc "|TIME TAKEN:"`printf '%.2f' $time`" s|"
test_print_trc "|PERFDATA|block:$block_size|count:$block_count|iomode:$iomode|throughput:"`printf '%.2f' $throughput`" MB/S|"
do_cmd "rm raw_perf.log"


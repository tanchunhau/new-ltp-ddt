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
test_print_trc " CMD | gst_dec.sh $* "
perf_string=$(gst_dec.sh $*)
FILE=$(echo "$*" | grep -o '\-f\s*[^( -)]*')

expected_perf=$(($(gst-discoverer-1.0 -v ${FILE:2} | grep -i 'Frame rate' | grep -o '[0-9\/]*')))

raw_data=$(echo -e "$perf_string" | grep -i rendered)
fps=( $(get_data current "$raw_data") )
dropped=( $(get_data dropped "$raw_data") )
test_print_trc " CAPT_FREQS | ${fps[@]:1} "
test_print_trc " MINREQ_FREQ | ${expected_perf[0]} "
fps_test=0
exp_fr=$(((expected_perf[0]-1)*100))
if [ ${#fps[@]} -lt 2 ]
then
  fps_test=1
fi
for fr in ${fps[@]:1}
do
  freq=${fr/./}
  if [ $freq -lt $exp_fr ]
	then
	  test_print_trc "Fps test failed expected ${expected_perf[0]}/${expected_perf}, got $fr"
	  fps_test=1
	fi
done
drop_test=0
for drop_fr in ${droppped[@]:1}
do
  drop_test=$((drop_test+drop_fr-dropped[0]))
done
if [ $drop_test -gt 0 ]
then
  test_print_trc "Frame drops detected during decode"
fi
exit $((fps_test+drop_test))

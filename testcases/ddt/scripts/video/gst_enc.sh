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

source "st_log.sh"
source "common.sh"

############################# Functions #######################################
usage()
{
cat <<-EOF >&2
        usage: ./${0##*/} [-n <vid_node>] [-r resolution] [-c codec] [-s sink] [-f frames ]  
        -n node name of the capture device, video0, video1,etc
        -r capture resolution <width>x<height>, i. e, 1920x1080, 1280x720, etc
        -c codec type h264, mpeg4, etc
        -s gstreamer sink type
        -t number of frames to capture
        -f frame rate, defaults to 30
        -h Help         print this usage
EOF
exit 0
}


############################ Script Variables ##################################
# Define default valus if possible

############################ CLI Params ###########################################
OPTIND=1
RESOLUTION=""
SINK="fakesink"
FRAMES=60
FRAMEINFO=""
RATE=", framerate=30/1"
while getopts :s:r:c:n:f:t: arg
do case $arg in
        n)
                NODE=$OPTARG ;;
        r)
                RES=( $(echo ${OPTARG} | grep -o '[0-9]*') )
                RESOLUTION=", width=${RES[0]}, height=${RES[1]}" ;;
        c)
                C_TYPE=$(echo ${OPTARG} | tr '[:upper:]' '[:lower:]') ;;
        s)
                SINK=$OPTARG ;;
        t)
                FRAMES=$OPTARG ;;
        f)
                RATE=", framerate=${OPTARG}/1" ;;
        \?)
		            echo "Invalid Option -$OPTARG ignored." >&2
                usage
                exit 1
                ;;
esac
done

RESOLUTION="! video/x-raw${RATE}${RESOLUTION}"

case $MACHINE in
	 dra7xx*|am57xx*)
			 CODEC="ducati${C_TYPE}enc";;
	 *)
			 CODEC="avenc_${C_TYPE}";;
esac

########################### DYNAMICALLY-DEFINED Params #########################
# Try to use /sys and /proc information to determine values dynamically.
# Alternatively you should check if there is an existing script to get the
# value you want

########################### REUSABLE TEST LOGIC ###############################
echo "gst-launch-1.0 v4l2src device=/dev/${NODE} num-buffers=${FRAMES} ${RESOLUTION} ! ${CODEC} ! ${SINK}"
gst-launch-1.0 v4l2src device=/dev/${NODE} num-buffers=${FRAMES} ${RESOLUTION} ! ${CODEC} ! ${SINK} 2>&1 | grep -i 'error'
if [ $? -eq 0 ]; then 
  die "Problem while trying to capture and encode video"
fi

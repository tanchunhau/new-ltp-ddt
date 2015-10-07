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
        usage: ./${0##*/} [-f FILE] [-s] [-p] [-x] [-c v_id] [-a a_id]  
        -f absolute path of the stream to be played
        -s Enable video and audio sync property
        -p Enable video performance (Not available on all platforms)
        -x Enable video scaling (Not available on all platforms or with -p)
        -c Video connector id
        -a audio device, i.e hw:0,0 
        -h Help         print this usage
EOF
exit 0
}

SYNC="sync=false"
GST_V=""
SCALING=""
V_CONN=""
A_DEV=""
case $MACHINE in
	 dra7xx*|am57xx*)
			 VSINK="kmssink";;
	 *)
			 VSINK="fbdevsink";;
esac
############################ Script Variables ##################################
# Define default valus if possible

############################ CLI Params ###########################################
OPTIND=1
while getopts :spxc:a:f: arg
do case $arg in
        f)
                FILE=$OPTARG ;;
        s)
                SYNC="sync=true" ;;
        p)
                VSINK="fpsdisplaysink"
                GST_V="-v" ;;
        x)
                SCALING="scale=true" ;;
        c)
                V_CONN="connector=$OPTARG" ;;
        a)
                A_DEV="device=$OPTARG" ;;
        \?)
		            echo "Invalid Option -$OPTARG ignored." >&2
                usage
                exit 1
                ;;
esac
done

########################### DYNAMICALLY-DEFINED Params #########################
# Try to use /sys and /proc information to determine values dynamically.
# Alternatively you should check if there is an existing script to get the
# value you want

########################### REUSABLE TEST LOGIC ###############################

/etc/init.d/weston stop && sleep 3
echo "gst-launch-1.0 playbin uri=file://${TESTFILE} video-sink=\"${VSINK} ${SCALING} ${SYNC} ${V_CONN}\" audio-sink=\"alsasink ${SYNC} ${A_DEV}\" $GST_V"
gst-launch-1.0 playbin uri=file://${FILE} video-sink=\"${VSINK} ${SCALING} ${SYNC} ${V_CONN}\" audio-sink=\"alsasink ${SYNC} ${A_DEV}\" $GST_V || die "Problem occurred while trying to play stream"

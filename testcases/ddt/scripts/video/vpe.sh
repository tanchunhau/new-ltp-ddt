#! /bin/bash
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

source "common.sh"
source "st_log.sh"
source "functions.sh"

# Load require video modules
insert_video_modules()
{
	local _modules="ti_vpe"
	for m in $_modules; do
		lsmod | grep ${m%.ko} || modprobe $m
	done
}

generate_sample()
{
 gst-launch-1.0 videotestsrc num-buffers=60 ! video/x-raw,format=\(string\) $1,width=$2,height=$3 ! filesink location=$4
}

get_videoparse_format()
{
 gst-inspect-1.0 videoparse | grep $1 | cut -d\( -f2 | cut -d\) -f1
}

vpe_yuv_to_yuv()
{
	insert_video_modules
	INPUT=$(mktemp)
	OUTPUT=$(mktemp)
	vid_devs=$(get_video_node.sh -d vpe); [ -z "$vid_devs" ] && exit 1
	generate_sample YUY2 720 420 $INPUT
	test-v4l2-m2m /dev/$vid_devs $INPUT 720 420 yuyv $OUTPUT 360 210 yuyv 0 1 60 && \
	gst-launch-1.0 filesrc location=$OUTPUT ! videoparse width=360 height=210 framerate=24/1 format=$(get_videoparse_format YUY2) ! autovideoconvert ! autovideosink
	rm $INPUT $OUTPUT
}

vpe_yuv_to_rgb565()
{
	insert_video_modules
	INPUT=$(mktemp)
	OUTPUT=$(mktemp)
	vid_devs=$(get_video_node.sh -d vpe); [ -z "$vid_devs" ] && exit 1;
	generate_sample YUY2 720 420 $INPUT
	test-v4l2-m2m /dev/$vid_devs $INPUT 720 420 yuyv $OUTPUT 400 300 rgb565 0 1 60 && \
	gst-launch-1.0 filesrc location=$OUTPUT ! videoparse width=400 height=300 framerate=24/1 format=$(get_videoparse_format RGB16) ! autovideoconvert ! autovideosink
	rm $INPUT $OUTPUT
}

vpe_yuv_to_yuv_crop()
{
	insert_video_modules$vid_devs
	INPUT=$(mktemp)
	OUTPUT=$(mktemp)
	vid_devs=$(get_video_node.sh -d vpe); [ -z "$vid_devs" ] && exit 1
	generate_sample YUY2 720 420 $INPUT
	test-v4l2-m2m /dev/$vid_devs $INPUT 720 420 yuyv $OUTPUT 360 210 yuyv 0 1 60 crop=360x210@350,200  && \
	gst-launch-1.0 filesrc location=$OUTPUT ! videoparse width=360 height=210 framerate=24/1 format=$(get_videoparse_format YUY2) ! autovideoconvert ! autovideosink
	rm $INPUT $OUTPUT
}

vpe_yuv_to_rgb565_crop()
{
	insert_video_modules
	INPUT=$(mktemp)
	OUTPUT=$(mktemp)
	vid_devs=$(get_video_node.sh -d vpe); [ -z "$vid_devs" ] && exit 1
	generate_sample YUY2 720 420 $INPUT
	test-v4l2-m2m /dev/$vid_devs $INPUT 720 420 yuyv $OUTPUT 400 300 rgb565 0 1 60 crop=400x300@300,100 && \
	gst-launch-1.0 filesrc location=$OUTPUT ! videoparse width=400 height=300 framerate=24/1 format=$(get_videoparse_format RGB16) ! autovideoconvert ! autovideosink
	rm $INPUT $OUTPUT
}

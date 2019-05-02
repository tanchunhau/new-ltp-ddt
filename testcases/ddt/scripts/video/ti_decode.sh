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

source "common.sh"
source "st_log.sh"
source "functions.sh"

# Load require video modules
insert_video_modules()
{
	local _modules="videobuf2-common.ko videobuf2-memops.ko videobuf2-v4l2.ko videobuf2-dma-sg.ko videobuf2-dma-contig.ko v4l2-mem2mem.ko vxd-dec.ko"
	for m in $_modules; do
		lsmod | grep ${m%.ko} || modprobe $m
	done
}

# Run  TI decoder
run_tidec_decode()
{
	insert_video_modules
	tidec_decode -b $* | grep 'test app completed successfully'
}

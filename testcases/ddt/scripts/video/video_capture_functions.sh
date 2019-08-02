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

get_video_capture_nodes()
{
  grep -i -r -e vpfe -e vip /sys/class/video4linux/video* | grep -o video[0-9]*/ | cut -d "/" -f 1
}

get_usb_camera_nodes()
{
  for d in `ls -d /sys/class/video4linux/video*`
  do
    dev=$(basename ${d})
    v4l2-ctl --all -d /dev/${dev} | grep 'Video input.*Camera' -B40 | grep Bus | grep usb > /dev/null && echo /dev/${dev}
  done
}

get_vpe_nodes()
{
  for d in `ls -d /sys/class/video4linux/video*`
  do
    cat ${d}/name | grep vpe > /dev/null && echo `basename $d`
  done
}

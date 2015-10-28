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

get_video_capture_nodes()
{
  grep -i -r -e vpfe -e vip /sys/class/video4linux/video* | grep -o video[0-9]*/ | cut -d "/" -f 1
}

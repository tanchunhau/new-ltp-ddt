#! /bin/sh
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

# Check SD or emmc speed to see if it is expected speed like HS200
# For now, it only works for emmc

source "common.sh"
source "blk_device_common.sh"

############################# Functions #######################################

############# Do the work ###########################################
device_type=$1

if [[ "$device_type" = "emmc" ]]; then
  do_cmd "dmesg | grep 'Command Queue Engine enabled' || die 'Command Queue Engine is not enabled' "
fi




















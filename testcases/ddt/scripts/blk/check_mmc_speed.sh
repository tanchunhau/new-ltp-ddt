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
expected_mode=$1

if [[ "$expected_mode" = "" ]]; then

  # Get emmc expected speed based on platform
  case $MACHINE in
    am57xx-evm)
      expected_mode="DDR52";;
    dra7xx-evm | dra72x-evm )
      expected_mode="HS200";;
    *)
      die "No expected eMMC mode is specified for this platform";;
  esac

fi

expected_timespec="(mmc ${expected_mode}"
mmcios=`printout_mmc_ios` 
echo "$mmcios" |grep "$expected_timespec" && echo "The test pass and mmc ios shows it is running at ${expected_mode} mode" || die "eMMC is not running at expected mode: ${expected_mode}"



















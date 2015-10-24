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

# Get Intel iwlwifi-1000 firmware

source "common.sh"

# for now, hardcode this URL; move to test case if needed later on
URL="http://git.kernel.org/cgit/linux/kernel/git/firmware/linux-firmware.git/plain/iwlwifi-1000-5.ucode"
firmware=`basename ${URL}`

fw_file="/lib/firmware/${firmware}"
if [ ! -s $fw_file ]; then
  Wget ${URL} -O $fw_file
  if [ $? -ne 0 ]; then
    die "Failed to wget iwlwifi firmware from $URL" 
  fi
  # load firmware
  do_cmd depmod -a
  do_cmd modprobe -r iwlwifi
  do_cmd modprobe iwlwifi
fi


#! /bin/sh
############################################################################### 
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
###############################################################################

# @desc Deletes default gateway 
# @params - None
# @returns -None
source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################
usage()
{
	echo "del_default_gateway.sh"
	exit 1
}

: ${GATEWAY:=`ip route show | grep default | awk '{print $3}'`}
gw_array=($GATEWAY)
for i in "${gw_array[@]}"
do
	`route del default gw $i`
done

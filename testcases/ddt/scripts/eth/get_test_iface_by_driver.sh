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
source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################
usage()
{
	echo "get_test_iface_by_driver.sh -d <driver> [-a]"
        echo "Returns an active interface which is of type driver (ex: icssg). Use -a to get all active ifaces of type driver"
	exit 1
}

################################ CLI Params ####################################
p_driver="cpsw"
p_num="one"

while getopts ":d:a" opt; do
  case $opt in
        d)
          p_driver=$OPTARG      
          ;;
        a)
          p_num="all"      
          ;;        
        \?)     die "Invalid Option -$OPTARG ";;
   esac
done
# Define default values if possible

############################ USER-DEFINED Params ###############################
# Try to avoid defining values here, instead see if possible
# to determine the value dynamically. ARCH, DRIVER, SOC and MACHINE are 
# initilized and exported by runltp script based on platform option (-P)
case $ARCH in
esac
case $DRIVER in
esac
case $SOC in
esac
case $MACHINE in
esac
# Define default values for variables being overriden

########################### DYNAMICALLY-DEFINED Params #########################
# Try to use /sys and /proc information to determine values dynamically.
# Alternatively you should check if there is an existing script to get the
# value you want

# Script checks all active interfaces for one that is implemented by p_driver
int_names=""
all_ifaces=`get_active_eth_interfaces.sh`

# Check all active interfaces for one implemented by correct driver
for iface in $all_ifaces; do
    iface_name=`check_eth_iface_driver.sh -d $p_driver -i $iface`

    if [ ! -z "$iface_name" ] 
    then
        int_names="$int_names $iface_name "

        # If we only want one interface for the test then break
        if [ "$p_num" == "one" ]; then break; fi
    fi
done

echo "$int_names" | awk '{$1=$1};1'
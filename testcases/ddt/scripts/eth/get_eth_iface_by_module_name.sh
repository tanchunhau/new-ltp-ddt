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
	echo "get_eth_iface_by_module_name.sh -m <module> -i <interface>"
        echo "Returns the name of the interface which is of type module (ex: pru) and interface name (ex: eth0) as mentioned)"
	exit 1
}

################################ CLI Params ####################################
p_module='cpsw'
p_interface='eth0'

while getopts  ":m:i:" opt; do
  case $opt in
        m)
          p_module=$OPTARG      
          ;;
        i)
          p_interface=$OPTARG      
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
int_name=''
driver=`ethtool -i $p_interface|grep driver|grep -i $p_module`
if [ ! -z "$driver" ]
then
  int_name=$p_interface
else
  die "No interface of type $p_module and name $p_interface"
fi

echo "$int_name"


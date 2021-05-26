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
	echo "check_eth_iface_driver.sh -d <driver> -i <interface>"
        echo "Returns the name of the interface which is of driver type (ex: pru) and interface name (ex: eth0) as mentioned)"
	exit 1
}

################################ CLI Params ####################################
p_driver='cpsw'
p_interface='eth0'

while getopts  ":d:i:" opt; do
  case $opt in
        d)
          p_driver=$OPTARG      
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
cpsw="cpsw TIKeyStoneEthernetDriver cpsw-switch"
cpsw2g="am65-cpsw-nuss"
cpsw9g="j721e-cpsw-virt-mac"
icssg="icssg-prueth"
icssm="PRUSSEthernetdriver prueth"

# Hash to map drivers to their possible names listed by ethtool
declare -A DRIVER_NAMES
DRIVER_NAMES=( ["cpsw"]="$cpsw" ["cpsw2g"]="$cpsw2g" ["cpsw9g"]="$cpsw9g" ["icssg"]="$icssg" ["icssm"]="$icssm")

int_name=''
int_driver=`ethtool -i $p_interface | grep driver | cut -d':' -f2 | tr -d '[:space:]'`

# Check if the requested driver (cpsw2g/9g, icssg...) matches the driver for that interface
if [[ "${DRIVER_NAMES[$p_driver]}" =~ "$int_driver" ]]
then
    int_name=$p_interface
fi

echo "$int_name"


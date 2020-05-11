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
                                                                                
########################### REUSABLE TEST LOGIC ############################### 
# Usage information: eth_multi_speed.sh -i <num_of_iterations> 
#                                       -s <speed setting>
#                                       -d <driver_type - example icssg>
#                                       -a [run on all active interfaces]
#################################################################################
p_iterations=2
p_speed=10
p_driver="cpsw"
p_interfaces="one"

while getopts ":i:s:d:a" opt; do
  case $opt in 
  i)
    p_iterations=$OPTARG
    ;;
  s)
    p_speed=$OPTARG
    ;;
  d)
    p_driver=$OPTARG
    ;;
  a)
    p_interfaces="all"
    ;;
  esac
done

# Run test on either one or all interfaces
if [ "$p_interfaces" == "all" ]
then
	interfaces=`get_test_iface_by_driver.sh -d $p_driver -a`
else
	interfaces=`get_test_iface_by_driver.sh -d $p_driver`
fi
                                                                                                    
# If interfaces is empty then we couldnt find an iface for the test                                          
if [ -z "$interfaces" ]                                                                             
then                                                                                                
        die "No interface found for $p_driver to run test!"                                         
fi                                                                                                  

for iface in $interfaces
do
  duplex=`cat /sys/class/net/$iface/duplex`
  
  # Sleep 5 seconds to allow speed change to take place
  do_cmd "ethtool -s $iface speed $p_speed duplex $duplex && sleep 5"
  final_speed=`cat /sys/class/net/$iface/speed`
  
  # Re-enable autonegotiation after test
  do_cmd "ethtool -s $iface autoneg on"
  if [ "$final_speed" != "$p_speed" ]
  then 
    die "Observed and expected ethernet link speeds do not match"
  fi
done
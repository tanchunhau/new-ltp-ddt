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
# Usage information: eth_multi_duplexity.sh -i <num_of_iterations> 
#                                           -t <duplex setting>
#                                           -d <driver_type - example icssg>
#                                           -a [run on all active interfaces]
#################################################################################
p_iterations=2
p_duplex="full"
p_driver="cpsw"
p_interfaces="one"

while getopts ":i:t:d:a" opt; do
  case $opt in 
  i)
    p_iterations=$OPTARG
    ;;
  t)
    p_duplex=$OPTARG
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
  speed=`cat /sys/class/net/$iface/speed`
  do_cmd "ethtool -s $iface speed $speed duplex $p_duplex" 
  final_duplex=`get_eth_link_duplexity.sh $iface`
  do_cmd "ethtool -s $iface autoneg on"
  echo "DUPLEX is $p_duplex and FINAL_DUPLEX is $final_duplex"
  if [ `echo $p_duplex | tr [:upper:] [:lower:]` = `echo $final_duplex | tr [:upper:] [:lower:]` ]
  then 
    echo "Test Passed for $iface"
  else 
    die "Observed and expected ethernet link duplex settings do not match"
  fi
done
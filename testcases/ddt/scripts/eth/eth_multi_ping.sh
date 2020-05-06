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
# Usage information: eth_multi_ping.sh -i <num_of_iterations> 
#                                      -t <duration of ping in seconds>
#                                      -p <packetsize for ping in bytes>   
#                                      -d <driver_type - example icssg>
#                                      -a [run on all active interfaces]
#################################################################################

p_iterations=2
p_duration=5
p_pktsize=64
p_driver="cpsw"
p_interfaces="one"

while getopts ":i:t:p:d:a" opt; do
  case $opt in 
  i)
    p_iterations=$OPTARG
    ;;
  t)
    p_duration=$OPTARG
    ;;
  p)
    p_pktsize=$OPTARG
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

# CPSW ports come up slowly 
bringup=10
if [ "$p_driver" == "cpsw" ]
then
  bringup=15
fi

for iface in $interfaces
do
	for (( i=0; i < $p_iterations; i++ ))
	do
		do_cmd "ifconfig $iface down"
		do_cmd "ifconfig $iface up && sleep $bringup" 
		gateway=`get_eth_gateway.sh -i $iface` || die "Error getting eth gateway for $iface"
		do_cmd "ping $gateway -s $p_pktsize -c $p_duration -I $iface" 
	done
done
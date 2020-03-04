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
# Usage information: eth_multi_mac_config.sh -i <num_of_iterations> 
#                                            -d <driver_type - example icssg>
#                                            -a [run on all active interfaces]
#################################################################################
p_iterations=2
p_driver="cpsw"
p_interfaces="one"

while getopts ":i:t:d:a" opt; do
  case $opt in 
  i)
    p_iterations=$OPTARG
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
  test_mac=`hexchars="0123456789ABCDEF"; end=$( for i in {1..10} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/:\1/g' ); echo 80$end`
  nfs=`cat /proc/cmdline|grep nfs`
  echo "NFS is $nfs"
  if [ -n "$nfs" ]
  then 
    die "Can't run this test over NFS!"
  fi

  initial_mac=`cat /sys/class/net/$iface/address`
  echo "$initial_mac"
  ifconfig $iface down
  ifconfig $iface hw ether $test_mac
  final_mac=`cat /sys/class/net/$iface/address`
  echo "FINAL MAC is $final_mac and TEST MAC is $test_mac"
  ifconfig $iface hw ether $initial_mac
  ifconfig $iface up
  if [ "${final_mac,,}" != "${test_mac,,}" ]
  then 
    die "MAC did not get set as expected Final $final_mac Test $test_mac"
  fi
done
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

# search for PCI Ethernet devices

source "common.sh"

net_type=$1     #type of ethernet, eth or wlan
ethdev=''

if [ -z "$net_type" ]; then
  net_type='eth'
fi

j=0
devices=`ls /sys/class/net|grep -iE "${net_type}|wlp|enp"`
for device in $devices
  do
    pci_interface=`udevadm info --attribute-walk --path=/sys/class/net/$device|grep -m 1 -i "pci"`
    if [[ -n "$pci_interface" ]];
    then
      pci_ints[j]=$device
      j+=1
      ethdev=$device
    fi
done
if [ -z $ethdev ];
then
  test_print_trc " ::"
  test_print_trc " :: Failed to find PCI Ethernet interface. Exiting PCI Ethernet tests..."
  test_print_trc " ::"
  exit 2	
fi
echo "${pci_ints[@]}"

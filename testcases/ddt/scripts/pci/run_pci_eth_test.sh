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

# Run PCI Ethernet tests

source "common.sh"

############################# Functions #######################################
usage()
{
cat <<-EOF >&2
  usage: ./${0##*/} [-i ETH_IFACE] [-a ACTION]  
  -a ACTION the ethernet test to be run .
  -h Help   print this usage
EOF
exit 0
}

############################### CLI Params ###################################
while getopts  :i:a:h arg
do case $arg in
  i)  ETH_IFACE="$OPTARG";;
  a)  ACTION="$OPTARG";;
  h)  usage;;
  :)  test_print_trc "$0: Must supply an argument to -$OPTARG." >&2
      exit 1
      ;;
  \?) test_print_trc "Invalid Option -$OPTARG ignored." >&2
      usage
      exit 1
      ;;
esac
done

############################ DEFAULT Params #######################
test_print_trc "ACTION: $ACTION"
test_print_trc "ETH_IFACE: $ETH_IFACE"

do_cmd "lspci -nn"
do_cmd "lspci -vv"

# prepare pci eth test
iface_list=`get_active_eth_interfaces.sh`; 
echo "${iface_list[@]}"; 
if [ -z "${ETH_IFACE}" ];then
  eth_ifaces=`pci_eth_search_device.sh 'eth'` || die "error getting pcie eth interface name";  
  echo "pci ifaces:"
  echo "${eth_ifaces[@]}"
fi

for eth_iface in ${eth_ifaces[@]}; do

  iface_config="iface ${eth_iface} inet dhcp"; 
  grep "$iface_config" /etc/network/interfaces || ( echo "$iface_config" >> /etc/network/interfaces ); 
  for interface in ${iface_list[@]}; do 
    do_cmd "ifconfig $interface down"; 
  done; 
  do_cmd "ifup ${eth_iface}"; 
  host=`get_eth_gateway.sh "-i ${eth_iface}"` || host=`get_eth_gateway.sh "-i eth0"` || die "error getting eth gateway address";
  echo "host:${host}"

  #run eth tests
  if [ -n "$ACTION" ]; then
    eval "$ACTION"
  fi

  # clean up after pci eth test
  do_cmd "ifdown $eth_iface"; 

done

for interface in ${iface_list[@]}; do 
  status=`cat /sys/class/net/"${interface}"/operstate`
  if [ $status == 'down' ]; then
    ifconfig $interface up; 
  fi
done

# end of script

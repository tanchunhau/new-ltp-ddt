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

# Run mPCI wifi tests
# This test requires AP_SSID to run. You may
# 1) export AP_SSID=<ap_ssid> before run this test; OR
# 2) AP_SSID=<ap_ssid> ./run_pci_wifi_test.sh

source "common.sh"

############################# Functions #######################################
usage()
{
cat <<-EOF >&2
  usage: ./${0##*/} [-i ETH_IFACE] [-t TEST] [-a AP_SSID] [-d DURATION] 
  -i ETH_IFACE Optional wlan interface
  -t TEST Optional tests other than ping tests like iperf
  -a AP_SSID Optional SSID for AP .
  -d DURATION ping test duration
  -h Help   print this usage
EOF
exit 0
}

############################### CLI Params ###################################
while getopts  :i:a:t:d:h arg
do case $arg in
  i)  ETH_IFACE="$OPTARG";;
  t)  TEST="$OPTARG";;
  a)  AP_SSID="$OPTARG";;
  d)  DURATION="$OPTARG";;
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
: ${DURATION:=10}

#AP_SSID="TRENDnet671N"

if [ -z "$AP_SSID" ];then
  die "Please specify the SSID for AP when calling the script. \
(i.e. run_pci_wifi_test.sh -a <AP_SSID> or export AP_SSID). "
fi

do_cmd "lspci"
do_cmd "ifconfig -a"
if [ -z "${ETH_IFACE}" ];then
  ETH_IFACE=`pci_eth_search_device.sh 'wlan'` || die "Failed to get pcie wifi interface name:$ETH_IFACE";  
  echo "PCI eth iface: $ETH_IFACE"; 
fi
do_cmd "ifconfig $ETH_IFACE"
if [ $? -ne 0 ]; then
  die "PCI wlan interface is not enumerated yet"
fi

do_cmd ifconfig $ETH_IFACE down
do_cmd sleep 1
do_cmd ifconfig $ETH_IFACE up
do_cmd ip addr show $ETH_IFACE |grep ",UP>" ||die "$ETH_IFACE could not be brought up"

echo "iw dev $ETH_IFACE scan"
iw dev $ETH_IFACE scan |grep $AP_SSID ||iw dev $ETH_IFACE scan |grep $AP_SSID ||die "Could not see testing AP: $AP_SSID"
  
cnt=0
while [ $cnt -lt 5 ]
do
  #do_cmd iw dev $ETH_IFACE connect $AP_SSID |grep "${ETH_IFACE}: associated" && break
  echo "cnt=$cnt; iw dev $ETH_IFACE connect $AP_SSID"
  iw dev $ETH_IFACE connect $AP_SSID 2>&1 |grep "${ETH_IFACE}: associated"
  if [ $? -eq 0 ]; then
    echo "Connected"
    break
  fi 
  cnt=$(( $cnt + 1 ))
  sleep 1
done

do_cmd iw dev $ETH_IFACE link |grep -i "not connected" && die "Could not connect to $AP_SSID"

timeout -t 120 -s2 udhcpc -x hostname:${PLATFORM} -i $ETH_IFACE || die "Failed to get ipaddr from dhcp server"
AP_IP=`udhcpc -x hostname:${PLATFORM} -i $ETH_IFACE |awk '/DNS/ {print $4}' `
do_cmd ifconfig $ETH_IFACE
ipaddr=`get_eth_ipaddr.sh -i $ETH_IFACE` ||die "error getting ipaddr of $ETH_IFACE :: $ipaddr "
sleep 1

#run tests
if [ -n "$TEST" ]; then
  eval "$TEST"
else
  if [[ $DURATION -ge 300 ]]; then
    end=$((SECONDS + $DURATION))
    while [ $SECONDS -lt $end ]; do
      do_cmd ping $AP_IP -w 300
    done
  else
    do_cmd ping $AP_IP -w $DURATION
  fi
fi
# clean up after pci eth test
do_cmd "ifconfig $ETH_IFACE down"; 

# end of script

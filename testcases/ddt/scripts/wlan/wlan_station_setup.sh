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

# @desc Starts a wlan station interface by invoking sta_start.sh and other
#	supporting scripts from /usr/share/wl18xx location.
#       SSID is set as environment variable AP_SSID manually for      
#       standalone LTP-DDT operation or exported from bench file when          
#       using vatf test execution. 

# @params <interface_name such as wlan0 or wlan1>, optional, default wlan0

# @returns 0 if commands are successful

###############################################################################

source "common.sh"  # Import do_cmd(), die() and other functions

if [ ! -z $1 ] 
then 
   wlan_interface=$1 
else
   wlan_interface="wlan0"
fi


`check_env_var 'AP_SSID'`
demo_folder=`find / -name sta_start.sh`
[ -n "$demo_folder" ] || die "Unable to find sta_start.sh in filesystem. Make sure all station scripts are present." 
demo_folder=${demo_folder%"/sta_start.sh"}
nohup "$demo_folder"/sta_start.sh &
sleep 5
scan_result=`wpa_cli -i $wlan_interface scan`
sleep 5
scan_result=`wpa_cli -i $wlan_interface scan_r|grep $AP_SSID`
[ -n "$scan_result" ] || die "Expected SSID $AP_SSID cannot be scanned. Check wireless router is turned on and/or check bench file"
		
# cd into demo folder since the sta_connect-ex-dhcp.sh depends on a local script
cd "$demo_folder"
connect_result=`./sta_connect-ex-dhcp.sh $AP_SSID`
[ -n "$connect_result" ] || die "Unable to connect to SSID. Check connecting manually to SSID $AP_SSID"

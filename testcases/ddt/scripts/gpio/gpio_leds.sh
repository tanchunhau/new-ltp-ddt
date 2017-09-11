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
# @desc Script to check CM clkctrl reg modulemode for gpio 

source "common.sh"

############################# Functions #######################################


############################### CLI Params ###################################
########################### DYNAMICALLY-DEFINED Params ########################

########################### REUSABLE TEST LOGIC ###############################
# DO NOT HARDCODE any value. If you need to use a specific value for your setup
# use user-defined Params section above.

do_cmd "cat /sys/kernel/debug/gpio"
do_cmd "cat /proc/interrupts |grep -i gpio"

do_cmd "ls /sys/class/leds/status*"
led_status=`ls /sys/class/leds/status*`
echo "$led_status" |grep ":blue" || die "Blue light is not registered in sys class"
echo "$led_status" |grep ":green" || die "Green light is not registered in sys class"
echo "$led_status" |grep ":red" || die "Red light is not registered in sys class"


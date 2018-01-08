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

# @desc This script is to check if gpio keypads are input device.
# @returns none
# @history 2017-12-06: First version

source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################

############################ USER-DEFINED Params ###############################
# Try to avoid defining values here, instead see if possible
# to determine the value dynamically. ARCH, DRIVER, SOC and MACHINE are 
# initilized and exported by runltp script based on platform option (-P)

# Define default values for variables being overriden

case $ARCH in
esac
case $DRIVER in
esac
case $SOC in
esac
case $MACHINE in
esac

########################### DYNAMICALLY-DEFINED Params #########################
# Try to use /sys and /proc information to determine values dynamically.
# Alternatively you should check if there is an existing script to get the
# value you want

########################### REUSABLE TEST LOGIC ###############################
# DO NOT HARDCODE any value. If you need to use a specific value for your setup
# use USER-DEFINED Params section above.

# Uncomment the following line if you want the change the behavior of
# do_cmd to treat non-zero values as pass and zero as fail.
# inverted_return="true"

# Avoid using echo. Instead use print functions provided by st_log.sh
test_print_trc "Test starts"

# Use do_cmd() (imported from common.sh) to execute your test steps.
# do_cmd() will check return code and fail the test is return code is non-zero.
do_cmd "cat /sys/kernel/debug/gpio"
do_cmd "cat /proc/interrupts |grep -i gpio"

echo "evtest &> /evtest.log &"       
evtest &> /evtest.log &                                               
pid=$!                              
sleep 5
echo "PID: $pid"                                                
kill -9 $pid
                                                                               
sleep 1
 
# processing the evtest output                           
do_cmd cat /evtest.log
cat /evtest.log |grep -iE 'matrix_keypad|gpio_key|gpio-keys' || die "matrix_keypad is not input event"
do_cmd rm /evtest.log



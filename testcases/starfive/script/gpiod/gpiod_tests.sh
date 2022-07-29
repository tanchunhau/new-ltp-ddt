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

# @desc Briefly describe what the script does.
# @params s) sample parameter
#         a) another sample parameter
# @returns Describes what the script returns if it does return a value
# @history 2011-03-05: First version

source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################
usage()
{
	echo "This tests checks whether pin 0 of the board are able to communicate with pin 2. "
    echo "To ensure the working of this tests, connect pin 0 to pin 2 using jumper wire. "
	exit 1
}

############################ Script Variables ##################################
# Define default valus if possible
SAMPLE1="val1"
SAMPLE2="val2"

################################ CLI Params ####################################
# Please use getopts
while getopts  :H:h arg
do case $arg in
        h)      usage;;
        :)      ;;
        \?)     ;;
esac
done

############################ USER-DEFINED Params ###############################
# Try to avoid defining values here, instead see if possible
# to determine the value dynamically. ARCH, DRIVER, SOC and MACHINE are 
# initilized and exported by runltp script based on platform option (-P)

# Define default values for variables being overriden
# PARTITION="4"

# case $ARCH in
# esac
# case $DRIVER in
# esac
# case $SOC in
# esac
# case $MACHINE in
# 	am180x-evm) PARTITION='2';;
# esac

########################### DYNAMICALLY-DEFINED Params #########################
# Try to use /sys and /proc information to determine values dynamically.
# Alternatively you should check if there is an existing script to get the
# value you want
# ERASE_SIZE=`./get_mtd_erase_size.sh $PARTITION`

########################### REUSABLE TEST LOGIC ###############################
# DO NOT HARDCODE any value. If you need to use a specific value for your setup
# use USER-DEFINED Params section above.

# Uncomment the following line if you want the change the behavior of
# do_cmd to treat non-zero values as pass and zero as fail.
# inverted_return="true"

# Avoid using echo. Instead use print functions provided by st_log.sh
test_print_trc "Starting GPIOD test"

pins_num=$(gpiod_pin_num.sh)
output_pin=$(echo $pins_num | awk '{print $1}')
input_pin=$(echo $pins_num | awk '{print $2}')

test_print_trc "Input pin is  pin $input_pin"
test_print_trc "Output pin is pin $output_pin"


# Use do_cmd() (imported from common.sh) to execute your test steps.
# do_cmd() will check return code and fail the test is return code is non-zero.
do_cmd "gpiod_tests $input_pin $output_pin"

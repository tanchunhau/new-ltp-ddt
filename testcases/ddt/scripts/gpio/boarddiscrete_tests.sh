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
# @desc Script to check the support of industrial input and output

source "common.sh"

############################# Functions #######################################


############################### CLI Params ###################################
mode=$1

########################### DYNAMICALLY-DEFINED Params ########################

########################### REUSABLE TEST LOGIC ###############################
# DO NOT HARDCODE any value. If you need to use a specific value for your setup
# use user-defined Params section above.

do_cmd "cat /sys/kernel/debug/gpio"

gpio_status=`cat /sys/kernel/debug/gpio`
if [[ "$mode" = 'output' ]];then
  echo "$gpio_status" |grep "tpic2810" || die "Industrial Output TPIC2810 is not found in gpio table"
  gpio_number_range=`echo "$gpio_status" |grep "tpic2810" |cut -d' ' -f3 |sed 's/,$//'`
  first_gpio=`echo $gpio_number_range |cut -d'-' -f1`
  last_gpio=`echo $gpio_number_range |cut -d'-' -f2`

  g=$first_gpio
  while [ $g -le $last_gpio ];do
    do_cmd "echo ${g} > /sys/class/gpio/export"
    do_cmd ls /sys/class/gpio
    do_cmd cat /sys/class/gpio/gpio${g}/direction
    #do_cmd cat /sys/class/gpio/gpio${g}/value
    do_cmd "echo 1 > /sys/class/gpio/gpio${g}/value"
    #do_cmd cat /sys/class/gpio/gpio${g}/value
    do_cmd "echo ${g} > /sys/class/gpio/unexport"
    (( g++ ))
  done
  # After seting the output gpio values, the LEDs should be lighten up.
else
  # for input
  echo "$gpio_status" |grep "pisosr" || die "Industrial Input pisosr(SN65HVS882) is not found in gpio table"
  gpio_number_range=`echo "$gpio_status" |grep "pisosr" |cut -d' ' -f3 |sed 's/,$//'`
  first_gpio=`echo $gpio_number_range |cut -d'-' -f1`
  last_gpio=`echo $gpio_number_range |cut -d'-' -f2`

  g=$first_gpio
  while [ $g -le $last_gpio ];do
    do_cmd "echo ${g} > /sys/class/gpio/export"
    do_cmd ls /sys/class/gpio
    do_cmd cat /sys/class/gpio/gpio${g}/direction
    direction=`cat /sys/class/gpio/gpio${g}/direction`
    if [[ $direction != 'in' ]]; then
      do_cmd "echo ${g} > /sys/class/gpio/unexport"
      die "The direction suppose to be IN for gpio${g}"
    fi
    do_cmd cat /sys/class/gpio/gpio${g}/value
    do_cmd "echo ${g} > /sys/class/gpio/unexport"
    (( g++ ))
  done

fi

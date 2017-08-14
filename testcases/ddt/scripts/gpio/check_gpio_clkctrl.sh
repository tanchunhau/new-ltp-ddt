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

# Check if module is disable or enabled by checking modulemode bits
# Input 
#    $1: clkctrl_register_addr
#    $2: boolean; true-> should be enabled; false->should be disabled
check_clkctrl_reg() {
  clkctrl_reg=$1
  should_enabled=$2

  test_print_trc "devmem2 ${clkctrl_reg}"
  reg_val=`devmem2 ${clkctrl_reg} |grep -i 'Read at address' |cut -d":" -f2`
  test_print_trc "Register value is: ${reg_val}"
  MODULEMODE_MASK="0x3"
  modulemode=$(( $reg_val & $MODULEMODE_MASK ))
  if [[ $modulemode -eq 0 ]];then
    test_print_trc "modulemode is 0 -> Module is disabled"
    if [[ "$should_enabled" = "true" ]]; then
      die "The gpio module should not be disabled"
    fi
  else
    test_print_trc "modulemode is not 0 -> Module is not disabled"
    if [[ "$should_enabled" = "false" ]]; then
      die "The gpio module should be disabled"
    fi
  fi

}

############################### CLI Params ###################################
########################### DYNAMICALLY-DEFINED Params ########################

########################### REUSABLE TEST LOGIC ###############################
# DO NOT HARDCODE any value. If you need to use a specific value for your setup
# use user-defined Params section above.

do_cmd "cat /sys/kernel/debug/gpio"
do_cmd "cat /proc/interrupts |grep -i gpio"

# gpio bank counts from 0 here. Ex, '0' is corresponding 'GPIO1' on dra7.
# table for gpio_bank:gpio_bank_clkctrl register address
case $MACHINE in
  am335x-evm)
    #gpio_banks="2:0x44E000B0 3:0x44E000B8"
    gpio_banks="2:0x44E000B0"
  ;;
  dra7xx-evm|dra72x-evm) 
    #gpio_banks="0:0x4AE07838 1:0x4A009760" # 0=>CM_WKUPAON_GPIO1_CLKCTRL; 1=>CM_L4PER_GPIO2_CLKCTRL
    gpio_banks="1:0x4A009760" # 0=>CM_WKUPAON_GPIO1_CLKCTRL; 1=>CM_L4PER_GPIO2_CLKCTRL
  ;;
  am57xx-evm)
    #gpio_banks="0:0x4AE07838 2:0x4A009768"
    gpio_banks="2:0x4A009768"
  ;;
  am43xx-epos|am43xx-gpevm|am437x-idk)
    gpio_banks="" #No free gpio bank for testing
  ;;
  *)
    die "The free gpio:reg pairs are not specified for this platform $MACHINE"
  ;;  
esac

if [[ -z "$gpio_banks" ]]; then
  test_print_trc "No free gpio bank for testing"
  exit 1
fi

for gpio_bank_reg_pair in $gpio_banks; do

  echo "This {gpio_bank : reg} = ${gpio_bank_reg_pair} "
  gpio_bank=`echo ${gpio_bank_reg_pair} |cut -d":" -f1`
  clkctrl_reg=`echo ${gpio_bank_reg_pair} |cut -d":" -f2`

  test_print_trc "Checking CLKCTRL register for gpio bank ${gpio_bank}"
  test_print_trc "Check when the bank is free"
  check_clkctrl_reg ${clkctrl_reg} false

  # register one gpio in this bank
  # get gpio number based on bank number and gpio number in bank
  # choose the first gpio in each bank
  test_print_trc "Check when the bank is not free"
  gpio_num=$((${gpio_bank}*32))
  case $MACHINE in
    am180x-evm)
      gpio_num=$((${gpio_bank}*16))
    ;;
    k2*-evm)
      gpio_num=$((${gpio_bank}*16))
    ;;
  esac

  test_print_trc "BANK_NUM:${gpio_bank}"
  test_print_trc "GPIO_NUM_in_Bank: 0"
  test_print_trc "GPIO_NUM:${gpio_num}"

  test_print_trc "echo ${gpio_num} > /sys/class/gpio/export"
  echo ${gpio_num} > /sys/class/gpio/export
  if [ $? -ne 0 ]; then
    die "Could not export gpio ${gpio_num} "
  fi

  # Check the CLKCTRL register
  check_clkctrl_reg ${clkctrl_reg} true

  test_print_trc "Check when the bank is free again"
  # Disable gpio and check clkctrl register again
  test_print_trc "echo ${gpio_num} > /sys/class/gpio/unexport"
  echo ${gpio_num} > /sys/class/gpio/unexport
  if [ $? -ne 0 ]; then
    die "Could not unexport gpio ${GPIO_NUM} "
  fi
  check_clkctrl_reg ${clkctrl_reg} false

done

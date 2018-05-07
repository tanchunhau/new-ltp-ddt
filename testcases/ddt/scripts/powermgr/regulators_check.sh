#! /bin/sh
###############################################################################
# Copyright (C) 2018 Texas Instruments Incorporated - http://www.ti.com/
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
# This script validates that key voltage regulators are enabled

source "functions.sh"  # Import do_cmd(), die() and other functions

############################ USER-DEFINED Params ###############################
REGULATOR_VOLT_PATH="/sys/class/regulator/"
REGULATORS=""

case $SOC in
  j6entry) REGULATORS="lp8733-buck0 lp8733-buck1";;
  j6eco) REGULATORS="smps1 smps2 smps3";;
  dra7xx) REGULATORS="smps123 smps45 smps6 smps7 smps8 ldo9";;
esac


########################### REUSABLE TEST LOGIC ###############################
for reg in $REGULATORS; do
  REG_NAME=""
  mkfifo temppipe
  ls /sys/class/regulator/ | awk ' {print "/sys/class/regulator/"$1"/name"}' > temppipe &
  while read line
  do
   CUR_REG=`cat $line`
   if [ $CUR_REG == $reg ]; then
    REG_NAME=`echo $line | cut -d '/' -f 5`
    REGULATOR_STATE=`cat /sys/class/regulator/"$REG_NAME"/state`
    echo "$reg regulator mapped to $REG_NAME and has state:$REGULATOR_STATE"
    break
   fi
  done < temppipe
  rm temppipe

  if [ -z $REG_NAME ]; then
    die "Regulator $reg not found"
  fi

  if [ $REGULATOR_STATE != "enabled" ]; then
    die "Regulator $reg is not enabled"
  fi
done
exit 0
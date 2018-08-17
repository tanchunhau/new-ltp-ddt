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

source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################
usage()
{
cat <<-EOF >&1
        usage: ./${0##*/} [-n TRIALS]
        -n TRIALS    Number of times to run the test
        -h Help      print this usage
EOF
exit 0
}

load_test_module()
{
  modprobe -r ti-mbox-fwk-test
  dmesg -c
  modprobe ti-mbox-fwk-test
  log=$(dmesg -c)
  nb_msg=$(echo "$log" | grep "sending [0-9]* messages" | grep -o '[0-9]\+ ')
  if [[ $? -ne 0 ]]
  then
    echo "No mailbox tests detected, exiting ...."
  else
    echo "Checking ${nb_msg} mailbox messages"
  fi

  TX=$(echo "$log" | grep 'success, token' | grep -o '[0-9]*\+$')
  RX=$(echo "$log" | grep 'rx: mbox msg' | grep -o '[0-9a-f]*\+$' | while read p ; do echo $((16#$p)); done)

  if [ "$RX" != "$TX" ]
  then
    echo "TX : $TX"
    echo "RX : $RX"
    die "TX and RX data don't match"
  fi
}

############################ Script Variables ##################################

TRIALS=-1
################################ CLI Params ####################################
while getopts  :n:h arg
do case $arg in
        n)      TRIALS="$OPTARG";;
        h)      usage;;
        \?)     die "Invalid Option -$OPTARG ";;
esac
done

########################### REUSABLE TEST LOGIC ###############################
# DO NOT HARDCODE any value. If you need to use a specific value for your setup
# use USER-DEFINED Params section above.

if [[ $TRIALS -le 0 ]]
then
  usage
fi

for i in seq 1 $TRIALS
do
  load_test_module
done

exit 0

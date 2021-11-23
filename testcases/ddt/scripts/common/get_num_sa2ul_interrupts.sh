#! /bin/sh
############################################################################### 
# Copyright (C) 2013 Texas Instruments Incorporated - http://www.ti.com/
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

# @desc returns total number of udma interrupts raised for each udma irq on a given cpu
# @params  
#         -c cpu number
# @history 2013-04-22: First version

source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################
usage()
{
	echo "$0 -c <0-based cpu number>."
	exit 1
}

############################ Script Variables ##################################
# Define default valus if possible
IRQ_NUM=''
CPU_NUM=''

################################ CLI Params ####################################
# Please use getopts
while getopts  :c:h arg
do case $arg in
	c)	CPU_NUM="$OPTARG";;
        h)      usage;;
        :)      die "$0: Must supply an argument to -$OPTARG.";; 
        \?)     die "Invalid Option -$OPTARG ";;
esac
done

########################### REUSABLE TEST LOGIC ###############################
# DO NOT HARDCODE any value. If you need to use a specific value for your setup
# use USER-DEFINED Params section above.
if [ "x$CPU_NUM" == "x" ]; then
	die "Must supply -c <cpu number> argument"
fi
INT_NUM=0
TOTAL_INT_NUM=0
declare -a arr=("chan0" "chan1" "chan2" "chan3" "chan4" "chan5" "chan6" "chan7" "chan8" "chan9" "chan10" "chan11" "chan12" "chan13" "chan14" "chan15" "chan16" "chan17" "chan18" "chan19" "chan20" "chan21" "chan22" "chan23" "chan24" "chan25" "chan26" "chan27" "chan28" "chan29" "chan30" "chan31" "chan32" "chan33" "chan34" "chan35" "chan36" "chan37" "chan38" "chan39")
for i in "${arr[@]}"
do
   IRQ_NUM=`cat /proc/interrupts | grep -i "dma-controller" | grep $i| head -n 1 | tail -n 1| cut -d':' -f 1`
   interrupts=`cat /proc/interrupts | grep "${IRQ_NUM}:" | cut -d':' -f 2`
   INT_NUM=`echo $interrupts | cut -d' ' -f $(( $CPU_NUM + 1 ))`
   TOTAL_INT_NUM=`expr $TOTAL_INT_NUM + $INT_NUM`
done
## Return number of interrupts
echo $TOTAL_INT_NUM

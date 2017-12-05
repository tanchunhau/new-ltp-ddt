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
# @params d) y/n
# @returns Display/capture device node
# @history 2011-03-05: First version

# Refactor script to allow filtering for the type of video device (vpe, vip, etc)
# @history 2017-12-05: First version

source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################
usage()
{
cat <<-EOF >&1
        usage: ./${0##*/} [-d TYPE]
        -d TYPE      (Optional) type of video device to filter for
        -h Help      print this usage
EOF
exit 0
}

############################ Script Variables ##################################
TYPE=".*"

################################ CLI Params ####################################
while getopts  :d:h arg
do case $arg in
        d)      TYPE="$OPTARG";;
        h)      usage;;
        \?)     die "Invalid Option -$OPTARG ";;
esac
done


########################### DYNAMICALLY-DEFINED Params #########################

########################### REUSABLE TEST LOGIC ###############################

for devicenode in `ls /sys/class/video4linux/ | grep video`
do
        cat /sys/class/video4linux/${devicenode}/name | grep -i -q "${TYPE}" && echo $devicenode
done




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

# @desc Download a file from the URL specified to a file with the name
#       defined in option -o in a device specified with option -d
# @params u) Source URL
#         d) destination device type
#         o) local file name
# @returns the absolute path of the destination file
# @history 2017-01-23: First version

source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################
usage()
{
cat <<-EOF >&1
        usage: ./${0##*/} -u URL [-d DEV_TYPE] [-o O_FILE] 
        -u URL       source url of the video file
        -d DEV_TYPE  destination storage device mmc, usb, etc. default mmc
        -o O_FILE    destination file name
        -h Help      print this usage
EOF
exit 0
}

############################ Script Variables ##################################
DEV_TYPE="mmc"
O_FILE="test.file"

################################ CLI Params ####################################
# Please use getopts
while getopts  :u:h:o:d: arg
do case $arg in
        u)      URL="$OPTARG";;
        d)      DEV_TYPE="$OPTARG";;
        o)      O_FILE="$OPTARG";;
        h)      usage;;
        :)      die "$0: Must supply an argument to -$OPTARG.";; 
        \?)     die "Invalid Option -$OPTARG ";;
esac
done

if [ -z "$URL" ]
then
  usage
fi

(dev_node=$(get_blk_device_node.sh $DEV_TYPE) && \
mnt_pt=$((blk_device_do_mount.sh -n ${dev_node} -f ext4 -d $DEV_TYPE || \
         blk_device_prepare_format.sh -d $DEV_TYPE -f ext4) | \
         grep -o "${dev_node} on /mnt/.* type ext4" | tail -1 | \
         grep -o "/mnt/[^ ]*") && \
file=${mnt_pt}/${O_FILE} && \
Wget ${URL} -O  ${file} && \
echo $file) || \
die "Unable to fetch source media from $URL"






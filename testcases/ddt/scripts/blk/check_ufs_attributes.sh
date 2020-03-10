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

# Check UFS attributes

source "common.sh"
source "blk_device_common.sh"

############################# Functions #######################################

############# Do the work ###########################################
usage()
{
cat <<-EOF >&2
    usage: ./${0##*/} [-t attr_type] [-e Expected] [-a attribute_number]
    -t attr_type  attribute type like 'speed', 'lanes', 'series'
    -e Expected Expected value for this attribuite type 
    -a UFS UniPro attribute number in Hex. ex 0x1560 for PA_ActiveTxDataLans 
    -h Help print this usage
EOF
exit 0
}

while getopts  :t:e:a:h arg
do case $arg in
    t) attr_type=$OPTARG ;;
    e) expected=$OPTARG ;;
    a) attr_number=$OPTARG ;;
    h) usage;;
    :) echo "$0: Must supply an argument to -$OPTARG." >&2
       exit 1
       ;;

    \?) echo "Invalid Option -$OPTARG ignored." >&2
        usage
        exit 1
        ;;
esac
done

do_cmd 'which ufs-tool' || die "ufs-tool is not in the filesystem"

do_cmd "ufs-tool uic -h"
do_cmd "ufs-tool uic -t 1 -i ${attr_number} -p /dev/bsg/ufs-bsg0"
attribute_dump=`do_cmd "ufs-tool uic -t 1 -i ${attr_number} -p /dev/bsg/ufs-bsg0" `
this_attr_hex=`echo ${attribute_dump} |grep -Eo 'local\s*=\s*[0-9x]+' |cut -d'=' -f2 |sed 's/0x//g' `
this_attr=`echo "ibase=16; $this_attr_hex" |bc` 
if [[ "$this_attr" = $expected ]]; then
  echo "UFS is working at the expected $attr_type" 
else
  echo "UFS is not working at the expected ${attr_type}; expected: ${expected} current: ${this_attr} "
fi


















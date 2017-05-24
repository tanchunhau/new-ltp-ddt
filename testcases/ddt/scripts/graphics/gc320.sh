#!/bin/sh
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

# Test basic functionality of gc320 
# Input: None
# Output: 0 on success, 1 on failure

usage()
{
cat <<-EOF >&2
        usage: ./${0##*/} [-b BASE_ADDRESS]
        -b BASE_ADDRESS of memory
        -h Help         print this usage
EOF
exit 0
}


BASE_ADDRESS=0x80000000

OPTIND=1
while getopts :b: arg
    do case $arg in
            b)
                    BASE_ADDRESS=$OPTARG ;;
            \?)
                    echo "Invalid Option -$OPTARG ignored." >&2
                    usage
                    exit 1
                    ;;
    esac
done

mem_kb=$(cat /proc/meminfo | grep -i memtotal | grep -o '[0-9]*'); mem_bits=$(echo "obase=2; print($mem_kb*1024)" | bc -l);
phy_size=$(printf '%x' $((2**${#mem_bits})))

if [ $((0x${phy_size})) -gt $((0x80000000)) ]
then
  echo "Memory size ${phy_size} is greater than 0x80000000, limiting to 0x80000000"
  phy_size='80000000'
fi

GC_TEST_ROOT=/usr/bin/GC320/tests/unit_test
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${GC_TEST_ROOT}
echo "Memory size used: 0x$phy_size"

modprobe galcore baseAddress=${BASE_ADDRESS} physSize=0x${phy_size} || exit 1

num_test=$(cat ${GC_TEST_ROOT}/runtest.sh | grep galRunTest | wc -l)
pushd ${GC_TEST_ROOT}
test_log=$(./runtest.sh)
echo "$test_log"

tst_cnt=$(echo "$test_log" | grep galRunTest | wc -l)

if [ $num_test -gt $tst_cnt ]
then
  echo "Test failure detected!!!"
  exit 1
fi

echo "$test_log" | grep 'Rendering.*frame [0-9]' | grep -v '... succeed'
if [ $? -eq 0 ]
then
  echo "Frame rendering failed!!!"
  exit 1
fi

echo "Test Passed"
exit 0

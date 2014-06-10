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

#@desc RPMsg enables the host processor to offload some of the CPU-intensive tasks to the remote processors.
#      This offloading is done using RPMSGing. RPMsg is a framework which include a different layers (modules).
#      This test loads the all modules and executes sample test to verify functionality of RPMsging.
# @returns The return for the script will be test status, pass or fail. 
# @history 2014-4-16: First version

source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################
usage()
{
cat <<-EOF >&2
  usage: ./${0##*/} [-t LOOP_NUMBER]  [-c CORE_ID] 
    -t LOOP_NUMBER  The number of loops the test has to run. 
                    1: 1000
                    2: 10000
                    3: 1000000
    -c CORE_ID    Core ID with which to communicate.
                    0: IPU CORE0 (default)
                    1: IPU CORE1
                    2: DSP
   -h Help   print this usage
EOF
exit 0
}


############################ Script Variables ##################################
declare -a modules

################################ CLI Params ####################################
# Please use getopts
while getopts  :t:c:h arg
do case $arg in
  t) LOOP_NUMBER="$OPTARG";;
  c) CORE_ID="$OPTARG";; 
  h)  usage;;
  :)  test_print_trc "$0: Must supply an argument to -$OPTARG." >&2
    exit 1 
    ;;

  \?)  test_print_trc "Invalid Option -$OPTARG ignored." >&2
    usage 
    exit 1
    ;;
esac
done

############################ USER-DEFINED Params ###############################
modules=(remoteproc omap_remoteproc virtio_rpmsg_bus rpmsg_proto)

do_cmd depmod -a 

for i in "${modules[@]}"
  do
    do_cmd modprobe ${modules[i]}
  done 


for i in "${modules[@]}"
  do
    modprobe_status=(`lsmod | grep -o ${modules[i]}`)
    if [ -z "$modprobe_status" ]
    then
     test_print_trc "Failed to load ${modules[i]}"
     exit 1
    fi
  done 


files=( "/etc/passwd" "/etc/group" "/etc/hosts" )
for i in "${files[@]}"
do
    echo $i
done


test_app_status=(`ls /usr/bin/ | grep lad`);
if [ -z "$test_app_status" ]
then
 test_print_trc "Failed to load modules"
 exit 1
fi

test_status=`/usr/bin/${test_app_status}`

echo "/usr/bin/MessageQApp  ${LOOP_NUMBER} ${CORE_ID}"
test_status=`/usr/bin/MessageQApp ${LOOP_NUMBER}  ${CORE_ID}  | grep -o 'Sample\s\+application\s\+successfully\s\+completed'`

for i in "${modules[@]}"
  do
    do_cmd rmmod ${modules[i]}
  done 

echo $test_status
if [ -z "$test_status" ]
then
 test_print_trc "Failed Test case: MessageQApp ${LOOP_NUMBER} ${CORE_ID}"
 exit 1
fi

exit 0





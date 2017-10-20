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

source "common.sh"  # Import do_cmd(), die() and other functions

# This fucntion sets up the appropriate firmware that will be loaded on the
# remote processor for IPC related test
# Inputs:
#    $1: name pattern of the firmware files that should be loaded. These files
#        should be located in /lib/firmware folder of the file system
setup_firmware()
{
  local __fw_pattern=$1
  local __fw_dir='/lib/firmware'
  local __fw_file
  local __fw_files=$(ls /sys/class/remoteproc/remoteproc*/firmware)
  local __fw
  local __new_pattern
  local __fw_type
  for __fw_dst in $__fw_files
  do
    __fw=$(cat ${__fw_dst})
    case $__fw in
      *dsp*)
        __fw_type=dsp
        __new_pattern=$(find_firmware_id "$__fw" dsp)
        ;;
      *ipu*)
        __fw_type=ipu
        __new_pattern=$(find_firmware_id "$__fw" ipu)
        ;;
      *pru*)
        __fw_type=pru
        __new_pattern=$(find_firmware_id "$__fw" pru)
        ;;
      am335x-pm-firmware*)
        continue
        ;;
      *)
        __fw_type=.*
        __new_pattern=.*
        ;;
    esac

    __fw_file=$(find ${__fw_dir} -type f -name "${__fw_pattern}" | grep "${__fw_type}" | grep "${__new_pattern}")
    if [[ -z $__fw_file ]]
    then
      __fw_file=$(find ${__fw_dir} -type f -name "${__fw_pattern}")
    fi
    if [[ !  -z  $__fw_file  ]]
    then
      echo "Setting ${__fw_file:14} on $__fw_dst ..."
      echo "${__fw_file:14}" > $__fw_dst
    else
      echo "Could not find fw matching $__fw_pattern for $__fw_dst"
    fi
  done
}

find_firmware_id()
{
  echo "$1" | grep -o "$2[^-]*" | grep -o '[0-9].*'
}

# Function to rmod the rpmsg loadable modules so that new firmware can 
# be loaded in the remote processors
rm_ipc_mods()
{

  local __modules=(rpmsg_rpc rpmsg_proto rpmsg_client_sample omap_remoteproc keystone_remoteproc remoteproc virtio_rpmsg_bus rpmsg_core)

  reset_rproc_mpm
  kill_lad
  kill_mpm_daemon

  toggle_rprocs stop

  rm_pru_mods

  for __mod in ${__modules[@]}
  do
    modprobe -r ${__mod}
  done
}

# Function to insmod the modules require to run RPMSG. Without parameters
# Inputs:
#   $*: (Optional) Additional modules to load, i.e 'rpmsg_rpc', 'rpmsg_proto', etc
ins_ipc_mods()
{
  local __modules
  case $MACHINE in
    k2*)
      modprobe keystone_remoteproc use_rproc_core_loader=1
      for __mod in $*
      do
        modprobe ${__mod}
      done
    ;;
    *)
      __modules=(remoteproc omap_remoteproc keystone_remoteproc virtio_rpmsg_bus rpmsg_core)
  
      if [ $# -gt 0 ];
      then
        __modules+=($*)
      fi
  
      for __mod in ${__modules[@]}
      do
        insmod.sh ${__mod}
      done
    ;;
  esac
  ins_pru_mods
  sleep 10
}

# Function to insmod the modules require to run RPMSG test with mpm
ins_ipc_mods_mpm()
{
  case $MACHINE in
    k2*)
      modprobe keystone_remoteproc
      for __mod in $*
      do
        modprobe ${__mod}
      done
    ;;
    *)
      "MPM remoteproc not supported for $MACHINE"
    ;;
  esac
  sleep 3
}

#Function to load remote procs via mpm for IPC related test
# Inputs:
#    $1: name pattern of the firmware files that should be loaded. These files
#        should be located in /lib/firmware folder of the file system
load_rproc_mpm()
{
  local __fw_pattern=$1
  local __fw_dir='/lib/firmware'
  local __fw_files=$(find $__fw_dir -type f -name "${__fw_pattern}")
  echo "Found $__fw_files fw files..."
  start_mpm_daemon
  case $MACHINE in
    k2*)
      local __procs=$(get_num_remote_procs)
      for i in `seq 0 $((__procs - 1))`
      do
        echo "Loading ${__fw_files} on dsp${i} ..."
#        mpmcl reset dsp${i}
        mpmcl load dsp${i} ${__fw_files}
        mpmcl run dsp${i}
      done
    ;;
    *)
      "MPM remoteproc not supported for $MACHINE"
    ;;
  esac
  sleep 3
}

#Function to reset the remote procs via mpm for IPC related test
# Inputs:
#    None
reset_rproc_mpm()
{
  case $MACHINE in
    k2*)
      local __procs=$(get_num_remote_procs)
      for i in `seq 0 $((__procs - 1))`
      do
        echo "Resetting ${__fw_files} on dsp${i} ..."
        mpmcl reset dsp${i}
      done
    ;;
    *)
      "MPM reset not supported for $MACHINE"
    ;;
  esac
}


ins_pru_mods()
{
  local __modules=(pruss pru_rproc pruss_soc_bus prueth)

  case $MACHINE in
    am57*|am43xx*|am335x*|k2g*)
      for __mod in ${__modules[@]}
      do
        modprobe ${__mod}
      done
      sleep 3
    ;;
  esac
}

rm_pru_mods()
{
  local __modules=(prueth rpmsg_pru pru_rproc pruss pruss_soc_bus)

  for p in `ifconfig | grep 'HWaddr' | grep -o '^[a-z0-9]\+'`
  do
    ifconfig $p | grep -e 'inet addr' -e 'inet6 addr' || ifconfig $p down
  done

  for __mod in ${__modules[@]}
  do
    modprobe -r ${__mod}
  done
}

kill_mpm_daemon()
{
  case $MACHINE in
    k2*)
      systemctl stop mpmsrv-daemon
    ;;
  esac
}

start_mpm_daemon()
{
  case $MACHINE in
    k2*)
      systemctl start mpmsrv-daemon; sleep 2
    ;;
  esac
}

# Function to obtain the number of remote processors in the SOC.
# Returns:
#  The number of remote processors in the SOC
get_num_remote_procs()
{
  case $SOC in
    *dra7xx|*j6plus)
      echo 4
      ;;
    *j6eco|*j6entry)
      echo 3
      ;;
    *keystone)
      local __model=$(cat /proc/device-tree/model)
      case $__model in
        *Hawking*)
          echo 8
        ;;
        *Lamarr*)
          echo 4
        ;;
        *Edison*|*K2G*)
          echo 1
        ;;
      esac
      ;;
    *omapl138)
      echo 1
      ;;
    *)
      echo "SOC ${SOC} not supported"
      return 1
      ;;           
  esac
}

# Function to obtain valid rproc ids for a given SOC.
# Inputs:
#   $1: The number of remote processor to get ids for
# Returns:
#  The proc ids of the remote procs
get_rpmsg_proto_rproc_ids()
{ 
  case $SOC in
    *dra7xx|*j6plus)
      rids=( `seq 1 4` )
      ;;
    *j6eco|*j6entry)
      rids=( 1 2 4 )
      ;;
    *keystone)
      local __model=$(cat /proc/device-tree/model)
      case $__model in
        *Hawking*)
          rids=( `seq 1 8` )
        ;;
        *Lamarr*)
          rids=( `seq 1 4` )
        ;;
        *Edison*|*K2G*)
          rids=( 1 )
        ;;
      esac
      ;;
    *omapl138)
      rids=( 1 )
      ;;
    *)
      echo "SOC ${SOC} not supported"
      return 1
      ;;           
  esac
  echo ${rids[@]::$1}
}

# Funtion to creat the RPMSG-RPC test cmds
# Inputs:
#   -p: The number of remote processor to use in the test
#   -f: (Optional) The function or part of the function name to execute
#       in the remote processor. Defaults to _triple
#   -m: (Optional) int used to trigger an MMU fault while running the test.
#       0:Fault on first message, 1: Fault on middle messsage 
#       2: Fault on last message 
#   -s: (Optional) the time in sec after which the test should be killed,
#       or if -a is specified after -c command will be sent.
#       This option is useful to test stability, 
#   -t: variable to store the single proc test commands array
#   -u: variable to store the multi-proc test commands array
#   -n: variable to store the number of processors to test
#   -c: (Optional) command to send after time -s seconds
# Returns, 0 if the test passed, 1 if the single processor test failed,
#          2 if the multiprocessors test failed, or 3 if both single and
#          multiprocessor test fails
rpmsg_rpc_test_cmds()
{
  local __num_procs
  local __kill_time=0
  local __result=0
  local __instances=10
  local __f_name='_triple'
  local __msg_num=''
  local __multiproc_cmds=("" "" "" "")
  local __rpc_cmd='test_rpmsg_rpc'
  local __test_log
  local __num_match
  local __command
  local __add_cmd=''
  local __n_procs
  local __s_cmds
  local __m_cmds

  OPTIND=1 
  local _iterations
  while getopts :p:c:f:s:m:t:u:n: arg
  do 
    case $arg in
      p)  __num_procs="$OPTARG";;
      s)  __kill_time="$OPTARG";;
      f)  __f_name="$OPTARG";;
      m)  __msg_num="-m $OPTARG";;
      c)  __add_cmd="$OPTARG";;
      t)  __s_cmds="$OPTARG";;
      u)  __m_cmds="$OPTARG";;
      n)  __n_procs="$OPTARG";;

      \?)  test_print_trc "Invalid Option -$OPTARG ignored." >&2
      ;;
    esac
  done

  eval "${__s_cmds}=()"
  eval "${__m_cmds}=()"
  eval "${__n_procs}=${__num_procs}"

  for __rproc in `seq 0 $((__num_procs - 1))`
  do
    __multiproc_cmds[0]="${__multiproc_cmds[0]} & $__rpc_cmd -t $((__rproc % 3 + 1)) -c $__rproc -x $__instances -l $__instances -f $__f_name $__msg_num"
    __multiproc_cmds[1]="${__multiproc_cmds[1]} & $__rpc_cmd -t 1 -c $__rproc -x $__instances -l $__instances -f $__f_name $__msg_num"
    __multiproc_cmds[2]="${__multiproc_cmds[2]} & $__rpc_cmd -t 2 -c $__rproc -x $__instances -l $__instances -f $__f_name $__msg_num"
    __multiproc_cmds[3]="${__multiproc_cmds[3]} & $__rpc_cmd -t 3 -c $__rproc -x $__instances -l $__instances -f $__f_name $__msg_num"
    for __t_type in `seq 1 3`
    do
      __command="$__rpc_cmd -t $__t_type -c $__rproc -x $__instances -l $__instances -f $__f_name $__msg_num"
      if [ $__kill_time -gt 0 ]
      then
        __command="${__command} & sleep $__kill_time; "
        if [ "$__add_cmd" != '' ]
        then
          __command="${__command} $__add_cmd"
        else
          __command="${__command} killall $__rpc_cmd"
        fi 
      fi
      eval "${__s_cmds}+=(\"$__command\")"
    done
  done

  if [ $__num_procs -gt 1 ]
  then
    i=0
    for __cmd in "${__multiproc_cmds[@]}"
    do
      if [ $__kill_time -gt 0 ]
      then
        __cmd="${__cmd} & sleep $__kill_time;"
        if [ "$__add_cmd" != '' ]
        then
          __cmd="${__cmd} $__add_cmd"
        else
          __cmd="${__cmd} killall $__rpc_cmd" 
        fi
      fi
      eval "${__m_cmds}[$i]=\"${__cmd:3}\""
      i=$((i+1))
    done
  else
    eval "${__m_cmds}=()"
  fi

}

# Funtion to run the RPMSG-RPC test
# Inputs:
#   -p: The number of remote processor to use in the test
#   -f: (Optional) The function or part of the function name to execute
#       in the remote processor. Defaults to _triple
#   -m: (Optional) int used to trigger an MMU fault while running the test.
#       0:Fault on first message, 1: Fault on middle messsage 
#       2: Fault on last message 
#   -s: (Optional) the time in sec after which the test should be killed,
#       or if -a is specified after -c command will be sent.
#       This option is useful to test stability, 
#   -c: (Optional) command to send after time -s seconds
# Returns, 0 if the test passed, 1 if the single processor test failed,
#          2 if the multiprocessors test failed, or 3 if both single and
#          multiprocessor test fails
rpmsg_rpc_test()
{
  local __result=0
  local __f_name='_triple'
  local __test_log
  local __num_match
  local __command

  rpmsg_rpc_test_cmds -t s_cmds -u m_cmds -n num_procs $*

  for __command in "${s_cmds[@]}"
  do
    echo $__command
    __test_log=$(eval $__command)
    __num_match=$(echo -e "$__test_log" | grep -c -i "TEST STATUS: PASSED")
    if [ $__num_match -ne 1 ]
    then
      __result=1
      echo -e "${__test_log}\n$__command failed"
    else
      echo "$__command passed"
    fi
  done

  for __cmd in "${m_cmds[@]}"
  do
    __test_log=$(eval ${__cmd})
    __num_match=$(echo -e "$__test_log" | grep -i -c "TEST STATUS: PASSED")
    echo -e "$__num_match processors passed..."
    if [ $__num_match -ne $num_procs ]
    then
      let "__result|=2"
      echo -e "$__test_log\nTest failed for ${__cmd}"
    else
      echo -e "Test passed for ${__cmd}"
    fi
  done

  return $__result
}

# Funtion to test recovery in rpmsg_rpc
# Inputs:
#   -p: The number of remote processor to use in the test
#   -f: (Optional) The function or part of the function name to execute
#       in the remote processor. Defaults to _triple
#   -m: (Optional) int used to trigger an MMU fault while running the test.
#       0:Fault on first message, 1: Fault on middle messsage 
#       2: Fault on last message 
#       This option is useful to test stability,
# Returns, 0 if the test passed, 1 if the single processor test failed,
#          2 if the multiprocessors test failed, or 3 if both single and
#          multiprocessor test fails
rpmsg_rpc_recovery_test()
{
  local __result=0
  local __f_name='_triple'
  local __test_log
  local __num_match
  local __command
  local __mr_events=''

  rpmsg_rpc_test_cmds -t s_cmds -u m_cmds -n num_procs $*

  rpmsg_recovery_event __rec_events

  i=0
  #single rproc recovery
  for __cmd in "${m_cmds[@]}"
  do
    __command="${__cmd} & sleep 5; ${__rec_events[$((i % num_procs))]}"
    __test_log=$(eval ${__command})
    __num_match=$(echo -e "$__test_log" | grep -i -c "TEST STATUS: PASSED")
    echo -e "$__num_match processors passed..."
    if [ $__num_match -ne $num_procs ]
    then
      let "__result|=2"
      echo -e "$__test_log\nTest failed for ${__command}"
    else
      echo -e "Test passed for ${__command}"
    fi
    i=$((i+1))
  done
  
  
  __mr_events="${__rec_events[0]}"
  for i in `seq 1 $((${#__rec_events[@]} - 1))`
  do
    __mr_events="${__mr_events} && ${__rec_events[$i]}"
  done
  
  #Multiple rproc recovery
  for __cmd in "${m_cmds[@]}"
  do
    __command="${__cmd} & sleep 5; ${__mr_events[@]}"
    __test_log=$(eval ${__command})
    __num_match=$(echo -e "$__test_log" | grep -i -c "TEST STATUS: PASSED")
    echo -e "$__num_match processors passed..."
    if [ $__num_match -ne $num_procs ]
    then
      let "__result|=2"
      echo -e "$__test_log\nTest failed for ${__command}"
    else
      echo -e "Test passed for ${__command}"
    fi
  done

  return $__result
}

#Function to stop the ipc lad daemon
kill_lad()
{
  case $MACHINE in
    *dra7xx-evm|*am57*)
      killall lad_dra7xx
      ;;
    k2*)
      local __model=$(cat /proc/device-tree/model)
      case $__model in
        *Hawking*)
          killall lad_tci6638
        ;;
        *Lamarr*)
          killall lad_tci6630
        ;;
        *Edison*)
          killall lad_66ak2e
        ;;
        *K2G*)
          killall lad_66ak2g
        ;;
      esac
      ;;
    omapl138*)
      killall lad_omapl138
      ;;
    *)
      echo "Machine ${MACHINE} not supported"
      return 1
      ;;           
  esac
  
  return 0
}

#Function to start the ipc lad daemon
start_lad()
{
  case $MACHINE in
    *dra7xx-evm|*am57*)
      lad_dra7xx
      ;;
    k2*)
      local __model=$(cat /proc/device-tree/model)
      case $__model in
        *Hawking*)
          lad_tci6638
        ;;
        *Lamarr*)
          lad_tci6630
        ;;
        *Edison*)
          lad_66ak2e
        ;;
        *K2G*)
          lad_66ak2g
        ;;
      esac
      ;;
    omapl138*)
      lad_omapl138
      ;;
    *)
      echo "Machine ${MACHINE} not supported"
      return 1
      ;;           
  esac
}

# Funtion to run the RPMSG-RPC test
# Inputs:
#   $1: The number of remote processor to use in the test
#   $2: (Optional) number of loops. Default 5000
#   $3: (Optional) the time in sec after which the test should be killed,
#       or if $4:* is specified after $4 will be sent.
#       This option is useful to test stability, 
#   $4:*: (Optional) command to send after time $3 seconds
# Returns, 0 if the test passed, 1 if the single processor test failed,
#          2 if the multiprocessors test failed, or 3 if both single and
#          multiprocessor test fails
rpmsg_proto_msgqapp_test()
{
  local __num_procs=$1
  local __kill_time=0
  local __result=0
  local __loops=5000
  local __multiproc_cmd=""
  local __ipc_cmd='MessageQApp'
  local __test_log
  local __num_match
  local __command
  local __rproc_ids=$(get_rpmsg_proto_rproc_ids $__num_procs)
  
  if [ $# -gt 1 ]
  then
    __loops=$2
  fi
  if [ $# -gt 2 ]
  then
    __kill_time=$3
  fi
  
  for __rproc in $__rproc_ids
  do
    __multiproc_cmd="$__multiproc_cmd & $__ipc_cmd $__loops $__rproc"
    __command="$__ipc_cmd $__loops $__rproc"
    if [ $__kill_time -gt 0 ]
    then
      __command="${__command} & sleep $__kill_time; "
      if [ $# -gt 3 ]
      then
        __command="${__command} ${@:4}"
      else
        __command="${__command} killall $__ipc_cmd"
      fi 
    fi
    echo $__command
    __test_log=$(eval $__command)
    __num_match=$(echo -e "$__test_log" | grep -c -i 'Sample\s\+application\s\+successfully\s\+completed')
    if [ $__num_match -ne 1 ]
    then
      __result=1
      echo -e "${__test_log}\nTest failed for proc ${__rproc}"
    else
      echo "Test passed for proc $__rproc"
    fi
  done

  if [ $__num_procs -gt 1 ]
  then
    if [ $__kill_time -gt 0 ]
    then
      __multiproc_cmd="${__multiproc_cmd} & sleep $__kill_time; "
      if [ $# -gt 3 ]
      then
        __multiproc_cmd="${__multiproc_cmd} ${@:4}"
      else
        __multiproc_cmd="${__multiproc_cmd} killall $__ipc_cmd"
      fi
    fi
    echo ${__multiproc_cmd:3}
    __test_log=$(eval ${__multiproc_cmd:3})
    __num_match=$(echo -e "$__test_log" | grep -i -c 'Sample\s\+application\s\+successfully\s\+completed')
    echo -e "$__num_match processors passed..."
    if [ $__num_match -ne $__num_procs ]
    then
      let "__result|=2"
      echo -e "$__test_log\nTest failed for ${__multiproc_cmd:3}"
    else
      echo -e "Test passed for ${__multiproc_cmd:3}"
    fi
  fi
  
  return $__result
}

# Funtion to run the RPMSG-RPC test
# Inputs:
#   $1: The number of remote processor to use in the test
#   $2: (Optional) number of loops. Default 5000
#   $3: (Optional) payload size. Default 8
# Returns, 0 if perf data was collected, 1 if not
rpmsg_proto_msgqbench_test()
{
  local __num_procs=$1
  local __result=0
  local __loops=5000
  local __payload_sz=8
  local __multiproc_cmd=""
  local __ipc_cmd='MessageQBench'
  local __test_log
  local __num_match
  local __command
  local __rproc_ids=$(get_rpmsg_proto_rproc_ids $__num_procs)
  
  if [ $# -gt 1 ]
  then
    __loops=$2
  fi
  if [ $# -gt 2 ]
  then
    __payload_sz=$3
  fi
  
  for __rproc in $__rproc_ids
  do
    __multiproc_cmd="$__multiproc_cmd & $__ipc_cmd $__loops $__payload_sz $__rproc"
    __command="$__ipc_cmd $__loops  $__payload_sz $__rproc"
    echo $__command
    __test_log=$(eval $__command)
    __num_match=$(echo -e "$__test_log" | grep -c -i 'Avg\s\+round\s\+trip\s\+time:')
    if [ $__num_match -ne 1 ]
    then
      __result=1
      echo -e "${__test_log}\nTest failed for proc ${__rproc}"
    else
      echo "Test passed for proc $__rproc"
      test_print_trc " ROUNDTRIP_TIME | $(echo -e "$__test_log" | grep -i 'Avg\s\+round\s\+trip\s\+time:')"
    fi
  done

  if [ $__num_procs -gt 1 ]
  then
    echo ${__multiproc_cmd:3}
    __test_log=$(eval ${__multiproc_cmd:3})
    __num_match=$(echo -e "$__test_log" | grep -c -i 'Avg\s\+round\s\+trip\s\+time:')
    echo -e "$__num_match processors passed..."
    if [ $__num_match -ne $__num_procs ]
    then
      let "__result|=2"
      echo -e "$__test_log\nTest failed for ${__multiproc_cmd:3}"
    else
      echo -e "Test passed for ${__multiproc_cmd:3}"
      test_print_trc " ROUNDTRIP_TIME_MULTI | $(echo -e "$__test_log" | grep -i 'Avg\s\+round\s\+trip\s\+time:')"
    fi
  fi
  
  return $__result
}

# Funtion to run the RPMSG-RPC test
# Inputs:
#   $1: (Optional) The number of threads to use in the test. 
#       Default 10
#   $2: (Optional) number of loops. Default 5000
#   $3: (Optional) the time in sec after which the test should be killed,
#       or if $4:* is specified after $4 will be sent.
#       This option is useful to test stability, 
#   $4:*: (Optional) command to send after time $3 seconds
# Returns, 0 if succesful, 1 otherwise
rpmsg_proto_msgqmulti_test()
{
  local __kill_time=0
  local __result=0
  local __loops=5000
  local __num_threads=10
  local __ipc_cmd='MessageQMulti'
  local __test_log
  local __num_match
  local __command
  if [ $# -gt 0 ]
  then
    __num_threads=$1
  fi
  if [ $# -gt 1 ]
  then
    __loops=$2
  fi
  if [ $# -gt 2 ]
  then
    __kill_time=$3
  fi
  
  __command="$__ipc_cmd $__num_threads $__loops"
  if [ $__kill_time -gt 0 ]
  then
    __command="${__command} & sleep $__kill_time; "
    if [ $# -gt 3 ]
    then
      __command="${__command} ${@:4}"
    else
      __command="${__command} killall $__ipc_cmd"
    fi 
  fi
  echo $__command
  __test_log=$(eval $__command)
  __num_match=$(echo -e "$__test_log" | grep -c -i 'pingThreadFxn\s\+successfully\s\+completed')
  if [ $__num_match -ne $__num_threads ]
  then
    __result=1
    echo -e "${__test_log}\nTest failed..."
  else
    echo "Test passed..."
  fi
  
  return $__result
}

# Funtion to run the RPMSG client sample test based on the kernel's 
# samples/rpmsg module
# Inputs:
#   $1: Number of remote proccessors in the SOC
#   $2: (Optional) Number of trials. Defaults to 1 
# Returns, 0 if succesful, 1 otherwise
rpmsg_client_sample_test()
{
  local __result=0
  local __test_log
  local __num_goodbye
  local __num_procs=$1
  local __command
  local __loops=1
  
  if [ $# -gt 1 ]
  then
    __loops=$2
  fi
  
  for idx in `seq 1 $__loops`
  do
    __test_log=$(dmesg -c > /dev/null && modprobe rpmsg_client_sample || modprobe -f rpmsg_client_sample && sleep 3 && dmesg)
    __num_match=$(echo -e "$__test_log" | grep -c -i 'rpmsg[0-9]\+: incoming msg 100')
    __num_goodbye=$(echo -e "$__test_log" | grep -c -i 'rpmsg[0-9]\+: goodbye!')
    if [ $__num_match -ne 1 -o  $__num_goodbye -ne $(($__num_procs * 2)) ]
    then
      __result=$((__result + 1))
      echo -e "${__test_log}\nTest failed..."
    else
      echo "Test passed..."
    fi
    rmmod rpmsg_client_sample
  done
  
  return $__result
}

# Funtion obtain the command that may be used to trigger a recovery
# event
# Inputs:
#   $1: Variable to store the array of recovery events commands
# Returns:
#   An array of string containing the commands to trigger the driver's crash
#   recovery mechanism is stored in $1
rpmsg_recovery_event()
{
  local __mbox_q_addr
  local __command=""
  
  eval "$1=()"
  case $MACHINE in
    *dra7*|*am57*)
      __mbox_q_addr=('0x48840044' '0x48840050' '0x48842044' '0x48842050')
      ;;
    *)
      echo "Machine ${MACHINE} not supported"
      return 1
      ;;           
  esac
  
  for __mb_addr in ${__mbox_q_addr[@]}
  do
    eval "$1+=(\"devmem2 $__mb_addr w 0xffffff02\")"
  done

}

# Function to bind/unbind the prus
# Inputs:
#   $1: action to perform, either "stop" or "start"
toggle_rprocs()
{
  local __driver_sysfs='/sys/class/remoteproc'

  for __pru in `ls ${__driver_sysfs}/`
  do
    cat ${__driver_sysfs}/${__pru}/device/of_node/name | grep wkup_m3 && continue
    echo "${1}ing $__pru ..."
    echo $1 > ${__driver_sysfs}/${__pru}/state
  done
}

# Funtion to obtain the list of pru devices
# Returns the list of PRU devices based on the MACHINE var value
list_prus()
{
  case $MACHINE in
    am43xx*)
      echo "54434000.pru0 54438000.pru1"
    ;;
    am335x*)
      echo "4a334000.pru0 4a338000.pru1"
    ;;
    am57*)
      echo "4b234000.pru0 4b238000.pru1 4b2b4000.pru0 4b2b8000.pru1"
    ;;
    k2g*)
      echo "20ab4000.pru0 20ab8000.pru1 20af4000.pru0 20af8000.pru1"
    ;;
    *)
      echo "Machine ${MACHINE} not supported"
    ;;
  esac
}

# Funtion to obtain the list of pru devices
# Returns the list of PRU devices based on the MACHINE var value
list_pru_devs()
{
  case $MACHINE in
    am335x*)
      for i in `seq 0 1`
      do
        echo "/dev/rpmsg_pru3${i}"
      done
    ;;
    am57*|am43xx*|k2g*)
      for i in `seq 0 3`
      do
        echo "/dev/rpmsg_pru3${i}"
      done
    ;;
    *)
      echo "Machine ${MACHINE} not supported"
    ;;
  esac
}

# Funtion to obtain the list of pru devices
# Returns the list of PRU devices based on the MACHINE var value
list_rprocs()
{
  case $SOC in
    dra7xx)
      echo "40800000.dsp 41000000.dsp 58820000.ipu 55020000.ipu"
    ;;
    j6eco)
      echo "40800000.dsp 58820000.ipu 55020000.ipu"
    ;;
    keystone)
      case $MACHINE in
        k2g-evm|k2e-evm)
          echo "10800000.dsp0"
        ;;
        k2l-evm)
          echo "10800000.dsp0 11800000.dsp1 12800000.dsp2 13800000.dsp3"
        ;;
        k2hk-evm)
          echo "10800000.dsp0 11800000.dsp1 12800000.dsp2 13800000.dsp3 14800000.dsp4 15800000.dsp5 16800000.dsp6 17800000.dsp7"
        ;;  
      esac
    ;;
    *)
      echo "Machine ${MACHINE} not supported"
    ;;
  esac
}

rpmsg_pru_test()
{
  local __test_cmd='test_rpmsg_pru'
  local __pru_list=( $(list_pru_devs) )
  local __num_msg=1000
  local __result=0

  for dev in ${__pru_list[@]}
  do
     echo -e "$(test_rpmsg_pru ${dev} ${__num_msg})"  | grep -i "Received ${__num_msg} messages, closing ${dev}" ;
     if [ $? -ne 0 ]
     then
       __result=1
       echo "Test failed for ${dev}"
     fi
  done

  if [ ${#__pru_list[@]} -gt 1 ]
  then
    local __multi_test_cmd="${__test_cmd} ${__pru_list[0]} ${__num_msg}"
    for i in `seq 1 $((${#__pru_list[@]}-1))`
    do
      __multi_test_cmd="${__multi_test_cmd} & ${__test_cmd} ${__pru_list[${i}]} ${__num_msg}"
    done
     echo -e "$(eval ${__multi_test_cmd})"  | grep -i "Received ${__num_msg} messages, closing" | wc -l | grep ${#__pru_list[@]}
     if [ $? -ne 0 ]
     then
       __result=1
       echo "Test failed for ${__multi_test_cmd}"
     fi
  fi

  return $__result
}

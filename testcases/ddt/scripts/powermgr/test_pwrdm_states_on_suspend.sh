source 'common.sh'
source 'functions.sh'
source 'board_requirements.sh'

tmp_ifs="$IFS"
IFS=','

collect_log() {
  domains=$1
  collection_time=$2
  local logfile
  for pwrdm_data in $domains; do
    pwrdm=`expr match "$pwrdm_data" '\(.*\):'`
    state=`expr match "$pwrdm_data" '.*:\(.*\)'`
    logfile="${pwrdm}_${collection_time}.log"
    if [ -f ${TMPDIR}/$logfile ]; then
      rm ${TMPDIR}/$logfile
    fi
    do_cmd log_pm_count "$pwrdm" "$state" ':' "${logfile}"
  done
}

compare_log() {
  domains=$1
  for pwrdm_data in $domains; do
    pwrdm=`expr match "$pwrdm_data" '\(.*\):'`
    state=`expr match "$pwrdm_data" '.*:\(.*\)'`
    do_cmd compare_pm_count "${pwrdm}" "${state}" ':' "${pwrdm}_before.log" "${pwrdm}_after.log"
  done
}

run_test() {
  local iterations=1
  if [ -n $1 ]; then
    iterations=$1
  fi
  local domains=`get_power_domain_states_on_suspend "$PLATFORM"`
  local i=0
  while [ $i -lt $iterations ]; do
    report "Running test iteration $i"
    collect_log "$domains" "before"
    suspend
    collect_log "$domains" "after"
    compare_log "$domains"
    let i=i+1
  done
}

run_test $1

IFS="$tmp_ifs"
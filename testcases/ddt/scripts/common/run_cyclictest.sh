#!/bin/sh

# Run cyclictest and compare max latency agains $1 pass criteria
    passcriteria=$1
    shift 1

    /bin/echo $$ > /sys/fs/cgroup/rt/tasks

    cyclictest $@  | awk -v passcriteria=$passcriteria '
      BEGIN {max=0; FS="Max:"};
      {print $0};
      /^T:.+Max:\s+[[:digit:]]+/ {if ($2 > max) max=$2};
      END {print "max_latency=" max};
      END {if (max > passcriteria) {print "TEST:FAILED"; exit 1;} else {print "TEST:PASSED"; exit 0}}'

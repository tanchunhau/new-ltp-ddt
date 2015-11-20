#! /bin/sh
###############################################################################
# Copyright (C) 2015 Texas Instruments Incorporated - http://www.ti.com/
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

# @desc Runs Linaro's PM-QA tests. It requires Make and gcc.
# @returns zero if no test fails and non-zero otherwise.

source "common.sh"  # Import do_cmd(), die() and other functions

############################ Script Variables ##################################
TOOL_REPO="http://git.linaro.org/tools/pm-qa.git"
tmp_dir=`mktemp -d`
tmp_log="$tmp_dir/pm-qa.log"
tmp_result="$tmp_dir/pm-qa.res"

########################### REUSABLE TEST LOGIC ###############################
get_sources() {
  do_cmd "cd ${TMPDIR}"
  if [ -d ${TMPDIR}/pm-qa ]; then
    do_cmd "cd ${TMPDIR}/pm-qa"
    do_cmd "git pull || http_proxy=$SITE_HTTP_PROXY git pull"
  else
    do_cmd "git clone ${TOOL_REPO} || http_proxy=$SITE_HTTP_PROXY git clone ${TOOL_REPO}"
    do_cmd "cd pm-qa"
  fi
}

print_test_results_summary() {
  echo "============================"
  echo "=== TEST RESULTS SUMMARY ==="
  echo "============================"
  cat $tmp_result
}

run_tests() {
  do_cmd "make check 2>&1 > $tmp_log"
  do_cmd "egrep '^[[:alnum:]\_]+:[[:space:]]+(pass|fail|skip)' $tmp_log > $tmp_result"
  print_test_results_summary
  egrep '^[[:alnum:]\_]+:[[:space:]]+fail' $tmp_log && die "Some tests failed"
}

get_sources || die "Could not clone ${TOOL_REPO}"
run_tests

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
# @desc Returns ethernet interrupt pacing interval value
#	depending on platform type
# @params
# @returns
# @history 2012-07-27: First version

source "st_log.sh"
source "common.sh"  # Import do_cmd(), die() and other functions

############################# Functions #######################################

################################ CLI Params ####################################

############################ USER-DEFINED Params ###############################
param="500"
case $ARCH in
esac
case $DRIVER in
esac
case $SOC in
esac
case $MACHINE in
        am57xx-evm|am571x-idk|am572x-idk|dra7xx-evm|dra72xx-evm)
                param="100";;
esac
echo "$param"

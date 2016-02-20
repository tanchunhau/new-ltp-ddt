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

# Get devnode for rtc device'
# Input: None
# Output: Array with all rtc nodes like /dev/rtc0, /dev/rtc1, etc. 

source "common.sh"

########################### DYNAMICALLY-DEFINED Params #########################
# Try to use /sys and /proc information to determine values dynamically.        
# Alternatively you should check if there is an existing script to get the      
# value you want                                                                
: ${DEV_NODE:=`ls /dev/rtc*|grep "rtc[0-9]"`}               
                                                                                
echo $DEV_NODE


#!/bin/sh
# Functions to test TI's tscadc driver modes of operation

source "common.sh"  # Import do_cmd(), die() and other functions

file=`find /sys/firmware/devicetree/ -name "ti\,adc-channels"`
if [ -z $file ]; then
        echo "ti,adc-channels not found on device tree"
        exit 1
fi
data=`hexdump -e '16/1 "%02X"' $file`

test_one_shot_mode() {
        for (( i=0; i<${#data}; i+=8 )); do
                channel=`echo "${data:$i:8}" | bc`
                cat /sys/bus/iio/devices/iio\:device0/in_voltage${channel}_raw || die "Error enabling one-shot mode for in_voltage${channel}_raw"
        done
}

# $1: buffer length per channel
test_continous_mode() {
        n=0
        buffer=$1
        for (( i=0; i<${#data}; i+=8 )); do
                n=$((n + 1))
                channel=`echo "${data:$i:8}" | bc`
                echo 1 > /sys/bus/iio/devices/iio\:device0/scan_elements/in_voltage${channel}_en || die "Error enabling continuous mode for in_voltage${channel}_en"
        done
        echo $buffer > /sys/bus/iio/devices/iio\:device0/buffer/length || die "Error setting continuous mode buffer size of ${buffer}"
        echo 1 > /sys/bus/iio/devices/iio\:device0/buffer/enable || die "Error starting continuous mode"
        sleep $((buffer/10 + 1))
        echo 0 > /sys/bus/iio/devices/iio\:device0/buffer/enable || die "Error stopping continuous mode"
        total=$((buffer * n * 2))
        timeout -t $((buffer/10 + 2)) hexdump -n $total -C /dev/iio:device0 || die "Timeout waiting for expected number of samples to be read"
}

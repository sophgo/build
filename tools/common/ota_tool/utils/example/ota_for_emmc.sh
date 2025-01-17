#!/bin/sh

current_dir=$(pwd)

mount_device=$(df "$current_dir" | awk 'NR==2 {print $1}')

device_number=$(echo "$mount_device" | sed -n 's/.*p\([0-9]\+\)$/\1/p')

fw_setenv ota_part $device_number

fw_setenv ota_enable 1

sync

reboot

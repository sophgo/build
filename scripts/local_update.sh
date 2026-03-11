#!/bin/bash

# this is se6 ota update script
if [ $# -lt 1  ] ; then
        echo "need md5 file"
        exit 1
fi

echo ">>>>>start upgrade app package..."

echo ">>>>>md5sum check ..."
CHECK_SCRIPT="./check_partition_start_sector.sh"
UPDATE_GPT_SCRIPT="./update_partition_gpt.sh"
basepath=$(cd `dirname $0`; pwd)
echo $basepath
cd $basepath
rm -rf ota_versino.txt
md5sum -c $1 > ota_versino.txt
ret=$?
count=$#
rootpath="/data/ota"

if [ $ret -ne 0 ]; then
    echo ">>>>> upgrade package is wrong stop upgrade..."
    echo "update failed"
    exit 1
else
    if bash "$CHECK_SCRIPT"; then
        echo "✓ Partition check passed."
    else
        echo "ERROR: Partition check failed! OTA update aborted." >&2
        exit 1
    fi
    if bash "$UPDATE_GPT_SCRIPT"; then
        echo "✓ Partition update passed."
    else
        echo "ERROR: Partition update failed! OTA update aborted." >&2
        exit 1
    fi
    md5sum * > md5.txt
    echo ">>>>>upgrade package starting..."
    # backup user information
    echo ">>>>>backup user information..."
    rm -rf ${rootpath}/public_ota/backup
    mkdir -p ${rootpath}/public_ota/backup
    # update boot-loader
    #sudo flash_update -i spi_flash.bin -b 0x06000000 -f 0x0
    #sudo flash_update -i fip.bin -b 0x6000000 -f 0x40000
    # upgrade mcu
    #sudo mcu-util-aarch64 upgrade 1 0x17 sa5-mcu*.bin

    # private ota :boot-recovery /data/ota/startup.sh\nprivate_update"
    sudo dd if=/dev/zero of=/dev/mmcblk0p3 bs=512 count=1
    if [ $# -ge 2 ]; then
        echo -e "boot-recovery\n/DATA/ota\n$2" > /dev/mmcblk0p3
    else
        echo -e "boot-recovery\n/DATA/ota" > /dev/mmcblk0p3
    fi
    echo "update success"
    sync
    reboot
fi

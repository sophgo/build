#!/bin/bash
# Note:
#   This script must be executed with root privileges.
#
# Usage:
#   ./local_update.sh <md5_file> [skip_partition_flag] [recovery_arg]
# Args:
#   <md5_file>            Required. md5 list file, e.g. md5.txt
#   [skip_partition_flag] Optional. If present, skip partition check/update
#                         and md5 regeneration step.
#   [recovery_arg]        Optional. Extra third line written to /dev/mmcblk0p3
# Examples:
#   ./local_update.sh md5.txt
#   ./local_update.sh md5.txt skip
#   ./local_update.sh md5.txt skip my_recovery_param
#   ./local_update.sh md5.txt "" my_recovery_param

# this is se6 ota update script
if [ $# -lt 1  ] ; then
        echo "need md5 file"
        exit 1
fi

echo ">>>>>start upgrade app package..."

echo ">>>>>md5sum check ..."
CHECK_SCRIPT="./check_partition_start_sector.sh"
UPDATE_GPT_SCRIPT="./update_partition_gpt.sh"
IGNORE_MD5_FILES=("md5.txt" "ota_versino.txt")
basepath=$(cd `dirname $0`; pwd)
echo $basepath
cd $basepath
rm -rf ota_versino.txt
md5sum -c "$1" > ota_versino.txt 2>&1
ret=$?
count=$#
rootpath="/data/ota"
skip_partition_ops=false
if [ $# -ge 2 ] && [ -n "$2" ]; then
    skip_partition_ops=true
fi

# collect real failed files except those in IGNORE_MD5_FILES
FAILED_LINES=""
while IFS= read -r line; do
    # only care lines ending with 'FAILED'
    echo "$line" | grep -q "FAILED$" || continue
    file_name=${line%%:*}
    skip=false
    for ignore in "${IGNORE_MD5_FILES[@]}"; do
        if [ "$file_name" = "$ignore" ]; then
            skip=true
            break
        fi
    done
    if [ "$skip" = false ]; then
        FAILED_LINES+="${line}"$'\n'
    fi
done < ota_versino.txt

if [ $ret -ne 0 ] && [ -n "$FAILED_LINES" ]; then
    echo ">>>>> upgrade package is wrong stop upgrade..."
    echo ">>>>> md5 check failed for the following files:"
    printf "%s" "$FAILED_LINES"
    echo "update failed"
    exit 1
else
    echo ">>>>> md5 check passed."
    if [ "$skip_partition_ops" = true ]; then
        echo ">>>>> skip partition check/update/md5 regenerate by optional arg."
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
    fi
    echo ">>>>>upgrade package starting..."
    dd if=/dev/zero of=/dev/mmcblk0p3 bs=512 count=1
    if [ $# -ge 3 ] && [ -n "$3" ]; then
        echo -e "boot-recovery\n/DATA/ota\n$3" > /dev/mmcblk0p3
    else
        echo -e "boot-recovery\n/DATA/ota" > /dev/mmcblk0p3
    fi
    echo "update success"
    sync
    reboot
fi

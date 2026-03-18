#!/bin/bash

set -e

TARGET_PARTITIONS=("DATA" "MISC" "ROOTFS")
CURRENT_DEVICE="/dev/mmcblk0"
NEW_PARTITION_XML="partition32G_sector.xml"
PARTITION_TABLE_OFFSET=8192

get_partition_start_sector_from_xml() {
    local partition_label=$1
    local xml_file=$2
    
    [[ ! -f "$xml_file" ]] && { echo "Error: XML file '$xml_file' not found" >&2; return 1; }
    
    local current_start=$PARTITION_TABLE_OFFSET
    local partition_found=0
    
    local temp_xml=$(mktemp)
    grep -v '^ *<!--' "$xml_file" | grep -v '^ *-->' | sed '/^ *$/d' > "$temp_xml"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        if [[ "$line" =~ label=\"([^\"]+)\"[[:space:]]*size_in_sectors=\"([0-9]+)\" ]]; then
            local label="${BASH_REMATCH[1]}"
            local size="${BASH_REMATCH[2]}"
            
            if [[ "$label" == "$partition_label" ]]; then
                partition_found=1
                break
            fi
            
            ((current_start += size))
        fi
    done < "$temp_xml"
    
    rm -f "$temp_xml"
    
    [[ $partition_found -eq 0 ]] && { echo "Error: Partition '$partition_label' not found" >&2; return 1; }
    
    echo "$current_start"
}

get_partition_start_sector_from_system() {
    local partition_device=$1
    local disk_device=$2
    
    local start_sector
    start_sector=$(sudo fdisk -l "$disk_device" | grep "$partition_device" | awk '{print $2}')
    
    [[ -z "$start_sector" ]] && { echo "Error: Cannot get start sector for '$partition_device'" >&2; return 1; }
    [[ "$start_sector" =~ ^[0-9]+$ ]] || { echo "Error: Invalid start sector '$start_sector'" >&2; return 1; }
    
    echo "$start_sector"
}

convert_label_to_device() {
    local label=$1
    local disk_device=$2
    
    case $label in
        "BOOT") echo "${disk_device}p1" ;;
        "RECOVERY") echo "${disk_device}p2" ;;
        "MISC") echo "${disk_device}p3" ;;
        "ROOTFS") echo "${disk_device}p4" ;;
        "ROOTFS_RW") echo "${disk_device}p5" ;;
        "DATA") echo "${disk_device}p6" ;;
        *) echo ""; return 1 ;;
    esac
}

echo "Starting partition start sector check..."
echo "Device: $CURRENT_DEVICE"
echo "XML file: $NEW_PARTITION_XML"
echo "Partitions to check: ${TARGET_PARTITIONS[*]}"
echo "========================================"

for TARGET_PARTITION in "${TARGET_PARTITIONS[@]}"; do
    echo "----------------------------------------"
    echo "Checking partition: $TARGET_PARTITION"

    PARTITION_DEVICE=$(convert_label_to_device "$TARGET_PARTITION" "$CURRENT_DEVICE")
    [[ -z "$PARTITION_DEVICE" ]] && { echo "Error: Cannot convert label '$TARGET_PARTITION'" >&2; exit 1; }

    CURRENT_START=$(get_partition_start_sector_from_system "$PARTITION_DEVICE" "$CURRENT_DEVICE")
    NEW_START=$(get_partition_start_sector_from_xml "$TARGET_PARTITION" "$NEW_PARTITION_XML")

    echo "Partition device: $PARTITION_DEVICE"
    echo "Current start sector: $CURRENT_START"
    echo "New layout start sector: $NEW_START"

    if [[ "$CURRENT_START" -eq "$NEW_START" ]]; then
        echo "✓ Check passed: Partition '$TARGET_PARTITION' start sector matches."
    else
        echo "✗ Check failed: Partition '$TARGET_PARTITION' start sector mismatch!"
        echo "Current: $CURRENT_START, New: $NEW_START"
        echo "OTA upgrade rejected to prevent data corruption."
        exit 1
    fi
done

echo "----------------------------------------"
echo "All partition start sector checks passed."
echo "OTA upgrade can proceed."
exit 0

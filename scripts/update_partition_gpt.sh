#!/bin/bash

set -e

CURRENT_DEVICE="/dev/mmcblk0"
NEW_PARTITION_XML="partition32G_sector.xml"
PARTITION_TABLE_OFFSET=8192
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
get_total_sectors_from_disk() {
    local disk_device=$1
    local total_sectors
    
    total_sectors=$(sudo fdisk -l "$disk_device" | grep "^Disk $disk_device" | awk '{print $7}' | sed 's/,//g')
    
    if [[ -z "$total_sectors" ]] || ! [[ "$total_sectors" =~ ^[0-9]+$ ]]; then
        echo "Error: Cannot get valid total sectors for disk '$disk_device'" >&2
        return 1
    fi
    
    echo "$total_sectors"
}

calculate_data_partition_size() {
    local xml_file=$1
    local disk_total_sectors=$2
    
    local previous_partitions_size=$PARTITION_TABLE_OFFSET
    
    while IFS= read -r line; do
        if [[ "$line" =~ size_in_sectors=\"([0-9]+)\" ]]; then
            local size="${BASH_REMATCH[1]}"
            if [[ ! "$line" =~ label=\"DATA\" ]]; then
                ((previous_partitions_size += size))
            fi
        fi
    done < <(grep '<partition' "$xml_file")
    
    local data_size=$((disk_total_sectors - previous_partitions_size))
    
    if [[ $data_size -le 0 ]]; then
        echo "Error: Calculated DATA partition size is invalid: $data_size" >&2
        return 1
    fi
    
    echo "$data_size"
}

update_xml_with_sed() {
    local xml_file=$1
    local disk_total_sectors=$2
    local data_partition_size=$3
    
    local backup_file="${xml_file}.backup.${TIMESTAMP}"
    if [ -n "${OTA_DEBUG:-}" ]; then
      cp "$xml_file" "$backup_file"
      echo "Backup created: $backup_file"
    fi
    sed -i "s/\(<physical_partition[^>]*size_in_sectors=\"\)[^\"]*\"/\1$disk_total_sectors\"/" "$xml_file"
    
    sed -i "s/\(<partition label=\"DATA\"[^>]*size_in_sectors=\"\)[^\"]*\"/\1$data_partition_size\"/" "$xml_file"
    
    echo "XML updated using sed"
}

verify_xml_update() {
    local xml_file=$1
    local expected_total_sectors=$2
    local expected_data_size=$3
    
    local actual_total_sectors
    actual_total_sectors=$(sed -n 's/.*<physical_partition[^>]*size_in_sectors="\([^"]*\)".*/\1/p' "$xml_file")
    
    local actual_data_size
    actual_data_size=$(sed -n 's/.*<partition label="DATA"[^>]*size_in_sectors="\([^"]*\)".*/\1/p' "$xml_file")
    
    if [[ "$actual_total_sectors" == "$expected_total_sectors" && "$actual_data_size" == "$expected_data_size" ]]; then
        echo "Verification passed:"
        echo "  Total sectors: $actual_total_sectors"
        echo "  DATA partition size: $actual_data_size"
        return 0
    else
        echo "Verification failed:"
        echo "  Expected total: $expected_total_sectors, Got: $actual_total_sectors"
        echo "  Expected DATA size: $expected_data_size, Got: $actual_data_size"
        return 1
    fi
}

main() {
    echo "=== XML Partition Size Update (Using sed) ==="
    echo "Disk: $CURRENT_DEVICE"
    echo "XML file: $NEW_PARTITION_XML"
    echo "----------------------------------------"
    
    local actual_total_sectors
    actual_total_sectors=$(get_total_sectors_from_disk "$CURRENT_DEVICE")
    [[ $? -ne 0 ]] && exit 1
    echo "Actual disk total sectors: $actual_total_sectors"
    
    local data_partition_size
    data_partition_size=$(calculate_data_partition_size "$NEW_PARTITION_XML" "$actual_total_sectors")
    [[ $? -ne 0 ]] && exit 1
    echo "Calculated DATA partition size: $data_partition_size"
    
    update_xml_with_sed "$NEW_PARTITION_XML" "$actual_total_sectors" "$data_partition_size"
    
    echo "----------------------------------------"
    echo "Verifying update..."
    if verify_xml_update "$NEW_PARTITION_XML" "$actual_total_sectors" "$data_partition_size"; then
        echo "Update completed successfully!"
        echo "The XML file now reflects the actual disk layout."
    else
        echo "Update verification failed!"
        exit 1
    fi
    echo "Starting GPT partition update..."
    if [ -n "${OTA_DEBUG:-}" ]; then
      if [ -f "gpt.gz" ]; then
        echo "Backing up existing gpt.gz file..."
        cp gpt.gz gpt.gz.old.${TIMESTAMP}
        echo "Backup created: gpt.gz.old"
      else
        echo "gpt.gz file not found, skipping backup"
      fi
    fi
    rm -rf gpt.gz

    echo "Creating new GPT partition with $NEW_PARTITION_XML..."
    if ! ./update_gpt -p "$NEW_PARTITION_XML" -d gpt; then
      exit_code=$?
    fi
    echo "update_gpt with exit code: $exit_code" >&2
    gzip gpt

    if [ -f "gpt.gz" ]; then
        echo "GPT partition update completed successfully!"
    else
        echo "Error: Failed to create gpt.gz file"
        exit 1
    fi
}

main

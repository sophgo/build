# -*- coding: utf-8 -*-
import os
import kconfiglib
from pathlib import Path
import xml.etree.ElementTree as ET
from xml.dom import minidom


def generate_partition_xml(partitions, output_file, storage_type, total_flash_size_kb):
    # Calculate total size (only partitions with values are counted)
    total_partition_size_kb = 0
    last_partition_index = len(partitions) - 1
    
    # Calculate the sum of sizes of non-last partitions
    for i, partition in enumerate(partitions):
        size_str = partition["size_in_kb"]
        if size_str.strip() != "" and i != last_partition_index:  # Non-last partitions with values
            try:
                total_partition_size_kb += int(size_str)
            except ValueError:
                pass
    
    # Process the last partition
    last_partition = partitions[last_partition_index]
    last_size_str = last_partition["size_in_kb"]
    
    if last_size_str.strip() == "":
        # Automatically calculate the size of the last partition (remaining space)
        remaining_size = total_flash_size_kb - total_partition_size_kb
        
        # Check if the remaining space is valid
        if remaining_size <= 0:
            raise ValueError(
                f"Error: Remaining space for last partition is {remaining_size} KB. "
                f"Total flash size: {total_flash_size_kb} KB, "
                f"allocated: {total_partition_size_kb} KB."
            )
        
        # Align the size of the last partition according to the storage type
        if storage_type == "spinor":
            # spinor align to 64KB
            aligned_size = (remaining_size // 64) * 64
        elif storage_type == "spinand":
            # spinand align to 128KB
            aligned_size = (remaining_size // 128) * 128
        else:
            aligned_size = remaining_size

        last_partition["size_in_kb"] = str(aligned_size)
        total_partition_size_kb += aligned_size
        
        print(f"Automatically set last partition '{last_partition['label']}' size to {aligned_size} KB")
    else:
        try:
            last_size = int(last_size_str)
            total_partition_size_kb += last_size
        except ValueError:
            pass
    
    # check total size
    if total_partition_size_kb > total_flash_size_kb:
        raise ValueError(
            f"Error: Total partition size ({total_partition_size_kb} KB) "
            f"exceeds total flash size ({total_flash_size_kb} KB)."
        )
    
    # create root node
    root = ET.Element("physical_partition", type=storage_type)

    comment = ET.Comment("This is an auto-generated file. DO NOT EDIT manually.")
    root.append(comment)

    # Traverse partition information and generate XML nodes
    for partition in partitions:
        partition_node = ET.SubElement(root, "partition")
        partition_node.set("label", partition.get("label", ""))
        
        # Directly use string value
        partition_node.set("size_in_kb", partition.get("size_in_kb", ""))
        
        partition_node.set("readonly", str(partition.get("readonly", "false")).lower())
        partition_node.set("file", partition.get("file", ""))
        partition_node.set("mountpoint", partition.get("mountpoint", ""))
        partition_node.set("type", partition.get("type", ""))

    # Format XML output
    xml_string = ET.tostring(root, encoding="utf-8")
    pretty_xml = minidom.parseString(xml_string).toprettyxml(indent="  ")

    # Write to file
    with open(output_file, "w") as f:
        f.write(pretty_xml)
    print(f"Flash xml generated: {output_file}")


def parse_kconfig(kconfig_file, config_file):
    kconfig_dir = Path(kconfig_file).parent
    os.environ["srctree"] = str(kconfig_dir)
    kconf = kconfiglib.Kconfig(kconfig_file)
    kconf.load_config(config_file)  # Load .config file if it exists
    partitions = []

    # Get storage type
    storage_type = kconf.syms["STORAGE_TYPE"].str_value
    if storage_type not in ["emmc", "spinor", "spinand"]:
        raise ValueError("Error: STORAGE_TYPE must be one of 'emmc', 'spinor', or 'spinand'.")

    # Parse total flash size
    flash_size_str = kconf.syms["FLASH_SIZE"].str_value.upper().replace(" ", "")
    
    # Convert string format to KB unit
    try:
        if flash_size_str.endswith("KB"):
            total_flash_size_kb = int(flash_size_str[:-2])
        elif flash_size_str.endswith("MB"):
            total_flash_size_kb = int(flash_size_str[:-2]) * 1024
        elif flash_size_str.endswith("GB"):
            total_flash_size_kb = int(flash_size_str[:-2]) * 1024 * 1024
        else:
            # No unit suffix, default to KB
            total_flash_size_kb = int(flash_size_str)
    except ValueError:
        raise ValueError(f"Invalid FLASH_SIZE format: '{flash_size_str}'. Use format like '16MB', '128MB', or '32GB'.")

    # Get the number of partitions
    partition_count = int(kconf.syms["PARTITION_COUNT"].str_value)

    # Traverse each partition
    for i in range(1, partition_count + 1):
        partition_key = f"PARTITION_{i}"
        if partition_key in kconf.syms and kconf.syms[partition_key].tri_value == 2:
            size_str = kconf.syms[f"{partition_key}_SIZE"].str_value
            label = kconf.syms[f"{partition_key}_LABEL"].str_value

            # Handle null case (only the last partition is allowed to be null)
            if i == partition_count:  # Last partition
                if size_str.strip() == "":
                    # The last partition is allowed to be empty, skip alignment check (will be handled in generate_partition_xml)
                    pass
                else:
                    try:
                        size_in_kb = int(size_str)
                        # The last partition still requires an alignment check when it has a value
                        if storage_type == "spinor" and size_in_kb % 64 != 0:
                            raise ValueError(f"Error: {storage_type} Partition {i} size ({size_in_kb} KB) is not aligned to 64KB.")
                        if storage_type == "spinand" and size_in_kb % 128 != 0:
                            raise ValueError(f"Error: {storage_type} Partition {i} size ({size_in_kb} KB) is not aligned to 128KB.")
                    except ValueError:
                        raise ValueError(f"Error: {partition_key}_SIZE must be an integer or empty, but got '{size_str}'")
            else:  # Not last partition
                if size_str.strip() == "":
                    raise ValueError(f"Error: Non-last partition {i} ({label}) must have a size value")
                try:
                    size_in_kb = int(size_str)
                    # Non-last partitions require alignment check
                    if storage_type == "spinor" and size_in_kb % 64 != 0:
                        raise ValueError(f"Error: {storage_type} Partition {i} size ({size_in_kb} KB) is not aligned to 64KB.")
                    if storage_type == "spinand" and size_in_kb % 128 != 0:
                        raise ValueError(f"Error: {storage_type} Partition {i} size ({size_in_kb} KB) is not aligned to 128KB.")
                except ValueError:
                    raise ValueError(f"Error: {partition_key}_SIZE must be an integer, but got '{size_str}'")

            partition = {
                "label": label,
                # Directly store string values, preserving nulls
                "size_in_kb": size_str,
                "readonly": kconf.syms[f"{partition_key}_READONLY"].tri_value == 2,
                "file": kconf.syms[f"{partition_key}_FILE"].str_value,
                "mountpoint": kconf.syms[f"{partition_key}_MOUNTPOINT"].str_value,
                "type": kconf.syms[f"{partition_key}_TYPE"].str_value,
            }
            
            # If it is SPI NAND type, check fip partition size
            if storage_type == "spinand" and label == "fip" and size_str.strip() != "":
                try:
                    size_in_kb = int(size_str)
                    if size_in_kb < 2560:
                        raise ValueError(f"Error: The 'fip' partition size ({size_in_kb} KB) cannot be less than 2560KB for spinand.")
                except ValueError:
                    pass

            partitions.append(partition)
    return partitions, storage_type, total_flash_size_kb


if __name__ == "__main__":
    kconfig_file = os.path.join(Path(__file__).resolve().parent.parent, "Kconfig")
    config_file = os.path.join(Path(__file__).resolve().parent.parent, ".config")
    # Parse Kconfig
    partitions, storage_type, total_flash_size_kb = parse_kconfig(kconfig_file, config_file)

    # Output xml file path
    output_file = os.path.join(Path(__file__).resolve().parent.parent, "partitions.xml")

    # Generate xml file
    generate_partition_xml(partitions, output_file, storage_type, total_flash_size_kb)

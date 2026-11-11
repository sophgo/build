# -*- coding: utf-8 -*-
import os
import kconfiglib
from pathlib import Path
import xml.etree.ElementTree as ET
from xml.dom import minidom


def align_partition_size_kb(size_kb, storage_type):
    if storage_type == "spinor":
        return (size_kb // 64) * 64
    if storage_type == "spinand":
        return (size_kb // 128) * 128
    return size_kb


def generate_partition_xml(partitions, output_file, storage_type, total_flash_size_kb, nandflash_page_size=2048):
    # Sum explicit sizes; collect partitions that need auto-sizing
    total_partition_size_kb = 0
    auto_size_indices = []

    for i, partition in enumerate(partitions):
        size_str = partition["size_in_kb"]
        if size_str.strip() != "":
            try:
                total_partition_size_kb += int(size_str)
            except ValueError:
                pass
        else:
            auto_size_indices.append(i)

    if len(auto_size_indices) > 1:
        labels = [partitions[i]["label"] for i in auto_size_indices]
        raise ValueError(
            f"Error: Only one partition may have an empty size, found: {labels}"
        )

    if len(auto_size_indices) == 1:
        idx = auto_size_indices[0]
        partition = partitions[idx]
        remaining_size = total_flash_size_kb - total_partition_size_kb

        if remaining_size <= 0:
            raise ValueError(
                f"Error: Remaining space for partition '{partition['label']}' is "
                f"{remaining_size} KB. Total flash size: {total_flash_size_kb} KB, "
                f"allocated: {total_partition_size_kb} KB."
            )

        aligned_size = align_partition_size_kb(remaining_size, storage_type)
        partition["size_in_kb"] = str(aligned_size)
        total_partition_size_kb += aligned_size

        print(
            f"Automatically set partition '{partition['label']}' size to {aligned_size} KB"
        )

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

    if storage_type == "spinand":
        if nandflash_page_size == 2048:
            comment = ET.Comment(
                "Uboot will ues 9th block to store a back up of fip.bin.\n"
                "      Please keep the first 2.5MB reserved for fip and fip size less than 1.25MB"
            )
        elif nandflash_page_size == 4096:
            comment = ET.Comment(
                "Uboot will ues 9th block to store a back up of fip.bin.\n"
                "      Please keep the first 5MB reserved for fip and fip size less than 2.5MB"
            )
        else:
            comment = None
        if comment is not None:
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

    # Get NAND flash page size for spinand fip size check and XML comment
    try:
        nandflash_page_size = int(kconf.syms["NANDFLASH_PAGESIZE"].str_value)
    except (KeyError, ValueError):
        nandflash_page_size = 2048  # default to 2K page

    # Get the number of partitions
    partition_count = int(kconf.syms["PARTITION_COUNT"].str_value)

    # Traverse each partition
    for i in range(1, partition_count + 1):
        partition_key = f"PARTITION_{i}"
        if partition_key in kconf.syms and kconf.syms[partition_key].tri_value == 2:
            size_str = kconf.syms[f"{partition_key}_SIZE"].str_value
            label = kconf.syms[f"{partition_key}_LABEL"].str_value

            # Empty size is allowed; generate_partition_xml fills the remaining space
            if size_str.strip() != "":
                try:
                    size_in_kb = int(size_str)
                    if storage_type == "spinor" and size_in_kb % 64 != 0:
                        raise ValueError(
                            f"Error: {storage_type} Partition {i} size ({size_in_kb} KB) "
                            f"is not aligned to 64KB."
                        )
                    if storage_type == "spinand" and size_in_kb % 128 != 0:
                        # 128KB alignment contains 2KB/4KB alignment
                        raise ValueError(
                            f"Error: {storage_type} Partition {i} size ({size_in_kb} KB) "
                            f"is not aligned to 128KB."
                        )
                except ValueError as e:
                    if str(e).startswith("Error:"):
                        raise
                    raise ValueError(
                        f"Error: {partition_key}_SIZE must be an integer or empty, "
                        f"but got '{size_str}'"
                    )

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
                size_in_kb = int(size_str)
                min_fip_size = 2560 if nandflash_page_size == 2048 else 5120
                if size_in_kb < min_fip_size:
                    raise ValueError(f"Error: The 'fip' partition size ({size_in_kb} KB) cannot be less than {min_fip_size}KB for spinand.")

            partitions.append(partition)
    return partitions, storage_type, total_flash_size_kb, nandflash_page_size


if __name__ == "__main__":
    kconfig_file = os.path.join(Path(__file__).resolve().parent.parent, "Kconfig")
    config_file = os.path.join(Path(__file__).resolve().parent.parent, ".config")
    # Parse Kconfig
    partitions, storage_type, total_flash_size_kb, nandflash_page_size = parse_kconfig(kconfig_file, config_file)

    # Output xml file path
    output_file = os.path.join(Path(__file__).resolve().parent.parent, "partitions.xml")

    # Generate xml file
    generate_partition_xml(partitions, output_file, storage_type, total_flash_size_kb, nandflash_page_size)

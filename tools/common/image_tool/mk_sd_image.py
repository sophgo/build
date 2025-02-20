#!/usr/bin/env python
# coding=utf-8

import xml.etree.ElementTree as ET
import subprocess
import os
import datetime
import argparse


def run_command(command, check=True):
    """Utility function to run a shell command."""
    print("Executing:", command)
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    print(result.stdout)
    if result.stderr:
        print("Error:", result.stderr)
    if check and result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, command)
    return result


def parse_partitions(xml_file):
    """Parse the XML file to get partition information."""
    tree = ET.parse(xml_file)
    root = tree.getroot()
    partitions = []
    for partition in root.findall("partition"):
        label = partition.get("label")
        size_in_kb = int(partition.get("size_in_kb"))
        partitions.append((label, size_in_kb))
    return partitions


def create_image(output_dir, partitions):
    """Create an image based on partition information."""
    image_name = f"custom-image-{datetime.datetime.now().strftime('%Y%m%d')}.img"
    total_size_mb = sum(size for _, size in partitions) // 1024
    total_size_mb += 64
    image_path = os.path.join(output_dir, image_name)
    run_command(f"dd if=/dev/zero of={image_path} bs=1M count={total_size_mb}")

    # Setup loop device
    dev_name = run_command("sudo losetup -f").stdout.strip()
    run_command(f"sudo losetup {dev_name} {image_path}")
    run_command(f"sudo partprobe {dev_name}")

    # Create partitions using fdisk
    fdisk_commands = "\n"
    partition_count = 0
    extended_partion = False
    rootfs_index = 0
    for label, size in partitions:
        size_mb = size // 1024
        if partition_count < 3:
            fdisk_commands += f"n\n"
            fdisk_commands += "p\n"
            fdisk_commands += "\n"  # Default partition number
            fdisk_commands += "\n"  # Default first sector
            fdisk_commands += f"+{size_mb}M\n"
        elif extended_partion == False:
            fdisk_commands += f"n\n"
            fdisk_commands += "e\n"
            fdisk_commands += "\n"  # Default partition number
            fdisk_commands += "\n"  # Default first sector
            fdisk_commands += "\n"
            partition_count += 1
            extended_partion = True
            fdisk_commands += f"n\n"
            fdisk_commands += "\n"  # Default first sector
            fdisk_commands += f"+{size_mb}M\n"
        else:
            fdisk_commands += f"n\n"
            fdisk_commands += "\n"  # Default first sector
            fdisk_commands += f"+{size_mb}M\n"
        partition_count += 1
        if "ROOTFS" == label:
            rootfs_index = partition_count
    fdisk_commands += "p\n"
    fdisk_commands += "w\n"
    run_command(f"echo '{fdisk_commands}' | sudo fdisk {image_path}")
    run_command(f"sudo partprobe {dev_name}")

    # Format and label partitions, and copy files if necessary
    mount_base = os.getenv("OUTPUT_DIR", "./")
    for index, (label, _) in enumerate(partitions, start=1):
        if label == "MISC":
            continue
        mount_path = os.path.join(mount_base, label)
        os.makedirs(mount_path, exist_ok=True)
        part_path = f"{dev_name}p{index}"
        if "RECOVERY" in label or "BOOT" in label:
            run_command(f"sudo mkfs.vfat -F 32 -n {label} {part_path}")
            run_command(f"sudo mount -t vfat {part_path} {mount_path}")
            # Copy boot files to the BOOT partition
            fip_name = "fip.bin"
            boot_name = "boot.itb"
            fip_path = os.path.join(os.getenv("OUTPUT_DIR", "./"), fip_name)
            boot_path = os.path.join(
                os.getenv("RAMDISK_PATH", "ramdisk"),
                os.getenv("RAMDISK_OUTPUT_FOLDER", "ramdisk/"),
                boot_name,
            )
            run_command(f"sudo cp {fip_path} {mount_path}")
            run_command(f"sudo cp {boot_path} {mount_path}")
            run_command(f"sync")
            run_command(f"sudo umount {mount_path}")
        elif label == "ROOTFS":
            part_path = f"{dev_name}p{rootfs_index}"
            run_command(f"sudo mkfs.ext4 -L {label} {part_path}")
            run_command(f"sudo mount -t ext4 {part_path} {mount_path}")
            # Copy root filesystem files to the ROOTFS partition
            rootfs_path = os.getenv("EDGE_ROOTFS_DIR", "")
            run_command(f"sudo cp -raf {rootfs_path}/* {mount_path}")
            run_command(f"sync")
            run_command(f"sudo umount {mount_path}")
        elif label == "ROOTFS_RW":
            index = rootfs_index + 1
            part_path = f"{dev_name}p{index}"
            run_command(f"sudo mkfs.ext4 -L {label} {part_path}")
        elif label == "DATA":
            index = rootfs_index + 2
            part_path = f"{dev_name}p{index}"
            run_command(f"sudo mkfs.ext4 -L {label} {part_path}")

    # Cleanup: Detach loop device
    run_command(f"sudo losetup -d {dev_name}")
    print(f"Image created successfully: {image_name}")

def main():
    parser = argparse.ArgumentParser(
        description="Create a disk image based on XML partition configuration."
    )
    parser.add_argument(
        "xml_file", help="Path to the XML file containing partition definitions."
    )
    parser.add_argument(
        "output_dir", help="Directory where the disk image will be created."
    )
    args = parser.parse_args()

    partitions = parse_partitions(args.xml_file)
    create_image(args.output_dir, partitions)


if __name__ == "__main__":
    main()

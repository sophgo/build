#!/usr/bin/env python3
import os
import argparse
import xml.etree.ElementTree as ET
import tempfile
import shutil
import subprocess
import signal
import sys
import stat
import time
import gzip  # 用于处理gzip文件

# Configuration parameters
SECTOR_BYTES = 512  # 512 bytes per sector
GPT_OFFSET_SECTORS = 8192  # 4MB (8192 * 512 bytes)
GPT_OFFSET = GPT_OFFSET_SECTORS * SECTOR_BYTES
RAW_DIR_NAME = "raw_image"  # Directory name to store individual partition images
GPT_FILENAME = "gpt.gz"  # GPT分区表文件名
GPT_RAW_FILENAME = "gpt.img"  # 保存到raw_image的GPT镜像文件名

# -------------------------- 新增：boot1/boot2 专属配置（独立定义，不修改原有配置） --------------------------
BOOT1_SIZE_MB = 4  # boot1总大小：4MB
BOOT1_FIP_OFFSETS_MB = [0, 1]  # boot1写入FIP的偏移：0MB（主）、1MB（备份）
BOOT2_SIZE_MB = 4  # boot2总大小：4MB
FIP_BIN_NAME = "fip.bin"  # 需要写入boot1的二进制文件
BOOT1_IMG_NAME = "boot1.img"  # boot1独立镜像文件名
BOOT2_IMG_NAME = "boot2.img"  # boot2独立镜像文件名
# -----------------------------------------------------------------------------

# Filesystem mapping
FS_TYPE_MAP = {
    'BOOT': 1,
    'RECOVERY': 2,
    'ROOTFS': 2,
    'ROOTFS_RW': 2,
    'DATA': 2,
    'MISC': 0  # 0 = no filesystem
}

# Track temporary directories for emergency cleanup
temp_directories = []

def signal_handler(sig, frame):
    """Clean up temporary files on interrupt"""
    print("\nReceived interrupt signal. Cleaning up temporary files...")
    cleanup_temp_directories()
    sys.exit(1)

def cleanup_temp_directories():
    """Explicitly clean up all temporary directories"""
    for temp_dir in temp_directories:
        if os.path.exists(temp_dir):
            try:
                # Handle read-only files
                for root, dirs, files in os.walk(temp_dir):
                    for file in files:
                        file_path = os.path.join(root, file)
                        os.chmod(file_path, stat.S_IWRITE)
                shutil.rmtree(temp_dir)
                print(f"Cleaned up temporary directory: {temp_dir}")
            except Exception as e:
                print(f"Warning: Failed to clean up {temp_dir}: {e}")

def align_to_sector(size_bytes):
    """Align size to nearest sector boundary"""
    if size_bytes % SECTOR_BYTES == 0:
        return size_bytes
    return (size_bytes // SECTOR_BYTES + 1) * SECTOR_BYTES

def parse_partition_xml(xml_file):
    """Parse partition configuration from XML file"""
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()

        partitions = []
        for idx, part in enumerate(root.findall('partition')):
            label = part.get('label')
            size_kb = int(part.get('size_in_kb'))
            size_bytes = size_kb * 1024
            aligned_size = align_to_sector(size_bytes)
            sectors = aligned_size // SECTOR_BYTES

            partitions.append({
                'index': idx,
                'label': label,
                'size_in_kb': size_kb,
                'size_bytes': size_bytes,
                'aligned_size': aligned_size,
                'sectors': sectors,
                'readonly': part.get('readonly').lower() == 'true',
                'format': int(part.get('format')),  # 1=resize, 0=no resize
                'fs_type': FS_TYPE_MAP.get(label, 0),
                'tarball': f"{label.lower()}.tgz",
                'image_file': f"{label.lower()}.img"
            })

        print(f"Successfully parsed {len(partitions)} partitions from {xml_file}")
        return partitions

    except Exception as e:
        print(f"Error parsing XML: {e}")
        return None

def generate_partition_image(part, temp_dir, tarball_dir, raw_dir):
    """
    Generate individual partition image using shell-like approach:
    1. Create empty image
    2. Format if needed
    3. Populate from tarball or use existing image
    4. Save copy to raw directory
    """
    part_image_exists = 0
    output_img = os.path.join(temp_dir, part['image_file'])
    raw_output_img = os.path.join(raw_dir, part['image_file'])

    # Step 1: Create empty image file
    print(f"  Creating empty image: {part['image_file']}")
    with open(output_img, 'wb') as f:
        f.seek(part['aligned_size'] - 1, os.SEEK_SET)
        f.write(b'\x00')

    # Step 2: Format filesystem based on type
    fs_type = part['fs_type']
    if fs_type == 1:  # vfat
        print(f"  Formatting as vfat filesystem")
        subprocess.run(
            ['mkfs.fat', output_img],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
    elif fs_type == 2:  # ext4
        print(f"  Formatting as ext4 filesystem")
        subprocess.run(
            ['mkfs.ext4', output_img],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
    else:
        print(f"  No filesystem formatting for this partition")
        # Check for existing image file for non-formatted partitions
        existing_img = os.path.join(tarball_dir, part['image_file'])
        if os.path.exists(existing_img):
            print(f"  Using existing image file: {part['image_file']}")
            shutil.copy2(existing_img, output_img)
            part_image_exists = 1

    # Step 3: Populate content if formatted filesystem
    if fs_type in (1, 2) and part_image_exists == 0:
        # Check for pre-built image file first
        existing_img = os.path.join(tarball_dir, part['image_file'])
        if os.path.exists(existing_img):
            img_size = os.path.getsize(existing_img)
            if img_size == part['aligned_size']:
                print(f"  Using pre-built image: {part['image_file']}")
                shutil.copy2(existing_img, output_img)
                part_image_exists = 1
            else:
                print(f"  Error: Image size mismatch for {part['image_file']}")
                print(f"  Expected: {part['aligned_size']}, Got: {img_size}")
                return None

        # If no pre-built image, try to use tarball
        if part_image_exists == 0:
            tarball_path = os.path.join(tarball_dir, part['tarball'])
            if os.path.exists(tarball_path):
                print(f"  Extracting content from {part['tarball']}")
                mount_dir = os.path.join(temp_dir, f"mount_{part['index']}")
                os.makedirs(mount_dir, exist_ok=True)
                temp_directories.append(mount_dir)

                # Mount the image file
                subprocess.run(
                    ['sudo', 'mount', '-o', 'loop', output_img, mount_dir],
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True
                )

                try:
                    # Extract tarball with appropriate options
                    tar_cmd = ['sudo', 'tar', '-xzf', tarball_path, '-C', mount_dir]
                    if fs_type == 1:  # vfat needs special handling
                        tar_cmd.insert(4, '--no-same-owner')

                    subprocess.run(
                        tar_cmd,
                        check=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        text=True
                    )
                    print(f"  Successfully extracted content to {part['label']}")

                    # Sync to ensure all data is written
                    subprocess.run(['sync'], check=True)
                    time.sleep(1)  # Short delay to ensure sync completes

                finally:
                    # Unmount the image
                    subprocess.run(
                        ['sudo', 'umount', mount_dir],
                        check=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        text=True
                    )
                    if mount_dir in temp_directories:
                        temp_directories.remove(mount_dir)
            else:
                print(f"  No tarball found for {part['label']}, creating empty partition")

    # Step 4: Resize filesystem if needed (for ext4)
    if part_image_exists == 0 and part['format'] == 1 and fs_type == 2:
        print(f"  Resizing ext4 filesystem to minimum size")
        subprocess.run(
            ['sudo', 'e2fsck', '-f', '-p', output_img],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        subprocess.run(
            ['sudo', 'resize2fs', '-M', output_img],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

    # Step 5: Save a copy to raw directory
    print(f"  Saving partition image to raw directory: {part['image_file']}")
    shutil.copy2(output_img, raw_output_img)

    return output_img

def generate_boot1(output_dir, tarball_dir):
    """
    生成独立boot1镜像: 4MB大小,0MB和1MB偏移写入fip.bin1MB为备份
    output_dir: 镜像保存目录,复用原有raw_image目录
    tarball_dir: fip.bin所在目录, 与原有tarball目录一致
    """
    boot1_path = os.path.join(output_dir, BOOT1_IMG_NAME)
    # 1. count boot1 size
    boot1_size_bytes = BOOT1_SIZE_MB * 1024 * 1024
    boot1_aligned = align_to_sector(boot1_size_bytes)

    print(f"\n=== Generating independent BOOT1 image ===")
    print(f"  Save path: {boot1_path}")
    print(f"  Size: {BOOT1_SIZE_MB}MB (aligned to {boot1_aligned} bytes)")
    print(f"  FIP write offsets: {BOOT1_FIP_OFFSETS_MB[0]}MB (main) / {BOOT1_FIP_OFFSETS_MB[1]}MB (backup)")

    # 2. check if fip.bin exists
    fip_path = os.path.join(tarball_dir, FIP_BIN_NAME)
    if not os.path.exists(fip_path):
        print(f"  Error: {FIP_BIN_NAME} not found in {tarball_dir} - BOOT1 generation failed")
        return False

    # 3. read content of fip.bin
    with open(fip_path, 'rb') as f:
        fip_data = f.read()
    fip_size = len(fip_data)
    print(f"  Read {fip_size} bytes from {FIP_BIN_NAME}")

    # 4. check if fip size exceeds offset gap
    offset_gap = BOOT1_FIP_OFFSETS_MB[1] - BOOT1_FIP_OFFSETS_MB[0]
    if fip_size > offset_gap * 1024 * 1024:
        print(f"  Error: FIP size exceeds {offset_gap}MB gap - main/backup will overlap")
        return False

    # 5. create zero-filled image
    with open(boot1_path, 'wb') as f:
        f.seek(boot1_aligned - 1, os.SEEK_SET)
        f.write(b'\x00')

    # 6. write fip.bin to two positions
    with open(boot1_path, 'r+b') as f:
        for offset_mb in BOOT1_FIP_OFFSETS_MB:
            offset_bytes = offset_mb * 1024 * 1024
            # check for out-of-bounds
            if offset_bytes + fip_size > boot1_aligned:
                print(f"  Error: {offset_mb}MB + FIP size exceeds BOOT1 total size")
                return False
            f.seek(offset_bytes)
            f.write(fip_data)
            print(f"  Successfully wrote FIP to {offset_mb}MB offset")

    print(f"  BOOT1 image generated successfully")
    return True

def generate_boot2(output_dir):
    """
    生成独立boot2镜像:4MB大小,全0填充
    output_dir: 镜像保存目录
    """
    boot2_path = os.path.join(output_dir, BOOT2_IMG_NAME)
    # 1. count boot2 size 4MB
    boot2_size_bytes = BOOT2_SIZE_MB * 1024 * 1024
    boot2_aligned = align_to_sector(boot2_size_bytes)

    print(f"\n=== Generating independent BOOT2 image ===")
    print(f"  Save path: {boot2_path}")
    print(f"  Size: {BOOT2_SIZE_MB}MB (aligned to {boot2_aligned} bytes)")

    # 2. create zero image
    with open(boot2_path, 'wb') as f:
        f.seek(boot2_aligned - 1, os.SEEK_SET)
        f.write(b'\x00')

    print(f"  BOOT2 image generated successfully (all zeros)")
    return True

def build_emmc_master_firmware(output_file, partitions, tarball_dir='.'):
    """Build complete eMMC master firmware image and save individual partitions"""
    if not partitions:
        print("No valid partition data - cannot build firmware")
        return

    # Get output directory from output file path and create raw directory there
    output_dir = os.path.dirname(output_file)
    if not output_dir:  # If output file is in current directory
        output_dir = os.getcwd()

    raw_dir = os.path.join(output_dir, RAW_DIR_NAME)
    os.makedirs(raw_dir, exist_ok=True)
    print(f"Created/using raw directory for individual images: {raw_dir}")

    # create boot1 and boot2
    boot1_ok = generate_boot1(output_dir, tarball_dir)
    boot2_ok = generate_boot2(output_dir)
    if not (boot1_ok and boot2_ok):
        print("\nWarning: BOOT1/BOOT2 generation failed - continue building main firmware")
    # -----------------------------------------------------------------------------

    # handle GPT
    gpt_path = os.path.join(tarball_dir, GPT_FILENAME)
    gpt_size = 0
    if not os.path.exists(gpt_path):
        print(f"Error: GPT file {gpt_path} not found in tarball directory")
        return

    try:
        # read and decompress GPT file
        with gzip.open(gpt_path, 'rb') as f:
            gpt_data = f.read()
        gpt_size = len(gpt_data)
        print(f"Successfully read GPT data (size: {gpt_size} bytes)")

        # save gpt.img to raw_image dir
        gpt_raw_path = os.path.join(raw_dir, GPT_RAW_FILENAME)
        with open(gpt_raw_path, 'wb') as f:
            f.write(gpt_data)
        print(f"Saved GPT image to raw directory: {GPT_RAW_FILENAME}")

    except Exception as e:
        print(f"Error processing GPT file: {e}")
        return

    # Calculate total sizes
    partitions_total_size = sum(p['aligned_size'] for p in partitions)
    total_size = GPT_OFFSET + partitions_total_size

    print(f"Starting eMMC master firmware build")
    print(f"  Sector size: {SECTOR_BYTES} bytes")
    print(f"  GPT data size: {gpt_size} bytes")
    print(f"  GPT offset: {GPT_OFFSET_SECTORS} sectors ({GPT_OFFSET/1024/1024:.2f} MB)")
    print(f"  Total firmware size: {total_size/1024/1024:.2f} MB")
    print(f"  Output file: {output_file}")
    print("-" * 70)

    # Create main temporary directory
    temp_dir = tempfile.mkdtemp()
    temp_directories.append(temp_dir)
    print(f"Using temporary directory: {temp_dir}")

    try:
        with open(output_file, 'wb') as out_f:
            print(f"Writing GPT data to the beginning of firmware image")
            out_f.write(gpt_data)

            # Process each partition
            for part in partitions:
                print(f"\nProcessing partition: {part['label']}")
                print(f"  Size: {part['size_in_kb']} KB ({part['sectors']} sectors)")
                print(f"  Filesystem type: {part['fs_type']}")

                # Generate individual partition image and save to raw directory
                part_img = generate_partition_image(part, temp_dir, tarball_dir, raw_dir)
                if not part_img or not os.path.exists(part_img):
                    print(f"  Warning: Failed to create {part['label']} image, using zero-filled")
                    out_f.write(b'\x00' * part['aligned_size'])
                    continue

                # Write partition to firmware
                with open(part_img, 'rb') as img_f:
                    # Read exactly the aligned size
                    out_f.write(img_f.read(part['aligned_size']))

                print(f"  Completed {part['label']} partition")

    finally:
        # Ensure cleanup even if errors occur
        cleanup_temp_directories()

    print("\n" + "-" * 70)
    print(f"eMMC master firmware build complete.")
    print(f"  Final master image size: {os.path.getsize(output_file)/1024/1024:.2f} MB")
    print(f"  Individual partition images saved to: {os.path.abspath(raw_dir)}")

if __name__ == "__main__":
    # Register signal handlers for clean shutdown
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    parser = argparse.ArgumentParser(description='Build eMMC master firmware with raw partition images')
    parser.add_argument('-o', '--output', default='emmc_master_firmware.bin',
                      help='Output firmware filename')
    parser.add_argument('-d', '--dir', default='.',
                      help='Directory containing partition tarballs, images and gpt.gz')
    parser.add_argument('-x', '--xml', required=True,
                      help='Path to partition configuration XML file')
    args = parser.parse_args()

    partitions = parse_partition_xml(args.xml)
    if partitions:
        build_emmc_master_firmware(args.output, partitions, args.dir)

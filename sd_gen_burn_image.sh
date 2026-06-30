#!/bin/bash
set -e
# a sd image generator for SD NAND / SD card (no sudo required)
# Requires: sfdisk, mkfs.vfat, mtools (mcopy), mkfs.ext4 (e2fsprogs >= 1.43 for -d)
#
# Partition layout (MBR):
#   p1: FAT32  36MB  (fip.bin, boot.sd, yoc.bin)
#   p2: ext4   40MB  rootfs
#   p3: ext4   20MB  system
#   p4: extended partition containing:
#     p5: ext4  12MB  cfg
#     p6: ext4  remaining  data

if [ "$#" -lt "1" ]
then
	echo "usage: ./sd_gen_burn_image.sh OUTPUT_DIR [SD_SIZE_MB]"
	echo ""
	echo "       The script creates a sd image with the following partitions:"
	echo "       p1=FAT32(boot), p2=rootfs, p3=system, p5=cfg, p6=data"
	echo "       SD_SIZE_MB: total SD NAND size in MB, default is 120."
	echo "       No sudo required."
	echo ""
	echo "Note:  Please backup your sdcard files before using this image!"

	exit
fi

# Check required tools
for tool in sfdisk mkfs.vfat mcopy mkfs.ext4; do
	if ! command -v "$tool" &>/dev/null; then
		echo "ERROR: '$tool' not found. Please install it first."
		echo "  sfdisk    -> util-linux"
		echo "  mkfs.vfat -> dosfstools"
		echo "  mcopy     -> mtools"
		echo "  mkfs.ext4 -> e2fsprogs"
		exit 1
	fi
done

sd_size_mb=${2:-120}
# Partition sizes in MB
vfat_size_mb=36
rootfs_size_mb=40
system_size_mb=20
cfg_size_mb=12
# data gets the remaining space

output_dir=$1
# Resolve to absolute path before pushd (relative path breaks later re-cd)
if ! output_dir=$(cd "${output_dir}" 2>/dev/null && pwd); then
	echo "ERROR: output dir not found: $1"
	exit 1
fi
echo "Output dir: ${output_dir}"
pushd "${output_dir}" >/dev/null

# Calculate partition layout (sector size = 512 bytes)
sect() { echo $(($1 * 1024 * 1024 / 512)); }

p1_start=2048
p1_size=$(sect ${vfat_size_mb})

p2_start=$((p1_start + p1_size))
p2_size=$(sect ${rootfs_size_mb})

p3_start=$((p2_start + p2_size))
p3_size=$(sect ${system_size_mb})

# Extended partition starts after p3, contains cfg + data
p4_start=$((p3_start + p3_size))
total_sectors=$((sd_size_mb * 1024 * 1024 / 512))
p4_size=$((total_sectors - p4_start))

# Logical partitions inside extended (1 sector EBR overhead each)
p5_start=$((p4_start + 2048))
p5_size=$(sect ${cfg_size_mb})

p6_start=$((p5_start + p5_size + 2048))
p6_size=$((total_sectors - p6_start))

# Sanity check
if [ ${p6_size} -le 0 ]; then
	echo "ERROR: SD NAND too small (${sd_size_mb}MB) to fit all partitions"
	exit 1
fi

echo "Partition layout:"
echo "  p1 FAT32  : ${vfat_size_mb}MB (boot)"
echo "  p2 ext4   : ${rootfs_size_mb}MB (rootfs)"
echo "  p3 ext4   : ${system_size_mb}MB (system)"
echo "  p5 ext4   : ${cfg_size_mb}MB (cfg)"
echo "  p6 ext4   : $((p6_size * 512 / 1024 / 1024))MB (data)"

# 1. Create empty image: <chip>-sd-... from install/soc_<chip>_... (2nd '_' field)
soc_dir=$(basename "${output_dir}")
chip_tag=$(echo "${soc_dir}" | cut -d'_' -f2)
if [ -z "${chip_tag}" ]; then
	echo "ERROR: cannot parse chip from output dir: ${soc_dir} (expected soc_<chip>_...)"
	exit 1
fi
image=${chip_tag}-sd-$(date +%Y%m%d-%H%M).img
echo "Image: ${image}"
dd if=/dev/zero of="./${image}" bs=1M count=${sd_size_mb} status=progress

# 2. Create MBR partition table using sfdisk
sfdisk "./${image}" << EOF
label: dos
start=${p1_start}, size=${p1_size}, type=c, bootable
start=${p2_start}, size=${p2_size}, type=83
start=${p3_start}, size=${p3_size}, type=83
start=${p4_start}, size=${p4_size}, type=5
start=${p5_start}, size=${p5_size}, type=83
start=${p6_start}, size=${p6_size}, type=83
EOF

# 3. Create FAT32 partition image and copy boot files
fat_img=$(mktemp -p . _fat_XXXXXX.img)
dd if=/dev/zero of="${fat_img}" bs=1M count=${vfat_size_mb}
mkfs.vfat -F 32 -s 1 -n "boot" "${fat_img}"
mcopy -i "${fat_img}" ./fip.bin "::fip.bin"
mcopy -i "${fat_img}" ./rawimages/boot.sd "::boot.sd"
if [ -f ./rawimages/yoc.bin ]; then
	mcopy -i "${fat_img}" ./rawimages/yoc.bin "::yoc.bin"
fi

# Helper: create ext4 partition image
# Usage: make_ext4 <output_file> <size_sectors> <label> [<content_dir>]
make_ext4() {
	local img=$1 size_sect=$2 label=$3 content_dir=$4
	local size_bytes=$((size_sect * 512))
	truncate -s ${size_bytes} "${img}"
	if [ -n "${content_dir}" ] && [ -d "${content_dir}" ]; then
		mkfs.ext4 -L "${label}" -d "${content_dir}" "${img}"
	else
		mkfs.ext4 -L "${label}" "${img}"
	fi
}

# 4. Create ext4 partition images
rootfs_img=$(mktemp -p . _rootfs_XXXXXX.img)
make_ext4 "${rootfs_img}" ${p2_size} "rootfs" ./rootfs

system_img=$(mktemp -p . _system_XXXXXX.img)
if [ -d ./system ]; then
	make_ext4 "${system_img}" ${p3_size} "system" ./system
else
	make_ext4 "${system_img}" ${p3_size} "system"
fi

cfg_img=$(mktemp -p . _cfg_XXXXXX.img)
if [ -d ./cfg ]; then
	make_ext4 "${cfg_img}" ${p5_size} "cfg" ./cfg
else
	make_ext4 "${cfg_img}" ${p5_size} "cfg"
fi

data_img=$(mktemp -p . _data_XXXXXX.img)
if [ -d ./data ]; then
	make_ext4 "${data_img}" ${p6_size} "data" ./data
else
	make_ext4 "${data_img}" ${p6_size} "data"
fi

# 5. Assemble: write partition images into the final image
dd if="${fat_img}"    of="./${image}" bs=512 seek=${p1_start} conv=notrunc status=progress
dd if="${rootfs_img}" of="./${image}" bs=512 seek=${p2_start} conv=notrunc status=progress
dd if="${system_img}" of="./${image}" bs=512 seek=${p3_start} conv=notrunc status=progress
dd if="${cfg_img}"    of="./${image}" bs=512 seek=${p5_start} conv=notrunc status=progress
dd if="${data_img}"   of="./${image}" bs=512 seek=${p6_start} conv=notrunc status=progress

# 6. Cleanup temp files
rm -f "${fat_img}" "${rootfs_img}" "${system_img}" "${cfg_img}" "${data_img}"

# tar image
tar zcvf "${image}.tar.gz" "${image}"

echo "Gen image successful: ${image} (${sd_size_mb}MB)"
echo ""

popd

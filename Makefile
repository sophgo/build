.PHONY: FORCE
.PHONY: bld bld-clean
.PHONY: arm-trusted-firmware arm-trusted-firmware-clean
.PHONY: u-boot u-boot-clean
.PHONY: rtos rtos-clean

-include .config

# Some basic check
ifneq ($(origin TOP_DIR),environment)
    $(error Please source envsetup_soc.sh first)
endif

ifneq ($(wildcard ${TOP_DIR}/build/Makefile),$(abspath Makefile))
    $(error $${TOP_DIR}/build/Makefile is not current Makefile)
endif

# Verbose flag
ifeq (${BUILD_VERBOSE},0)
    Q:=@
else
    Q:=
endif
export Q

define print_target
	@printf '\033[1;36;40m  [TARGET] $@ \033[0m\n'
endef

qstrip = $(strip $(subst ",,$(1)))

################################################################################
# Default actions
################################################################################
NPROC := $(shell nproc)
FTP_SRV := ftp://10.58.65.3

export CHIP_ARCH_L := $(shell echo $(CHIP_ARCH) | tr A-Z a-z)
export BORAD_FOLDER_PATH := ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}

export KEYSERVER := 10.18.98.102
export KEYSERVER_SSHKEY_PATH := ${ATF_PATH}/tools/build_script/service_sign@cvi_keyserver.pem

export RELEASE_BIN_DIR := $(TOP_DIR)/rel_bin
export RELEASE_BIN_LICENSE_DIR := ${RELEASE_BIN_DIR}/release_bin_license
export RELEASE_BIN_ATF_DIR     := ${RELEASE_BIN_DIR}/release_bin_atf
export RELEASE_BIN_BLD_DIR     := ${RELEASE_BIN_DIR}/release_bin_bld
export RELEASE_BIN_BLDP_DIR    := ${RELEASE_BIN_DIR}/release_bin_bldp
export RELEASE_BIN_BLP_DIR     := ${RELEASE_BIN_DIR}/release_bin_blp

ifneq ($(origin OUTPUT_DIR),environment)
    $(error Please execute defconfig/menuconfig/oldconfig first)
endif

$(shell mkdir -p ${OUTPUT_DIR})
ifeq ($(wildcard ${OUTPUT_DIR}),)
    $(error "OUTPUT_DIR (${OUTPUT_DIR})" does not exist)
endif


################################################################################
# Output directory
################################################################################
${OUTPUT_DIR}/elf:
	${Q}mkdir -p $@

################################################################################
# Generate global memmory map for all source repo
################################################################################
include scripts/mmap.mk

################################################################################
# arm-trusted-firmware and bld
################################################################################
include scripts/atf.mk

################################################################################
# rtos targets
################################################################################
include scripts/rtos.mk

################################################################################
# fip targets
################################################################################
ifeq (${CONFIG_FIP_V1},y)
include scripts/fip_v1.mk
else ifeq (${CONFIG_FIP_V2},y)
include scripts/fip_v2.mk
else
$(error no fip version)
endif

################################################################################
# u-boot targets
################################################################################
# configure uboot defconfig
ifeq ($(CONFIG_BUILD_FOR_DEBUG),y)
UBOOT_CONFIG_NAME := ${PROJECT_FULLNAME}_defconfig
else
UBOOT_CONFIG_NAME := ${PROJECT_FULLNAME}_rls_defconfig
endif

ifeq (${RELEASE_VERSION},1)
uboot_release_action := ${Q}sed -i "s/CONFIG_BOOTDELAY=1/CONFIG_BOOTDELAY=-2/g" ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/.config
endif

# Set CONFIG_BOOTLOGO config in defconfig
ifeq (${ENABLE_BOOTLOGO},1)
uboot_bootlogo_action := ${Q}sed -i "s/CONFIG_BOOTLOGO=n/CONFIG_BOOTLOGO=y/g" ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/.config
else
uboot_bootlogo_action := ${Q}sed -i "s/CONFIG_BOOTLOGO=y/CONFIG_BOOTLOGO=n/g" ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/.config
endif

# Set CONFIG_USE_4K_ERASE_SIZE_FOR_JFFS2 config in defconfig
ifeq (${CONFIG_USE_4K_ERASE_SIZE_FOR_JFFS2},y)
uboot_erasesize_set := ${Q}sed -in "s/.*CONFIG_SPI_FLASH_USE_4K_SECTORS is not set/CONFIG_SPI_FLASH_USE_4K_SECTORS=y/g" ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/.config
else
uboot_erasesize_set := ${Q}sed -in "s/CONFIG_SPI_FLASH_USE_4K_SECTORS=y/\# CONFIG_SPI_FLASH_USE_4K_SECTORS is not set/g" ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/.config
endif

ifeq (${COMPRESSOR_UBOOT},lzma)
define uboot_compress_action
	${Q}echo "Compress u-boot with LZMA"
	${Q}lzma --force ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot.bin
	${Q}echo -n 'LZMA' | cat - ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot.bin.lzma > \
		${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot.bin
endef
endif

UBOOT_CVIPART_DEP := ${UBOOT_PATH}/include/imgs.h ${UBOOT_PATH}/include/cvipart.h

${UBOOT_CVIPART_DEP}: ${FLASH_PARTITION_XML} ${BUILD_PATH}/.config
	$(call print_target)
	${Q}python3 ${IMGTOOL_PATH}/mkcvipart.py ${FLASH_PARTITION_XML} ${UBOOT_PATH}/include
	${Q}python3 ${IMGTOOL_PATH}/mk_imgHeader.py ${FLASH_PARTITION_XML} ${UBOOT_PATH}/include

${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}:
	${Q}mkdir -p $@

UBOOT_OUTPUT_CONFIG_PATH := ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/.config
UBOOT_DEFAULT_CONFIG_PATH := ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/u-boot/${UBOOT_CONFIG_NAME}

# Make a copy to .config~
${UBOOT_OUTPUT_CONFIG_PATH}: ${UBOOT_DEFAULT_CONFIG_PATH} ${BUILD_PATH}/.config
	$(call print_target)
	${Q}echo "u-boot's defconfig is updated. Use it."
	${Q}mkdir -p $(dir ${UBOOT_OUTPUT_CONFIG_PATH})
	${Q}cmp -s ${UBOOT_DEFAULT_CONFIG_PATH} ${UBOOT_OUTPUT_CONFIG_PATH} || \
		${Q}cp -vb ${UBOOT_DEFAULT_CONFIG_PATH} ${UBOOT_OUTPUT_CONFIG_PATH}
	$(call uboot_release_action)
	$(call uboot_bootlogo_action)
ifeq ($(STORAGE_TYPE), spinor)
	$(call uboot_erasesize_set)
endif

UBOOT_CVI_BOARD_INIT_PATH := ${UBOOT_PATH}/board/cvitek/cvi_board_init.c
UBOOT_CVITEK_PATH := ${UBOOT_PATH}/include/cvitek/cvitek.h

u-boo%: export KBUILD_OUTPUT=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}
u-boo%: export RELEASE=${RELEASE_VERSION}
u-boo%: export CVIBOARD=${BOARD}
u-boo%: export CONFIG_SKIP_RAMDISK:=${CONFIG_SKIP_RAMDISK}
u-boo%: export CONFIG_USE_DEFAULT_ENV:=${CONFIG_USE_DEFAULT_ENV}
u-boo%: export MULTI_FIP=$(if ${CONFIG_MULTI_FIP},1,0)
u-boo%: export CROSS_COMPILE=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE))
u-boo%: export ARCH=$(patsubst "%",%,$(CONFIG_ARCH))

u-boot-menuconfig: ${UBOOT_OUTPUT_CONFIG_PATH}
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} menuconfig
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} savedefconfig

u-boot-dts:
	$(call print_target)
ifeq ($(UBOOT_SRC), u-boot-2021.10)
# U-boot doesn't has arch/arm64
ifeq ($(ARCH), arm64)
	${Q}find ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME} \
		\( -path "*linux/*.dts*" -o -path "*dts_${ARCH}/*.dts*" \) \
		-exec cp {} ${UBOOT_PATH}/arch/arm/dts/ \;
	${Q}find ${DTS_DEFATUL_PATHS} -name *.dts* -exec cp {} ${UBOOT_PATH}/arch/arm/dts/ \;
else
	${Q}find ${BUILD_PATH}/boards/${CHIP_ARCH_L} \
		\( -path "*linux/*.dts*" -o -path "*dts_${ARCH}/*.dts*" \) \
		-exec cp {} ${UBOOT_PATH}/arch/${ARCH}/dts/ \;
	${Q}find ${DTS_DEFATUL_PATHS} -name *.dts* -exec cp {} ${UBOOT_PATH}/arch/${ARCH}/dts/ \;
endif
endif

u-boot-build: memory-map
u-boot-build: u-boot-dts
u-boot-build: ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER} ${UBOOT_CVIPART_DEP} ${UBOOT_OUTPUT_CONFIG_PATH}
	$(call print_target)
	${Q}ln -snrf ${CVI_BOARD_MEMMAP_H_PATH} ${UBOOT_PATH}/include/
	${Q}rm -f ${UBOOT_CVI_BOARD_INIT_PATH}
	${Q}ln -s ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/u-boot/cvi_board_init.c ${UBOOT_CVI_BOARD_INIT_PATH}
	${Q}rm -f ${UBOOT_CVITEK_PATH}
	${Q}ln -s ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/u-boot/cvitek.h ${UBOOT_CVITEK_PATH}
ifeq ($(CONFIG_ROOTFS_UBUNTU),y)
	${Q}sed -i "s/CONFIG_ROOTFS_UBUNTU=n/CONFIG_ROOTFS_UBUNTU=y/g" ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/.config
else ifeq ($(CONFIG_ROOTFS_DEBIAN),y)
	${Q}sed -i "s/CONFIG_ROOTFS_DEBIAN=n/CONFIG_ROOTFS_DEBIAN=y/g" ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/.config
endif
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} olddefconfig
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} all
	${Q}cat ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot.bin > ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot-raw.bin
	${Q} ${CROSS_COMPILE}objdump -S ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot > ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot.dis

u-boot: u-boot-dep

u-boot-env-tools: export CROSS_COMPILE=$(CONFIG_CROSS_COMPILE_SDK)
u-boot-env-tools:
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} env

u-boot-clean: export KBUILD_OUTPUT=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}
u-boot-clean:
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} distclean
	${Q}rm -f ${OUTPUT_DIR}/fip.bin ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot.bin.lzma


################################################################################
# kernel targets
################################################################################
# configure kernel defconfig
ifeq ($(CONFIG_BUILD_FOR_DEBUG),y)
KERNEL_CONFIG_NAME := ${PROJECT_FULLNAME}_defconfig
else
KERNEL_CONFIG_NAME := ${PROJECT_FULLNAME}_rls_defconfig
endif

# KERNEL_VERSION ?= -tag-$(shell git -C ${KERNEL_PATH} describe --exact-match HEAD 2>/dev/null)

${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}:
	${Q}mkdir -p $@

define copy_Image_action
	${Q}mkdir -p ${OUTPUT_DIR}/elf
	${Q}mkdir -p ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}
	${Q}cp ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arch/${ARCH}/boot/Image ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}
	${Q}cp ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/vmlinux ${OUTPUT_DIR}/elf/
endef

define copy_ko_action
	${Q}mkdir -p ${SYSTEM_OUT_DIR}/ko
	${Q}find ${1} -name '*.ko' -exec cp -f {} ${SYSTEM_OUT_DIR}/ko/ \;
endef

ifeq ($(CHIP_ARCH),$(filter $(CHIP_ARCH),CV181X CV180X SOPHON))
define copy_header_action
	# TODO change "soph" to "$(shell echo $(CHIP_ARCH) | tr A-Z a-z)"
	#${Q}cp -r ${OSDRV_PATH}/interdrv/${MW_VER}/include/chip/soph/uapi/linux/* ${1}/linux/
	#${Q}cp -r ${OSDRV_PATH}/interdrv/${MW_VER}/include/common/uapi/linux/* ${1}/linux/
	${Q}cp ${OSDRV_PATH}/interdrv/${MW_VER}/usb/gadget/function/f_cvg.h ${1}/linux/
	${Q}cp ${KERNEL_PATH}/drivers/staging/android/uapi/ion.h ${1}/linux/
	${Q}cp ${KERNEL_PATH}/drivers/staging/android/uapi/ion_cvitek.h ${1}/linux/
	${Q}cp ${KERNEL_PATH}/include/uapi/linux/dma-buf.h ${1}/linux/
endef
else
define copy_header_action
	${Q}cp -r ${OSDRV_PATH}/interdrv/${MW_VER}/vip/chip/$(shell echo $(CHIP_ARCH) | tr A-Z a-z)/uapi/* ${1}/linux/
	${Q}cp -r ${OSDRV_PATH}/interdrv/${MW_VER}/base/uapi/* ${1}/linux/
	${Q}cp -r ${OSDRV_PATH}/interdrv/${MW_VER}/include/uapi/* ${1}/linux/
	${Q}cp ${OSDRV_PATH}/interdrv/${MW_VER}/usb/gadget/function/f_cvg.h ${1}/linux/
	${Q}cp ${KERNEL_PATH}/drivers/staging/android/uapi/ion.h ${1}/linux/
	${Q}cp ${KERNEL_PATH}/drivers/staging/android/uapi/ion_cvitek.h ${1}/linux/
	${Q}cp ${KERNEL_PATH}/include/uapi/linux/dma-buf.h ${1}/linux/
endef
endif

KERNEL_OUTPUT_CONFIG_PATH := ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/.config
KERNEL_DEFAULT_CONFIG_PATH := ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/linux/${KERNEL_CONFIG_NAME}

# Set CONFIG_USE_4K_ERASE_SIZE_FOR_JFFS2 config in defconfig
ifeq (${CONFIG_USE_4K_ERASE_SIZE_FOR_JFFS2},y)
kernel_erasesize_set := ${Q}sed -i "s/.*CONFIG_MTD_SPI_NOR_USE_4K_SECTORS is not set/CONFIG_MTD_SPI_NOR_USE_4K_SECTORS=y/g" ${KERNEL_OUTPUT_CONFIG_PATH}
else
kernel_erasesize_set := ${Q}sed -i "s/CONFIG_MTD_SPI_NOR_USE_4K_SECTORS=y/\# CONFIG_MTD_SPI_NOR_USE_4K_SECTORS is not set/g" ${KERNEL_OUTPUT_CONFIG_PATH}
endif

# Make a copy to .config~
${KERNEL_OUTPUT_CONFIG_PATH}: ${KERNEL_DEFAULT_CONFIG_PATH} ${BUILD_PATH}/.config
	$(call print_target)
	${Q}echo "Kernel's defconfig is updated. Use it."
	${Q}mkdir -p $(dir ${KERNEL_OUTPUT_CONFIG_PATH})
	${Q}cmp -s ${KERNEL_DEFAULT_CONFIG_PATH} ${KERNEL_OUTPUT_CONFIG_PATH} || \
		${Q}cp -vb ${KERNEL_DEFAULT_CONFIG_PATH} ${KERNEL_OUTPUT_CONFIG_PATH}
ifeq ($(STORAGE_TYPE), spinor)
	$(call kernel_erasesize_set)
endif

kerne%: export LOCALVERSION=-sophon-custom
kerne%: export KERNELRELEASE=5.10.4
# kerne%: export KDEB_PKGVERSION=${KERNELRELEASE}${LOCALVERSION}
kerne%: export CVIBOARD=${BOARD}
kerne%: export CROSS_COMPILE=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE_KERNEL))
kerne%: export INSTALL_MOD_PATH=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/modules
kerne%: export INSTALL_HDR_PATH=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/usr/include
kerne%: export ARCH=$(patsubst "%",%,$(CONFIG_ARCH))

kernel-menuconfig: ${KERNEL_OUTPUT_CONFIG_PATH}
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} menuconfig
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} savedefconfig

kernel-setconfig: ${KERNEL_OUTPUT_CONFIG_PATH}
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG=${SCRIPT_ARG}'
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} savedefconfig

kernel-build: ${KERNEL_OUTPUT_CONFIG_PATH}
	$(call print_target)
ifeq ($(_BUILD_OPENSBI_KERNEL_),y)
ifneq ($(CONFIG_TPU_DEBUG_PORT),y)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG=SERIAL_8250=n'
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG=SERIAL_EARLYCON_RISCV_SBI=n'
endif
endif
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} olddefconfig
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} Image modules
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} modules_install headers_install INSTALL_HDR_PATH=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/$(ARCH)/usr
	${Q} ln -sf ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/$(ARCH)/usr/include ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/usr/include
ifeq ($(patsubst "%",%,$(CONFIG_ARCH)),arm64)
	# Since we will support aarch32 user space even if the kernel is aarch64, install aarch32 headers also
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} ARCH=arm headers_install INSTALL_HDR_PATH=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arm/usr
endif

DTS_DEFATUL_PATHS := \
	${BUILD_PATH}/boards/default/dts/${CHIP_ARCH_L} \
	${BUILD_PATH}/boards/default/dts/${CHIP_ARCH_L}_$(patsubst "%",%,$(CONFIG_ARCH))
DTS_DEFATUL_PATHS := $(wildcard ${DTS_DEFATUL_PATHS})

kernel-dts: memory-map
kernel-dts: ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}
	$(call print_target)
	${Q}ln -snrf ${CVI_BOARD_MEMMAP_H_PATH} ${KERNEL_PATH}/scripts/dtc/include-prefixes/
	${Q}find ${KERNEL_PATH}/arch/${ARCH}/boot/dts/${BRAND}/ -type l -delete
	${Q}find ${DTS_DEFATUL_PATHS} -name *.dts* -exec ln -sf {} ${KERNEL_PATH}/arch/${ARCH}/boot/dts/${BRAND}/ \;
	${Q}find ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/ \
		\( -path "*linux/*.dts*" -o -path "*dts_${ARCH}/*.dts*" \) \
		-exec ln -sf {} ${KERNEL_PATH}/arch/${ARCH}/boot/dts/${BRAND}/ \;
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} dtbs
	${Q}cp ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arch/${ARCH}/boot/dts/${BRAND}/*.dtb ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}
kernel: $(OUTPUT_DIR)/rootfs
kernel: kernel-build
	$(call print_target)
ifeq ($(CONFIG_ROOTFS_UBUNTU),y)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} Image.gz bindeb-pkg
else ifeq ($(CONFIG_ROOTFS_DEBIAN),y)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} Image.gz bindeb-pkg
endif
	$(call copy_Image_action)
	$(call copy_ko_action, ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/modules)
	$(call copy_header_action, ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/$(ARCH)/usr/include)
ifeq ($(patsubst "%",%,$(CONFIG_ARCH)),arm64)
	# Since we will support aarch32 user space even if the kernel is aarch64, install aarch32 headers also
	$(call copy_header_action, ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arm/usr/include)
endif
	${Q}ln -sf ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}  ${KERNEL_PATH}/build/kernel_output

ifeq ($(CONFIG_TOOLCHAIN_GLIBC_ARM64),y)
INITRAMFS_BASE := glibc_arm64
else ifeq ($(CONFIG_TOOLCHAIN_GLIBC_ARM),y)
INITRAMFS_BASE := glibc_arm
else ifeq ($(CONFIG_TOOLCHAIN_UCLIBC_ARM),y)
INITRAMFS_BASE := uclibc_arm
else ifeq ($(CONFIG_TOOLCHAIN_GLIBC_RISCV64),y)
INITRAMFS_BASE := glibc_riscv64
else ifeq ($(CONFIG_TOOLCHAIN_MUSL_RISCV64),y)
INITRAMFS_BASE := musl_riscv64
endif

$(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/target:
	${Q}mkdir -p $@

$(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/configs:
	${Q}mkdir -p $@

$(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/workspace:
	${Q}mkdir -p $@

ramdisk: $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/target
ramdisk: $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/configs
ramdisk: $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/workspace
ramdisk:
	${Q}rm -rf $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/configs/*
	${Q}rm -rf $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/target/*
	${Q}cp -r $(RAMDISK_PATH)/initramfs/$(INITRAMFS_BASE)/* $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/target
ifneq ("$(wildcard $(SDK_VER_FOLDER_PATH))", "")
	${Q}cp -r $(SDK_VER_FOLDER_PATH)/* $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/target
endif
ifneq ("$(wildcard $(CHIP_FOLDER_PATH))", "")
	${Q}cp -r $(CHIP_FOLDER_PATH)/* $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/target
endif
ifneq ("$(wildcard $(CUST_FOLDER_PATH))", "")
	${Q}cp -r $(CUST_FOLDER_PATH)/* $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/target
endif
ifneq ($(CONFIG_TPU_DEBUG_PORT),y)
	sed -i '47,49 s/^\(.*\)/#\1/' $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_BASE)/target/init_ramboot.sh
endif

define gen_cpio
	cd $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_FOLDER);\
	$(COMMON_TOOLS_PATH)/gen_init_cpio $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_FOLDER)/../configs/$(1) > $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_FOLDER)/boot.cpio
endef

#create ramdisk.img for u-boot booti cmd
define build_ramdisk_image
	cd $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_FOLDER);\
	$(COMMON_TOOLS_PATH)/prebuild/mkimage -n "ramdisk" -A arm -O linux -T ramdisk -C gzip -d boot.cpio.gz boot.cpio.gz.img;
endef

BOOT_IMAGE_ARG :=
ifeq ($(CONFIG_SKIP_RAMDISK),y)
BOOT_IMAGE_ARG += --skip_ramdisk
endif

ifeq ($(CONFIG_BOOT_IMAGE_SINGLE_DTB), y)
BOOT_IMAGE_ARG += --gen_single_board_its --chip_name "${CHIP}" --board_name "${BOARD}"
RAMBOOT_IMAGE_ARG = --gen_single_board_its --chip_name "${CHIP}" --board_name "${BOARD}"
else
BOOT_IMAGE_ARG += --gen-board-its ${CHIP_ARCH}
RAMBOOT_IMAGE_ARG = --gen_single_board_its --chip_name "${CHIP}" --board_name "${BOARD}"
endif

boot: export KERNEL_COMPRESS=$(patsubst "%",%,$(CONFIG_KERNEL_COMPRESS))
boot: kernel-dts
	$(call print_target)
ifeq ($(CONFIG_ROOTFS_UBUNTU),y)
	$(call gen_cpio,boot_fixed_files.txt)
else ifeq ($(CONFIG_ROOTFS_DEBIAN),y)
	$(call gen_cpio,boot_fixed_files.txt)
else
ifeq ($(CONFIG_ROOTFS_OVERLAYFS),y)
	$(call gen_cpio,overlayfs_fixed_files.txt.sqsh)
else
# uncompressed kernel image for PLD env
ifeq ($(CONFIG_KERNEL_UNCOMPRESSED),y)
	$(call gen_cpio,ramboot_fixed_files.txt)
else
	$(call gen_cpio,onekernel_fixed_files.txt.sqsh)
endif #CONFIG_KERNEL_UNCOMPRESSED
endif #CONFIG_ROOTFS_OVERLAYFS
endif #CONFIG_ROOTFS_UBUNTU
	# copy multi.its for *.itb layout
	${Q}cp -f "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/../configs/multi.its" "${BUILD_PATH}/output/multi.its.tmp"

	${Q}python3 "${BUILD_PATH}/scripts/boards_scan.py" ${BOOT_IMAGE_ARG}
	${Q}mv "${BUILD_PATH}/output/multi.its.tmp" "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its"
ifeq ($(CONFIG_KERNEL_UNCOMPRESSED),y)
	sed -i "s/data = \/incbin\/(\".\/Image.gz\");/data = \/incbin\/(\".\/Image\");/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
else
	${Q}${KERNEL_COMPRESS} -c -9 -f -k ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/Image > ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/Image.${KERNEL_COMPRESS}
	${Q}sed -i "s/data = \/incbin\/(\".\/Image.gz\");/data = \/incbin\/(\".\/Image.${KERNEL_COMPRESS}\");/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
endif
ifeq ($(CONFIG_KERNEL_UNCOMPRESSED),y)
	sed -i "18s/compression = \"gzip\";/compression = \"none\";/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
else
	${Q}sed -i "s/compression = \"gzip\";/compression = \"${KERNEL_COMPRESS}\";/" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
endif
	${Q}cp -f "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio" "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/emmcboot.cpio"
	${Q}gzip -9 -f -k ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio > ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio.gz
ifneq ($(wildcard ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/multi.its), )
ifneq ($(CONFIG_BOOT_IMAGE_SINGLE_DTB), y)
	${Q}cp -r ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/multi.its ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
endif
endif
ifeq ($(CONFIG_SKIP_RAMDISK),y)
	${Q}awk ' \
BEGIN { depth = 0; skip = 0; }  \
/ramdisk-1 \{/ { skip = 1; depth = 1; next; } \
skip {  \
    if (/{/) depth++;\
    if (/}/) depth--;\
    if (depth == 0) { skip = 0; next; }\
}\
!skip { print }' ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its > multi.its.tmp &&  \
	mv multi.its.tmp ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
else
	${Q}sed -i "s/data = \/incbin\/(\".\/rootfs.cpio.gz\");/data = \/incbin\/(\".\/boot.cpio.gz\");/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
endif
	${Q}sed -i "s/arch = \"arm64\";/arch = \"$(patsubst "%",%,$(CONFIG_ARCH))\";/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
ifeq ($(CONFIG_KERNEL_ENTRY_HACK),y)
ifeq ($(CONFIG_KERNEL_ENTRY_HACK_ADDR_H),"")
	${Q}sed -i "s/load = <0x.* 0x.*>;/load = <0x0 $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
	${Q}sed -i "s/entry = <0x.* 0x.*>;/entry = <0x0 $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
else
	${Q}sed -i "s/load = <0x.* 0x.*>;/load = <$(CONFIG_KERNEL_ENTRY_HACK_ADDR_H) $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
	${Q}sed -i "s/entry = <0x.* 0x.*>;/entry = <$(CONFIG_KERNEL_ENTRY_HACK_ADDR_H) $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
endif
endif

ifneq ($(wildcard $(RAMDISK_PATH)/keys/cfg.key),)
	openssl genpkey -algorithm RSA -out $(RAMDISK_PATH)/keys/cfg.key
endif
	$(COMMON_TOOLS_PATH)/prebuild/mkimage -f ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its -k $(RAMDISK_PATH)/keys -r ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.itb

ramboot: kernel-dts
	$(call print_target)
ifeq ($(CONFIG_BOARD_palladium_c906),y)
	$(call gen_cpio,ramboot_fixed_files_c906.txt)
else
	$(call gen_cpio,ramboot_fixed_files.txt)
endif
	# copy multi.its for *.itb layout
	${Q}cp -f "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/../configs/multi.its" "${BUILD_PATH}/output/multi.its.tmp"
	${Q}python3 "${BUILD_PATH}/scripts/boards_scan.py" ${RAMBOOT_IMAGE_ARG}
	${Q}mv "${BUILD_PATH}/output/multi.its.tmp" "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/ramboot-multi.its"
	${Q}gzip -9 -f -k ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/Image > ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/Image.gz
	${Q}gzip -9 -f -k ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio > ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio.gz
	$(call build_ramdisk_image)
	${Q}sed -i "s/data = \/incbin\/(\".\/rootfs.cpio.gz\");/data = \/incbin\/(\".\/boot.cpio.gz\");/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/ramboot-multi.its
	${Q}sed -i "s/arch = \"arm64\";/arch = \"$(patsubst "%",%,$(CONFIG_ARCH))\";/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/ramboot-multi.its
ifeq ($(CONFIG_KERNEL_ENTRY_HACK),y)
ifeq ($(CONFIG_KERNEL_ENTRY_HACK_ADDR_H),"")
	${Q}sed -i "s/load = <0x.* 0x.*>;/load = <0x0 $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/ramboot-multi.its
	${Q}sed -i "s/entry = <0x.* 0x.*>;/entry = <0x0 $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/ramboot-multi.its
else
	${Q}sed -i "s/load = <0x.* 0x.*>;/load = <$(CONFIG_KERNEL_ENTRY_HACK_ADDR_H) $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/ramboot-multi.its
	${Q}sed -i "s/entry = <0x.* 0x.*>;/entry = <$(CONFIG_KERNEL_ENTRY_HACK_ADDR_H) $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/ramboot-multi.its
endif
endif
	$(COMMON_TOOLS_PATH)/prebuild/mkimage -f ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/ramboot-multi.its -k $(RAMDISK_PATH)/keys -r $(OUTPUT_DIR)/ramboot.itb

kernel-clean: clean-memory-map
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} distclean
	${Q}$(if $(wildcard ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}), rm -rf ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER},)
	${Q}rm -f  ${OUTPUT_DIR}/elf/vmlinux
	${Q}$(if $(wildcard ${SYSTEM_OUT_DIR}/ko/kernel), rm -rf ${SYSTEM_OUT_DIR}/ko/kernel,)
	${Q}find ${KERNEL_PATH}/arch/${ARCH}/boot/dts/${BRAND}/ -name "*.dts*" -type l -exec rm -rf {} \;
ifeq ($(CONFIG_ROOTFS_UBUNTU),y)
	${Q}rm -rf ${KERNEL_PATH}/build/*.deb
	${Q}rm -rf ${KERNEL_PATH}/build/*.buildinfo
	${Q}rm -rf ${KERNEL_PATH}/build/*.changes
else ifeq ($(CONFIG_ROOTFS_DEBIAN),y)
	${Q}rm -rf ${KERNEL_PATH}/build/*.deb
	${Q}rm -rf ${KERNEL_PATH}/build/*.buildinfo
	${Q}rm -rf ${KERNEL_PATH}/build/*.changes
endif

ifeq ($(CONFIG_TOOLCHAIN_GLIBC_ARM64),y)
packages_arch := arm64
else ifeq ($(CONFIG_TOOLCHAIN_GLIBC_ARM),y)
packages_arch := arm
else ifeq ($(CONFIG_TOOLCHAIN_UCLIBC_ARM),y)
packages_arch := uclibc
else ifeq ($(CONFIG_TOOLCHAIN_GLIBC_RISCV64),y)
packages_arch := glibc_riscv64
else ifeq ($(CONFIG_TOOLCHAIN_MUSL_RISCV64),y)
packages_arch := musl_riscv64
endif
ROOTFS_BASE := common_$(packages_arch)

$(OUTPUT_DIR)/rootfs:
	${Q}mkdir -p $@

-include $(TOP_DIR)/ramdisk/rootfs/public/packages.mk
define TARGET_PACKAGE_INSTALL_CMD
	@echo 'TARGET PACKAGE OUTPUT DIR=$(OUTPUT_DIR)/rootfs';\
	$(foreach t,$(TARGET_PACKAGES),\
		${Q}cd $(TOP_DIR)/ramdisk/rootfs/public/$(t)/$(packages_arch)/ && \
		${Q}find . \( ! -type d ! -name "*.a" ! -path "*include*" ! -name ".gitkeep" \) \
			-printf 'Copy Package file $(TOP_DIR)/ramdisk/rootfs/public/$(t)/$(packages_arch)/%p\n' \
			-exec cp -a --remove-destination --parents '{}' $(OUTPUT_DIR)/rootfs/ \; ; )
endef

print-target-packages:
	@echo ${TARGET_PACKAGES}

print-target-packages-libdir:
	@echo $(foreach t,$(TARGET_PACKAGES),\
		-L$(TOP_DIR)/ramdisk/rootfs/public/$(t)/$(packages_arch)/lib \
		-L$(TOP_DIR)/ramdisk/rootfs/public/$(t)/$(packages_arch)/lib/3rd \
		-L$(TOP_DIR)/ramdisk/rootfs/public/$(t)/$(packages_arch)/usr/lib)

print-target-packages-include:
	@echo $(foreach t,$(TARGET_PACKAGES),\
		-I$(TOP_DIR)/ramdisk/rootfs/public/$(t)/include)

rootfs-prepare:$(OUTPUT_DIR)/rootfs
	# Copy rootfs
	${Q}cp -a --remove-destination $(RAMDISK_PATH)/rootfs/$(ROOTFS_BASE)/* $(OUTPUT_DIR)/rootfs

        # Copy arch overlay rootfs
ifneq ("$(wildcard $(SDK_VER_FOLDER_PATH))", "")
	${Q}cp -r $(SDK_VER_FOLDER_PATH)/* $(OUTPUT_DIR)/rootfs
endif
	# Copy chip overlay rootfs
ifneq ("$(wildcard $(CHIP_FOLDER_PATH))", "")
	${Q}cp -r $(CHIP_FOLDER_PATH)/* $(OUTPUT_DIR)/rootfs
endif
	# Copy project overlay rootfs
ifneq ("$(wildcard $(CUST_FOLDER_PATH))", "")
	${Q}cp -r $(CUST_FOLDER_PATH)/* $(OUTPUT_DIR)/rootfs
endif
	$(call TARGET_PACKAGE_INSTALL_CMD)
	${Q}${BUILD_PATH}/boards/default/rootfs_script/prepare_rootfs.sh $(OUTPUT_DIR)/rootfs
	# Generate S10_automount
	${Q}python3 $(COMMON_TOOLS_PATH)/image_tool/create_automount.py $(FLASH_PARTITION_XML) $(OUTPUT_DIR)/rootfs/etc/init.d/
	# Generate /etc/fw_env.config
	${Q}python3 $(COMMON_TOOLS_PATH)/image_tool/mkcvipart.py $(FLASH_PARTITION_XML) $(OUTPUT_DIR)/rootfs/etc/ --fw_env

$(OUTPUT_DIR)/rawimages:
	${Q}mkdir -p $@

rootfs%:$(OUTPUT_DIR)/rawimages
rootfs%:export CROSS_COMPILE_KERNEL=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE_KERNEL))
rootfs%:export CROSS_COMPILE_SDK=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE_SDK))

rootfs-pack:rootfs-prepare
rootfs-pack:
	$(call print_target)
	${Q}printf '\033[1;36;40m  Striping rootfs \033[0m\n'
ifeq (${FLASH_SIZE_SHRINK},y)
	${Q}printf 'remove unneeded files'
	${Q}${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/rootfs_script/clean_rootfs.sh $(ROOTFS_DIR)
endif
	${Q}find $(ROOTFS_DIR) -name "*.ko" -type f -printf 'striping %p\n' -exec $(CROSS_COMPILE_KERNEL)strip --strip-unneeded {} \;
	${Q}find $(ROOTFS_DIR) -name "*.so*" -type f -printf 'striping %p\n' -exec $(CROSS_COMPILE_SDK)strip --strip-all {} \;
	${Q}find $(ROOTFS_DIR) -executable -type f ! -name "*.sh" ! -path "*etc*" ! -path "*.ko" -printf 'striping %p\n' -exec $(CROSS_COMPILE_SDK)strip --strip-all {} 2>/dev/null \;
ifeq ($(STORAGE_TYPE),spinor)
	${Q}mksquashfs $(ROOTFS_DIR) $(OUTPUT_DIR)/rawimages/rootfs.sqsh -root-owned -comp xz
else
	${Q}mksquashfs $(ROOTFS_DIR) $(OUTPUT_DIR)/rawimages/rootfs.sqsh -root-owned -comp xz -e mnt/cfg/*
endif
ifeq ($(STORAGE_TYPE),spinand)
	${Q}python3 $(COMMON_TOOLS_PATH)/spinand_tool/mkubiimg.py --ubionly $(FLASH_PARTITION_XML) ROOTFS $(OUTPUT_DIR)/rawimages/rootfs.sqsh $(OUTPUT_DIR)/rawimages/rootfs.spinand -b $(CONFIG_NANDFLASH_BLOCKSIZE) -p $(CONFIG_NANDFLASH_PAGESIZE)
	${Q}rm $(OUTPUT_DIR)/rawimages/rootfs.sqsh
else
	${Q}mv $(OUTPUT_DIR)/rawimages/rootfs.sqsh $(OUTPUT_DIR)/rawimages/rootfs.$(STORAGE_TYPE)
endif

define raw2cimg
	${Q}python3 $(COMMON_TOOLS_PATH)/image_tool/raw2cimg.py $(OUTPUT_DIR)/rawimages/${1} $(OUTPUT_DIR) $(FLASH_PARTITION_XML)
endef

ifeq ($(findstring bm1688,$(PROJECT_FULLNAME)),bm1688)
BR2_CONFIG_NAME := soph_bm1688_defconfig 
else
BR2_CONFIG_NAME := soph_cv186ah_defconfig 
endif

BR2_OUTPUT_CONFIG_PATH := ${BUILDROOT_PATH}/.config
BR2_DEFAULT_CONFIG_PATH := ${BUILD_PATH}/boards/default/buildroot/${BR2_CONFIG_NAME}
BR2_COMMON_OVERLAY_PATH := ${BR2_OVERLAY_PATH}/common/overlay
BR2_PROJECT_OVERLAY_PATH := ${BR2_OVERLAY_PATH}/${PROJECT_FULLNAME}/overlay

${BR2_OUTPUT_CONFIG_PATH}: ${BR2_DEFAULT_CONFIG_PATH} ${BUILD_PATH}/.config
	$(call print_target)
	${Q}mkdir -p $(dir ${BR2_OUTPUT_CONFIG_PATH})
	${Q}cmp -s ${BR2_DEFAULT_CONFIG_PATH} ${BR2_OUTPUT_CONFIG_PATH} || \
		${Q}cp -vb ${BR2_DEFAULT_CONFIG_PATH} ${BR2_OUTPUT_CONFIG_PATH}

menuconfig-br2: ${BR2_OUTPUT_CONFIG_PATH}
	${Q}$(MAKE) -C ${BUILDROOT_PATH} menuconfig

savedefconfig-br2: ${BR2_OUTPUT_CONFIG_PATH}
	${Q}$(MAKE) -C ${BUILDROOT_PATH} savedefconfig

$(ROOTFS_DIR)/mnt: 
	${Q}mkdir -p $@

rootfs_prepare_br2:$(ROOTFS_DIR)/mnt
	# # Copy common files
	${Q}cp $(RAMDISK_PATH)/rootfs/$(ROOTFS_BASE)/etc/profile ${BR2_COMMON_OVERLAY_PATH}/etc
	${Q}cp  $(RAMDISK_PATH)/rootfs/$(ROOTFS_BASE)/sbin/fw_* ${BR2_COMMON_OVERLAY_PATH}/usr/sbin
	${Q}cp  $(CHIP_FOLDER_PATH)/bin/* ${BR2_COMMON_OVERLAY_PATH}/usr/sbin
	# Generate /etc/fw_env.config
	${Q}python3 $(COMMON_TOOLS_PATH)/image_tool/mkcvipart.py $(FLASH_PARTITION_XML) $(BR2_COMMON_OVERLAY_PATH)/etc/ --fw_env

	# Generate S10_automount
	${Q}python3 $(COMMON_TOOLS_PATH)/image_tool/create_automount.py $(FLASH_PARTITION_XML) $(BR2_COMMON_OVERLAY_PATH)/etc/init.d/

	# Copy project data
	${Q}cp -r $(ROOTFS_DIR)/mnt/* ${BR2_PROJECT_OVERLAY_PATH}/mnt


rootfs-br2-pack:rootfs_prepare_br2 ${BR2_OUTPUT_CONFIG_PATH}
	# buildroot would do strip
	${Q}find ${BR2_OVERLAY_PATH}/* -name "*.ko" -type f -printf 'striping %p\n' -exec $(CROSS_COMPILE_KERNEL)strip --strip-unneeded {} \;
	${Q}find ${BR2_OVERLAY_PATH}/* -name "*.so*" -type f -printf 'striping %p\n' -exec $(CROSS_COMPILE_SDK)strip --strip-all {} \;
	${Q}find ${BR2_OVERLAY_PATH}/* -executable -type f ! -name "*.sh" ! -path "*etc*" ! -path "*.ko" -printf 'striping %p\n' -exec $(CROSS_COMPILE_SDK)strip --strip-all {} 2>/dev/null \;
	${Q}$(MAKE) -j${NPROC} -C ${BUILDROOT_PATH} olddefconfig
	${Q}$(MAKE) -j${NPROC} -C ${BUILDROOT_PATH}
	${Q}cp ${BUILDROOT_PATH}/output/images/rootfs.squashfs $(OUTPUT_DIR)/rawimages/rootfs.${STORAGE_TYPE}

ifneq ($(CONFIG_ROOTFS_BUILD_FROM_BR2),y)
ROOTFS_BUILD := rootfs-pack
else
ROOTFS_BUILD := rootfs-br2-pack
endif

rootfs: $(ROOTFS_BUILD)
rootfs:
	$(call print_target)
	$(call raw2cimg ,rootfs.$(STORAGE_TYPE))

jffs2:
	$(call print_target)
ifeq ($(STORAGE_TYPE),spinor)
	chmod 777 $(COMMON_TOOLS_PATH)/mkfs.jffs2
ifeq (${CONFIG_USE_4K_ERASE_SIZE_FOR_JFFS2},y)
	${Q}$(COMMON_TOOLS_PATH)/mkfs.jffs2 -d $(OUTPUT_DIR)/data -l -e 0x1000 --squash -o $(OUTPUT_DIR)/rawimages/data.spinor
else
	${Q}$(COMMON_TOOLS_PATH)/mkfs.jffs2 -d $(OUTPUT_DIR)/data -l -e 0x10000 --squash -o $(OUTPUT_DIR)/rawimages/data.spinor
endif
	$(call raw2cimg ,data.$(STORAGE_TYPE))
endif

rootfs-clean:
	$(call print_target)
	$(Q)rm -rf $(OUTPUT_DIR)/rootfs/
	$(Q)rm $(OUTPUT_DIR)/rootfs.$(STORAGE_TYPE)
ifeq ($(CONFIG_ROOTFS_BUILD_FROM_BR2),y)
	${Q}$(MAKE) -j${NPROC} -C ${BUILDROOT_PATH} clean
	${Q}rm -rf ${BR2_PROJECT_OVERLAY_PATH}/mnt/*
endif

$(OUTPUT_DIR)/system:
	${Q}mkdir -p $@

# Pack_image
# Description: Macro for packing image
# Parameters 1: partition label
# Parameters 2: Folder path for pack
# Parameters 3: Size for packing (for make_ext4fs)
ifeq (${STORAGE_TYPE},spinand)
define pack_image
	${Q}python3 $(COMMON_TOOLS_PATH)/spinand_tool/mkubiimg.py $(FLASH_PARTITION_XML) $(shell echo ${1} | tr  '[:lower:]' '[:upper:]') ${2} $(OUTPUT_DIR)/rawimages/${1}.spinand -b $(CONFIG_NANDFLASH_BLOCKSIZE) -p $(CONFIG_NANDFLASH_PAGESIZE)
endef
else ifeq (${STORAGE_TYPE},emmc)
define pack_image
	${Q}$(COMMON_TOOLS_PATH)/prebuild/make_ext4fs -l ${3}  -L $(shell echo ${1} | tr  '[:lower:]' '[:upper:]') $(OUTPUT_DIR)/rawimages/${1}.emmc ${2}
	resize2fs -M $(OUTPUT_DIR)/rawimages/${1}.emmc
endef
else ifeq (${STORAGE_TYPE},spinor)
# TODO:
define pack_image
endef
else
define pack_image
	$(error Unknown STORAGE_TYPE ${STORAGE_TYPE})
endef
endif

$(OUTPUT_DIR)/rawimages/system.$(STORAGE_TYPE):$(OUTPUT_DIR)/system
	$(call pack_image,system,$(OUTPUT_DIR)/system,38M)

system:$(OUTPUT_DIR)/rawimages/system.$(STORAGE_TYPE)
system:
	$(call print_target)
	$(call raw2cimg ,system.$(STORAGE_TYPE))

$(ROOTFS_DIR)/mnt/cfg:
	${Q}mkdir -p $@

$(ROOTFS_DIR)/mnt/cfg/secure.img:$(ROOTFS_DIR)/mnt/cfg
	# Create image for encrypting.
	${Q}dd if=/dev/zero of=$(ROOTFS_DIR)/mnt/cfg/secure.img bs=5M count=1
	$(TOOLS_PATH)/common/prebuild/mke2fs -T ext4 -O encrypt $(ROOTFS_DIR)/mnt/cfg/secure.img

cfg-build:$(ROOTFS_DIR)/mnt/cfg/secure.img
cfg-build:
	$(call print_target)
	$(call pack_image,cfg,$(ROOTFS_DIR)/mnt/cfg/,15M)

cfg:cfg-build
	$(call print_target)
	$(call raw2cimg ,cfg.$(STORAGE_TYPE))

-include riscv.mk
-include alios.mk

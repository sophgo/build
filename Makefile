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
UBOOT_CONFIG_NAME := ${BRAND}_${PROJECT_FULLNAME}_defconfig

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
	${Q}rm -rf ${UBOOT_CVIPART_DEP}
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
ifeq ($(CONFIG_BOOT_IMAGE_SINGLE_DTB), y)
	BOARD_DTS_SEARCH_PATH = ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}
else
	BOARD_DTS_SEARCH_PATH = ${BUILD_PATH}/boards/${CHIP_ARCH_L}
endif

u-boo%: export KBUILD_OUTPUT=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}
u-boo%: export RELEASE=${RELEASE_VERSION}
u-boo%: export CVIBOARD=${BOARD}
u-boo%: export CONFIG_SKIP_RAMDISK:=${CONFIG_SKIP_RAMDISK}
u-boo%: export CONFIG_ENABLE_EMMC_HW_RESET_QFN:=${CONFIG_ENABLE_EMMC_HW_RESET_QFN}
u-boo%: export CONFIG_ENABLE_EMMC_SET_RESET_OTP:=${CONFIG_ENABLE_EMMC_SET_RESET_OTP}
u-boo%: export CONFIG_USE_DEFAULT_ENV:=${CONFIG_USE_DEFAULT_ENV}
u-boo%: export CONFIG_BUILD_FOR_DEBUG:=${CONFIG_BUILD_FOR_DEBUG}
u-boo%: export CONFIG_MMC_SKIP_TUNING:=${CONFIG_MMC_SKIP_TUNING}
u-boo%: export MULTI_FIP=$(if ${CONFIG_MULTI_FIP},1,0)
u-boo%: export CROSS_COMPILE=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE))
u-boo%: export ARCH=$(patsubst "%",%,$(CONFIG_ARCH))
u-boo%: export CONFIG_SUP_LARGE_PART_SIZE=${SUP_LARGE_PART_SIZE}

u-boot-menuconfig: ${UBOOT_OUTPUT_CONFIG_PATH}
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} menuconfig
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} savedefconfig

u-boot-dts:
	$(call print_target)
ifeq ($(UBOOT_SRC), u-boot-2021.10)
	${Q}find ${BOARD_DTS_SEARCH_PATH} \
		\( -path "*linux/*.dts*" -o -path "*dts_${ARCH}/*.dts*" \) \
		-exec cp {} ${UBOOT_PATH}/arch/${ARCH}/dts/ \;
	${Q}find ${DTS_DEFATUL_PATHS} -name *.dts* -exec cp {} ${UBOOT_PATH}/arch/${ARCH}/dts/ \;
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
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} olddefconfig
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} all
	${Q}cat ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot.bin > ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot-raw.bin
ifeq (${CONFIG_UBOOT_SPL_CUSTOM},y)
	${Q}cat ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/spl/u-boot-spl.bin > ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot-raw_spl.bin
endif
u-boot: u-boot-dep

u-boot-env-tools: export CROSS_COMPILE=$(CONFIG_CROSS_COMPILE_SDK)
u-boot-env-tools:
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} env

u-boot-clean: export KBUILD_OUTPUT=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}
u-boot-clean:
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} distclean
	${Q}rm -f ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot.bin.lzma ${UBOOT_CVIPART_DEP}

################################################################################
# kernel targets
################################################################################
# configure kernel defconfig
ifeq ($(CONFIG_BUILD_FOR_DEBUG),y)
KERNEL_CONFIG_NAME := ${BRAND}_${PROJECT_FULLNAME}_defconfig
else
ifeq (${CONFIG_FASTBOOT},y)
KERNEL_CONFIG_NAME := ${BRAND}_${PROJECT_FULLNAME}_fastboot_defconfig
ifeq ("$(wildcard ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/linux/${KERNEL_CONFIG_NAME})","")
$(error ${BRAND}_${PROJECT_FULLNAME} do not support fastboot!)
endif
else
KERNEL_CONFIG_NAME := ${BRAND}_${PROJECT_FULLNAME}_rls_defconfig
endif
endif

KERNEL_VERSION ?= -tag-$(shell git -C ${KERNEL_PATH} describe --exact-match HEAD 2>/dev/null)

${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}:
	${Q}mkdir -p $@

define copy_Image_action
	${Q}mkdir -p ${OUTPUT_DIR}/elf
	${Q}mkdir -p ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}
	${Q}cp ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arch/${ARCH}/boot/Image ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}
	${Q}cp ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/vmlinux ${OUTPUT_DIR}/elf/
endef


ifeq (${CONFIG_FASTBOOT},y)

KERNEL_KO_OUTPUT_DIR := ${OUTPUT_DIR}/data/ko

define copy_ko_action
	${Q}mkdir -p ${KERNEL_KO_OUTPUT_DIR}
	${Q}find ${1} -name '*.ko' -exec cp -f {} ${KERNEL_KO_OUTPUT_DIR} \;
endef

else

define copy_ko_action
	${Q}mkdir -p ${SYSTEM_OUT_DIR}/ko
	${Q}find ${1} -name '*.ko' -exec cp -f {} ${SYSTEM_OUT_DIR}/ko/ \;
endef

endif

ifeq ($(CHIP_ARCH),$(filter $(CHIP_ARCH),CV181X CV180X))
define copy_header_action
	${Q}cp -r ${OSDRV_PATH}/interdrv/include/common/uapi/linux/* ${1}/linux/
endef
endif

KERNEL_OUTPUT_CONFIG_PATH := ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/.config
KERNEL_DEFAULT_CONFIG_PATH := ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/linux/${KERNEL_CONFIG_NAME}

ifeq (${CONFIG_C906L_DMA_ENABLE},y)
define kernel_c906b_dma_enable
	$(call print_target)
	${Q}sed -i "s,CONFIG_CV1835_SYSDMA_REMAP=y,CONFIG_CV1835_SYSDMA_REMAP=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_DW_DMAC_CVITEK=y,CONFIG_DW_DMAC_CVITEK=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_DMADEVICES=y,CONFIG_DMADEVICES=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_DMA_CMA=y,CONFIG_DMA_CMA=n," ${KERNEL_OUTPUT_CONFIG_PATH}
endef
else
CFLAGS += -DDMMR_DMA_MODE
define kernel_c906b_dma_enable
	$(call print_target)
	${Q}sed -i "s,CONFIG_CV1835_SYSDMA_REMAP=n,CONFIG_CV1835_SYSDMA_REMAP=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_DW_DMAC_CVITEK=n,CONFIG_DW_DMAC_CVITEK=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_DMADEVICES=n,CONFIG_DMADEVICES=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_DMA_CMA=n,CONFIG_DMA_CMA=y," ${KERNEL_OUTPUT_CONFIG_PATH}
endef
endif

ifeq (${CONFIG_AUD_DRV_SEL},y)
define kernel_aud_drv_sel
	$(call print_target)
	${Q}sed -i "s,CONFIG_SOUND=y,CONFIG_SOUND=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND=y,CONFIG_SND=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC=y,CONFIG_SND_SOC=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV182XA_CV182XAADC=y,CONFIG_SND_SOC_CV182XA_CV182XAADC=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV182XA_CV182XADAC=y,CONFIG_SND_SOC_CV182XA_CV182XADAC=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_CV1835_I2S=y,CONFIG_SND_CV1835_I2S=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV182XAADC=y,CONFIG_SND_SOC_CV182XAADC=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV182XADAC=y,CONFIG_SND_SOC_CV182XADAC=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV1835_USE_AUDIO_PLL=y,CONFIG_SND_SOC_CV1835_USE_AUDIO_PLL=n," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_CV1835_I2S_SUBSYS=y,CONFIG_CV1835_I2S_SUBSYS=n," ${KERNEL_OUTPUT_CONFIG_PATH}
endef
else
define kernel_aud_drv_sel
	$(call print_target)
	${Q}sed -i "s,CONFIG_SOUND=n,CONFIG_SOUND=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND=n,CONFIG_SND=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC=n,CONFIG_SND_SOC=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV182XA_CV182XAADC=n,CONFIG_SND_SOC_CV182XA_CV182XAADC=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV182XA_CV182XADAC=n,CONFIG_SND_SOC_CV182XA_CV182XADAC=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_CV1835_I2S=n,CONFIG_SND_CV1835_I2S=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV182XAADC=n,CONFIG_SND_SOC_CV182XAADC=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV182XADAC=n,CONFIG_SND_SOC_CV182XADAC=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_SND_SOC_CV1835_USE_AUDIO_PLL=n,CONFIG_SND_SOC_CV1835_USE_AUDIO_PLL=y," ${KERNEL_OUTPUT_CONFIG_PATH}
	${Q}sed -i "s,CONFIG_CV1835_I2S_SUBSYS=n,CONFIG_CV1835_I2S_SUBSYS=y," ${KERNEL_OUTPUT_CONFIG_PATH}
endef
endif
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
	$(call kernel_c906b_dma_enable)
	$(call kernel_aud_drv_sel)

kerne%: export LOCALVERSION=${KERNEL_VERSION}
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

kernel-build: memory-map
kernel-build: ${KERNEL_OUTPUT_CONFIG_PATH}
	$(call print_target)
	${Q}echo LOCALVERSION=${LOCALVERSION}
# Set CONFIG_SERIAL_EARLYCON_RISCV_SBI config in defconfig
ifeq (${CONFIG_SKIP_UBOOT_DEBUG},y)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG="SERIAL_EARLYCON_RISCV_SBI=y"'
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} savedefconfig
endif
ifeq (${CONFIG_MMC_SKIP_TUNING},y)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG="MMC_SKIP_TUNING=y"'
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} savedefconfig
endif
ifeq (${CONFIG_NO_FB},y)
	#use default .config
else
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG="FB=y"'
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG="FB_CVITEK=m"'
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} savedefconfig
endif
ifeq (${CONFIG_NO_TP},y)
	#use default .config
else
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG="INPUT=y"'
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} savedefconfig
endif
ifeq (${CONFIG_ROOTFS_FORMAT_OPTIMIZATION},y)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG="SQUASHFS_ZLIB=y"'
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} savedefconfig
endif
ifeq (${CONFIG_ENABLE_EMMC_HW_RESET_QFN},y)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} setconfig 'SCRIPT_ARG="ENABLE_EMMC_HW_RESET_QFN=y"'
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} O=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} savedefconfig
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
	${Q}find ${BOARD_DTS_SEARCH_PATH} \
		\( -path "*linux/*.dts*" -o -path "*dts_${ARCH}/*.dts*" \) \
		-exec ln -sf {} ${KERNEL_PATH}/arch/${ARCH}/boot/dts/${BRAND}/ \;
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER} dtbs
	${Q}cp ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arch/${ARCH}/boot/dts/${BRAND}/*.dtb ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}

kernel: $(OUTPUT_DIR)/rootfs
kernel: kernel-build
	$(call print_target)
	${Q}echo LOCALVERSION=${LOCALVERSION}
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

define gen_cpio
	cd $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_FOLDER);\
	$(COMMON_TOOLS_PATH)/gen_init_cpio $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_FOLDER)/../configs/$(1) > $(RAMDISK_PATH)/$(RAMDISK_OUTPUT_FOLDER)/boot.cpio
endef

BOOT_IMAGE_ARG :=
ifeq ($(CONFIG_SKIP_RAMDISK),y)
BOOT_IMAGE_ARG += --skip_ramdisk
endif

ifeq ($(CONFIG_BOOT_IMAGE_SINGLE_DTB), y)
BOOT_IMAGE_ARG += --gen_single_board_its --chip_name "${CHIP}" --board_name "${BOARD}"
else
BOOT_IMAGE_ARG += --gen-board-its ${CHIP_ARCH}
endif

boot: export KERNEL_COMPRESS=$(patsubst "%",%,$(CONFIG_KERNEL_COMPRESS))
boot: kernel-dts
	$(call print_target)
ifeq ($(CONFIG_ROOTFS_OVERLAYFS),y)
	$(call gen_cpio,overlayfs_fixed_files.txt.sqsh)
else
	$(call gen_cpio,onekernel_fixed_files.txt.sqsh)
endif
	# copy multi.its for *.itb layout
	${Q}cp -f "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/../configs/multi.its" "${BUILD_PATH}/output/multi.its.tmp"

	${Q}python3 "${BUILD_PATH}/scripts/boards_scan.py" ${BOOT_IMAGE_ARG}
	${Q}mv "${BUILD_PATH}/output/multi.its.tmp" "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its"
ifeq ($(CONFIG_KERNEL_UNCOMPRESSED),y)
	${Q}sed -i "s/data = \/incbin\/(\".\/Image.gz\");/data = \/incbin\/(\".\/Image\");/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
else
	${Q}${KERNEL_COMPRESS} -c -9 -f -k ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/Image > ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/Image.${KERNEL_COMPRESS}
	${Q}sed -i "s/data = \/incbin\/(\".\/Image.gz\");/data = \/incbin\/(\".\/Image.${KERNEL_COMPRESS}\");/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
endif
	${Q}sed -i "s/compression = \"gzip\";/compression = \"${KERNEL_COMPRESS}\";/" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
	${Q}gzip -9 -f -k ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio > ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio.gz
ifeq ($(CONFIG_SKIP_RAMDISK),y)
	${Q}sed -ie '26,38d' ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
else
	${Q}sed -i "s/data = \/incbin\/(\".\/rootfs.cpio.gz\");/data = \/incbin\/(\".\/boot.cpio.gz\");/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
endif
	${Q}sed -i "s/arch = \"arm64\";/arch = \"$(patsubst "%",%,$(CONFIG_ARCH))\";/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
ifeq ($(CONFIG_KERNEL_ENTRY_HACK),y)
	${Q}sed -i "s/load = <0x0 0x.*>;/load = <0x0 $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
	${Q}sed -i "s/entry = <0x0 0x.*>;/entry = <0x0 $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
endif
	$(COMMON_TOOLS_PATH)/prebuild/mkimage -f ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its -k $(RAMDISK_PATH)/keys -r ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.itb

ramboot: kernel-dts
	$(call print_target)
	$(call gen_cpio,ramboot_fixed_files.txt)
	# copy multi.its for *.itb layout
	${Q}cp -f "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/../configs/multi.its" "${BUILD_PATH}/output/multi.its.tmp"
	${Q}python3 "${BUILD_PATH}/scripts/boards_scan.py" --gen_single_board_its --chip_name "${CHIP}" --board_name "${BOARD}"
	${Q}mv "${BUILD_PATH}/output/multi.its.tmp" "${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its"
	${Q}gzip -9 -f -k ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/Image > ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/Image.gz
	${Q}gzip -9 -f -k ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio > ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio.gz
	${Q}sed -i "s/data = \/incbin\/(\".\/rootfs.cpio.gz\");/data = \/incbin\/(\".\/boot.cpio.gz\");/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
	${Q}sed -i "s/arch = \"arm64\";/arch = \"$(patsubst "%",%,$(CONFIG_ARCH))\";/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
ifeq ($(CONFIG_KERNEL_ENTRY_HACK),y)
	${Q}sed -i "s/load = <0x0 0x.*>;/load = <0x0 $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
	${Q}sed -i "s/entry = <0x0 0x.*>;/entry = <0x0 $(CONFIG_KERNEL_ENTRY_HACK_ADDR)>;/g" ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its
endif
	$(COMMON_TOOLS_PATH)/prebuild/mkimage -f ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/multi.its -k $(RAMDISK_PATH)/keys -r $(OUTPUT_DIR)/ramboot.itb

kernel-clean:
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${KERNEL_PATH} distclean
	${Q}$(if $(wildcard ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}), rm -rf ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER},)
	${Q}rm -f  ${OUTPUT_DIR}/elf/vmlinux
	${Q}$(if $(wildcard ${SYSTEM_OUT_DIR}/ko/kernel), rm -rf ${SYSTEM_OUT_DIR}/ko/kernel,)

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

rootfs-prepare:export CROSS_COMPILE_SDK=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE_SDK))
rootfs-prepare:$(OUTPUT_DIR)/rootfs
	# Copy rootfs
ifeq ($(CONFIG_FASTBOOT),y)
	${Q}cp -a --remove-destination $(RAMDISK_PATH)/rootfs/$(ROOTFS_BASE)_shrink/* $(OUTPUT_DIR)/rootfs
else
	${Q}cp -a --remove-destination $(RAMDISK_PATH)/rootfs/$(ROOTFS_BASE)/* $(OUTPUT_DIR)/rootfs
endif

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
ifneq ($(CONFIG_FASTBOOT),y)
	if [ -f $(ROOTFS_DIR)/etc/init.d/fastboot ]; then ${Q}rm -rf $(ROOTFS_DIR)/etc/init.d/fastboot ; fi ;
	if [ -f $(ROOTFS_DIR)/etc/init.d/S11defer_init ]; then ${Q}rm -rf $(ROOTFS_DIR)/etc/init.d/S11defer_init; fi ;
endif

$(OUTPUT_DIR)/rawimages:
	${Q}mkdir -p $@

rootfs-pack:export CROSS_COMPILE_KERNEL=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE_KERNEL))
rootfs-pack:export CROSS_COMPILE_SDK=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE_SDK))
rootfs-pack:export OSDRV_BUILD_IN:=$(CONFIG_OSDRV_BUILD_IN)
rootfs-pack:$(OUTPUT_DIR)/rawimages
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
ifeq (${CONFIG_ROOTFS_FORMAT_OPTIMIZATION},y)
	${Q}mksquashfs $(ROOTFS_DIR) $(OUTPUT_DIR)/rawimages/rootfs.sqsh -root-owned -comp gzip
else
	${Q}mksquashfs $(ROOTFS_DIR) $(OUTPUT_DIR)/rawimages/rootfs.sqsh -root-owned -comp xz
endif
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

define raw2cimg_lps
	${Q}python3 $(COMMON_TOOLS_PATH)/image_tool/raw2cimg_lps.py $(OUTPUT_DIR)/rawimages/${1} $(OUTPUT_DIR) $(FLASH_PARTITION_XML)
endef

define mkjffs2image
	${Q}python3 $(COMMON_TOOLS_PATH)/image_tool/mkjffs2.py $(COMMON_TOOLS_PATH)/mkfs.jffs2 $(OUTPUT_DIR)/data ${1} $(OUTPUT_DIR)/rawimages/${2} $(FLASH_PARTITION_XML)
endef

rootfs:rootfs-pack
rootfs:
	$(call print_target)
ifeq ($(CONFIG_SUP_LARGE_PART_SIZE),y)
	$(call raw2cimg_lps ,rootfs.$(STORAGE_TYPE))
else
ifeq ($(CONFIG_DOUBLESDK),y)
	${Q}cp $(OUTPUT_DIR)/rawimages/rootfs.$(STORAGE_TYPE) $(OUTPUT_DIR)/rawimages/rootfs_v420.$(STORAGE_TYPE)
	$(call raw2cimg ,rootfs_v420.$(STORAGE_TYPE))
else
	$(call raw2cimg ,rootfs.$(STORAGE_TYPE))
endif
endif

data:
	$(call print_target)
ifeq ($(STORAGE_TYPE),spinor)
	chmod +x $(COMMON_TOOLS_PATH)/mkfs.jffs2
ifeq (${CONFIG_USE_4K_ERASE_SIZE_FOR_JFFS2},y)
	$(call mkjffs2image ,4096,data.spinor)
else
	# can not have space before param
	$(call mkjffs2image ,65536,data.spinor)
endif
else ifeq (${STORAGE_TYPE},spinand)
	$(call pack_image,data,$(OUTPUT_DIR)/data/)
else ifeq (${STORAGE_TYPE},emmc)
	$(call pack_image,data,$(OUTPUT_DIR)/data/,3072M)
endif
ifeq ($(CONFIG_SUP_LARGE_PART_SIZE),y)
	$(call raw2cimg_lps,data.$(STORAGE_TYPE))
else
	$(call raw2cimg,data.$(STORAGE_TYPE))
endif

rootfs-clean:
	$(call print_target)
	$(Q)rm -rf $(OUTPUT_DIR)/rootfs/
	$(Q)rm $(OUTPUT_DIR)/rootfs.$(STORAGE_TYPE)
ifeq (${CONFIG_FASTBOOT},y)
	${Q}rm -rf $(OUTPUT_DIR)/data/ko
	${Q}rm -rf $(OUTPUT_DIR)/data.$(STORAGE_TYPE)
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
ifeq ($(CONFIG_SUP_LARGE_PART_SIZE),y)
	$(call raw2cimg_lps ,system.$(STORAGE_TYPE))
else
	$(call raw2cimg ,system.$(STORAGE_TYPE))
endif

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
ifeq ($(CONFIG_SUP_LARGE_PART_SIZE),y)
	$(call raw2cimg_lps ,cfg.$(STORAGE_TYPE))
else
	$(call raw2cimg ,cfg.$(STORAGE_TYPE))
endif

-include riscv.mk
-include alios.mk

################################################################################
# busybox targets
################################################################################
ifeq (${CONFIG_FASTBOOT},y)
BUSYBOX_OUTPUT_PATH := ${BUSYBOX_PATH}/${packages_arch}_fastboot_install
else
BUSYBOX_OUTPUT_PATH := ${BUSYBOX_PATH}/${packages_arch}_install
endif

BUSYBOX_OUTPUT_CONFIG_PATH := ${BUSYBOX_PATH}/.config
ifeq (${packages_arch},musl_riscv64)
ifeq (${CONFIG_FASTBOOT},y)
BUSYBOX_DEFAULT_CONFIG_PATH := ${BUSYBOX_PATH}/configs/cvitek_musl_simplify_defconfig
else
BUSYBOX_DEFAULT_CONFIG_PATH := ${BUSYBOX_PATH}/configs/cvitek_musl_defconfig
endif

else ifeq (${packages_arch},arm)

ifeq (${CONFIG_FASTBOOT},y)
BUSYBOX_DEFAULT_CONFIG_PATH := ${BUSYBOX_PATH}/configs/cvitek_arm_simplify_defconfig
else
BUSYBOX_DEFAULT_CONFIG_PATH := ${BUSYBOX_PATH}/configs/cvitek_arm_defconfig
endif

endif

${BUSYBOX_OUTPUT_CONFIG_PATH}: ${BUSYBOX_DEFAULT_CONFIG_PATH} ${BUILD_PATH}/.config
	$(call print_target)
	${Q}mkdir -p $(dir ${BUSYBOX_OUTPUT_CONFIG_PATH})
	${Q}cmp -s ${BUSYBOX_DEFAULT_CONFIG_PATH} ${BUSYBOX_OUTPUT_CONFIG_PATH} || \
		${Q}cp -vb ${BUSYBOX_DEFAULT_CONFIG_PATH} ${BUSYBOX_OUTPUT_CONFIG_PATH}

busybox-menuconfig: ${BUSYBOX_OUTPUT_CONFIG_PATH}
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${BUSYBOX_PATH} menuconfig

ifeq (${CONFIG_FASTBOOT},y)
BUSYBOX_ROOTFS_PATH := ${RAMDISK_PATH}/rootfs/common_${packages_arch}_shrink/
else
BUSYBOX_ROOTFS_PATH := ${RAMDISK_PATH}/rootfs/common_${packages_arch}/
endif

${BUSYBOX_OUTPUT_PATH}:
	${Q}mkdir -p $@

busybox: ${BUSYBOX_OUTPUT_CONFIG_PATH} ${BUSYBOX_OUTPUT_PATH}
	$(call print_target)
	${Q}rm -rf  ${BUSYBOX_OUTPUT_PATH}/*
	${Q}$(MAKE) -j${NPROC} -C ${BUSYBOX_PATH} ENABLE_FASTBOOT=${CONFIG_FASTBOOT}
	${Q}$(MAKE) -j${NPROC} -C ${BUSYBOX_PATH} install ENABLE_FASTBOOT=${CONFIG_FASTBOOT}
	${Q}cp -r ${BUSYBOX_OUTPUT_PATH}/* ${BUSYBOX_ROOTFS_PATH}

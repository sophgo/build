BL2_CVIPART_DEP := ${FSBL_PATH}/build/cvipart.h
${BL2_CVIPART_DEP}: FORCE
	$(call print_target)
	${Q}mkdir -p ${FSBL_PATH}/build
	${Q}rm -rf ${BL2_CVIPART_DEP}
	${Q}python3 ${IMGTOOL_PATH}/mkcvipart.py ${FLASH_PARTITION_XML} ${FSBL_PATH}/build/

opensbi: export CROSS_COMPILE=$(CONFIG_CROSS_COMPILE_SDK)
opensbi: u-boot-build
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${OPENSBI_PATH} PLATFORM=generic \
	    FW_PAYLOAD_PATH=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot-raw.bin \
	    FW_FDT_PATH=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/arch/riscv/dts/${CHIP}_${BOARD}.dtb

opensbi-clean:
	$(call print_target)
	${Q}$(MAKE) -C ${OPENSBI_PATH} PLATFORM=generic distclean

FSBL_OUTPUT_PATH = ${FSBL_PATH}/build/${PROJECT_FULLNAME}
ifeq ($(call qstrip,${CONFIG_ARCH}),riscv)
fsbl-build: opensbi
endif
fsbl%: export CVIBOARD=${CONFIG_BOARD}
fsbl%: export FSBL_SECURE_BOOT_SUPPORT=${CONFIG_FSBL_SECURE_BOOT_SUPPORT}
fsbl%: export ARCH=$(call qstrip,${CONFIG_ARCH})
fsbl%: export OD_CLK_SEL=${CONFIG_OD_CLK_SEL}
fsbl%: export VC_CLK_OVERDRIVE=${CONFIG_VC_CLK_OVERDRIVE}
fsbl%: export IMPROVE_AXI_CLK=${CONFIG_IMPROVE_AXI_CLK}
fsbl%: export IMPROVE_BL_NOR_SPEED=${CONFIG_IMPROVE_BL_NOR_SPEED}
fsbl%: export CHIP_CV1811HA=${CONFIG_CHIP_cv1811ha}
fsbl%: export TPU_PERF_MODE=${CONFIG_CHIP_cv1812cp}
fsbl%: export RTOS_ENABLE_FREERTOS=${CONFIG_ENABLE_FREERTOS}
fsbl%: export RTOS_ENABLE_RTT=${CONFIG_ENABLE_RTT}
ifeq (${CONFIG_ENABLE_BURN_BUTTON},y)
fsbl%: export ENABLE_BURN_BUTTON=${CONFIG_ENABLE_BURN_BUTTON}
fsbl%: export GPIO_GRP=${CONFIG_GPIO_GRP}
fsbl%: export GPIO_PIN=${CONFIG_GPIO_PIN}
endif
ifeq (${CONFIG_BUILD_FOR_DEBUG},y)
fsbl%: export LOG_LEVEL=3
else
fsbl%: export LOG_LEVEL=1
endif
ifeq (${CONFIG_ENABLE_FREERTOS},y)
fsbl-build: rtos
fsbl%: export BLCP_2ND_PATH=${FREERTOS_PATH}/yoc.bin
fsbl%: export RTOS_DUMP_PRINT_ENABLE=$(CONFIG_ENABLE_RTOS_DUMP_PRINT)
fsbl%: export RTOS_DUMP_PRINT_SZ_IDX=$(CONFIG_DUMP_PRINT_SZ_IDX)
fsbl%: export RTOS_FAST_IMAGE_TYPE=${CONFIG_FAST_IMAGE_TYPE}
else ifeq (${CONFIG_ENABLE_ALIOS},y)
fsbl-build: alios
fsbl%: export BLCP_2ND_PATH=${ALIOS_PATH}/solutions/${CONFIG_ALIOS_SOLUTION}/yoc.bin
else ifeq (${CONFIG_ENABLE_RTT},y)
fsbl-build: rtt
fsbl%: export RTOS_DUMP_PRINT_ENABLE=$(CONFIG_ENABLE_RTOS_DUMP_PRINT)
fsbl%: export RTOS_DUMP_PRINT_SZ_IDX=$(CONFIG_DUMP_PRINT_SZ_IDX)
fsbl%: export RTOS_FAST_IMAGE_TYPE=${CONFIG_FAST_IMAGE_TYPE}
fsbl%: export BLCP_2ND_PATH=${RTT_PATH}/bsp/cvitek/c906_little/yoc.bin
endif
ifeq (${CONFIG_ENABLE_BURN_BUTTON},y)
LOADER_2ND_PATH_B=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot-raw.bin
else
LOADER_2ND_PATH_B=""
endif

fsbl-build: u-boot-build memory-map ${BL2_CVIPART_DEP}
	$(call print_target)
	${Q}ln -snrf -t ${FSBL_PATH}/build ${CVI_BOARD_MEMMAP_H_PATH}
	${Q}$(MAKE) -C ${FSBL_PATH} clean O=${FSBL_OUTPUT_PATH}
	${Q}$(MAKE) -j${NPROC} -C ${FSBL_PATH} O=${FSBL_OUTPUT_PATH} LOG_LEVEL=${LOG_LEVEL} \
		BLCP_2ND_PATH=${BLCP_2ND_PATH} BLCP_2ND_BUILDIN=${CONFIG_RTOS_BUILD_IN_FIP} \
		BLCP_2ND_COMP_TYPE=${CONFIG_RTOS_COMPRESS_TYPE} \
		CONFIG_SKIP_UBOOT=n LOADER_2ND_PATH=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot-raw.bin \
		CONFIG_MMC_SKIP_TUNING=$(CONFIG_MMC_SKIP_TUNING) \
		FORCE_BOOT_FROM_FLASH=y
	${Q}cp ${FSBL_OUTPUT_PATH}/fip.bin ${OUTPUT_DIR}

ifeq (${CONFIG_UBOOT_SPL_CUSTOM},y)
	${Q}$(MAKE) -C ${FSBL_PATH} clean O=${FSBL_OUTPUT_PATH}
	${Q}$(MAKE) -j${NPROC} -C ${FSBL_PATH} O=${FSBL_OUTPUT_PATH} LOG_LEVEL=${LOG_LEVEL} \
		BLCP_2ND_PATH=${BLCP_2ND_PATH} BLCP_2ND_BUILDIN=${CONFIG_RTOS_BUILD_IN_FIP} \
		BLCP_2ND_COMP_TYPE=${CONFIG_RTOS_COMPRESS_TYPE} \
		LOADER_2ND_PATH_B=${LOADER_2ND_PATH_B} \
		CONFIG_SKIP_UBOOT=$(CONFIG_SKIP_UBOOT) LOADER_2ND_PATH=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot-raw_spl.bin \
		CONFIG_MMC_SKIP_TUNING=$(CONFIG_MMC_SKIP_TUNING)
	${Q}cp ${FSBL_OUTPUT_PATH}/fip.bin ${OUTPUT_DIR}/fip_spl.bin
else
	${Q}$(MAKE) -C ${FSBL_PATH} clean O=${FSBL_OUTPUT_PATH}
	${Q}$(MAKE) -j${NPROC} -C ${FSBL_PATH} O=${FSBL_OUTPUT_PATH} LOG_LEVEL=${LOG_LEVEL} \
		BLCP_2ND_PATH=${BLCP_2ND_PATH} BLCP_2ND_BUILDIN=${CONFIG_RTOS_BUILD_IN_FIP} \
		BLCP_2ND_COMP_TYPE=${CONFIG_RTOS_COMPRESS_TYPE} \
		CONFIG_SKIP_UBOOT=$(CONFIG_SKIP_UBOOT) LOADER_2ND_PATH=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot-raw.bin \
		CONFIG_MMC_SKIP_TUNING=$(CONFIG_MMC_SKIP_TUNING)
	${Q}cp ${FSBL_OUTPUT_PATH}/fip.bin ${OUTPUT_DIR}/fip_spl.bin
endif
	${Q}cp ${OUTPUT_DIR}/fip* ${OUTPUT_DIR}/rawimages/

fsbl-clean: rtos-clean
	$(call print_target)
	${Q}$(MAKE) -C ${FSBL_PATH} clean O=${FSBL_OUTPUT_PATH}
	${Q}rm -rf ${BL2_CVIPART_DEP}

u-boot-dep: ${OUTPUT_DIR}/elf ${OUTPUT_DIR}/rawimages fsbl-build
	$(call print_target)
ifeq ($(call qstrip,${CONFIG_ARCH}),riscv)
	${Q}cp ${OPENSBI_PATH}/build/platform/generic/firmware/fw_payload.bin ${OUTPUT_DIR}/fw_payload_uboot.bin
	${Q}cp ${OPENSBI_PATH}/build/platform/generic/firmware/fw_payload.elf ${OUTPUT_DIR}/elf/fw_payload_uboot.elf
endif

ifeq ($(call qstrip,${CONFIG_ARCH}),riscv)
u-boot-clean: opensbi-clean
endif
u-boot-clean: fsbl-clean

bl2-build: memory-map ${BL2_CVIPART_DEP}
	${Q}ln -snrf -t ${FSBL_PATH}/build ${CVI_BOARD_MEMMAP_H_PATH}
	${Q}${MAKE} -j${NPROC} -C ${FSBL_PATH} O=${FSBL_OUTPUT_PATH} bl2

bl2-clean:
	${Q}$(MAKE) -C ${FSBL_PATH} clean O=${FSBL_OUTPUT_PATH}
	${Q}rm -rf ${BL2_CVIPART_DEP}

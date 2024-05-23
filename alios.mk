.PHONY: alios_partition_dep
.PHONY: alios-tool-clean
.PHONY: alios-loader-clean

ALIOS_SOLUTIONS_DIR=${ALIOS_PATH}/solutions/${CONFIG_ALIOS_SOLUTION}

alios-build:
	$(call print_target)
	${Q}$(MAKE) -C ${ALIOS_SOLUTIONS_DIR} BOARD=""
	${Q}cp ${ALIOS_SOLUTIONS_DIR}/yoc.bin ${OUTPUT_DIR}/
	${Q}cp ${ALIOS_SOLUTIONS_DIR}/rom.bin ${OUTPUT_DIR}/
	${Q}unzip -o ${ALIOS_SOLUTIONS_DIR}/generated/images.zip -d ${OUTPUT_DIR}

alios_clean:
	$(call print_target)
	${Q}$(MAKE) -C ${ALIOS_SOLUTIONS_DIR} clean

alios: alios-build

alios_build_burn_tool%: export KBUILD_OUTPUT=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/burn_tool
alios_build_burn_tool%: export RELEASE=${RELEASE_VERSION}
alios_build_burn_tool%: export CVIBOARD=${BOARD}
alios_build_burn_tool%: export CONFIG_SKIP_RAMDISK:=${CONFIG_SKIP_RAMDISK}
alios_build_burn_tool%: export CONFIG_USE_DEFAULT_ENV:=${CONFIG_USE_DEFAULT_ENV}
alios_build_burn_tool%: export MULTI_FIP=$(if ${CONFIG_MULTI_FIP},1,0)
alios_build_burn_tool%: export CROSS_COMPILE=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE))
alios_build_burn_tool%: export ARCH=$(patsubst "%",%,$(CONFIG_ARCH))

ALIOS_BURN_TOOL_BUILD_PATH:
	mkdir -p ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/burn_tool

#ALIOS_PARTITION_DEP := ${UBOOT_PATH}/include/imgs.h ${UBOOT_PATH}/include/cvipart.h
ALIOS_PARTITION_DEP := alios_partition_dep

${ALIOS_PARTITION_DEP}: ${FLASH_CONFIG_YAML} ${BUILD_PATH}/.config
	$(call print_target)
	${Q}python3 ${IMGTOOL_PATH}/alios/mkcvipart_alios.py ${FLASH_CONFIG_YAML} ${UBOOT_PATH}/include
	${Q}python3 ${IMGTOOL_PATH}/alios/mk_imgHeader_alios.py ${FLASH_CONFIG_YAML} ${UBOOT_PATH}/include

BURNTOOL_OUTPUT_CONFIG_PATH := ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/burn_tool/.config
BURNTOOL_DEFAULT_CONFIG_PATH := ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/u-boot/${BRAND}_${PROJECT_FULLNAME}_burntool_defconfig

${BURNTOOL_OUTPUT_CONFIG_PATH}: ${BURNTOOL_DEFAULT_CONFIG_PATH} ${BUILD_PATH}/.config
	$(call print_target)
	${Q}echo "u-boot's defconfig is updated. Use it."
	${Q}mkdir -p $(dir ${BURNTOOL_OUTPUT_CONFIG_PATH})
	${Q}cmp -s ${BURNTOOL_DEFAULT_CONFIG_PATH} ${BURNTOOL_OUTPUT_CONFIG_PATH} || \
		${Q}cp -vb ${BURNTOOL_DEFAULT_CONFIG_PATH} ${BURNTOOL_OUTPUT_CONFIG_PATH}

alios_build_burn_tool: ${ALIOS_BURN_TOOL_BUILD_PATH}
alios_build_burn_tool: ${ALIOS_PARTITION_DEP} ${BURNTOOL_OUTPUT_CONFIG_PATH}
	$(call print_target)
	${Q}rm -f ${UBOOT_CVI_BOARD_INIT_PATH}
	${Q}ln -s ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/u-boot/cvi_board_init.c ${UBOOT_CVI_BOARD_INIT_PATH}
	${Q}rm -f ${UBOOT_CVITEK_PATH}
	${Q}ln -s ${BUILD_PATH}/boards/${CHIP_ARCH_L}/${PROJECT_FULLNAME}/u-boot/cvitek.h ${UBOOT_CVITEK_PATH}
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} olddefconfig
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} all
	${Q}cat ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/burn_tool/u-boot.bin > ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/burn_tool/u-boot-raw.bin

alios_build_burn_tool_dep: fip-pre-merge alios_build_burn_tool
	$(call print_target)
	${Q}python3 ${TOOLS_PATH}/${CHIP_ARCH_L}/pack_fip/pack_fip.py ${FIP_PRE_BIN_DIR}/fip_pre.bin \
		--add-bl33 ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/burn_tool/u-boot.bin --output ${OUTPUT_DIR}/fip.bin

alios-tool: alios_build_burn_tool_dep

alios-tool-menuconfig: export KBUILD_OUTPUT=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/burn_tool
alios-tool-menuconfig: ${BURNTOOL_OUTPUT_CONFIG_PATH}
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} menuconfig
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} savedefconfig

alios-tool-clean: export KBUILD_OUTPUT=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/burn_tool
alios-tool-clean:
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} distclean

alios-loader-clean: export KBUILD_OUTPUT=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}
alios-loader-clean:
	$(call print_target)
	${Q}$(MAKE) -j${NPROC} -C ${UBOOT_PATH} distclean
	rm -f ${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot.bin.lzma
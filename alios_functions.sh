#!/bin/bash
#
# For alios
#

function _build_alios_env()
{
	export ALIOS_PATH FLASH_PARTITION_XML

	cd "$ALIOS_PATH" || return
	if [ ! -f ".yoc" ]; then
		yoc init;
	fi;
}

function clean_alios()
{(
	print_notice "Run ${FUNCNAME[0]}() function"
	_build_alios_env

	cd "$BUILD_PATH" || return
	make alios_clean || return "$?"
)}

function build_alios()
{(
	print_notice "Run ${FUNCNAME[0]}() function"
	_build_alios_env

	cd "$BUILD_PATH" || return
	make alios || return "$?"
)}

function build_alios_tool()
{(
	print_notice "Run ${FUNCNAME[0]}() function"
	_build_uboot_env
	_build_alios_env
	cd "$BUILD_PATH" || return

	export ENABLE_ALIOS_FASTBOOT=n
	make alios-tool || return "$?"
)}

function menuconfig_alios_tool()
{(
	print_notice "Run ${FUNCNAME[0]}() function"
	_build_uboot_env
	_build_alios_env
	cd "$BUILD_PATH" || return
	make alios-tool-menuconfig || return "$?"
)}

function build_alios_loader()
{(
	if [ -e "$OUTPUT_DIR"/fip.bin ]; then
		mv "$OUTPUT_DIR"/fip.bin "$OUTPUT_DIR"/fip.bin.bak
	fi

	ALIOS_UBOOT_CONFIG_PATH=${UBOOT_PATH}/build/"$PROJECT_FULLNAME"/bootloader/.config

	if [ -e $ALIOS_UBOOT_CONFIG_PATH ]; then
		${UBOOT_PATH}/scripts/config \
			--file $ALIOS_UBOOT_CONFIG_PATH \
			--set-val CVI_LOG_LEVEL 3
	fi

	export UBOOT_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"/bootloader
	export ENABLE_ALIOS_FASTBOOT=n
	build_uboot || return "$?"
	mv "$OUTPUT_DIR"/fip.bin "$OUTPUT_DIR"/fip_bootloader.bin

	export ENABLE_ALIOS_FASTBOOT=y
	build_uboot || return "$?"
	mv "$OUTPUT_DIR"/fip.bin "$OUTPUT_DIR"/fip_bootloader.bin.fastboot

	${UBOOT_PATH}/scripts/config \
		--file $ALIOS_UBOOT_CONFIG_PATH \
		--set-val CVI_LOG_LEVEL 5

	export ENABLE_ALIOS_FASTBOOT=y
	build_uboot || return "$?"
	mv "$OUTPUT_DIR"/fip.bin "$OUTPUT_DIR"/fip_bootloader.bin.fastboot.debug

	if [ -e "$OUTPUT_DIR"/fip.bin.bak ]; then
		mv "$OUTPUT_DIR"/fip.bin.bak "$OUTPUT_DIR"/fip.bin
	fi
)}

function menuconfig_alios_loader()
{(
	print_notice "Run ${FUNCNAME[0]}() function"
	_build_uboot_env
	_build_alios_env
	cd "$BUILD_PATH" || return

	export UBOOT_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"/bootloader
	make u-boot-menuconfig || return "$?"
)}

function clean_alios_loader()
{(
	print_notice "Run ${FUNCNAME[0]}() function"
	_build_uboot_env
	cd "$BUILD_PATH" || return

	export UBOOT_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"/bootloader
	make alios-loader-clean || return "$?"
)}

function clean_alios_tool()
{(
	print_notice "Run ${FUNCNAME[0]}() function"
	_build_uboot_env
	_build_alios_env
	cd "$BUILD_PATH" || return
	make alios-tool-clean || return "$?"
)}

function build_alios_all()
{(
	print_notice "Run ${FUNCNAME[0]}() function"

	build_alios_tool || return "$?"
	build_alios_loader || return "$?"
	build_alios || return "$?"
)}

function clean_alios_all()
{(
	print_notice "Run ${FUNCNAME[0]}() function"

	clean_alios_tool || return "$?"
	clean_alios_loader || return "$?"
	clean_alios || return "$?"
)}

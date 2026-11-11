riscv-cpio:
	$(call print_target)
	${Q}mkdir -p ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}
	${Q}mkdir -p ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}
	${Q}cd $(RAMDISK_PATH)/initramfs/$(INITRAMFS_BASE) ;\
	${Q}find . | cpio --quiet -o -H newc > ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio
	${Q}cp ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/

opensbi-kernel: export CROSS_COMPILE=$(patsubst "%",%,$(CONFIG_CROSS_COMPILE_KERNEL))
opensbi-kernel: export ARCH=$(patsubst "%",%,$(CONFIG_ARCH))
opensbi-kernel:
	$(call print_target)
ifeq (${CONFIG_SKIP_UBOOT},y)
	${Q}python3 ${IMGTOOL_PATH}/mkcvipart.py ${FLASH_PARTITION_XML} ${OPENSBI_PATH}/include
endif
	${Q}$(MAKE) -C ${OPENSBI_PATH} PLATFORM=generic CONFIG_SKIP_UBOOT=$(CONFIG_SKIP_UBOOT) \
		CONFIG_SKIP_UBOOT_DEBUG=$(CONFIG_SKIP_UBOOT_DEBUG) \
	    FW_PAYLOAD_PATH=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arch/${ARCH}/boot/Image \
	    FW_FDT_PATH=${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/${CHIP}_${BOARD}.dtb
	${Q}mkdir -p ${OUTPUT_DIR}/elf
	${Q}cp ${OPENSBI_PATH}/build/platform/generic/firmware/fw_jump.bin ${OUTPUT_DIR}/fw_jump.bin
	${Q}cp ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arch/${ARCH}/boot/Image ${OUTPUT_DIR}/Image


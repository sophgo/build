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
	# Clean first, otherwise the last built firmware.bin would not work
	${Q}$(MAKE) -C ${OPENSBI_PATH} PLATFORM=generic distclean
	${Q}$(MAKE) -C ${OPENSBI_PATH} PLATFORM=generic \
	    FW_PAYLOAD_PATH=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arch/${ARCH}/boot/Image \
	    FW_FDT_PATH=${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/${CHIP}_${BOARD}.dtb \
	    _TPU_DEBUG_PORT_=${CONFIG_TPU_DEBUG_PORT}
	${Q}mkdir -p ${OUTPUT_DIR}/elf
	${Q}cp ${OPENSBI_PATH}/build/platform/generic/firmware/fw_payload.bin ${OUTPUT_DIR}/fw_payload_linux.bin
	${Q}cp ${OPENSBI_PATH}/build/platform/generic/firmware/fw_payload.elf ${OUTPUT_DIR}/elf/fw_payload_linux.elf
ifdef CONFIG_C906_HART1
	${Q}cp ${OPENSBI_PATH}/build/platform/generic/firmware/fw_payload.bin ${OUTPUT_DIR}/bm1688_firmware0_os.bin
	${Q}cp ${OPENSBI_PATH}/build/platform/generic/firmware/fw_payload.bin ${LIBSOPHON_PATH}/driver/bm1688_firmware0_os.bin
else ifdef CONFIG_C906_HART2
	${Q}cp ${OPENSBI_PATH}/build/platform/generic/firmware/fw_payload.bin ${OUTPUT_DIR}/bm1688_firmware1_os.bin
	${Q}cp ${OPENSBI_PATH}/build/platform/generic/firmware/fw_payload.bin ${LIBSOPHON_PATH}/driver/bm1688_firmware1_os.bin
endif

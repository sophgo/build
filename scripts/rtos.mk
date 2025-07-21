rtos: memory-map
	$(call print_target)
ifeq ($(CHIP_ARCH_L),$(filter $(CHIP_ARCH_L), cv184x))
ifneq (${CONFIG_RTOS_BUILD_IN_FIP},y)
	${Q}cp ${FREERTOS_PATH}/yoc.bin ${OUTPUT_DIR}/rawimages/
	$(call raw2cimg,yoc.bin)
endif
endif

rtos-clean:
ifeq (${CONFIG_ENABLE_FREERTOS},y)
	$(call print_target)
endif

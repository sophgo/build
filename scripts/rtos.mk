.PHONY: rtt-clean rtt-build rtt-menuconfig
rtos: memory-map
	$(call print_target)
ifeq ($(CHIP_ARCH_L),$(filter $(CHIP_ARCH_L), cv184x))
	cd ${FREERTOS_PATH}/cvitek && ./build_cv184x.sh
ifneq (${CONFIG_RTOS_BUILD_IN_FIP},y)
	${Q}cp ${FREERTOS_PATH}/yoc.bin ${OUTPUT_DIR}/rawimages/
	$(Q)${BUILD_PATH}/scripts/rtos_header.py -v appendHeader \
		--BLCP_2ND_RUNADDR=${CVIMMAP_FSBL_C906L_START_ADDR} \
		--BLCP_2ND_COMP_ADDR=${CVIMMAP_RTOS_COMPRESS_BIN_ADDR} \
		--BLCP_2ND_COMP_TYPE=${CONFIG_RTOS_COMPRESS_TYPE} \
		${OUTPUT_DIR}/rawimages/yoc.bin ${OUTPUT_DIR}/rawimages/yoc.bin
	$(call raw2cimg,yoc.bin)
endif
endif

rtos-clean:
ifeq (${CONFIG_ENABLE_FREERTOS},y)
	$(call print_target)
	cd ${FREERTOS_PATH}/cvitek && rm -rf build install
endif

-include ${BUILD_PATH}/output/${PROJECT_FULLNAME}/cvi_board_memmap.conf
RTT_C906L_PATH := ${RTT_PATH}/bsp/cvitek/c906_little
rtt-build: memory-map $(OUTPUT_DIR)/rawimages
	$(call print_target)
	${Q}cp -f ${CVI_BOARD_MEMMAP_H_PATH} ${RTT_C906L_PATH}/board/script/memmap/cvi_board_memmap.h
	${Q}cp -f ${CVI_BOARD_MEMMAP_LD_PATH} ${RTT_C906L_PATH}/board/script/memmap/cvi_board_memmap.ld
	cd ${RTT_C906L_PATH} && scons -c && scons
	${Q}cp ${RTT_C906L_PATH}/rtthread.bin ${RTT_C906L_PATH}/yoc.bin
ifneq (${CONFIG_RTOS_BUILD_IN_FIP},y)
	${Q}cp ${RTT_C906L_PATH}/yoc.bin ${OUTPUT_DIR}/rawimages/
	$(Q)${BUILD_PATH}/scripts/rtos_header.py -v appendHeader \
		--BLCP_2ND_RUNADDR=${CVIMMAP_FSBL_C906L_START_ADDR} \
		--BLCP_2ND_COMP_ADDR=${CVIMMAP_RTOS_COMPRESS_BIN_ADDR} \
		--BLCP_2ND_COMP_TYPE=${CONFIG_RTOS_COMPRESS_TYPE} \
		${OUTPUT_DIR}/rawimages/yoc.bin ${OUTPUT_DIR}/rawimages/yoc.bin
	$(call raw2cimg,yoc.bin)
endif

rtt-clean:
ifeq (${CONFIG_ENABLE_RTT},y)
	$(call print_target)
	cd ${RTT_C906L_PATH} && scons -c && rm -rf ${RTT_C906L_PATH}/yoc.bin
endif

rtt-menuconfig:
	$(call print_target)
	cd ${RTT_C906L_PATH} && scons --menuconfig

rtt: rtt-build

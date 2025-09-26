.PHONY: alios_partition_dep
.PHONY: alios-tool-clean
.PHONY: alios-loader-clean

ALIOS_SOLUTIONS_DIR=${ALIOS_PATH}/solutions/${subst ",,${CONFIG_ALIOS_SOLUTION}}
PACK_YOC_TOOL=$(COMMON_TOOLS_PATH)/image_tool/alios/PackYocTool/PackYocTool

ALIOS_OSDRV_PATH=${ALIOS_PATH}/components/cvi_mmf_sdk/cvi_osdrv
ALIOS_MW_PATH=${ALIOS_PATH}/components/cvi_mmf_sdk/cvi_middleware
ALIOS_MSG_PATH=${ALIOS_PATH}/components/cvi_mmf_sdk/cvi_msg
MEDIA_INCLUDE_DIR = $(TOP_DIR)/build/media/include

RTOS_COMPRESS_TYPE=$(patsubst "%",%, ${CONFIG_RTOS_COMPRESS_TYPE})
define raw2cimg_alios
	python3 $(COMMON_TOOLS_PATH)/image_tool/raw2cimg_alios.py $(OUTPUT_DIR)/rawimages/${1} $(OUTPUT_DIR) $(FLASH_PARTITION_XML) $(PACK_YOC_TOOL)
endef

alios-depends:
	$(call print_target)
	${Q}ln -sf $(TOP_DIR)/build/media/SensorSupportList $(TOP_DIR)/cvi_alios/components/cvi_mmf_sdk/
	${Q}cp -f $(MEDIA_INCLUDE_DIR)/internal/osdrv_uapi/* $(ALIOS_OSDRV_PATH)/include/common/uapi/
	${Q}cp -f $(MEDIA_INCLUDE_DIR)/internal/comm/* $(ALIOS_OSDRV_PATH)/include/common/uapi/
	${Q}cp -f $(MEDIA_INCLUDE_DIR)/release/cvi_defines.h $(ALIOS_OSDRV_PATH)/include/chip/$(CHIP_ARCH_L)/uapi/defines.h
	${Q}cp -f $(MEDIA_INCLUDE_DIR)/release/*.h $(ALIOS_MW_PATH)/include
	${Q}cp -f $(MEDIA_INCLUDE_DIR)/internal/mpi_uapi/*.h $(ALIOS_MW_PATH)/uapi
	${Q}cp -f $(MEDIA_INCLUDE_DIR)/internal/msg/*.h $(ALIOS_MSG_PATH)/internal_include/msg/
	${Q}cp -af ${ALIOS_SOLUTIONS_DIR}/customization/${CONFIG_ALIOS_CUSTOMIZATION_PIPELINE}/package.yaml.turnkey ${ALIOS_SOLUTIONS_DIR}/package_yamls/

alios-build: $(OUTPUT_DIR)/rawimages
alios-build: memory-map alios-depends
	$(call print_target)
	${Q}cp -f ${CVI_BOARD_MEMMAP_H_PATH} ${ALIOS_PATH}/components/aos/include/cvi_board_memmap.h
	${Q}cp -f ${CVI_BOARD_MEMMAP_LD_PATH} ${ALIOS_SOLUTIONS_DIR}/cvi_board_memmap.ld
	${Q}cd ${ALIOS_PATH};echo "y" | yoc init;cd -
	${Q}$(MAKE) -C ${ALIOS_SOLUTIONS_DIR} ALIOS_BOARD="" RTOS_COMPRESS_TYPE=${RTOS_COMPRESS_TYPE}
	${Q}cp ${ALIOS_SOLUTIONS_DIR}/yoc.bin ${OUTPUT_DIR}/rawimages/
	$(call raw2cimg,yoc.bin)

alios_clean: alios-depends
	$(call print_target)
	${Q}rm -f $(ALIOS_OSDRV_PATH)/include/common/uapi/*.h
	${Q}rm -f $(ALIOS_OSDRV_PATH)/include/chip/$(CHIP_ARCH_L)/uapi/defines.h
	${Q}rm -f $(ALIOS_MW_PATH)/include/*.h
	${Q}rm -f $(ALIOS_MW_PATH)/uapi/*.h
	${Q}rm -f $(ALIOS_MSG_PATH)/internal_include/msg/*.h
#	${Q}rm -f $(TOP_DIR)/cvi_alios/components/cvi_mmf_sdk/SensorSupportList
	${Q}$(MAKE) -C ${ALIOS_SOLUTIONS_DIR} clean

alios: alios-build

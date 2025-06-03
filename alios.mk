.PHONY: alios_partition_dep
.PHONY: alios-tool-clean
.PHONY: alios-loader-clean

ALIOS_SOLUTIONS_DIR=${ALIOS_PATH}/solutions/${subst ",,${CONFIG_ALIOS_SOLUTION}}
PACK_YOC_TOOL=$(COMMON_TOOLS_PATH)/image_tool/alios/PackYocTool/PackYocTool

MEDIA_INCLUDE_DIR = $(TOP_DIR)/build/media/include

RTOS_COMPRESS_TYPE=$(patsubst "%",%, ${CONFIG_RTOS_COMPRESS_TYPE})
define raw2cimg_alios
	python3 $(COMMON_TOOLS_PATH)/image_tool/raw2cimg_alios.py $(OUTPUT_DIR)/rawimages/${1} $(OUTPUT_DIR) $(FLASH_PARTITION_XML) $(PACK_YOC_TOOL)
endef

alios-depends:
	$(call print_target)

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
	${Q}$(MAKE) -C ${ALIOS_SOLUTIONS_DIR} clean

alios: alios-build

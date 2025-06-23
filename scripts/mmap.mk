.PHONY: memory-map FORCE

CVI_BOARD_MEMMAP_H_PATH := ${BUILD_PATH}/output/${PROJECT_FULLNAME}/cvi_board_memmap.h
CVI_BOARD_MEMMAP_CONF_PATH := ${BUILD_PATH}/output/${PROJECT_FULLNAME}/cvi_board_memmap.conf
CVI_BOARD_MEMMAP_LD_PATH:= ${BUILD_PATH}/output/${PROJECT_FULLNAME}/cvi_board_memmap.ld
CVI_BOARD_MEMMAP_TXT_PATH= ${BUILD_PATH}/output/${PROJECT_FULLNAME}/cvi_board_memmap.txt

BOARD_MMAP_PATH := ${BUILD_PATH}/boards/default/memmap/memmap.py

MMAP_CONV_PY := ${BUILD_PATH}/scripts/mmap_conv.py

MMAP_DISPLAY_PY := ${BUILD_PATH}/scripts/memory_display.py

${CVI_BOARD_MEMMAP_H_PATH}: ${BOARD_MMAP_PATH} ${MMAP_CONV_PY} FORCE
	$(call print_target)
	@mkdir -p $(dir $@)
	@${MMAP_CONV_PY} --type h $< $@

${CVI_BOARD_MEMMAP_CONF_PATH}: ${BOARD_MMAP_PATH} ${MMAP_CONV_PY} FORCE
	$(call print_target)
	@mkdir -p $(dir $@)
	@${MMAP_CONV_PY} --type conf $< $@

${CVI_BOARD_MEMMAP_LD_PATH}: ${BOARD_MMAP_PATH} ${MMAP_CONV_PY} FORCE
	$(call print_target)
	@mkdir -p $(dir $@)
	@${MMAP_CONV_PY} --type ld $< $@

${CVI_BOARD_MEMMAP_TXT_PATH}: ${BOARD_MMAP_PATH} ${MMAP_DISPLAY_PY}
	$(call print_target)
	@mkdir -p $(dir $@)
	@${MMAP_DISPLAY_PY} $< $@


ifeq ($(wildcard ${BOARD_MMAP_PATH}),)
memory-map:
$(error "(${BOARD_MMAP_PATH})" does not exist)
else
memory-map: ${CVI_BOARD_MEMMAP_H_PATH} ${CVI_BOARD_MEMMAP_CONF_PATH} ${CVI_BOARD_MEMMAP_LD_PATH} ${CVI_BOARD_MEMMAP_TXT_PATH} FORCE
endif
FORCE:
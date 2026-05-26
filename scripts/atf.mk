
################################################################################
# BLD targets
################################################################################
BM_BLD_OUTPUT := ${BM_BLD_PATH}/out

bld-build:
	${Q}mkdir -p $(RELEASE_BIN_BLD_DIR)
	${Q}mkdir -p $(RELEASE_BIN_BLDP_DIR)
	${Q}mkdir -p $(RELEASE_BIN_BLP_DIR)

bld: export ARCH=$(patsubst "%",%,$(CONFIG_ARCH))
bld: bld-build
	$(call print_target)
	${Q}$(MAKE) -C ${BM_BLD_PATH} bld
	${Q}cp ${BM_BLD_OUTPUT}/bldp.bin ${RELEASE_BIN_BLDP_DIR}/bldp_${CHIP_ARCH_L}_${CHIP}_${DDR_CFG}.bin
	${Q}cp ${BM_BLD_OUTPUT}/blp.bin ${RELEASE_BIN_BLP_DIR}/blp_${CHIP_ARCH_L}_${CHIP}.bin
	${Q}git -C ${BM_BLD_PATH} log --pretty=oneline -n 1 > ${RELEASE_BIN_BLDP_DIR}/bldp_${CHIP_ARCH_L}_${CHIP}_${DDR_CFG}.txt
	${Q}git -C ${BM_BLD_PATH} log --pretty=oneline -n 1 > ${RELEASE_BIN_BLP_DIR}/blp_${CHIP_ARCH_L}_${CHIP}.txt

bld-clean:
	$(call print_target)
	${Q}$(MAKE) -C ${BM_BLD_PATH} clean

################################################################################
# arm-trusted-firmware targets
################################################################################
ifeq ($(CHIP_ARCH),SOPHON)
ATF_PLAT := cv186x
else ifeq ($(CHIP_ARCH_L),sophon)
ATF_PLAT := cv186x
else
ATF_PLAT := ${CHIP}_${SUBTYPE}
endif
# TF-A install dir: default build/${PLAT}/release; when defconfig sets PROJECT_FULLNAME,
# build directly under build/${PROJECT_FULLNAME} (no trailing /release).
ATF_BUILD_OUT := ${ATF_PATH}/build/$(if ${PROJECT_FULLNAME},${PROJECT_FULLNAME},${ATF_PLAT}/release)
ATF_BUILD_PLAT_ABS := $(abspath $(ATF_BUILD_OUT))
ATF_FIP_PATH := ${ATF_BUILD_OUT}/fip.bin
CVI_FIPTOOL_ATF := ${ATF_PATH}/tools/cvitek/fiptool.py
CVI_CHIP_CONF_ATF := ${ATF_PATH}/tools/cvitek/chip_conf.bin
CVI_DDR_PARAM_ATF := ${ATF_PATH}/tools/cvitek/ddr_param.bin
CVI_BLMCU_ATF := ${ATF_PATH}/tools/cvitek/cv186x_mcu_fw.bin
ATF_CVITEK_STANDALONE ?= 1
ATF_RESET_TO_BL2 ?= 0
RESET_TO_BL2_MAKE_OPT :=
ifeq (${ATF_RESET_TO_BL2},1)
RESET_TO_BL2_MAKE_OPT := RESET_TO_BL2=1
endif

# clear is not encrypted
# key0 is encrypted by keys in ATF git repo
export ATF_KEY_SEL := $(subst default,,${ATF_KEY_SEL})

ifeq ($(CHIP_ARCH_L),$(filter $(CHIP_ARCH_L),cv183x cv75x1 cv952x))
define atf_post_action
	${Q}mv ${ATF_FIP_PATH} ${ATF_FIP_PATH}.ori
	# append blp.bin and bldp.bin to fip.bin
	${Q}dd if=${ATF_FIP_PATH}.ori of=${ATF_FIP_PATH} bs=2K conv=sync
	${Q}dd if=${BLP_PATH} bs=2K conv=sync >> ${ATF_FIP_PATH}
	${Q}dd if=${DDRC_PATH} bs=2K conv=sync >> ${ATF_FIP_PATH}
endef
    ATF_KEY_SEL := $(or ${ATF_KEY_SEL},key0)
else
    ATF_KEY_SEL := $(or ${ATF_KEY_SEL},clear)
endif

export IMG_ENC_KPATH :=
export IMG_ENC_KSRC := dev

ifeq (${ATF_KEY_SEL},clear)
    export ATF_TBBR := 0
    export IMG_ENC := 0
    export ATF_CRC := 1
else
    export ATF_TBBR := 1
    export IMG_ENC := 1
    export ATF_CRC := 0
endif

# ARM ATF TBBR configuration
TBBR_MAKE_OPT :=
TBBR_MAKE_TGT :=
ifeq (${ATF_TBBR},1)
    TBBR_MAKE_OPT := TRUSTED_BOARD_BOOT=1
    #TGT is short for TarGeT
    TBBR_MAKE_TGT := certificates
endif

# ARM ATF bl32
SPD_MAKE_OPT :=
ifeq ($(ATF_PLAT),cv186x)
    SPD_MAKE_OPT := SPD=opteed
else ifeq (${ATF_BL32},1)
    SPD_MAKE_OPT := SPD=opteed
endif

FAKE_BL31_32_TGT :=
ifeq (${FAKE_BL31_32},1)
    FAKE_BL31_32_TGT := fake_bl31_32
endif

ifeq ($(wildcard ${BM_BLD_PATH}/*),)
arm-trusted-firmware-build: export BLP_PATH=${ATF_PATH}/tools/blp.bin
arm-trusted-firmware-build: export DDRC_PATH=${ATF_PATH}/tools/bldp.bin
arm-trusted-firmware: export SCP_BL2=${ATF_PATH}/tools/bld.bin
else
ifeq (${CONFIG_FIP_V1},y)
arm-trusted-firmware-build: bld
arm-trusted-firmware-build: export BLP_PATH=${BM_BLD_OUTPUT}/blp.bin
arm-trusted-firmware-build: export DDRC_PATH=${BM_BLD_OUTPUT}/bldp.bin
arm-trusted-firmware: export RTC_CORE_SRAM_BIN_PATH=${BM_BLD_OUTPUT}/blds.bin
else
arm-trusted-firmware-build: export BLP_PATH=${ATF_PATH}/tools/blp.bin
arm-trusted-firmware-build: export DDRC_PATH=${ATF_PATH}/tools/bldp.bin
arm-trusted-firmware-build: export SCP_BL2=${ATF_PATH}/tools/bld.bin
arm-trusted-firmware-build: export RTC_CORE_SRAM_BIN_PATH=${ATF_PATH}/tools/bld.bin
endif

ifeq (${CONFIG_MULTI_FIP},y)
ATF_DEFAULT_SUFFIX := ${ATF_DEFAULT_SUFFIX}_single
arm-trusted-firmware: export MULTI_FIP=1
arm-trusted-firmware: export SCP_BL2=${ATF_PATH}/tools/fastboot/fake_bld_enc.bin
arm-trusted-firmware: export DDR_INIT=${BM_BLD_OUTPUT}/bld.bin
else
arm-trusted-firmware: export SCP_BL2=${BM_BLD_OUTPUT}/bld.bin
endif

endif

arm-trusted-firmware-build: export CROSS_COMPILE=${CROSS_COMPILE_64}
arm-trusted-firmware-build: export UBOOT_OUTPUT_FOLDER ?= build/${PROJECT_FULLNAME}
arm-trusted-firmware-build: export BL33_REAL=${UBOOT_PATH}/${UBOOT_OUTPUT_FOLDER}/u-boot-raw.bin
arm-trusted-firmware-build: export BL33=${ATF_PATH}/build/fake_bl33.bin
arm-trusted-firmware-build: export BL32_ATF_REAL=${ATF_BUILD_OUT}/bl32.bin
arm-trusted-firmware-build: export BL32_EXT ?=
arm-trusted-firmware-build: export BL2_EXT ?=
arm-trusted-firmware-build: export BL31_EXT ?=
arm-trusted-firmware-build:
	$(call print_target)
	${Q}mkdir -p $(dir ${BL33})
	${Q}mkdir -p ${RELEASE_BIN_ATF_DIR}
ifeq ($(ATF_PLAT),cv186x)
	${Q}mkdir -p ${ATF_PATH}/plat/cvitek/cv186x/asic/include
	${Q}cp -f ${CVI_BOARD_MEMMAP_H_PATH} ${ATF_PATH}/plat/cvitek/cv186x/asic/include/cvi_board_memmap.h
endif
	${Q}if [ -f "${BL33_REAL}" ]; then \
		cp -f "${BL33_REAL}" "${BL33}"; \
	else \
		printf 'BL33............' > "${BL33}"; \
	fi
	${Q}echo "SCP_BL2=${SCP_BL2}"
	${Q}if [ -n "$$SCP_BL2" ] && [ ! -f "$$SCP_BL2" ]; then \
		mkdir -p $$(dirname "$$SCP_BL2"); \
		dd if=/dev/zero of="$$SCP_BL2" bs=4096 count=1 2>/dev/null; \
	fi
	${Q}$(MAKE) -j${NPROC} -C ${ATF_PATH} \
		PLAT=${ATF_PLAT} \
		BUILD_PLAT=$(ATF_BUILD_PLAT_ABS) \
		${RESET_TO_BL2_MAKE_OPT} \
		CRC=${ATF_CRC} IMG_BLD=1 DEBUG=0 ENABLE_ASSERTIONS=1 \
		${SPD_MAKE_OPT} ${TBBR_MAKE_TGT} ${TBBR_MAKE_OPT} ${FAKE_BL31_32_TGT} \
		all fip
	${Q}mkdir -p "${ATF_PATH}/tools/cvitek/${PROJECT_FULLNAME}"
	# Repack TF-A images into CVitek private FIP container (param1/param2 + payloads).
	# Keep a backup of raw TF-A FIP for debugging and standard fiptool inspection.
	${Q}BL2_FOR_FIP="${ATF_BUILD_OUT}/bl2.bin"; \
	if [ -n "${BL2_EXT}" ] && [ -f "${BL2_EXT}" ]; then \
		BL2_FOR_FIP="${BL2_EXT}"; \
		echo "Use external BL2 for CVitek repack: $$BL2_FOR_FIP"; \
	elif [ -n "${BL2_EXT}" ]; then \
		echo "WARN: BL2_EXT not found, fallback to ATF BL2: ${BL2_EXT}"; \
	fi; \
	BL31_FOR_FIP="${ATF_BUILD_OUT}/bl31.bin"; \
	if [ -n "${BL31_EXT}" ] && [ -f "${BL31_EXT}" ]; then \
		BL31_FOR_FIP="${BL31_EXT}"; \
		echo "Use external BL31 for CVitek repack: $$BL31_FOR_FIP"; \
	fi; \
	BL32_FOR_FIP="${BL32_ATF_REAL}"; \
	if [ -n "${BL32_EXT}" ] && [ -f "${BL32_EXT}" ]; then \
		BL32_FOR_FIP="${BL32_EXT}"; \
		echo "Use external BL32 for CVitek repack: $$BL32_FOR_FIP"; \
	elif [ -n "${BL32_EXT}" ]; then \
		echo "WARN: BL32_EXT not found, fallback to ATF BL32: ${BL32_EXT}"; \
	fi; \
	for req in "${CVI_FIPTOOL_ATF}" "$$BL2_FOR_FIP" "$$BL31_FOR_FIP" "$$BL32_FOR_FIP" "${BL33}" \
		   "${CVI_CHIP_CONF_ATF}" "${CVI_DDR_PARAM_ATF}" "${CVI_BLMCU_ATF}"; do \
		if [ ! -f "$$req" ]; then \
			echo "ERROR: missing required file for CVitek FIP repack: $$req"; \
			exit 1; \
		fi; \
	done; \
	cp -f "${ATF_FIP_PATH}" "${ATF_FIP_PATH}.tfa.raw"; \
	params_log="${ATF_BUILD_OUT}/fip.params.txt"; \
	compact_log="${ATF_BUILD_OUT}/fip.params.compact.txt"; \
	plat_mmap_h="${ATF_PATH}/plat/cvitek/${ATF_PLAT}/asic/include/mmap.h"; \
	python3 "${CVI_FIPTOOL_ATF}" genfip \
		--CHIP_CONF "${CVI_CHIP_CONF_ATF}" \
		--BL2 "$$BL2_FOR_FIP" \
		--DDR_PARAM "${CVI_DDR_PARAM_ATF}" \
		--MONITOR "$$BL31_FOR_FIP" \
		--MONITOR_RUNADDR 0x100000000 \
		--BL32 "$$BL32_FOR_FIP" \
		--BL32_RUNADDR 0x100050000 \
		--BLMCU "${CVI_BLMCU_ATF}" \
		--BLMCU_RUNADDR 0x05200000 \
		--LOADER_2ND "${BL33}" \
		--compress lzma \
		"${ATF_FIP_PATH}.cvitek.new" > "$$params_log" 2>&1 && \
	cat "$$params_log" && \
	python3 "${BUILD_PATH}/scripts/atf_params_compact.py" "$$params_log" "$$compact_log" "$$plat_mmap_h" && \
	mv -f "${ATF_FIP_PATH}.cvitek.new" "${ATF_FIP_PATH}";
	$(call atf_post_action)

ifeq (${ATF_TBBR},0)
    ATF_DEFAULT_SUFFIX := clear
else
    ATF_DEFAULT_SUFFIX := key0
endif

ifeq (${CONFIG_FIP_V1},y)
arm-trusted-firmware-pack: arm-trusted-firmware-build
	$(call print_target)
	${Q}cp ${ATF_FIP_PATH} ${RELEASE_BIN_ATF_DIR}/fip_atf_${CHIP_ARCH_L}_${ATF_DEFAULT_SUFFIX}.bin
ifneq ($(wildcard ${BM_BLD_PATH}/*),)
	${Q}python3 ${TOOLS_PATH}/${CHIP_ARCH_L}/pack_fip/pack_fip.py $(if ${CONFIG_MULTI_FIP},--multibin) \
		--tar-bld ${ATF_FIP_PATH} \
		--output ${RELEASE_BIN_BLD_DIR}/bld_${CHIP_ARCH_L}_${CHIP}_${BOARD}_${ATF_DEFAULT_SUFFIX}.tar
	${Q}git -C ${BM_BLD_PATH} log --pretty=oneline -n 1 > ${RELEASE_BIN_BLD_DIR}/bld_${CHIP_ARCH_L}_${CHIP}_${BOARD}_${ATF_DEFAULT_SUFFIX}.txt
endif
	${Q}git -C ${ATF_PATH} log --pretty=oneline -n 1 > ${RELEASE_BIN_ATF_DIR}/fip_atf_${CHIP_ARCH_L}_${ATF_DEFAULT_SUFFIX}.txt

arm-trusted-firmware: arm-trusted-firmware-pack
endif

arm-trusted-firmware: arm-trusted-firmware-build

arm-trusted-firmware-clean: bld-clean
	$(call print_target)
	${Q}$(MAKE) -C ${ATF_PATH} PLAT=${ATF_PLAT} BUILD_PLAT=$(ATF_BUILD_PLAT_ABS) clean
	${Q}$(MAKE) -C ${ATF_PATH}/tools/fiptool clean


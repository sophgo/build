SIZE_1M = 0x100000
SIZE_1K = 1024


# Only attributes in class MemoryMap are generated to .h
class MemoryMap:
    # No prefix "CVIMMAP_" for the items in _no_prefix[]
    _no_prefix = [
        "CONFIG_SYS_TEXT_BASE"  # u-boot's CONFIG_SYS_TEXT_BASE is used without CPP.
    ]

    DRAM_BASE = 0x80000000
    DRAM_SIZE = 64 * SIZE_1M

    # ==============
    # C906L FreeRTOS
    # ==============
    FREERTOS_SIZE = 30 * SIZE_1M
    # FreeRTOS is at the end of DRAM
    FREERTOS_ADDR = DRAM_BASE + DRAM_SIZE - FREERTOS_SIZE
    FSBL_C906L_START_ADDR = FREERTOS_ADDR

    # =============================
    # dual os: alios & share memory
    # =============================
    ALIOS_SYS_SIZE = 6 * SIZE_1M
    ALIOS_LOG_SIZE = 128 * SIZE_1K
    SHARE_MEM_SIZE = 128 * SIZE_1K
    SHARE_PARAM_SIZE = 64 * SIZE_1K
    PQBIN_SIZE = 1024 * SIZE_1K
    ALIOS_RESV_SIZE = FREERTOS_SIZE - ALIOS_LOG_SIZE - ALIOS_SYS_SIZE - SHARE_MEM_SIZE - (SHARE_PARAM_SIZE * 2) - PQBIN_SIZE

    ALIOS_SYS_ADDR = FREERTOS_ADDR
    ALIOS_RESV_ADDR = ALIOS_SYS_ADDR + ALIOS_SYS_SIZE
    ALIOS_LOG_ADDR = ALIOS_RESV_ADDR + ALIOS_RESV_SIZE
    SHARE_MEM_ADDR = ALIOS_LOG_ADDR + ALIOS_LOG_SIZE
    SHARE_PARAM_ADDR = SHARE_MEM_ADDR + SHARE_MEM_SIZE
    SHARE_PARAM_ADDR_BAK = SHARE_PARAM_ADDR + SHARE_PARAM_SIZE
    PQBIN_ADDR = SHARE_PARAM_ADDR_BAK + SHARE_PARAM_SIZE
    ALIOS_COMPRESS_BIN_ADDR = ALIOS_SYS_ADDR + 6 * SIZE_1M

    # ==============================
    # OpenSBI | arm-trusted-firmware
    # ==============================
    # Monitor is at the begining of DRAM
    MONITOR_ADDR = DRAM_BASE

    ATF_SIZE = 512 * SIZE_1K
    OPENSBI_SIZE = 512 * SIZE_1K
    OPENSBI_FDT_ADDR = MONITOR_ADDR + OPENSBI_SIZE

    # =========================
    # memory@DRAM_BASE in .dts.
    # =========================
    # Ignore the area of FreeRTOS in u-boot and kernel
    KERNEL_MEMORY_ADDR = DRAM_BASE
    KERNEL_MEMORY_SIZE = DRAM_SIZE

    # =================
    # Multimedia buffer. Used by u-boot/kernel/FreeRTOS
    # =================
    ION_SIZE = 6 * SIZE_1M
    H26X_BITSTREAM_SIZE = 0 * SIZE_1M
    H26X_ENC_BUFF_SIZE = 0
    ISP_MEM_BASE_SIZE = 0 * SIZE_1M
    BOOTLOGO_SIZE = 900 * SIZE_1K
    FREERTOS_RESERVED_ION_SIZE = H26X_BITSTREAM_SIZE + H26X_ENC_BUFF_SIZE + ISP_MEM_BASE_SIZE + BOOTLOGO_SIZE + SHARE_MEM_SIZE

    # ION after FreeRTOS
    ION_ADDR = FREERTOS_ADDR - ION_SIZE

    # Buffers of the fast image are inside the ION buffer
    H26X_BITSTREAM_ADDR = ION_ADDR
    H26X_ENC_BUFF_ADDR = H26X_BITSTREAM_ADDR + H26X_BITSTREAM_SIZE
    ISP_MEM_BASE_ADDR = H26X_ENC_BUFF_ADDR + H26X_ENC_BUFF_SIZE

    # Boot logo is after ISP buffer and inside the ION buffer
    BOOTLOGO_ADDR = ISP_MEM_BASE_ADDR + ISP_MEM_BASE_SIZE

    assert BOOTLOGO_ADDR + BOOTLOGO_SIZE <= ION_ADDR + ION_SIZE

    # ===================
    # FSBL and u-boot-2021
    # ===================
    CVI_UPDATE_HEADER_SIZE = SIZE_1K
    CVI_MMC_SKIP_TUNING_SIZE = SIZE_1K
    UIMAG_SIZE = 7 * SIZE_1M

    # kernel image loading buffer
    UIMAG_ADDR = DRAM_BASE + 10 * SIZE_1M
    CVI_UPDATE_HEADER_ADDR = UIMAG_ADDR - CVI_UPDATE_HEADER_SIZE
    CVI_MMC_SKIP_TUNING_ADDR = CVI_UPDATE_HEADER_ADDR - CVI_MMC_SKIP_TUNING_SIZE

    # FSBL decompress buffer
    FSBL_UNZIP_ADDR = UIMAG_ADDR
    FSBL_UNZIP_SIZE = UIMAG_SIZE

    assert UIMAG_ADDR + UIMAG_SIZE <= ION_ADDR

    # u-boot's run address and entry point
    # CONFIG_SYS_TEXT_BASE = DRAM_BASE + 2 * SIZE_1M
    CONFIG_SYS_TEXT_BASE = BOOTLOGO_ADDR + BOOTLOGO_SIZE

    # SYS_TEXT_SIZE 1M
    assert CONFIG_SYS_TEXT_BASE + SIZE_1M <= ION_ADDR + ION_SIZE

    # u-boot's init stack point is only used before board_init_f()
    CONFIG_SYS_INIT_SP_ADDR = UIMAG_ADDR + UIMAG_SIZE

    #asssert CONFIG_SYS_INIT_SP_ADDR +  SIZE_1M <= ION_ADDR

    # spl fdt addr
    SPL_FDT_SIZE = SIZE_1M
    SPL_FDT_ADDR = CVI_UPDATE_HEADER_ADDR - SPL_FDT_SIZE

    #assert SPL_FDT_ADDR

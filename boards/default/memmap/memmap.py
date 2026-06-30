import os
SIZE_1M = 0x100000
SIZE_1K = 1024


# Only attributes in class MemoryMap are generated to .h
class MemoryMap:
    # No prefix "CVIMMAP_" for the items in _no_prefix[]
    _no_prefix = [
        "CONFIG_SYS_TEXT_BASE"  # u-boot's CONFIG_SYS_TEXT_BASE is used without CPP.
    ]
    DRAM_BASE = 0x80000000
    DRAM_SIZE = 510 * SIZE_1M

    # =========================
    # memory@DRAM_BASE in .dts.
    # =========================
    # kernel can see all ddr
    KERNEL_MEMORY_ADDR = DRAM_BASE
    KERNEL_MEMORY_SIZE = DRAM_SIZE

    # ==============================
    # OpenSBI | arm-trusted-firmware
    # ==============================
    # Monitor is at the begining of DRAM
    MONITOR_ADDR = DRAM_BASE

    ATF_SIZE = 640 * SIZE_1K
    OPENSBI_SIZE = 640 * SIZE_1K
    OPENSBI_FDT_ADDR = MONITOR_ADDR + OPENSBI_SIZE
    # =============================
    # dual os: alios & share memory  &  C906L start addr
    # =============================

    FSBL_C906L_START_ADDR = DRAM_BASE + ATF_SIZE

    RTOS_SYS_SIZE = 4 * SIZE_1M
    RTOS_LOG_SIZE = 128 * SIZE_1K
    SHARE_MEM_SIZE = 128 * SIZE_1K
    SHARE_PARAM_SIZE = 128 * SIZE_1K
    PQBIN_SIZE = 512 * SIZE_1K
    RTOS_LOGO_SIZE = 0 * SIZE_1K
    RTOS_SYS_TOTAL_SIZE = RTOS_SYS_SIZE + RTOS_LOG_SIZE + SHARE_MEM_SIZE + \
        (SHARE_PARAM_SIZE * 2) + PQBIN_SIZE + RTOS_LOGO_SIZE
    FREERTOS_SYS_SIZE = 1 * SIZE_1M

    RTOS_LOG_ADDR = FSBL_C906L_START_ADDR + RTOS_SYS_SIZE
    SHARE_MEM_ADDR = RTOS_LOG_ADDR + RTOS_LOG_SIZE
    SHARE_PARAM_ADDR = SHARE_MEM_ADDR + SHARE_MEM_SIZE
    SHARE_PARAM_ADDR_BAK = SHARE_PARAM_ADDR + SHARE_PARAM_SIZE
    PQBIN_ADDR = SHARE_PARAM_ADDR_BAK + SHARE_PARAM_SIZE
    RTOS_COMPRESS_BIN_ADDR = FSBL_C906L_START_ADDR + 30 * SIZE_1M
    RTOS_LOGO_ADDR = PQBIN_ADDR + PQBIN_SIZE
    # RTOS ION memory
    RTOS_ION_SIZE = 100 * SIZE_1M
    RTOS_ION_ADDR = DRAM_BASE + 256 * SIZE_1M - RTOS_ION_SIZE
    # RTOS_ION_ADDR = DRAM_BASE + DRAM_SIZE - RTOS_ION_SIZE

    # =================
    # Multimedia buffer. Used by u-boot/kernel/alios/FreeRTOS
    # =================
    ION_SIZE = 6 * SIZE_1M
    H26X_BITSTREAM_SIZE = 0 * SIZE_1M
    H26X_ENC_BUFF_SIZE = 0
    ISP_MEM_BASE_SIZE = 0 * SIZE_1M
    BOOTLOGO_SIZE = 1800 * SIZE_1K
    # ION before rtos_ion_addr
    ION_ADDR = RTOS_ION_ADDR - ION_SIZE
    # ION_ADDR = DRAM_BASE + 128 * SIZE_1M

    # Buffers of the fast image are inside the ION buffer
    H26X_BITSTREAM_ADDR = ION_ADDR
    H26X_ENC_BUFF_ADDR = H26X_BITSTREAM_ADDR + H26X_BITSTREAM_SIZE
    ISP_MEM_BASE_ADDR = H26X_ENC_BUFF_ADDR + H26X_ENC_BUFF_SIZE

    # Boot logo is after ISP buffer and inside the ION buffer
    BOOTLOGO_ADDR = ION_ADDR + ION_SIZE - BOOTLOGO_SIZE

    # ===================
    # FSBL and u-boot-2021
    # ===================
    CVI_UPDATE_HEADER_SIZE = SIZE_1K
    CVI_MMC_SKIP_TUNING_SIZE = SIZE_1K
    UIMAG_SIZE = 4 * SIZE_1M

    # kernel image loading buffer
    UIMAG_ADDR = DRAM_BASE + 20 * SIZE_1M
    # UIMAG_ADDR = ION_ADDR + ION_SIZE + 12 * SIZE_1M
    CVI_UPDATE_HEADER_ADDR = UIMAG_ADDR - CVI_UPDATE_HEADER_SIZE
    CVI_MMC_SKIP_TUNING_ADDR = CVI_UPDATE_HEADER_ADDR - CVI_MMC_SKIP_TUNING_SIZE
    # spl fdt addr
    SPL_FDT_SIZE = SIZE_1M
    SPL_FDT_ADDR = CVI_UPDATE_HEADER_ADDR - SPL_FDT_SIZE

    # FSBL decompress buffer
    FSBL_UNZIP_ADDR = UIMAG_ADDR
    FSBL_UNZIP_SIZE = UIMAG_SIZE

    # u-boot's run address and entry point
    CONFIG_SYS_TEXT_BASE = DRAM_BASE + 64 * SIZE_1M - 8 * SIZE_1M
    # SYS_TEXT_SIZE 1M

    # u-boot's init stack point is only used before board_init_f()
    # CONFIG_SYS_INIT_SP_ADDR = UIMAG_ADDR + UIMAG_SIZE

    # asssert CONFIG_SYS_INIT_SP_ADDR +  SIZE_1M <= ION_ADDR
    CONFIG_SYS_INIT_SP_ADDR = CONFIG_SYS_TEXT_BASE - 3 * SIZE_1M

    # assert SPL_FDT_ADDR

    # read config file
    @staticmethod
    def read_kconfig(config_file):
        config = {}
        with open(config_file, 'r') as f:
            for line in f:
                line = line.strip()
                # handle like CONFIG_XXX=y
                if line.startswith('CONFIG_') and '=' in line:
                    key, value = line.split('=', 1)
                    # remove quotes (if exists)
                    value = value.strip('"')
                    config[key] = value
                # handle like # CONFIG_XXX is not set
                elif line.startswith('# CONFIG_') and 'is not set' in line:
                    key = line.split()[1]
                    config[key] = 'n'
        return config

    def __init__(self):
        build_path = os.environ.get('BUILD_PATH', '')
        config_file = os.path.join(build_path, '.config')
        kconfig = self.read_kconfig(config_file)
        # example: read config value
        dram_size = kconfig.get('CONFIG_DRAM_SIZE', '')
        ion_size = kconfig.get('CONFIG_ION_SIZE', '')
        rtos_sys_size = kconfig.get('CONFIG_RTOS_SYS_SIZE', '0x00000000')
        rtos_ion_size = kconfig.get('CONFIG_RTOS_ION_SIZE', '0x00000000')
        rtos_logo_size = kconfig.get('CONFIG_RTOS_LOGO_SIZE', '0x00000000')
        enable_freertos = kconfig.get('CONFIG_ENABLE_FREERTOS', 'n')
        enable_rtt = kconfig.get('CONFIG_ENABLE_RTT', 'n')
        enable_alios = kconfig.get('CONFIG_ENABLE_ALIOS', 'n')
        # modify private attribute values
        setattr(MemoryMap, 'DRAM_SIZE', int(dram_size, 16))
        setattr(MemoryMap, 'KERNEL_MEMORY_SIZE', int(dram_size, 16))
        setattr(MemoryMap, 'RTOS_SYS_ADDR', getattr(MemoryMap, 'FSBL_C906L_START_ADDR'))
        setattr(MemoryMap, 'RTOS_SYS_SIZE', int(rtos_sys_size, 16))
        setattr(MemoryMap, 'RTOS_LOG_ADDR',
                getattr(MemoryMap, 'RTOS_SYS_ADDR') + getattr(MemoryMap, 'RTOS_SYS_SIZE'))
        setattr(MemoryMap, 'SHARE_MEM_ADDR',
                getattr(MemoryMap, 'RTOS_LOG_ADDR') + getattr(MemoryMap, 'RTOS_LOG_SIZE'))
        setattr(MemoryMap, 'SHARE_PARAM_ADDR',
                getattr(MemoryMap, 'SHARE_MEM_ADDR') + getattr(MemoryMap, 'SHARE_MEM_SIZE'))
        setattr(MemoryMap, 'SHARE_PARAM_ADDR_BAK',
                getattr(MemoryMap, 'SHARE_PARAM_ADDR') + getattr(MemoryMap, 'SHARE_PARAM_SIZE'))
        setattr(MemoryMap, 'PQBIN_ADDR',
                getattr(MemoryMap, 'SHARE_PARAM_ADDR_BAK') + getattr(MemoryMap, 'SHARE_PARAM_SIZE'))
        setattr(MemoryMap, 'RTOS_LOGO_ADDR',
                getattr(MemoryMap, 'PQBIN_ADDR') + getattr(MemoryMap, 'PQBIN_SIZE'))
        setattr(MemoryMap, 'RTOS_LOGO_SIZE', int(rtos_logo_size, 16))

        setattr(MemoryMap, 'RTOS_SYS_TOTAL_ADDR', getattr(MemoryMap, 'FSBL_C906L_START_ADDR'))
        if rtos_sys_size == '0x00000000' or enable_freertos == 'y':
            setattr(MemoryMap, 'RTOS_SYS_TOTAL_SIZE', getattr(MemoryMap, 'FREERTOS_SYS_SIZE'))
        elif enable_rtt == 'y':
            setattr(MemoryMap, 'RTOS_SYS_TOTAL_SIZE', getattr(MemoryMap, 'RTOS_SYS_SIZE'))
        else:
            setattr(MemoryMap, 'RTOS_SYS_TOTAL_SIZE',
                    (getattr(MemoryMap, 'RTOS_SYS_SIZE') + getattr(MemoryMap, 'RTOS_LOG_SIZE') +
                     getattr(MemoryMap, 'SHARE_MEM_SIZE')+ (getattr(MemoryMap, 'SHARE_PARAM_SIZE') * 2) +
                     getattr(MemoryMap, 'PQBIN_SIZE') + (getattr(MemoryMap, 'RTOS_LOGO_SIZE'))))

        if enable_alios == 'y':
            assert getattr(MemoryMap, 'PQBIN_ADDR') + getattr(MemoryMap, 'PQBIN_SIZE') <= \
                getattr(MemoryMap, 'FSBL_C906L_START_ADDR') + getattr(MemoryMap, 'RTOS_SYS_TOTAL_SIZE')

        setattr(MemoryMap, 'RTOS_ION_SIZE', int(rtos_ion_size, 16))
        setattr(MemoryMap, 'RTOS_ION_ADDR',
                getattr(MemoryMap, 'DRAM_BASE') + getattr(MemoryMap, 'DRAM_SIZE') - getattr(MemoryMap, 'RTOS_ION_SIZE'))

        if getattr(MemoryMap, 'RTOS_SYS_SIZE') > 0:
            assert getattr(MemoryMap, 'RTOS_ION_ADDR') >= \
                getattr(MemoryMap, 'FSBL_C906L_START_ADDR') + getattr(MemoryMap, 'RTOS_SYS_SIZE')
            assert getattr(MemoryMap, 'RTOS_COMPRESS_BIN_ADDR') >= \
                getattr(MemoryMap, 'UIMAG_ADDR') + getattr(MemoryMap, 'UIMAG_SIZE')

        setattr(MemoryMap, 'ION_SIZE', int(ion_size, 16))
        setattr(MemoryMap, 'ION_ADDR', getattr(MemoryMap, 'RTOS_ION_ADDR') - getattr(MemoryMap, 'ION_SIZE'))
        setattr(MemoryMap, 'H26X_BITSTREAM_ADDR', getattr(MemoryMap, 'ION_ADDR'))
        setattr(MemoryMap, 'H26X_ENC_BUFF_ADDR',
                getattr(MemoryMap, 'H26X_BITSTREAM_ADDR') + getattr(MemoryMap, 'H26X_BITSTREAM_SIZE'))
        setattr(MemoryMap, 'ISP_MEM_BASE_ADDR',
                getattr(MemoryMap, 'H26X_ENC_BUFF_ADDR') + getattr(MemoryMap, 'H26X_ENC_BUFF_SIZE'))
        setattr(MemoryMap, 'BOOTLOGO_ADDR',
                getattr(MemoryMap, 'ION_ADDR') + getattr(MemoryMap, 'ION_SIZE') - getattr(MemoryMap, 'BOOTLOGO_SIZE'))
        if enable_alios == 'y':
            assert getattr(MemoryMap, 'ION_ADDR') >= \
                getattr(MemoryMap, 'FSBL_C906L_START_ADDR') + getattr(MemoryMap, 'RTOS_SYS_SIZE')

        assert getattr(MemoryMap, 'CONFIG_SYS_TEXT_BASE') >= \
            getattr(MemoryMap, 'UIMAG_ADDR') + getattr(MemoryMap, 'UIMAG_SIZE')
        assert getattr(MemoryMap, 'CONFIG_SYS_INIT_SP_ADDR') >= \
            getattr(MemoryMap, 'UIMAG_ADDR') + getattr(MemoryMap, 'UIMAG_SIZE')

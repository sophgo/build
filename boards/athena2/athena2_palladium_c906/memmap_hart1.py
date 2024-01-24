SIZE_1M = 0x100000
SIZE_1K = 1024


# Only attributes in class MemoryMap are generated to .h
class MemoryMap:
    # No prefix "CVIMMAP_" for the items in _no_prefix[]
    _no_prefix = [
        "HART_ID"
    ]

    HART_ID = 1

    KERNEL_MEMORY_SIZE = 0x10000000
    KERNEL_MEMORY_ADDR_H = 0x1
    KERNEL_MEMORY_ADDR_L = 0x04000000

    KERNEL_MEMORY_ADDR_64 = (KERNEL_MEMORY_ADDR_H << 32) + KERNEL_MEMORY_ADDR_L
    MONITOR_ADDR = KERNEL_MEMORY_ADDR_64
    OPENSBI_SIZE = 512 * SIZE_1K
#!/usr/bin/env python3
import re
import sys


def _section(text: str, name: str) -> str:
    m = re.search(rf"INFO:root:print\({name}\):\n(\[.*?\])", text, re.S)
    return m.group(1).strip() if m else f"<missing {name}>"


def _field_hex(text: str, name: str, default: int = 0) -> int:
    m = re.search(rf"<{name}:.*?c=(0x[0-9a-fA-F]+)", text)
    return int(m.group(1), 16) if m else default


def _read_bl2_base_define(mmap_h: str) -> str:
    try:
        with open(mmap_h, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                s = line.strip()
                if s.startswith("#define BL2_BASE"):
                    parts = s.split()
                    if len(parts) >= 3:
                        return " ".join(parts[2:])
    except OSError:
        pass
    return "<not found>"


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: atf_params_compact.py <fip.params.txt> <fip.params.compact.txt> <mmap.h>")
        return 2

    params_log, compact_log, mmap_h = sys.argv[1], sys.argv[2], sys.argv[3]
    text = open(params_log, "r", encoding="utf-8", errors="ignore").read()

    blcp_img_size = _field_hex(text, "BLCP_IMG_SIZE")
    bl2_img_size = _field_hex(text, "BL2_IMG_SIZE")
    param2_loadaddr = _field_hex(text, "PARAM2_LOADADDR")
    bl2_offset = 0x1000 + blcp_img_size
    bl2_base_define = _read_bl2_base_define(mmap_h)

    with open(compact_log, "w", encoding="utf-8") as f:
        f.write("## key_derived\n")
        f.write(f"BL2_OFFSET_IN_FIP = 0x{bl2_offset:08x}\n")
        f.write(f"BL2_SIZE          = 0x{bl2_img_size:08x}\n")
        f.write(f"PARAM2_LOADADDR   = 0x{param2_loadaddr:08x}\n")
        f.write(f"BL2_BASE_DEFINE   = {bl2_base_define}\n")
        f.write(f"BL2_END_OFFSET    = 0x{(bl2_offset + bl2_img_size):08x}\n")
        f.write("\n## param1\n")
        f.write(_section(text, "param1"))
        f.write("\n\n## param2\n")
        f.write(_section(text, "param2"))
        f.write("\n\n## ldr_2nd_hdr\n")
        f.write(_section(text, "ldr_2nd_hdr"))
        f.write("\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

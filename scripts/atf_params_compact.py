#!/usr/bin/env python3
import os
import re
import sys


def _section(text: str, name: str) -> str:
    m = re.search(rf"INFO:root:print\({name}\):\n(\[.*?\])", text, re.S)
    return m.group(1).strip() if m else f"<missing {name}>"


def _field_hex(text: str, name: str, default: int = 0) -> int:
    m = re.search(rf"<{name}:.*?c=(0x[0-9a-fA-F]+)", text)
    return int(m.group(1), 16) if m else default


def _read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()


def _define_body(text: str, name: str) -> str:
    m = re.search(rf"^#define\s+{re.escape(name)}\s+(.+)$", text, re.M)
    if not m:
        raise ValueError(f"missing #define {name}")
    return re.sub(r"/\*.*?\*/", "", m.group(1)).strip()


def _eval_c_int(expr: str, macros: dict) -> int:
    expanded = expr
    for _ in range(16):
        nxt = re.sub(
            r"\b([A-Z_][A-Z0-9_]*)\b",
            lambda m: hex(macros[m.group(1)]) if m.group(1) in macros else m.group(0),
            expanded,
        )
        if nxt == expanded:
            break
        expanded = nxt
    leftover = re.sub(r"0[xX][0-9a-fA-F]+", "", expanded)
    if re.search(r"[A-Za-z_]", leftover):
        raise ValueError(f"unresolved expression: {expr} -> {expanded}")
    if not re.fullmatch(r"[0-9a-fA-Fx+\-() \t]+", expanded):
        raise ValueError(f"unsafe expression: {expr} -> {expanded}")
    return int(eval(expanded, {"__builtins__": {}}, {}))


def plat_runaddrs(mmap_h: str):
    """Resolve MONITOR/BL32/BLMCU runaddrs from platform mmap.h + cvi_board_memmap.h."""
    mmap_h = os.path.abspath(mmap_h)
    memmap_h = os.path.join(os.path.dirname(mmap_h), "cvi_board_memmap.h")
    mem = _read_text(memmap_h)
    mm = _read_text(mmap_h)
    macros = {
        "CVIMMAP_MONITOR_ADDR": _eval_c_int(_define_body(mem, "CVIMMAP_MONITOR_ADDR"), {}),
    }
    monitor = _eval_c_int(_define_body(mm, "MONITOR_RUNADDR"), macros)
    bl32 = _eval_c_int(_define_body(mm, "BL32_RUNADDR"), macros)
    blmcu = _eval_c_int(_define_body(mm, "BLMCU_RUNADDR"), macros)
    return monitor, bl32, blmcu


def dump_runaddrs(mmap_h: str) -> int:
    try:
        monitor, bl32, blmcu = plat_runaddrs(mmap_h)
    except (OSError, ValueError) as exc:
        print(f"ERROR: failed to resolve FIP runaddrs from {mmap_h}: {exc}", file=sys.stderr)
        return 1
    print(f"0x{monitor:x} 0x{bl32:x} 0x{blmcu:x}")
    return 0


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
    if len(sys.argv) == 3 and sys.argv[1] == "--runaddrs":
        return dump_runaddrs(sys.argv[2])

    if len(sys.argv) != 4:
        print("usage: atf_params_compact.py <fip.params.txt> <fip.params.compact.txt> <mmap.h>")
        print("       atf_params_compact.py --runaddrs <mmap.h>")
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

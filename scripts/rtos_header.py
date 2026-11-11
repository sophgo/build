#!/usr/bin/env python3
#

import sys
import logging
import os
import os.path
import argparse
from collections import OrderedDict
import binascii
from struct import pack

PYTHON_MIN_VERSION = (3, 5, 2)  # Ubuntu 16.04 LTS contains Python v3.5.2 by default

if sys.version_info < PYTHON_MIN_VERSION:
    print("Python >= %r is required" % (PYTHON_MIN_VERSION,))
    sys.exit(-1)

try:
    import coloredlogs
except ImportError:
    coloredlogs = None

try:
    import argcomplete
except ImportError:
    argcomplete = None


LOADER_2ND_MAGIC_ORIG = b"BL33"
LOADER_2ND_MAGIC_LZMA = b"B3MA"
LOADER_2ND_MAGIC_LZ4 = b"B3Z4"

IMAGE_ALIGN = 512


class Entry:
    __slots__ = "name", "type", "addr", "_content", "entry_size"

    def __init__(self):
        self.addr = None
        self._content = None

    @property
    def end(self):
        return self.addr + self.entry_size

    @property
    def content(self):
        return self._content

    @content.setter
    def content(self, value):
        if type(value) == int:
            value = value.to_bytes(self.entry_size, "little")

        if self.entry_size is not None:
            if len(value) > self.entry_size:
                raise ValueError("%s (%d bytes) must <= %#r" % (self.name, len(value), self.entry_size))
            value = value + b"\0" * (self.entry_size - len(value))

        self._content = value

    @classmethod
    def make(cls, name, entry_size, _type, init=None):
        entry = Entry()
        entry.name = name
        entry.type = _type
        entry.entry_size = entry_size

        if type(init) in (bytes, bytearray):
            entry.content = bytes(init)
        elif entry_size is not None:
            entry.content = b"\0" * entry.entry_size
        else:
            entry.content = b""

        return (name, entry)

    def toint(self):
        if self.type != int:
            raise TypeError("%s is not int type" % self.name)

        return int.from_bytes(self.content, "little")

    def tostr(self):
        v = self.content
        if self.type == int:
            v = "%#08x" % self.toint()
        elif type(self.content) in [bytes, bytearray]:
            v = v.hex()
            if len(v) > 32:
                v = v[:32] + "..."

        return v

    def __str__(self):
        v = self.tostr()
        return "<%s=%s (%dbytes)>" % (self.name, v, self.entry_size)

    def __repr__(self):
        v = self.tostr()
        return "<%s: a=%#x s=%#x c=%s %r>" % (self.name, self.addr, self.entry_size, v, self.type)


Header = OrderedDict(
    [
        Entry.make("BLCP_2ND_MAGIC", 4, bytes),
        Entry.make("BLCP_2ND_CKSUM", 4, int),
        Entry.make("BLCP_2ND_COMP_TYPE", 4, int),
        Entry.make("BLCP_2ND_COMP_SIZE", 4, int),
        Entry.make("BLCP_2ND_COMP_ADDR", 8, int),
        Entry.make("BLCP_2ND_LOADADDR", 8, int),
        Entry.make("BLCP_2ND_SIZE", 4, int),
        Entry.make("BLCP_2ND_RUNADDR", 8, int),
        Entry.make("BLCP_2ND_RESERVED", (512 - 4*5 - 8*3), bytes),
    ])


def init_logging(log_file=None, file_level="DEBUG", stdout_level="WARNING"):
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.NOTSET)

    fmt = "%(asctime)s %(levelname)8s:%(name)s:%(message)s"

    if log_file is not None:
        file_handler = logging.FileHandler(log_file, encoding="utf-8")
        file_handler.setFormatter(logging.Formatter(fmt))
        file_handler.setLevel(file_level)
        root_logger.addHandler(file_handler)

    if coloredlogs:
        os.environ["COLOREDLOGS_DATE_FORMAT"] = "%H:%M:%S"

        field_styles = {
            "asctime": {"color": "green"},
            "hostname": {"color": "magenta"},
            "levelname": {"color": "black", "bold": True},
            "name": {"color": "blue"},
            "programname": {"color": "cyan"},
        }

        level_styles = coloredlogs.DEFAULT_LEVEL_STYLES
        level_styles["debug"]["color"] = "cyan"

        coloredlogs.install(
            level=stdout_level,
            fmt=fmt,
            field_styles=field_styles,
            level_styles=level_styles,
            milliseconds=True,
        )


def pad(data, block_size):
    logging.debug(f"pad: input data type={type(data)}")
    if type(data) not in [bytearray, bytes]:
        logging.error(f"Invalid data type: {type(data)}")
        raise TypeError("Need bytearray or bytes")

    r = len(data) % block_size
    if r:
        if isinstance(data, bytes):
            data = bytearray(data)
        data += b"\0" * (block_size - r)
        logging.debug(f"pad: output data type={type(data)}")
    return data


def image_crc(image):
    crc = binascii.crc_hqx(image, 0)
    crc = pack("<H", crc) + b"\xFE\xCA"
    return crc


def append_yoc_header(args):
    logging.debug("append_yoc_header:")
    if args.input:
        with open(args.input, "rb") as fp:
            yoc_bin = bytearray(fp.read())
    else:
        logging.error("append_yoc_header: input file is missing")
        raise SystemExit(1)

    Header["BLCP_2ND_MAGIC"].content = b"YOCB"
    logging.debug(f"append_yoc_header: BLCP_2ND_MAGIC={Header['BLCP_2ND_MAGIC'].tostr()}")
    comp_type = args.BLCP_2ND_COMP_TYPE
    comp_type_magic = LOADER_2ND_MAGIC_ORIG if comp_type == "orig" \
        else LOADER_2ND_MAGIC_LZMA if comp_type == "lzma" \
        else LOADER_2ND_MAGIC_LZ4 if comp_type == "lz4" \
        else None
    Header["BLCP_2ND_COMP_TYPE"].content = comp_type_magic
    Header["BLCP_2ND_COMP_ADDR"].content = int(args.BLCP_2ND_COMP_ADDR)
    Header["BLCP_2ND_CKSUM"].content = image_crc(yoc_bin)
    Header["BLCP_2ND_RUNADDR"].content = int(args.BLCP_2ND_RUNADDR)
    Header["BLCP_2ND_LOADADDR"].content = 0

    if comp_type == "orig":
        Header["BLCP_2ND_SIZE"].content = len(yoc_bin)
    else:
        Header["BLCP_2ND_COMP_SIZE"].content = len(yoc_bin)

    header_bin = b"".join([entry.content for entry in Header.values()])
    new_yoc_bin = pad((header_bin + yoc_bin), IMAGE_ALIGN)

    logging.debug(f"append_yoc_header: header: {header_bin.hex():.128s}")
    logging.debug(f"append_yoc_header: outpt: {new_yoc_bin.hex():.256s}")
    if args.output:
        with open(args.output, "+wb") as fp:
            fp.write(new_yoc_bin)


def parse_args():
    parser = argparse.ArgumentParser(description="append yoc.bin header tool")

    parser.add_argument(
        "-v",
        "--verbose",
        help="Increase output verbosity",
        action="store_const",
        const=logging.DEBUG,
        default=logging.INFO,
    )

    subparsers = parser.add_subparsers(dest="subcmd", help="Sub-command help")
    pr_gen = subparsers.add_parser("appendHeader", help="Append Yoc.bin Header")

    def auto_int(x):
        return int(x, 0)

    pr_gen.add_argument("--BLCP_2ND_RUNADDR", type=auto_int)
    pr_gen.add_argument("--BLCP_2ND_COMP_TYPE", type=str, choices=["orig", "lzma", "lz4", ""])
    pr_gen.add_argument("--BLCP_2ND_COMP_ADDR", type=auto_int)
    pr_gen.add_argument("input", type=str, help="Input filename")
    pr_gen.add_argument("output", type=str, help="Output filename")

    pr_gen.set_defaults(func=append_yoc_header)

    if argcomplete:
        argcomplete.autocomplete(parser)

    args = parser.parse_args()
    init_logging(stdout_level=args.verbose)
    logging.info("PROG: %s", parser.prog)

    if not args.subcmd:
        parser.print_help()
        raise SystemExit(1)

    for a, v in sorted(vars(args).items()):
        logging.debug("  %s=%r", a, v)

    return args


def main():
    args = parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

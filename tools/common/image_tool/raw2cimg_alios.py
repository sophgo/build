#!/usr/bin/python3
# -*- coding: utf-8 -*-
import logging
import argparse
import os
from array import array
import binascii
from XmlParser import XmlParser
from tempfile import TemporaryDirectory
import shutil

MAX_LOAD_SIZE = 16 * 1024 * 1024
CHUNK_TYPE_DONT_CARE = 0
CHUNK_TYPE_CRC_CHECK = 1
FORMAT = "%(levelname)s: %(message)s"
logging.basicConfig(level=logging.INFO, format=FORMAT)


def parse_Args():
    parser = argparse.ArgumentParser(description="Create CVITEK device image")
    parser.add_argument(
        "file_path",
        metavar="file_path",
        type=str,
        help="the file you want to pack with cvitek image header",
    )
    parser.add_argument(
        "output_dir",
        metavar="output_folder_path",
        type=str,
        help="the folder path to install dir inclued fip,rootfs and kernel",
    )
    parser.add_argument("xml", help="path to partition xml")

    parser.add_argument(
        "PackYocTool",
        metavar="PackYocTool",
        type=str,
    )

    parser.add_argument(
        "-v", "--verbose", help="increase output verbosity", action="store_true"
    )
    args = parser.parse_args()
    if args.verbose:
        logging.debug("Enable more verbose output")
        logging.getLogger().setLevel(level=logging.DEBUG)

    return args


class ImagerBuilder(object):
    def __init__(self, storage: int, output_path):
        self.storage = storage
        self.output_path = output_path

def main():
    args = parse_Args()
    xmlParser = XmlParser(args.xml)
    install_dir = os.path.dirname(args.file_path)
    parts = xmlParser.parse(install_dir)
    storage = xmlParser.getStorage()

    for p in parts:
        # Since xml parser will parse with abspath and the user input path can
        # be relative path, use file name to check.
        if os.path.basename(args.file_path) == p["file_name"]:
            if (
                storage != "emmc"
                and storage != "spinor"
                and p["file_size"] > p["part_size"] - 128 * 1024
                and p["mountpoint"]
                and p["mountpoint"] != ""
            ):
                logging.error(
                    "Imaege is too big, it will cause mount partition failed!!"
                )
                raise ValueError

            magic = 0x474d4943  # "CIMG"
            version = 0x12345678
            chunk_crc_offset = 0x0
            chunk_crc_size = 0x1000
            out_path = os.path.join(args.output_dir, p["file_name"])
            cmd = "{} {:04X} {:04X} {:04X} {:04X} {:04X} {:04X} {} {}".format(args.PackYocTool, magic, version, chunk_crc_offset, chunk_crc_size, p["offset"], p["part_size"], args.file_path, out_path)
            logging.info(cmd)
            os.system(cmd)

            logging.info("Packing %s done!" % (p["file_name"]))
            


if __name__ == "__main__":
    main()

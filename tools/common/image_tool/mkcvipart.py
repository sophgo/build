#!/usr/bin/python
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import sys
from XmlParser import XmlParser

FORMAT = "%(levelname)s: %(message)s"
logging.basicConfig(level=logging.INFO, format=FORMAT)


def parse_args():
    parser = argparse.ArgumentParser(description="Create cvipart.h and fw_env.config")
    parser.add_argument("xml", help="path to partition xml")
    parser.add_argument("output", help="output folder")
    parser.add_argument(
        "--fw_env",
        help="create fw_env.config with the parameter the script will create cvipart.h for u-boot",
        action="store_true",
    )
    parser.add_argument(
        "--block_size",
        help="set block size for spinand, default is 128KB",
        default=128 * 1024,
    )

    parser.add_argument(
        "-v", "--verbose", help="increase output verbosity", action="store_true"
    )
    args = parser.parse_args()
    if args.verbose:
        logging.debug("Enable more verbose output")
        logging.getLogger().setLevel(level=logging.DEBUG)

    return args


def gen_cvipart_h(output, parser):
    logging.info("generating cvipart.h")
    parts = parser.parse()
    with open(os.path.join(output, "cvipart.h"), "w") as of:
        of.write("/* this file should be generated by mkcvipart.py,")
        of.write("please do not modify this file manually*/\n\n")
        of.write("#ifndef CVIPART_H\n")
        of.write("#define CVIPART_H\n")
        env_exist = True
        env_bak = False

        # Generate ENV_OFFSET
        if "ENV" in parser.parts:
            label = "ENV"
        elif "U-BOOT ENV" in parser.parts:
            label = "U-BOOT ENV"
        else:
            # If no ENV or U-BOOT ENV has been set in partition.xml, we assume
            # there is no env support
            of.write("#ifndef CONFIG_ENV_IS_NOWHERE\n#define CONFIG_ENV_IS_NOWHERE\n#endif\n")
            of.write("#define CONFIG_ENV_SIZE 0x20000\n")
            env_exist = False

        if env_exist and "ENV_BAK" in parser.parts:
            env_bak = True

        LBA_SIZE = 1
        if parser.getStorage() == "emmc":
            if env_exist:
                of.write("#define CONFIG_ENV_IS_IN_MMC\n")
                of.write("#define CONFIG_ENV_SECT_SIZE  0x40000\n")
                of.write("#define CONFIG_SYS_MMC_ENV_DEV 0\n")
                of.write("#define CONFIG_SYS_MMC_ENV_PART 0\n")

            # Generintg BLKDEV
            of.write("#define PART_LAYOUT    ")
            of.write("\"blkdevparts=mmcblk0:")
            for i, p in enumerate(parts):
                if p["part_size"] != sys.maxsize:
                    part_size = str(int(p["part_size"] / 1024)) + "K"
                else:
                    part_size = "-"
                if part_size == "-" or i == len(parts) - 1:
                    comma = ";"
                else:
                    comma = ","
                of.write("%s(%s)%s" % (part_size, p["label"], comma))
            of.write("mmcblk0boot0:1M(fip),1M(fip_bak);\"")
            of.write("\n")

            for i, p in enumerate(parts):
                if p["label"] == "ROOTFS":
                    of.write('#define ROOTFS_DEV "/dev/mmcblk0p%d"\n' % (i + 1))

        elif parser.getStorage() == "spinand":
            if env_exist:
                of.write("#define CONFIG_ENV_IS_IN_NAND\n")
                of.write("#define CONFIG_ENV_SECT_SIZE  0x40000\n")
            # Generintg MTDPART
            of.write("#define PART_LAYOUT    ")
            of.write('"mtdparts=cvsnfc:')
            for i, p in enumerate(parts):
                if p["part_size"] != sys.maxsize:
                    part_size = str(int(p["part_size"] / 1024)) + "K"
                else:
                    part_size = "-"
                if part_size == "-" or i == len(parts) - 1:
                    comma = "\"\n"
                else:
                    comma = ","
                of.write("%s(%s)%s" % (part_size, p["label"], comma))

        elif parser.getStorage() == "spinor":
            if env_exist:
                of.write("#define CONFIG_ENV_IS_IN_SPI_FLASH\n")
                of.write("#define CONFIG_ENV_SECT_SIZE  0x10000\n")
            # Generintg MTDPART
            of.write("#define PART_LAYOUT    ")
            of.write('"mtdparts=57000000.cvi-spif:')
            for i, p in enumerate(parts):
                if p["part_size"] != sys.maxsize:
                    part_size = str(int(p["part_size"] / 1024)) + "K"
                else:
                    part_size = "-"
                if part_size == "-" or i == len(parts) - 1:
                    comma = '"\n'
                else:
                    comma = ","
                of.write("%s(%s)%s" % (part_size, p["label"], comma))

            for i, p in enumerate(parts):
                if p["label"] == "ROOTFS":
                    of.write('#define ROOTFS_DEV "/dev/mtdblock%d"\n' % i)
                    break

        elif parser.getStorage() == "none":
            of.write('#define PART_LAYOUT ""\n')
            of.write('#define ROOTFS_DEV ""\n')
            of.write('#define PARTS_OFFSET ""\n')

        if env_exist:
            of.write(
                "#define CONFIG_ENV_OFFSET 0x%X\n"
                % (parser.parts[label]["offset"])
            )
            if env_bak:
                of.write(
                    "#define CONFIG_ENV_OFFSET_REDUND 0x%X\n"
                    % (parser.parts["ENV_BAK"]["offset"] * LBA_SIZE)
                )
                of.write("#define CONFIG_SYS_REDUNDAND_ENVIRONMENT\n")
            of.write(
                "#define CONFIG_ENV_SIZE 0x%X\n" % parser.parts[label]["part_size"]
            )

        # Generintg PART_ENV
        if parser.getStorage() == "emmc":
            LBA_SIZE = 512

        if parser.getStorage() != "none":
            of.write("#define PARTS_OFFSET \\\n")
            for i, p in enumerate(parts):
                of.write('"%s_PART_OFFSET=0x%x\\0" \\\n' % (p["label"], int(p["offset"] / LBA_SIZE)))
                if i == len(parts) - 1:
                    of.write(
                        '"%s_PART_SIZE=0x%x\\0"\n'
                        % (p["label"], int(p["part_size"] / LBA_SIZE))
                    )
                else:
                    of.write(
                        '"%s_PART_SIZE=0x%x\\0" \\\n'
                        % (p["label"], int(p["part_size"] / LBA_SIZE))
                    )

        of.write("#endif")
        logging.info("Done!")


def gen_fw_config(output, parser, block_size=128 * 1024):
    logging.info("generating fw_env.config")
    parts = parser.parse()
    part_index = -1
    with open(os.path.join(output, "fw_env.config"), "w") as of:
        for i in range(len(parts)):
            if parts[i]["label"] == "ENV" or parts[i]["label"] == "U-BOOT ENV" or parts[i]["label"] == "ENV_BAK":
                part_index = i
                if parser.storage == "spinand":
                    of.write(
                        "/dev/mtd%d 0x%x 0x%x 0x%x\n"
                        % (part_index, 0, parts[part_index]["part_size"], block_size)
                    )
                elif parser.storage == "emmc":
                    of.write(
                        "/dev/mmcblk0 0x%x 0x%x\n"
                        % ((parts[part_index]["offset"]), parts[part_index]["part_size"])
                    )
                elif parser.storage == "spinor":
                    of.write(
                        "/dev/mtd%d 0x%x 0x%x 0x%x\n"
                        % (part_index, 0, parts[part_index]["part_size"], 64 * 1024)
                    )
        if part_index == -1:
            logging.info(
                "There is no ENV or U-BOOT ENV partition in partition.xml ignore generating fw_env.config"
            )
            if os.path.isfile("fw_env.config"):
                os.remove("fw_env.config")
            return


def main():
    args = parse_args()
    parser = XmlParser(args.xml)
    if not args.fw_env:
        gen_cvipart_h(args.output, parser)
    else:
        gen_fw_config(args.output, parser, args.block_size)


if __name__ == "__main__":
    main()

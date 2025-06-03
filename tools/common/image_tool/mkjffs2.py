#!/usr/bin/python3
# -*- coding: utf-8 -*-
import logging
import argparse
from os import path, getcwd
from XmlParser import XmlParser
import subprocess

FORMAT = "%(levelname)s: %(message)s"
logging.basicConfig(level=logging.INFO, format=FORMAT)


def parse_Args():
    parser = argparse.ArgumentParser(description="create image for jffs2")

    parser.add_argument(
        "tool_path",
        metavar="tool_path",
        type=str,
        help="the path of mkfs.jffs2",
    )

    parser.add_argument(
        "doc_path",
        metavar="doc_path",
        type=str,
        help="the document you want to pack for jffs2 image",
    )
    parser.add_argument(
        "erase_size",
        metavar="erase_size",
        type=int,
        help="the erase size for jffs2",
    )

    parser.add_argument(
        "output_file",
        metavar="output_file",
        type=str,
        help="the output filename",
    )
    parser.add_argument("xml", help="path to partition xml")
    parser.add_argument(
        "-v", "--verbose", help="increase output verbosity", action="store_true"
    )
    args = parser.parse_args()
    if args.verbose:
        logging.debug("Enable more verbose output")
        logging.getLogger().setLevel(level=logging.DEBUG)

    return args


def log_subprocess_output(pipe):
    for line in iter(pipe.readline, b""):  # b'\n'-separated lines
        logging.debug("got line from subprocess: %r", line)


def main():
    args = parse_Args()
    xmlParser = XmlParser(args.xml)
    install_dir = path.dirname(args.output_file)
    parts = xmlParser.parse(install_dir)
    storage = xmlParser.getStorage()
    verbose = args.verbose

    if storage != "spinor":
        return 0

    logging.debug("tools path %s " % args.tool_path)
    logging.debug("document path %s " % args.doc_path)
    logging.debug("erase size %s " % args.erase_size)
    logging.debug("output dir %s " % args.output_file)

    for p in parts:
        # Since xml parser will parse with abspath and the user input path can
        # be relative path, use file name to check.
        if path.basename(args.output_file) == p["file_name"]:
            cmd = "%s -d %s -l -e 0x%x --pad=0x%x --squash -o %s" % (
                args.tool_path,
                args.doc_path,
                args.erase_size,
                p["part_size"],
                args.output_file,
            )
            logging.debug("cmd: %s " % cmd)
            try:
                process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    cwd=getcwd(),
                    shell=True,
                )
            except Exception:
                return -1

            if verbose:
                with process.stdout:
                    log_subprocess_output(process.stdout)
            ret = process.wait()
            return ret


if __name__ == "__main__":
    main()

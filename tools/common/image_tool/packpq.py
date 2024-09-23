#!/usr/bin/python3
# -*- coding: utf-8 -*-
import logging
import argparse
import os
import sys
from array import array
import binascii
from tempfile import TemporaryDirectory
import shutil


MAX_LOAD_SIZE = 100 * 1024 * 1024
CHUNK_TYPE_DONT_CARE = 0
CHUNK_TYPE_CRC_CHECK = 1
FORMAT = '%(levelname)s: %(message)s'
logging.basicConfig(level=logging.INFO, format=FORMAT)


def parse_Args():
    parser = argparse.ArgumentParser(description='Pack file into one bin')
    parser.add_argument('-i','--input',action='append',nargs=1,required=True,
        metavar=('input'),help='help:')
    parser.add_argument(
        '-o',
        '--output_file',
        metavar='output_file',
        required=True,
        type=str,
        help='the output file')
    parser.add_argument(
        '-b',
        '--bootloader_file',
        metavar='bootloader_file',
        required=False,
        type=str,
        help='bootloader file')
    parser.add_argument("-v",
                        "--verbose",
                        help="increase output verbosity",
                        action="store_true")
    args = parser.parse_args()
    if args.verbose:
        logging.debug("Enable more verbose output")
        logging.getLogger().setLevel(level=logging.DEBUG)

    return args


class CImagerBuilder(object):
    def __init__(self, output_path):
        self.output_path = output_path

    def packHeader(self, part):
        """
        Header format total 64 bytes
        4 Bytes: Magic
        4 Bytes: Version
        4 Bytes: Chunk header size
        4 Bytes: Total chunks
        4 Bytes: File size
        32 Bytes: Extra Flags
        12 Bytes: Reserved
        """
        with open(part["file_path"], "rb") as fd:
            magic = fd.read(4)
            if magic == b"CIMG":
                logging.debug("%s has been packed, skip it!" % part["file_name"])
                return
            fd.seek(0)
            Magic = array("b", [ord(c) for c in "CIMG"])
            Version = array("I", [1])
            chunk_header_sz = 64
            Chunk_sz = array("I", [chunk_header_sz])
            chunk_counts = int(part["file_size"] / MAX_LOAD_SIZE) + 1
            Totak_chunk = array("I", [chunk_counts])
            File_sz = array("I", [part["file_size"] + (chunk_counts * chunk_header_sz)])
            label = part["label"]
            Extra_flags = array("B", [ord(c) for c in label])
            for _ in range(len(label), 32):
                Extra_flags.append(ord("\0"))
            if os.path.exists(self.output_path):
                os.remove(self.output_path)
            img = open(os.path.join(self.output_path, part["file_name"]), "wb")
            # Write Header
            for h in [Magic, Version, Chunk_sz, Totak_chunk, File_sz, Extra_flags]:
                h.tofile(img)
            img.seek(64)
            total_size = part["file_size"]
            offset = part["offset"]
            while total_size:
                chunk_sz = min(MAX_LOAD_SIZE, total_size)
                chunk = fd.read(chunk_sz)
                crc = binascii.crc32(chunk) & 0xFFFFFFFF
                chunk_header = self._getChunkHeader(chunk_sz, offset, crc)
                img.write(chunk_header)
                img.write(chunk)
                total_size -= chunk_sz
                offset += chunk_sz
            img.close()

    def _getChunkHeader(self, size: int, offset: int, crc32: int):
        """
        Header format total 64 bytes
        4 Bytes: Chunk Type
        4 Bytes: Chunk data size
        4 Bytes: Program offset
        4 Bytes: Crc32 checksum
        """
        logging.info("size:%x, offset:%x,crc:%x" % (size, offset, crc32))
        Chunk = array(
            "I",
            [
                CHUNK_TYPE_CRC_CHECK,
                size,
                offset,
                crc32,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
        )
        return Chunk

def main():
    args = parse_Args()
    #Version = args.ver
    input_arrray = args.input
    #print ("Version:", Version)
    #print ("PKG Model:", args.model)
    # print (input_arrray)
    PartNum = 0
    PartOffset = array('I', [0 for _ in range(10)])
    with open(args.output_file, 'wb') as outfile:
        """
        Header format total 64 bytes
        4 Bytes: Magic number
        4 Bytes: CRC
        4 Bytes: Header Ver
        4 Bytes: Package length
        4 Bytes: reserved
        4 Bytes: Total partition number in package
        4x10 Bytes: per file length (Max num:10)
        """
        # magic number 0xdeadbeef
        HeaderPartI = array('I', [3735928559, 0, 1, 0, 0])
        #HeaderPartII = array('B', [ord(c) for c in args.model])
        #for _ in range(len(args.model), 64):
        #    HeaderPartII.append(ord('\0'))
        #HeaderPartIII = array('B', [ord(c) for c in Version])
        #for _ in range(len(Version), 64):
        #    HeaderPartIII.append(ord('\0'))
        #HeaderPartIV = array('B', [0 for _ in range(1024)])
        HeaderPartV = array('I', [0])
        HeaderPartVI = array('I', [0 for _ in range(10)])
        # Write Header
        for h in [
                HeaderPartI, HeaderPartV, HeaderPartVI
        ]:
            h.tofile(outfile)
        HeaderSize = outfile.tell()
        #PartOffset[0] = HeaderSize
        # print (HeaderSize)
        ReadSize = HeaderSize
        if args.bootloader_file is not None:
            tmp = TemporaryDirectory()
            # print ("fip.bin has been given (path is %s)" % args.bootloader_file )
            imgBuilder = CImagerBuilder(tmp.name)
            p = {
            "offset": 0,
            "file_path": args.bootloader_file,
            "file_size": int(os.stat(args.bootloader_file).st_size),
            "file_name": "fip.img",
            "label" : "fip",
            }
            imgBuilder.packHeader(p)
            tmp_path = os.path.join(tmp.name, p["file_name"])
            input_arrray.insert(0, [tmp_path])
            # print ( input_arrray )

        for fname in input_arrray:
            with open(fname[0], 'rb') as infile:
                #PartOffset[PartNum] = ReadSize
                #magic = infile.read(4)
                #if magic != b"CIMG":
                #    print ('Error! File format un-recognized!')
                #    logging.debug("%s MUST be CIMG, return error" %
                #                fname[0])
                #    sys.exit(1)
                infile.seek(0)
                infile_buf = infile.read()
                outfile.write(infile_buf)
                # print(fname[0] + ':' )
                # print(len(infile_buf))
                ReadSize += len(infile_buf)
                PartOffset[PartNum] = len(infile_buf)
                #ReadSize += PartOffset[PartNum]
                PartNum += 1
        outfile.seek(12)
        outfile.write(ReadSize.to_bytes(4, byteorder="little", signed=False))
        outfile.seek(20)
        outfile.write(PartNum.to_bytes(4, byteorder="little", signed=False))
        PartOffset.tofile(outfile)
        # print (PartNum)
        print (PartOffset)
        outfile.close

    with open(args.output_file, "r+b") as fd:
        fd.seek(8)
        chunk = fd.read()
        crc = binascii.crc32(chunk) & 0xFFFFFFFF
        fd.seek(4)
        fd.write(crc.to_bytes(4, byteorder="little", signed=False))
        fd.close

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import sys

def reverse_4byte_blocks(data, bytes_per_line):
    data = data.ljust((bytes_per_line // 4) * 4, b'\0')
    blocks = [data[i:i+4] for i in range(0, len(data), 4)]
    blocks.reverse()
    return b''.join(blocks)

def bin_to_hex_file(bin_file, hex_file, bytes_per_line):
    with open(bin_file, 'rb') as f_in:
        with open(hex_file, 'w') as f_out:
            while True:
                data = f_in.read(bytes_per_line)
                if not data:
                    break
                data = reverse_4byte_blocks(data, bytes_per_line)
                hex_line = ""
                for i in range(0, len(data), 4):
                    chunk = data[i:i+4]
                    value = int.from_bytes(chunk, byteorder='little')
                    hex_line += f"{value:08x}"
                f_out.write(f"{hex_line}\n")

def split_file(input_file, output_file1, output_file2):
    BLOCK_SIZE = 32
    FIRST_PART = 20
    SECOND_PART = 12

    bin_file1 = output_file1 + ".bin"
    bin_file2 = output_file2 + ".bin"
    
    with open(input_file, 'rb') as f_in:
        with open(bin_file1, 'wb') as f_out1:
            with open(bin_file2, 'wb') as f_out2:
                while True:
                    block = f_in.read(BLOCK_SIZE)
                    if not block:
                        break
                    f_out1.write(block[:FIRST_PART])
                    f_out2.write(block[FIRST_PART:])

    bin_to_hex_file(bin_file1, output_file1, FIRST_PART)
    bin_to_hex_file(bin_file2, output_file2, SECOND_PART)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 script.py <input_file> <output_file1> <output_file2>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file1 = sys.argv[2]
    output_file2 = sys.argv[3]

    split_file(input_file, output_file1, output_file2)
import os
import sys
import time

ddr_start_addr = 0x80000000
start_num = 0
end_num = 0
start_addr = 0
end_addr = 0

# need to be confirmed
# 1.burst_length(interleave)
# 2.data line
# 3.flow review completely


def split_file(file_name):
    global end_num, start_num

    start_num = int(offset_addr / 2)
    end_num = int(offset_addr / 2)

    axi_file = open(file_name, 'r')
    lines = axi_file.readlines()
    for line in lines:
        end_num += 1

    axi_file.close()


def gen_script_file():
    start_addr = start_num
    end_addr = end_num - 1

    load_file = open('{0}'.format(load_tcl), 'w')

    load_line_0 = 'memory -load %readmemh {tb_mars3.u_chip_top.chip_core.A_ddr_pr_wrap.A_ddr_subsystem.'
    load_line_1 = 'u_synopsys_mc_asic.dfiphy_wrapper.DDR_0.memcore} '
    load_line_2 = '-file ../c_build/ddr/{0}  -start {1} -end {2}'.format(txt_file, hex(start_addr), hex(end_addr))
    load_file.writelines(load_line_0 + load_line_1 + load_line_2 + "\n")

    load_file.close()

    dump_file = open('{0}'.format(dump_tcl), 'w')

    dump_line_0 = 'memory -dump %readmemh {tb_mars3.u_chip_top.chip_core.A_ddr_pr_wrap.A_ddr_subsystem.'
    dump_line_1 = 'u_synopsys_mc_asic.dfiphy_wrapper.DDR_0.memcore} '
    dump_line_2 = '-file ../c_build/ddr/{0}  -start {1} -end {2}'.format(txt_file, hex(start_addr), hex(end_addr))
    dump_file.writelines(dump_line_0 + dump_line_1 + dump_line_2 + "\n")

    dump_file.close()


if __name__ == '__main__':

    start = time.time()

    if (len(sys.argv) != 3):
        print("Input should be python {0} source_file_path offset_addr".format(__file__.split("/")[-1]))
        exit(-1)

    source_file_path = sys.argv[1]
    source_file = sys.argv[1].split('/')[-1]
    source_name = source_file.split('.')[0]
    offset_addr = int(sys.argv[2], 16) - ddr_start_addr

    txt_file = source_name + ".text"

    load_tcl = 'load_' + source_name + '.tcl'
    dump_tcl = 'dump_' + source_name + '.tcl'

    print("source file: " + source_file)
    print("txt_file: " + txt_file)
    print("offset addr: {}".format(hex(offset_addr)))
    print("load_tcl: " + load_tcl)
    print("dump_tcl: " + dump_tcl)

    cmd = 'hexdump -v -e \'1/2 "%04x\n"\' {0} > {1}'.format(source_file_path, txt_file)
    os.system(cmd)

    file = txt_file

    split_file(file)

    gen_script_file()

    end = time.time()
    print('use time is {0} s'.format((end - start)))

import os
import sys
import time
import shutil
import multiprocessing

number = 8   # sys0~7 -- ch0~1
sram_width = 2        # x16
interleave = 256      # 256B
linenum_in_cycle = int(interleave / sram_width)

ddr_start_addr = 0x1000000000       #根据最终DRAM空间的base address再做修改
start_num = [0x2000000]*number    
end_num = [0]*number
end_num_addr = [0]*number
start_addr = [0]*number
end_addr = [0]*number

#sys_list = [0, 2, 1, 3]
file_list = [0, 2, 4, 6, 1, 3, 5, 7]


def mkdir_folder():
    if os.path.exists(temp_folder):
        shutil.rmtree(temp_folder)

    os.makedirs(temp_folder)

    if os.path.exists(load_folder):
        shutil.rmtree(load_folder)

    os.makedirs(load_folder)
    
    if not os.path.exists(r'script_real_ddr'):
        os.makedirs('script_real_ddr')


def pxp2ddrc(file_32k):

    # unordered_map = [5, 0, 1, 2, 6, 3, 4]
    unordered_map = [1, 2, 3, 5, 6, 4, 0]
    # unordered_map = [1, 2, 3, 5, 6, 4, 0]

    #every PXP 32KB interleave with 256Btye     
    data_length = len(file_32k) #data_length = 16384
    chunk_size = 128
    chunks = [file_32k[i:i + chunk_size] for i in range(0, data_length, chunk_size)] 
    # print("chunks = {0}".format(len(chunks))) #len(chunks) = 128

    # print("256Byte num {0}".format(len(chunks)))
    result0 = []
    result1 = []
    result0.append(chunks[0])
    # flag = 0
    
    for i in range(1, 128):
        bit0 = i & 0x01
        bit1 = (i & 0x02) >> 1
        bit2 = (i & 0x04) >> 2
        bit3 = (i & 0x08) >> 3
        bit4 = (i & 0x10) >> 4
        bit5 = (i & 0x20) >> 5
        bit6 = (i & 0x40) >> 6
        index = (bit0 << unordered_map[0]) | (bit1 << unordered_map[1]) | (bit2 << unordered_map[2]) | (bit3 << unordered_map[3]) | (bit4 << unordered_map[4]) | (bit5 << unordered_map[5]) | (bit6 << unordered_map[6])
        # if(flag == 0):
            # print("index ===== {0}".format(index))
        
        result0.append(chunks[index])
    # flag += 1
    # print("\n\n\n")
    for sub in result0:
        result1.extend(sub)

    # print("result1 = {0}".format(result1)) 

    return result1


def split_file(file_name):

    line_counter = 0                    # 0~64      4B*64=256B
    addr = offset_addr - interleave     # 256B

    axi_file = open(file_name,'r')
    lines = axi_file.readlines()
    for line in lines:
        if line_counter == 0:
            address = addr + interleave
            addr = address
            #sys_num = sys_list[(address >> 9) & 0x3]
            #chl_num = (address >> 8) & 0x1
            #file_counter = (sys_num << 1) | chl_num
            file_counter = file_list[(address >> 8) & 0x7]#logical channel to physical channel
            file_num = address >> 11
            temp_file = open('{0}/temp{1}_{2}.h'.format(temp_folder, file_counter, file_num), 'a')
            if (file_num + 1) > end_num[file_counter]:
                end_num[file_counter] = file_num + 1
                end_num_addr[file_counter] = file_num + 1
            if file_num < start_num[file_counter]:
                start_num[file_counter] = file_num

        temp_file.writelines(line)

        line_counter = line_counter + 1
        
        if line_counter == linenum_in_cycle:
            temp_file.close()
            line_counter = 0
    
    axi_file.close()


def result_output(i):

    output_file_0 = source_name + '_sys{0}_ch{1}_r0_m0.h'.format((i >> 1), (i & 0x1))
    ddr_file_0 = open('{0}/{1}'.format(load_folder, output_file_0),'w')
    ddr_file_0.close()
    output_file_1 = source_name + '_sys{0}_ch{1}_r0_m1.h'.format((i >> 1), (i & 0x1))
    ddr_file_1 = open('{0}/{1}'.format(load_folder, output_file_1),'w')
    ddr_file_1.close()

    output_file_2 = source_name + '_sys{0}_ch{1}_r1_m0.h'.format((i >> 1), (i & 0x1))
    ddr_file_2 = open('{0}/{1}'.format(load_folder, output_file_2),'w')
    ddr_file_2.close()
    output_file_3 = source_name + '_sys{0}_ch{1}_r1_m1.h'.format((i >> 1), (i & 0x1))
    ddr_file_3 = open('{0}/{1}'.format(load_folder, output_file_3),'w')
    ddr_file_3.close()
    
    for p in range(start_num[i], end_num[i], 128):
        if (p * 0x800) < 0x800000000:
            if (p * 0x800) < 0x400000000:
                output_file_0 = source_name + '_sys{0}_ch{1}_r0_m0.h'.format((i >> 1), (i & 0x1))
                ddr_file_0 = open('{0}/{1}'.format(load_folder, output_file_0),'a')
                file_32k_in = []
                for q in range(0, 128):
                    line_num = 0
                    temp_file_name = '{0}/temp{1}_{2}.h'.format(temp_folder, i, p+q)
                    if os.path.exists(temp_file_name):
                        temp_file = open(temp_file_name, 'r')
                        lines = temp_file.readlines()
                        for line in lines:
                            stripped_line = line.strip()
                            file_32k_in.append(stripped_line)
                            line_num = line_num + 1
                        if line_num < linenum_in_cycle:
                            for k in range(line_num, linenum_in_cycle):
                                file_32k_in.append("0000")
                        temp_file.close()
                    else:
                        end_num_addr[i] += 1
                        for k in range(0, linenum_in_cycle):
                            file_32k_in.append("0000")

                # print("file_32k_in = {0}".format(len(file_32k_in)))
 
                file_32k_out = []
                file_32k_out = pxp2ddrc(file_32k_in)
                for line in file_32k_out:
                    # print("line = {0}".format(line)) 
                    ddr_file_0.writelines(str(line)+'\n')
                ddr_file_0.close()
            else:
                output_file_1 = source_name + '_sys{0}_ch{1}_r0_m1.h'.format((i >> 1), (i & 0x1))
                ddr_file_1 = open('{0}/{1}'.format(load_folder, output_file_1),'a')
                file_32k_in = []
                for q in range(0, 128):
                    line_num = 0
                    temp_file_name = '{0}/temp{1}_{2}.h'.format(temp_folder, i, p+q)
                    if os.path.exists(temp_file_name):
                        temp_file = open(temp_file_name, 'r')
                        lines = temp_file.readlines()
                        for line in lines:
                            file_32k_in.append(line)
                            line_num = line_num + 1
                        if line_num < linenum_in_cycle:
                            for k in range(line_num, linenum_in_cycle):
                                file_32k_in.append("0000")
                        temp_file.close()
                    else:
                        end_num_addr[i] += 1
                        for k in range(0, linenum_in_cycle):
                            file_32k_in.append("0000")
                        
                file_32k_out = []
                file_32k_out = pxp2ddrc(file_32k_in)
                for line in file_32k_out:
                    ddr_file_1.writelines(str(line))
                ddr_file_1.close()
        else:
            if (p * 0x800) < 0xc00000000:
                output_file_2 = source_name + '_sys{0}_ch{1}_r1_m0.h'.format((i >> 1), (i & 0x1))
                ddr_file_2 = open('{0}/{1}'.format(load_folder, output_file_2),'a')
                file_32k_in = []
                for q in range(0, 128):
                    line_num = 0
                    temp_file_name = '{0}/temp{1}_{2}.h'.format(temp_folder, i, p+q)
                    if os.path.exists(temp_file_name):
                        temp_file = open(temp_file_name, 'r')
                        lines = temp_file.readlines()
                        for line in lines:
                            file_32k_in.append(line)
                            line_num = line_num + 1
                        if line_num < linenum_in_cycle:
                            for k in range(line_num, linenum_in_cycle):
                                file_32k_in.append("0000")
                        temp_file.close()
                    else:
                        end_num_addr[i] += 1
                        for k in range(0, linenum_in_cycle):
                            file_32k_in.append("0000")
                        
                file_32k_out = []
                file_32k_out = pxp2ddrc(file_32k_in)
                for line in file_32k_out:
                    ddr_file_2.writelines(str(line))
                ddr_file_2.close()
            else:
                output_file_3 = source_name + '_sys{0}_ch{1}_r1_m1.h'.format((i >> 1), (i & 0x1))
                ddr_file_3 = open('{0}/{1}'.format(load_folder, output_file_3),'a')
                file_32k_in = []
                for q in range(0, 128):
                    line_num = 0
                    temp_file_name = '{0}/temp{1}_{2}.h'.format(temp_folder, i, p+q)
                    if os.path.exists(temp_file_name):
                        temp_file = open(temp_file_name, 'r')
                        lines = temp_file.readlines()
                        for line in lines:
                            file_32k_in.append(line)
                            line_num = line_num + 1
                        if line_num < linenum_in_cycle:
                            for k in range(line_num, linenum_in_cycle):
                                file_32k_in.append("0000")
                        temp_file.close()
                    else:
                        end_num_addr[i] += 1
                        for k in range(0, linenum_in_cycle):
                            file_32k_in.append("0000")
                        
                file_32k_out = []
                file_32k_out = pxp2ddrc(file_32k_in)
                for line in file_32k_out:
                    ddr_file_3.writelines(str(line))
                ddr_file_3.close()

def gen_script_file():
    
    for i in range(0, number):
        if start_num[i] != 0x2000000:
            start_addr[i] = start_num[i]*linenum_in_cycle
            print("start_num{} = {:#x}".format(i, start_addr[i]))
            end_addr[i] = end_num_addr[i]*linenum_in_cycle - 1
            print("end_num{} = {:#x}".format(i, end_addr[i]))

        if (end_num_addr[i] * 0x800) < 0x800000000:
            #in rank0
            if (end_num_addr[i] * 0x800) < 0x400000000:
                load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')
            
                load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore0}} '.format((i >> 1), (i & 0x1))
                load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]), hex(end_addr[i]))
                load_file.writelines(load_line_0 + load_line_1 + "\n")
                dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore0}} '.format((i >> 1), (i & 0x1))
                dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]), hex(end_addr[i]))
                dump_file.writelines(dump_line_0 + dump_line_1 + "\n")

                load_file.close()
                dump_file.close()
            elif (start_num[i] * 0x800) >= 0x400000000:
                load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')
            
                load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x40000000), hex(end_addr[i]-0x40000000))
                load_file.writelines(load_line_0 + load_line_1 + "\n")
                dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x40000000), hex(end_addr[i]-0x40000000))
                dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                
                load_file.close()
                dump_file.close()
            else:
                load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')

                load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore0}} '.format((i >> 1), (i & 0x1))
                load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]), hex(0x3fffffff))
                load_file.writelines(load_line_0 + load_line_1 + "\n")
                load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0x00000000), hex(end_addr[i]-0x40000000))
                load_file.writelines(load_line_0 + load_line_1 + "\n")

                dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore0}} '.format((i >> 1), (i & 0x1))
                dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]), hex(0x3fffffff))
                dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0x00000000), hex(end_addr[i]-0x40000000))
                dump_file.writelines(dump_line_0 + dump_line_1 + "\n")

                load_file.close()
                dump_file.close()

        elif (start_num[i] * 0x800) >= 0x800000000:
            #in rank1
            if (end_num_addr[i] * 0x800) < 0xc00000000:
                load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')
            
                load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x80000000), hex(end_addr[i]-0x80000000))
                load_file.writelines(load_line_0 + load_line_1 + "\n")
                dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x80000000), hex(end_addr[i]-0x80000000))
                dump_file.writelines(dump_line_0 + dump_line_1 + "\n")

                load_file.close()
                dump_file.close()
            elif (start_num[i] * 0x800) >= 0xc00000000:
                load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')
            
                load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore1}} '.format((i >> 1), (i & 0x1))
                load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0xc0000000), hex(end_addr[i]-0xc0000000))
                load_file.writelines(load_line_0 + load_line_1 + "\n")
                dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore1}} '.format((i >> 1), (i & 0x1))
                dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m1.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0xc0000000), hex(end_addr[i]-0xc0000000))
                dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                
                load_file.close()
                dump_file.close()
            else:
                load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')

                load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x80000000), hex(0xbfffffff-0x80000000))
                load_file.writelines(load_line_0 + load_line_1 + "\n")
                load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore1}} '.format((i >> 1), (i & 0x1))
                load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0xc0000000-0xc0000000), hex(end_addr[i]-0xc0000000))
                load_file.writelines(load_line_0 + load_line_1 + "\n")

                dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x80000000), hex(0xbfffffff-0x80000000))
                dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore1}} '.format((i >> 1), (i & 0x1))
                dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m1.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0xc0000000-0xc0000000), hex(end_addr[i]-0xc0000000))
                dump_file.writelines(dump_line_0 + dump_line_1 + "\n")

                load_file.close()
                dump_file.close()
        else:
            #in rank0 & rank1
            if (start_num[i] * 0x800) < 0x400000000:
                if (end_num_addr[i] * 0x800) < 0xc00000000:
                    load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                    dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')

                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore0}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]), hex(0x3fffffff))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")
                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0x40000000-0x40000000), hex(0x7fffffff-0x40000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")
                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0x80000000-0x80000000), hex(end_addr[i]-0x80000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")

                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore0}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]), hex(0x3fffffff))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0x40000000-0x40000000), hex(0x7fffffff-0x40000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0x80000000-0x80000000), hex(end_addr[i]-0x80000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")

                    load_file.close()
                    dump_file.close()
                else:
                    load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                    dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')

                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore0}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]), hex(0x3fffffff))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")
                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0x40000000-0x40000000), hex(0x7fffffff-0x40000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")
                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0x80000000-0x80000000), hex(0xbfffffff-0x80000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")
                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore1}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0xc0000000-0xc0000000), hex(end_addr[i]-0xc0000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")

                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore0}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]), hex(0x3fffffff))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0x40000000-0x40000000), hex(0x7fffffff-0x40000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0x80000000-0x80000000), hex(0xbfffffff-0x80000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore1}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0xc0000000-0xc0000000), hex(end_addr[i]-0xc0000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")

                    load_file.close()
                    dump_file.close()
            else:
                if (end_num_addr[i] * 0x800) < 0xc00000000:
                    load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                    dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')
                    print("case 2-1")

                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x40000000), hex(0x7fffffff-0x40000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")
                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0x80000000-0x80000000), hex(end_addr[i]-0x80000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")

                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x40000000), hex(0x7fffffff-0x40000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0x80000000-0x80000000), hex(end_addr[i]-0x80000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")

                    load_file.close()
                    dump_file.close()
                else:
                    load_file = open('script_real_ddr/{0}'.format(load_tcl), 'a')
                    dump_file = open('script_real_ddr/{0}'.format(dump_tcl), 'a')

                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x40000000), hex(0x7fffffff-0x40000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")
                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0x80000000-0x80000000), hex(0xbfffffff-0x80000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")
                    load_line_0 = 'memory -load %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore1}} '.format((i >> 1), (i & 0x1))
                    load_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m1.h  -start {4} -end {5}'.format(load_folder, source_name, (i >> 1), (i & 0x1), hex(0xc0000000-0xc0000000), hex(end_addr[i]-0xc0000000))
                    load_file.writelines(load_line_0 + load_line_1 + "\n")

                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank0.memcore1}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r0_m1.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(start_addr[i]-0x40000000), hex(0x7fffffff-0x40000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore0}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m0.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0x80000000-0x80000000), hex(0xbfffffff-0x80000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")
                    dump_line_0 = 'memory -dump %readmemh {{tb_bm1684x2.u_chip_top.chip_core.A_ddr_sys_{0}_pr_wrap.u_ddr_chip.u_dfiphy5_lpddr5_ch{1}.u_lp5_x16_rank1.memcore1}} '.format((i >> 1), (i & 0x1))
                    dump_line_1 = '-file ../c_build/{0}/{1}_sys{2}_ch{3}_r1_m1.h  -start {4} -end {5}'.format(dump_folder, source_name, (i >> 1), (i & 0x1), hex(0xc0000000-0xc0000000), hex(end_addr[i]-0xc0000000))
                    dump_file.writelines(dump_line_0 + dump_line_1 + "\n")

                    load_file.close()
                    dump_file.close()


def check_file(filename):

    index = 0
    file = open(filename,'r')
    lines = file.readlines()
    file.close()
    for line in lines:
        index += 2
    print("index == {}".format(index))

    while(index % (32*1024) != 0):
        file = open(filename,'a')
        file.writelines('0000' + '\n')
        index += 2

    file.close()
    print("index == {}".format(index))
 

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
    temp_folder = 'temp_' + source_name
    load_folder = 'load_' + source_name
    dump_folder = 'dump_' + source_name

    load_tcl = 'load_' + source_name + '.tcl'
    dump_tcl = 'dump_' + source_name + '.tcl'

    print("source file: " + source_file)
    print("txt_file: " + txt_file)
    print("offset addr: {}".format(hex(offset_addr)))
    print("temp_folder: " + temp_folder)
    print("load_folder: " + load_folder)
    print("dump_folder: " + dump_folder)
    print("load_tcl: " + load_tcl)
    print("dump_tcl: " + dump_tcl)

    # cmd = 'hexdump -v -e \'1/4 "%08x\n"\' {0} > {1}'.format(source_file_path, txt_file)
    cmd = 'hexdump -v -e \'1/2 "%04x\n"\' {0} > {1}'.format(source_file_path, txt_file)
    os.system(cmd)
    
    mkdir_folder()

    file = txt_file
    check_file(file) #ok

    split_file(file)
    # pool = multiprocessing.Pool()
    # pool.map(result_output, range(number))
    # pool.close()
    # pool.join()
    for i in range(0, 8):
        result_output(i)

    gen_script_file()

    end = time.time()
    print('use time is {0} s'.format((end - start)))


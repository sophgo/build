#!/bin/bash
#
# Usage:
#    The common functions for envsetup_soc.sh
#
# Partition generation :
# pack_backdoor -> pack (bl1/bmtest) for PLD backdoor.
#

USE_DDR=yes
#USE_DDR=yes

function build_backdoor_bmtest_file_for_ddr
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bl2(ddr init) --> bmtest(ddr)

  local ROM_BIN="${TOP_DIR}/bl1.bin"
  local BL2_BIN="${TOP_DIR}/bl2.bin"
  local BMTEST_BIN="${TOP_DIR}/bmtest.bin"
  local BMTEST_ADDR=0x80000000
  local DATA_BIN="${TOP_DIR}/data.bin"
  local DATA_ADDR=0x81000000

  pushd "$OUTPUT_DIR"
    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build/rom,c_build/sram,c_build/ddr,script}

      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ./script
      fi
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ./script
      fi

      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      dd if=${ROM_BIN} of=./workspace/bootrom_0.bin bs=64k count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_1.bin bs=64k skip=1 count=1
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_0.bin > ./c_build/rom/bootrom0.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_1.bin > ./c_build/rom/bootrom1.bin.text

      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom1}" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom1} -file ../c_build/rom/bootrom1.bin.text" >> reload_rom.tcl
      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

      if [ -e ${BL2_BIN} ];then
      echo "============================ bl2: load bl2.bin to sram offset: 256KB ============================="
      chunk_size=4096 #4KB
      input_file=${BL2_BIN}
      bl2_file_index="bl2_"
      file_size=$(stat -c %s "${BL2_BIN}")
      touch reload_sram.tcl

      # Determine if the file is aligned to 4KB
      remainder=$(expr $file_size % $chunk_size)
      if [ $remainder -eq 0 ]; then
         echo "file is aligned to $chunk_size"
      else
         padding=$(expr $chunk_size - $remainder)
         dd if=/dev/zero bs=1 count=$padding >> "$input_file" 2>/dev/null
         echo "dd $padding size to $input_file for aligned to $chunk_size"
      fi

      num_chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
      echo "num block is ${num_chunks}"
      for ((i = 0; i < num_chunks; i++)); do
        offset=$((i * chunk_size))
        output_file="./workspace/${bl2_file_index}${i}.bin"
        text_output_file="./c_build/sram/${bl2_file_index}${i}.bin.text"
        tmp_text_output_file="./c_build/sram/_${bl2_file_index}${i}.bin.text"

        # Extract the chunk
        dd if="${input_file}" of="${output_file}" bs=$chunk_size skip=$i count=1

        # Generate hexdump for the chunk
        # d256 w128
        #[127-96] [95-64] [63-32] [31-0]
        hexdump -v -e '4/4 "%08x"' -e '"\n"' "$output_file" > "$tmp_text_output_file"
        awk '{ printf "%s%s%s%s\n", substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$tmp_text_output_file" > "$text_output_file"
        rm -rf "$tmp_text_output_file"


      # 1 array 8lane 16bank 1slice
      local bank=$(expr $i % 16)
      local lane=$(expr $i / 16)
      echo "bank ${bank} lane ${lane}"
      echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_tpu.u_tpu_pwr_wrap.u_tpu.arrays_grp.gen_arrays[0]"\
".genblk1.u_array.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[$lane]"\
".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]"\
".u_lmem_bank.gen_sram_slice[0]"\
".u_ram0.u_mem_u_tpu_mem_d256w128_0.MEMORY}" >> reload_sram.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_tpu.u_tpu_pwr_wrap.u_tpu.arrays_grp.gen_arrays[0]"\
".genblk1.u_array.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[$lane]"\
".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]"\
".u_lmem_bank.gen_sram_slice[0]"\
".u_ram0.u_mem_u_tpu_mem_d256w128_0.MEMORY} -file ../c_build/sram/${bl2_file_index}${i}.bin.text" >> reload_sram.tcl

      done

      echo "bl2 end"
      else
        echo "${BL2_BIN} not found!!!"
      fi

      if [ -e ${BMTEST_BIN} ];then
      echo "============================ bmtest: load bmtest.bin to ddr offset: ${BMTEST_ADDR} ============================="

      local bl3_file_name="${BMTEST_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv184x/pld_tools/
      python3 real_ddr_axi2dram.py ${BMTEST_BIN} ${BMTEST_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "${BMTEST_BIN} not found!!!"
      fi

      if [ -e ${DATA_BIN} ];then
      echo "============================ data: load data.bin to ddr offset: ${DATA_ADDR} ============================="
      
      local data_file_name="${DATA_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv184x/pld_tools/
      python3 real_ddr_axi2dram.py ${DATA_BIN} ${DATA_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "${DATA_BIN} not found!!!"
      fi

      rm -rf ./workspace
      mv *.tcl ./script
    popd
    tar -zcvf pld_backdoor_bmtest.tgz backdoor/{c_build,script}
    rm -rf backdoor
    md5sum pld_backdoor_bmtest.tgz
  popd
)}

function build_backdoor_bmtest_file
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bmtest

  local ROM_BIN="${TOP_DIR}/bl1.bin"
  local BMTEST_BIN="${TOP_DIR}/bmtest.bin"

  pushd "$OUTPUT_DIR"
    if [ -e backdoor ]; then
        rm -rf backdoor
    fi

    if [ -e pld_backdoor_bmtest.tgz ]; then
        rm -f pld_backdoor_bmtest.tgz
    fi

    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build/rom,c_build/sram,script}

      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ./script
      fi
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ./script
      fi

      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      dd if=${ROM_BIN} of=./workspace/bootrom_0.bin bs=64k count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_1.bin bs=64k skip=1 count=1
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_0.bin > ./c_build/rom/bootrom0.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_1.bin > ./c_build/rom/bootrom1.bin.text

      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom1}" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom1} -file ../c_build/rom/bootrom1.bin.text" >> reload_rom.tcl
      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

      if [ -e ${BMTEST_BIN} ];then
      echo "============================ bmtest: load bmtest.bin to sram offset: 256KB ============================="
      chunk_size=4096 #4KB
      input_file=${BMTEST_BIN}
      bmtest_index="bmtest_"
      file_size=$(stat -c %s "${BMTEST_BIN}")
      touch reload_sram.tcl

      # Determine if the file is aligned to 4KB
      remainder=$(expr $file_size % $chunk_size)
      if [ $remainder -eq 0 ]; then
         echo "file is aligned to $chunk_size"
      else
         padding=$(expr $chunk_size - $remainder)
         dd if=/dev/zero bs=1 count=$padding >> "$input_file" 2>/dev/null
         echo "dd $padding size to $input_file for aligned to $chunk_size"
      fi

      num_chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
      echo "num block is ${num_chunks}"
      for ((i = 0; i < num_chunks; i++)); do
        offset=$((i * chunk_size))
        output_file="./workspace/${bmtest_index}${i}.bin"
        text_output_file="./c_build/sram/${bmtest_index}${i}.bin.text"
        tmp_text_output_file="./c_build/sram/_${bmtest_index}${i}.bin.text"

        # Extract the chunk
        dd if="${input_file}" of="${output_file}" bs=$chunk_size skip=$i count=1

        # Generate hexdump for the chunk
        # d256 w128
        #[127-96] [95-64] [63-32] [31-0]
        hexdump -v -e '4/4 "%08x"' -e '"\n"' "$output_file" > "$tmp_text_output_file"
        awk '{ printf "%s%s%s%s\n", substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$tmp_text_output_file" > "$text_output_file"
        rm -rf "$tmp_text_output_file"


      # 1 array 8lane 16bank 1slice
      local bank=$(expr $i % 16)
      local lane=$(expr $i / 16)
      echo "bank ${bank} lane ${lane}"
      echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_tpu.u_tpu_pwr_wrap.u_tpu.arrays_grp.gen_arrays[0]"\
".genblk1.u_array.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[$lane]"\
".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]"\
".u_lmem_bank.gen_sram_slice[0]"\
".u_ram0.u_mem_u_tpu_mem_d256w128_0.MEMORY}" >> reload_sram.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_tpu.u_tpu_pwr_wrap.u_tpu.arrays_grp.gen_arrays[0]"\
".genblk1.u_array.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[$lane]"\
".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]"\
".u_lmem_bank.gen_sram_slice[0]"\
".u_ram0.u_mem_u_tpu_mem_d256w128_0.MEMORY} -file ../c_build/sram/${bmtest_index}${i}.bin.text" >> reload_sram.tcl

      done

      echo "bmtest end"
      else
        echo "${BMTEST_BIN} not found!!!"
      fi

      rm -rf ./workspace
      mv *.tcl ./script

    popd
    tar -zcvf pld_backdoor_bmtest.tgz backdoor/{c_build,script}
    rm -rf backdoor
    md5sum pld_backdoor_bmtest.tgz
  popd
)}

function build_backdoor_for_linux
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bl2(ddr init) --> bl31 --> uboot --> linux

  local ROM_BIN="${TOP_DIR}/rom/build/cv184x/bl1.bin"
  local BL2_BIN="${TOP_DIR}/fsbl/build/cv184x_palladium/bl2.bin"
  local BL31_BIN="${TOP_DIR}/fsbl/build/cv184x_palladium/bl31.bin"
  local BL31_ADDR=0x80000000
  local DATA_BIN="${TOP_DIR}/u-boot-2021.10/build/cv184x_palladium/u-boot.bin"
  local DATA_ADDR=0x80200000
  local DATA1_BIN="${TOP_DIR}/install/soc_cv184x_palladium/ramboot.itb"
  local DATA1_ADDR=0x81200000

  pushd "$OUTPUT_DIR"
    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build/rom,c_build/sram,c_build/ddr,script}

      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ./script
      fi
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ./script
      fi

      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      dd if=${ROM_BIN} of=./workspace/bootrom_0.bin bs=64k count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_1.bin bs=64k skip=1 count=1
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_0.bin > ./c_build/rom/bootrom0.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_1.bin > ./c_build/rom/bootrom1.bin.text

      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom1}" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom1} -file ../c_build/rom/bootrom1.bin.text" >> reload_rom.tcl
      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

      if [ -e ${BL2_BIN} ];then
      echo "============================ bl2: load bl2.bin to sram offset: 256KB ============================="
      chunk_size=4096 #4KB
      input_file=${BL2_BIN}
      bl2_file_index="bl2_"
      file_size=$(stat -c %s "${BL2_BIN}")
      touch reload_sram.tcl

      # Determine if the file is aligned to 4KB
      remainder=$(expr $file_size % $chunk_size)
      if [ $remainder -eq 0 ]; then
         echo "file is aligned to $chunk_size"
      else
         padding=$(expr $chunk_size - $remainder)
         dd if=/dev/zero bs=1 count=$padding >> "$input_file" 2>/dev/null
         echo "dd $padding size to $input_file for aligned to $chunk_size"
      fi

      num_chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
      echo "num block is ${num_chunks}"
      for ((i = 0; i < num_chunks; i++)); do
        offset=$((i * chunk_size))
        output_file="./workspace/${bl2_file_index}${i}.bin"
        text_output_file="./c_build/sram/${bl2_file_index}${i}.bin.text"
        tmp_text_output_file="./c_build/sram/_${bl2_file_index}${i}.bin.text"

        # Extract the chunk
        dd if="${input_file}" of="${output_file}" bs=$chunk_size skip=$i count=1

        # Generate hexdump for the chunk
        # d256 w128
        #[127-96] [95-64] [63-32] [31-0]
        hexdump -v -e '4/4 "%08x"' -e '"\n"' "$output_file" > "$tmp_text_output_file"
        awk '{ printf "%s%s%s%s\n", substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$tmp_text_output_file" > "$text_output_file"
        rm -rf "$tmp_text_output_file"


      # 1 array 8lane 16bank 1slice
      local bank=$(expr $i % 16)
      local lane=$(expr $i / 16)
      echo "bank ${bank} lane ${lane}"
      echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_tpu.u_tpu_pwr_wrap.u_tpu.arrays_grp.gen_arrays[0]"\
".genblk1.u_array.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[$lane]"\
".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]"\
".u_lmem_bank.gen_sram_slice[0]"\
".u_ram0.u_mem_u_tpu_mem_d256w128_0.MEMORY}" >> reload_sram.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_tpu.u_tpu_pwr_wrap.u_tpu.arrays_grp.gen_arrays[0]"\
".genblk1.u_array.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[$lane]"\
".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]"\
".u_lmem_bank.gen_sram_slice[0]"\
".u_ram0.u_mem_u_tpu_mem_d256w128_0.MEMORY} -file ../c_build/sram/${bl2_file_index}${i}.bin.text" >> reload_sram.tcl

      done

      echo "bl2 end"
      else
        echo "${BL2_BIN} not found!!!"
      fi

      if [ -e ${BL31_BIN} ];then
      echo "============================ BL31: load bl31.bin to ddr offset: ${BL31_ADDR} ============================="

      local bl3_file_name="${BL31_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv184x/pld_tools/
      python3 real_ddr_axi2dram.py ${BL31_BIN} ${BL31_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "${BL31_BIN} not found!!!"
      fi

      if [ -e ${DATA_BIN} ];then
      echo "============================ data: load data.bin to ddr offset: ${DATA_ADDR} ============================="
      
      local data_file_name="${DATA_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv184x/pld_tools/
      python3 real_ddr_axi2dram.py ${DATA_BIN} ${DATA_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "data.bin not found!!!"
      fi

      if [ -e ${DATA1_BIN} ];then
      echo "============================ data1: load data1.bin to ddr offset: ${DATA1_ADDR} ============================="
      
      local data_file_name="${DATA1_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv184x/pld_tools/
      python3 real_ddr_axi2dram.py ${DATA1_BIN} ${DATA1_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "data.bin not found!!!"
      fi
      rm -rf ./workspace
      mv *.tcl ./script
    popd
    tar -zcvf pld_backdoor_linux.tgz backdoor/{c_build,script}
    rm -rf backdoor
    md5sum pld_backdoor_linux.tgz
  popd
)}

function build_backdoor_for_dualOS
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bl2(ddr init) --> bl31 --> uboot --> linux && alios

  local ROM_BIN="${TOP_DIR}/bl1.bin"
  local BL2_BIN="${TOP_DIR}/fsbl/build/cv184x_palladium/bl2.bin"
  local BL31_BIN="${TOP_DIR}/fsbl/build/cv184x_palladium/bl31.bin"
  local BL31_ADDR=0x80000000
  local DATA_BIN="${TOP_DIR}/u-boot-2021.10/build/cv184x_palladium/u-boot.bin"
  local DATA_ADDR=0x83800000
  local DATA1_BIN="${TOP_DIR}/install/soc_cv184x_palladium/ramboot.itb"
  local DATA1_ADDR=0x81200000
  local DATA2_BIN="${TOP_DIR}/cvi_alios/solutions/normboot/yoc.bin"
  local DATA2_ADDR=0x80200000

  pushd "$OUTPUT_DIR"
    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build/rom,c_build/sram,c_build/ddr,script}

      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ./script
      fi
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ./script
      fi

      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      dd if=${ROM_BIN} of=./workspace/bootrom_0.bin bs=64k count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_1.bin bs=64k skip=1 count=1
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_0.bin > ./c_build/rom/bootrom0.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_1.bin > ./c_build/rom/bootrom1.bin.text

      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom1}" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom1} -file ../c_build/rom/bootrom1.bin.text" >> reload_rom.tcl
      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

      if [ -e ${BL2_BIN} ];then
      echo "============================ bl2: load bl2.bin to sram offset: 256KB ============================="
      chunk_size=4096 #4KB
      input_file=${BL2_BIN}
      bl2_file_index="bl2_"
      file_size=$(stat -c %s "${BL2_BIN}")
      touch reload_sram.tcl

      # Determine if the file is aligned to 4KB
      remainder=$(expr $file_size % $chunk_size)
      if [ $remainder -eq 0 ]; then
         echo "file is aligned to $chunk_size"
      else
         padding=$(expr $chunk_size - $remainder)
         dd if=/dev/zero bs=1 count=$padding >> "$input_file" 2>/dev/null
         echo "dd $padding size to $input_file for aligned to $chunk_size"
      fi

      num_chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
      echo "num block is ${num_chunks}"
      for ((i = 0; i < num_chunks; i++)); do
        offset=$((i * chunk_size))
        output_file="./workspace/${bl2_file_index}${i}.bin"
        text_output_file="./c_build/sram/${bl2_file_index}${i}.bin.text"
        tmp_text_output_file="./c_build/sram/_${bl2_file_index}${i}.bin.text"

        # Extract the chunk
        dd if="${input_file}" of="${output_file}" bs=$chunk_size skip=$i count=1

        # Generate hexdump for the chunk
        # d256 w128
        #[127-96] [95-64] [63-32] [31-0]
        hexdump -v -e '4/4 "%08x"' -e '"\n"' "$output_file" > "$tmp_text_output_file"
        awk '{ printf "%s%s%s%s\n", substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$tmp_text_output_file" > "$text_output_file"
        rm -rf "$tmp_text_output_file"


      # 1 array 8lane 16bank 1slice
      local bank=$(expr $i % 16)
      local lane=$(expr $i / 16)
      echo "bank ${bank} lane ${lane}"
      echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_tpu.u_tpu_pwr_wrap.u_tpu.arrays_grp.gen_arrays[0]"\
".genblk1.u_array.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[$lane]"\
".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]"\
".u_lmem_bank.gen_sram_slice[0]"\
".u_ram0.u_mem_u_tpu_mem_d256w128_0.MEMORY}" >> reload_sram.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_tpu.u_tpu_pwr_wrap.u_tpu.arrays_grp.gen_arrays[0]"\
".genblk1.u_array.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[$lane]"\
".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]"\
".u_lmem_bank.gen_sram_slice[0]"\
".u_ram0.u_mem_u_tpu_mem_d256w128_0.MEMORY} -file ../c_build/sram/${bl2_file_index}${i}.bin.text" >> reload_sram.tcl

      done

      echo "bl2 end"
      else
        echo "${BL2_BIN} not found!!!"
      fi

      if [ -e ${BL31_BIN} ];then
      echo "============================ BL31: load bl31.bin to ddr offset: ${BL31_ADDR} ============================="

      local bl3_file_name="${BL31_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv184x/pld_tools/
      python3 real_ddr_axi2dram.py ${BL31_BIN} ${BL31_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "${BL31_BIN} not found!!!"
      fi

      if [ -e ${DATA_BIN} ];then
      echo "============================ data: load data.bin to ddr offset: ${DATA_ADDR} ============================="

      local data_file_name="${DATA_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv184x/pld_tools/
      python3 real_ddr_axi2dram.py ${DATA_BIN} ${DATA_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "data.bin not found!!!"
      fi

      if [ -e ${DATA1_BIN} ];then
      echo "============================ data1: load data1.bin to ddr offset: ${DATA1_ADDR} ============================="

      local data_file_name="${DATA1_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv184x/pld_tools/
      python3 real_ddr_axi2dram.py ${DATA1_BIN} ${DATA1_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "${DATA1_BIN} not found!!!"
      fi

      if [ -e ${DATA2_BIN} ];then
      echo "============================ data1: load data2.bin to ddr offset: ${DATA2_ADDR} ============================="

      local data_file_name="${DATA2_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv184x/pld_tools/
      python3 real_ddr_axi2dram.py ${DATA2_BIN} ${DATA2_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "${DATA2_BIN} not found!!!"
      fi
      rm -rf ./workspace
      mv *.tcl ./script
    popd
    tar -zcvf pld_backdoor_dualOS.tgz backdoor/{c_build,script}
    rm -rf backdoor
    md5sum pld_backdoor_dualOS.tgz
  popd
)}

function pack_backdoor
{(
  print_notice "Run ${FUNCNAME[0]}() function"
if [ "$USE_DDR" = "yes" ]; then
  build_backdoor_bmtest_file_for_ddr
else
  build_backdoor_bmtest_file
fi
  build_backdoor_for_linux
)}

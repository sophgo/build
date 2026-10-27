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



function build_backdoor_bmtest_file_sram
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bmtest
  local ROM_BIN="${TOP_DIR}/bl1.bin"
  local BL2_BIN="/media/cvitek/martin.xuan/edge_sdk/84x6/fsbl/build/edge_84x6_palladium/bl2.bin"

  pushd "$OUTPUT_DIR"
    if [ -e backdoor ]; then
        rm -rf backdoor
    fi

    if [ -e pld_backdoor_bmtest_sram.tgz ]; then
        rm -f pld_backdoor_bmtest_sram.tgz
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
      echo "ROM PATH: ${ROM_BIN}"
      dd if=${ROM_BIN} of=./workspace/bootrom_0.bin bs=64k count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_1.bin bs=64k skip=1 count=1
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_0.bin > ./c_build/rom/bootrom0.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_1.bin > ./c_build/rom/bootrom1.bin.text

      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1}" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1} -file ../c_build/rom/bootrom1.bin.text" >> reload_rom.tcl
      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

      if [ -e ${BL2_BIN} ];then
      echo "============================ bl2: load bl2.bin to sram offset: 0x0 ============================="
      chunk_size=8192 #8KB
      input_file=${BL2_BIN}
      bl2_file_index="bl2_"
      file_size=$(stat -c %s "${BL2_BIN}")
      touch reload_sram.tcl

      # Determine if the file is aligned to 8KB
      remainder=$(expr $file_size % $chunk_size)
      if [ $remainder -eq 0 ]; then
         echo "file is aligned to $chunk_size"
      else
         padding=$(expr $chunk_size - $remainder)
         dd if=/dev/zero bs=1 count=$padding >> "$input_file" 2>/dev/null
         echo "dd $padding size to $input_file for aligned to $chunk_size"
      fi

      num_chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
      if (( num_chunks % 2 != 0 )); then
            dd if=/dev/zero bs=1 count=$chunk_size >> "$input_file" 2>/dev/null
            num_chunks=$(( num_chunks + 1 ))
      fi
      echo "num block is ${num_chunks}"

      for ((i = 0; i < num_chunks; i++)); do
        offset=$((i * chunk_size))
        output_file="./workspace/${bl2_file_index}${i}.bin"
        text_output_file="./c_build/sram/${bl2_file_index}${i}.bin.text"
        tmp_text_output_file="./c_build/sram/_${bl2_file_index}${i}.bin.text"

        # Extract the chunk
        dd if="${input_file}" of="${output_file}" bs=$chunk_size skip=$i count=1

        # Generate hexdump for the chunk
        # d256 w256
        # [255-224] [223-192] [191-160] [159-128] [127-96] [95-64] [63-32] [31-0]
        hexdump -v -e '8/4 "%08x"' -e '"\n"' "$output_file" > "$tmp_text_output_file"
        awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$tmp_text_output_file" > "$text_output_file"
        rm -rf "$tmp_text_output_file"


      # 4 array 2lane 16bank 2slice
      local bank=$(expr $i / 2)
      local slice=$(expr $i % 2)
      echo "bank ${bank} lane ${lane}"
      echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x256_0_0.ram_core}" >> reload_sram.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x256_0_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}_.bin.text" >> reload_sram.tcl
      echo "memory -dump %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x256_0_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}dump.txt -start 0 -end 0xff" >> dump_sram.tcl
      done

      for ((j = 0; j < num_chunks; j+=2)); do

	A_input_file="./c_build/sram/${bl2_file_index}${j}.bin.text"
	B_input_file="./c_build/sram/${bl2_file_index}$((j+1)).bin.text"
	A_output_file="./c_build/sram/${bl2_file_index}${j}_.bin.text"
	B_output_file="./c_build/sram/${bl2_file_index}$((j+1))_.bin.text"

	# echo "A: ${A_input_file}, B: ${B_input_file}"
	for ((i=1; i<=256; i++)); do
		line=$(sed -n "${i}p" ${A_input_file})  # read colume i
		if (( i % 2 == 1 )); then
			echo "$line" >> ${A_output_file}
		else
			echo "$line" >> ${B_output_file}
		fi
	done

	for ((i=1; i<=256; i++)); do
		line=$(sed -n "${i}p" ${B_input_file})  # read colume i
		if (( i % 2 == 1 )); then
			echo "$line" >> ${A_output_file}
		else
			echo "$line" >> ${B_output_file}
		fi
	done

	rm -rf ${A_input_file}
	rm -rf ${B_input_file}

      done

      echo "bl2 end"
      else
        echo "${BL2_BIN} not found!!!"
      fi

      rm -rf ./workspace
      mv *.tcl ./script

    popd
    tar -zcvf pld_backdoor_bmtest_sram.tgz backdoor/{c_build,script}
    rm -rf backdoor
    md5sum pld_backdoor_bmtest_sram.tgz
  popd
)}

function build_backdoor_84x6_bring_up_fake
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bmtest
  local ROM_BIN="${TOP_DIR}/rom/build/cv84x6/bl1.bin"
  local BL2_BIN="${TOP_DIR}/fsbl/build/edge_84x6_palladium/bl2.bin"
  local BL31_BIN="${TOP_DIR}/fsbl/build/edge_84x6_palladium/bl31.bin"
  local BL32_BIN="${TOP_DIR}/fsbl/build/edge_84x6_palladium/bl32.bin"
  local UBOOT_BIN="${TOP_DIR}/u-boot-2021.10/build/edge_84x6_palladium/u-boot-raw.bin"
  local IMAGE_BIN="${TOP_DIR}/ramdisk/build/edge_84x6_palladium/workspace/Image"
  local DTB_BIN="${TOP_DIR}/ramdisk/build/edge_84x6_palladium/workspace/cv84x6_palladium.dtb"
  local RAMDISK_BIN="${TOP_DIR}/ramdisk/build/edge_84x6_palladium/workspace/boot.cpio.img"

    read -p "Pls input db version (example:0.39/0.40/0.41):" input_version

    if ! echo "$input_version" | grep -qE '^[0-9]+\.[0-9]+$'; then
        echo "!!! =Input version invalid! Pls input format like: 0.40"
        popd
        return 1
    fi


    local version_branch
    version_branch=$(echo "$input_version 0.40" | awk '{
        if ($1 >= $2) print "HIGH_VERSION";
        else print "LOW_VERSION";
    }')

  pushd "$OUTPUT_DIR"
    if [ -e backdoor ]; then
        rm -rf backdoor
    fi

    if [ -e pld_backdoor_bmtest_sram.tgz ]; then
        rm -f pld_backdoor_bmtest_sram.tgz
    fi

    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build/rom,c_build/sram,c_build/bl31,c_build/bl32,c_build/uboot,c_build/image,c_build/dtb,c_build/ramdisk,script}

      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ./script
      fi
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ./script
      fi

      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      echo "ROM PATH: ${ROM_BIN}"
      dd if=${ROM_BIN} of=./workspace/bootrom_0.bin bs=64k count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_1.bin bs=64k skip=1 count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_2.bin bs=64k skip=2 count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_3.bin bs=64k skip=3 count=1
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_0.bin > ./c_build/rom/bootrom0.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_1.bin > ./c_build/rom/bootrom1.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_2.bin > ./c_build/rom/bootrom2.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_3.bin > ./c_build/rom/bootrom3.bin.text

      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1}" >> reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom2}" >> reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom3}" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1} -file ../c_build/rom/bootrom1.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom2} -file ../c_build/rom/bootrom2.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom3} -file ../c_build/rom/bootrom3.bin.text" >> reload_rom.tcl

      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

      if [ -e ${BL2_BIN} ];then
      echo "============================ bmtest: load bmtest.bin to sram offset: 256KB ============================="
      chunk_size=8192 #8KB
      input_file=${BL2_BIN}
      bl2_file_index="bl2_"
      file_size=$(stat -c %s "${BL2_BIN}")
      touch reload_sram.tcl

      # Determine if the file is aligned to 8KB
      remainder=$(expr $file_size % $chunk_size)
      if [ $remainder -eq 0 ]; then
         echo "file is aligned to $chunk_size"
      else
         padding=$(expr $chunk_size - $remainder)
         dd if=/dev/zero bs=1 count=$padding >> "$input_file" 2>/dev/null
         echo "dd $padding size to $input_file for aligned to $chunk_size"
      fi

      num_chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
      if (( num_chunks % 2 != 0 )); then
            dd if=/dev/zero bs=1 count=$chunk_size >> "$input_file" 2>/dev/null
            num_chunks=$(( num_chunks + 1 ))
      fi
      echo "num block is ${num_chunks}"

      for ((i = 0; i < num_chunks; i++)); do
        offset=$((i * chunk_size))
        output_file="./workspace/${bl2_file_index}${i}.bin"
        text_output_file="./c_build/sram/${bl2_file_index}${i}.bin.text"
        tmp_text_output_file="./c_build/sram/_${bl2_file_index}${i}.bin.text"

        # Extract the chunk
        dd if="${input_file}" of="${output_file}" bs=$chunk_size skip=$i count=1

        # Generate hexdump for the chunk
        # d256 w256
        # [255-224] [223-192] [191-160] [159-128] [127-96] [95-64] [63-32] [31-0]
        hexdump -v -e '8/4 "%08x"' -e '"\n"' "$output_file" > "$tmp_text_output_file"
        awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$tmp_text_output_file" > "$text_output_file"
        rm -rf "$tmp_text_output_file"


      # 4 array 2lane 16bank 2slice
      local bank=$(expr $i / 2)
      local slice=$(expr $i % 2)
      echo "bank ${bank} lane ${lane}"
	echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_0_0.ram_core}" >> reload_sram.tcl

	echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_1_0.ram_core}" >> reload_sram.tcl

	echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_0_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}_0.bin.text" >> reload_sram.tcl

	echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_1_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}_1.bin.text" >> reload_sram.tcl

	echo "memory -dump %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_0_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}dump.txt -start 0 -end 0x7f" >> dump_sram.tcl

	echo "memory -dump %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_1_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}dump.txt -start 0 -end 0x7f" >> dump_sram.tcl
      done

      for ((j = 0; j < num_chunks; j+=2)); do

	A_input_file="./c_build/sram/${bl2_file_index}${j}.bin.text"
	B_input_file="./c_build/sram/${bl2_file_index}$((j+1)).bin.text"
	A_output_file="./c_build/sram/${bl2_file_index}${j}_.bin.text"
	B_output_file="./c_build/sram/${bl2_file_index}$((j+1))_.bin.text"

	A_0_output_file="./c_build/sram/${bl2_file_index}${j}_0.bin.text"
	A_1_output_file="./c_build/sram/${bl2_file_index}${j}_1.bin.text"
	B_0_output_file="./c_build/sram/${bl2_file_index}$((j+1))_0.bin.text"
	B_1_output_file="./c_build/sram/${bl2_file_index}$((j+1))_1.bin.text"

	# echo "A: ${A_input_file}, B: ${B_input_file}"
	for ((i=1; i<=256; i++)); do
		line=$(sed -n "${i}p" ${A_input_file})  # read colume i
		if (( i % 2 == 1 )); then
			echo "$line" >> ${A_output_file}
		else
			echo "$line" >> ${B_output_file}
		fi
	done

	for ((i=1; i<=256; i++)); do
		line=$(sed -n "${i}p" ${B_input_file})  # read colume i
		if (( i % 2 == 1 )); then
			echo "$line" >> ${A_output_file}
		else
			echo "$line" >> ${B_output_file}
		fi
	done

	rm -rf ${A_input_file}
	rm -rf ${B_input_file}

	for ((i=1; i<=256; i++)); do
		# A
		line=$(sed -n "${i}p" ${A_output_file})  # read colume i
		CLEAN_LINE=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

		PART0=${CLEAN_LINE:0:32}
		PART0_PADDED=$(printf "%-32s" "$PART0" | sed 's/ /0/g')

		PART1=${CLEAN_LINE:32:32}
		PART1_PADDED=$(printf "%-32s" "$PART1" | sed 's/ /0/g')

		echo "$PART0_PADDED" >> "$A_1_output_file"
		echo "$PART1_PADDED" >> "$A_0_output_file"

		# B
		line=$(sed -n "${i}p" ${B_output_file})  # read colume i
		CLEAN_LINE=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

		PART0=${CLEAN_LINE:0:32}
		PART0_PADDED=$(printf "%-32s" "$PART0" | sed 's/ /0/g')

		PART1=${CLEAN_LINE:32:32}
		PART1_PADDED=$(printf "%-32s" "$PART1" | sed 's/ /0/g')

		echo "$PART0_PADDED" >> "$B_1_output_file"
		echo "$PART1_PADDED" >> "$B_0_output_file"
	done

	rm -rf ${A_output_file}
	rm -rf ${B_output_file}

      done

      echo "bl2 end"
      else
        echo "${BL2_BIN} not found!!!"
      fi

      local TMP_BIN="./workspace/tmp.bin"

      if [ -e ${BL31_BIN} ];then
      echo "bl31 start..."
      echo "bl31.bin: ${BL31_BIN}"
      if [ "$version_branch" = "HIGH_VERSION" ]; then
	hexdump -v -e '8/4 "%08x"' -e '"\n"' ${BL31_BIN} > "$TMP_BIN"
	awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$TMP_BIN" > "./c_build/bl31/bl31.bin.text"
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/bl31/bl31.bin.text -start 0x0" >> reload_bl31.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/bl31/bl31.bin.text -start 0x0" >> reload_bl31.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/bl31/bl31.bin.text -start 0x0 -end 0x100" >> dump_bl31.tcl
      else
	hexdump -v -e '1/4 "%08x\n"' ${BL31_BIN} > ./c_build/bl31/bl31.bin.text
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/bl31/bl31.bin.text -start 0x0" >> reload_bl31.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/bl31/bl31.bin.text -start 0x0" >> reload_bl31.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/bl31/bl31.bin.text -start 0x0 -end 0x100" >> dump_bl31.tcl
      fi
      echo "bl31 end"
      else
        echo "${BL31_BIN} not found!!!"
      fi

      if [ -e ${BL32_BIN} ];then
      echo "bl32 start..."
      echo "bl32.bin: ${BL32_BIN}"
      if [ "$version_branch" = "HIGH_VERSION" ]; then
        hexdump -v -e '8/4 "%08x"' -e '"\n"' ${BL32_BIN} > "$TMP_BIN"
        awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$TMP_BIN" > "./c_build/bl32/bl32.bin.text"
        echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/bl32/bl32.bin.text -start 0x8000" >> reload_bl32.tcl
        echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/bl32/bl32.bin.text -start 0x8000" >> reload_bl32.tcl
        echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/bl32/bl32.bin.text -start 0x8000 -end 0x100" >> dump_bl32.tcl
      else
         echo "${BL32_BIN} ver error!!!"
      fi
      echo "bl32 end"
      else
        echo "${BL32_BIN} not found!!!"
      fi

      if [ -e ${UBOOT_BIN} ];then
      echo "uboot start..."
      echo "u-boot-raw.bin: ${UBOOT_BIN}"
      if [ "$version_branch" = "HIGH_VERSION" ]; then
	hexdump -v -e '8/4 "%08x"' -e '"\n"' ${UBOOT_BIN} > "$TMP_BIN"
	awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$TMP_BIN" > "./c_build/uboot/u-boot-raw.bin.text"
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/uboot/u-boot-raw.bin.text -start 0x10000" >> reload_uboot.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/uboot/u-boot-raw.bin.text -start 0x10000" >> reload_uboot.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/uboot/u-boot-raw.bin.text -start 0x10000 -end 0x1e000" >> dump_uboot.tcl
      else
	hexdump -v -e '1/4 "%08x\n"' ${UBOOT_BIN} > ./c_build/uboot/u-boot-raw.bin.text
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/uboot/u-boot-raw.bin.text -start 0x50000" >> reload_uboot.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/uboot/u-boot-raw.bin.text -start 0x50000" >> reload_uboot.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/uboot/u-boot-raw.bin.text -start 0x50000 -end 0xf0000" >> dump_uboot.tcl
      fi
      echo "uboot end"
      else
        echo "${UBOOT_BIN} not found!!!"
      fi

      if [ -e ${IMAGE_BIN} ];then
      echo "image start..."
      echo "image.bin: ${IMAGE_BIN}"
      if [ "$version_branch" = "HIGH_VERSION" ]; then
	hexdump -v -e '8/4 "%08x"' -e '"\n"' ${IMAGE_BIN} > "$TMP_BIN"
	awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$TMP_BIN" > "./c_build/image/image.bin.text"
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/image/image.bin.text -start 0x100000" >> reload_image.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/image/image.bin.text -start 0x100000" >> reload_image.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/image/image.bin.text -start 0x100000 -end 0x100200" >> dump_image.tcl
      else
	hexdump -v -e '1/4 "%08x\n"' ${IMAGE_BIN} > ./c_build/image/image.bin.text
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/image/image.bin.text -start 0x800000" >> reload_image.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/image/image.bin.text -start 0x800000" >> reload_image.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/image/image.bin.text -start 0x800000 -end 0x801000" >> dump_image.tcl
      fi
      echo "image end"
      else
        echo "${IMAGE_BIN} not found!!!"
      fi

      if [ -e ${RAMDISK_BIN} ];then
      echo "ramdisk start..."
      echo "ramdisk.bin: ${RAMDISK_BIN}"
      if [ "$version_branch" = "HIGH_VERSION" ]; then
	hexdump -v -e '8/4 "%08x"' -e '"\n"' ${RAMDISK_BIN} > "$TMP_BIN"
	awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$TMP_BIN" > "./c_build/ramdisk/ramdisk.bin.text"
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/ramdisk/ramdisk.bin.text -start 0x300000" >> reload_ramdisk.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/ramdisk/ramdisk.bin.text -start 0x300000" >> reload_ramdisk.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/ramdisk/ramdisk.bin.text -start 0x300000 -end 0x302000" >> dump_ramdisk.tcl
      else
	hexdump -v -e '1/4 "%08x\n"' ${RAMDISK_BIN} > ./c_build/ramdisk/ramdisk.bin.text
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/ramdisk/ramdisk.bin.text -start 0x2000000" >> reload_ramdisk.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/ramdisk/ramdisk.bin.text -start 0x2000000" >> reload_ramdisk.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/ramdisk/ramdisk.bin.text -start 0x2000000 -end 0x2010000" >> dump_ramdisk.tcl
      fi
      echo "ramdisk end"
      else  
        echo "${RAMDISK_BIN} not found!!!"
      fi

      if [ -e ${DTB_BIN} ];then
      echo "dtb start..."
      echo "dtb.bin: ${DTB_BIN}"
      if [ "$version_branch" = "HIGH_VERSION" ]; then
	hexdump -v -e '8/4 "%08x"' -e '"\n"' ${DTB_BIN} > "$TMP_BIN"
	awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$TMP_BIN" > "./c_build/dtb/dtb.bin.text"
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/dtb/dtb.bin.text -start 0xB00000" >> reload_dtb.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/dtb/dtb.bin.text -start 0xB00000" >> reload_dtb.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/dtb/dtb.bin.text -start 0xB00000 -end 0xB02000" >> dump_dtb.tcl
      else
	hexdump -v -e '1/4 "%08x\n"' ${DTB_BIN} > ./c_build/dtb/dtb.bin.text
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/dtb/dtb.bin.text -start 0x2400000" >> reload_dtb.tcl
	echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/dtb/dtb.bin.text -start 0x2400000" >> reload_dtb.tcl
	echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/dtb/dtb.bin.text -start 0x2400000 -end 0x2410000" >> dump_dtb.tcl
      fi
      echo "dtb end"
      else
        echo "${DTB_BIN} not found!!!"
      fi

      rm -rf ./workspace
      mv *.tcl ./script

    popd
 
    tar -zcvf pld_backdoor_84x6_bring_up_fake.tgz backdoor/{c_build,script}
    rm -rf backdoor
    md5sum pld_backdoor_84x6_bring_up_fake.tgz
  popd
)}

function build_backdoor_84x6_bring_up_real_ddr
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bmtest
  local ROM_BIN="${TOP_DIR}/rom/build/cv84x6/bl1.bin"
  local BL2_BIN="${TOP_DIR}/fsbl/build/edge_84x6_palladium/bl2.bin"
  local BL31_BIN="${TOP_DIR}/fsbl/build/edge_84x6_palladium/bl31.bin"
  local BL32_BIN="${TOP_DIR}/fsbl/build/edge_84x6_palladium/bl32.bin"
  local UBOOT_BIN="${TOP_DIR}/u-boot-2021.10/build/edge_84x6_palladium/u-boot-raw.bin"
  local IMAGE_BIN="${TOP_DIR}/ramdisk/build/edge_84x6_palladium/workspace/Image"
  local DTB_BIN="${TOP_DIR}/ramdisk/build/edge_84x6_palladium/workspace/cv84x6_palladium.dtb"
  local RAMDISK_BIN="${TOP_DIR}/ramdisk/build/edge_84x6_palladium/workspace/boot.cpio.img"

  # DDR memory addresses (需要根据实际情况调整)
  local BL31_ADDR="0x1000000000"
  local BL32_ADDR="0x1000100000"
  local UBOOT_ADDR="0x1000200000"
  local IMAGE_ADDR="0x1002000000"
  local RAMDISK_ADDR="0x1006000000"
  local DTB_ADDR="0x1016000000"

  # Python conversion script path
  local PYTHON_SCRIPT="${TOP_DIR}/build/tools/cv84x6/pld_tools/84x6_real_ddr_axi2dram_lp5_r2.py"



  pushd "$OUTPUT_DIR"
    if [ -e backdoor ]; then
        rm -rf backdoor
    fi

    if [ -e pld_backdoor_84x6_bring_up_real_ddr.tgz ]; then
        rm -f pld_backdoor_84x6_bring_up_real_ddr.tgz
    fi

    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build/rom,c_build/sram,c_build/load_bl31,c_build/load_bl32,c_build/load_u-boot-raw,c_build/load_Image,c_build/load_cv84x6_palladium,c_build/load_boot,script}

      # Copy common scripts
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ./script
      fi
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ./script
      fi

      # Process ROM 
      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      echo "ROM PATH: ${ROM_BIN}"
      dd if=${ROM_BIN} of=./workspace/bootrom_0.bin bs=64k count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_1.bin bs=64k skip=1 count=1
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_0.bin > ./c_build/rom/bootrom0.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_1.bin > ./c_build/rom/bootrom1.bin.text

      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1}" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1} -file ../c_build/rom/bootrom1.bin.text" >> reload_rom.tcl
      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

      if [ -e ${BL2_BIN} ];then
      echo "============================ bmtest: load bmtest.bin to sram offset: 256KB ============================="
      chunk_size=8192 #8KB
      input_file=${BL2_BIN}
      bl2_file_index="bl2_"
      file_size=$(stat -c %s "${BL2_BIN}")
      touch reload_sram.tcl

      # Determine if the file is aligned to 8KB
      remainder=$(expr $file_size % $chunk_size)
      if [ $remainder -eq 0 ]; then
         echo "file is aligned to $chunk_size"
      else
         padding=$(expr $chunk_size - $remainder)
         dd if=/dev/zero bs=1 count=$padding >> "$input_file" 2>/dev/null
         echo "dd $padding size to $input_file for aligned to $chunk_size"
      fi

      num_chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
      if (( num_chunks % 2 != 0 )); then
            dd if=/dev/zero bs=1 count=$chunk_size >> "$input_file" 2>/dev/null
            num_chunks=$(( num_chunks + 1 ))
      fi
      echo "num block is ${num_chunks}"

      for ((i = 0; i < num_chunks; i++)); do
        offset=$((i * chunk_size))
        output_file="./workspace/${bl2_file_index}${i}.bin"
        text_output_file="./c_build/sram/${bl2_file_index}${i}.bin.text"
        tmp_text_output_file="./c_build/sram/_${bl2_file_index}${i}.bin.text"

        # Extract the chunk
        dd if="${input_file}" of="${output_file}" bs=$chunk_size skip=$i count=1

        # Generate hexdump for the chunk
        # d256 w256
        # [255-224] [223-192] [191-160] [159-128] [127-96] [95-64] [63-32] [31-0]
        hexdump -v -e '8/4 "%08x"' -e '"\n"' "$output_file" > "$tmp_text_output_file"
        awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$tmp_text_output_file" > "$text_output_file"
        rm -rf "$tmp_text_output_file"


      # 4 array 2lane 16bank 2slice
      local bank=$(expr $i / 2)
      local slice=$(expr $i % 2)
      echo "bank ${bank} lane ${lane}"
	echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_0_0.ram_core}" >> reload_sram.tcl

	echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_1_0.ram_core}" >> reload_sram.tcl

	echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_0_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}_0.bin.text" >> reload_sram.tcl

	echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_1_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}_1.bin.text" >> reload_sram.tcl

	echo "memory -dump %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_0_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}dump.txt -start 0 -end 0x7f" >> dump_sram.tcl

	echo "memory -dump %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_1_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}dump.txt -start 0 -end 0x7f" >> dump_sram.tcl
      done

      for ((j = 0; j < num_chunks; j+=2)); do

	A_input_file="./c_build/sram/${bl2_file_index}${j}.bin.text"
	B_input_file="./c_build/sram/${bl2_file_index}$((j+1)).bin.text"
	A_output_file="./c_build/sram/${bl2_file_index}${j}_.bin.text"
	B_output_file="./c_build/sram/${bl2_file_index}$((j+1))_.bin.text"

	A_0_output_file="./c_build/sram/${bl2_file_index}${j}_0.bin.text"
	A_1_output_file="./c_build/sram/${bl2_file_index}${j}_1.bin.text"
	B_0_output_file="./c_build/sram/${bl2_file_index}$((j+1))_0.bin.text"
	B_1_output_file="./c_build/sram/${bl2_file_index}$((j+1))_1.bin.text"

	# echo "A: ${A_input_file}, B: ${B_input_file}"
	for ((i=1; i<=256; i++)); do
		line=$(sed -n "${i}p" ${A_input_file})  # read colume i
		if (( i % 2 == 1 )); then
			echo "$line" >> ${A_output_file}
		else
			echo "$line" >> ${B_output_file}
		fi
	done

	for ((i=1; i<=256; i++)); do
		line=$(sed -n "${i}p" ${B_input_file})  # read colume i
		if (( i % 2 == 1 )); then
			echo "$line" >> ${A_output_file}
		else
			echo "$line" >> ${B_output_file}
		fi
	done

	rm -rf ${A_input_file}
	rm -rf ${B_input_file}

	for ((i=1; i<=256; i++)); do
		# A
		line=$(sed -n "${i}p" ${A_output_file})  # read colume i
		CLEAN_LINE=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

		PART0=${CLEAN_LINE:0:32}
		PART0_PADDED=$(printf "%-32s" "$PART0" | sed 's/ /0/g')

		PART1=${CLEAN_LINE:32:32}
		PART1_PADDED=$(printf "%-32s" "$PART1" | sed 's/ /0/g')

		echo "$PART0_PADDED" >> "$A_1_output_file"
		echo "$PART1_PADDED" >> "$A_0_output_file"

		# B
		line=$(sed -n "${i}p" ${B_output_file})  # read colume i
		CLEAN_LINE=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

		PART0=${CLEAN_LINE:0:32}
		PART0_PADDED=$(printf "%-32s" "$PART0" | sed 's/ /0/g')

		PART1=${CLEAN_LINE:32:32}
		PART1_PADDED=$(printf "%-32s" "$PART1" | sed 's/ /0/g')

		echo "$PART0_PADDED" >> "$B_1_output_file"
		echo "$PART1_PADDED" >> "$B_0_output_file"
	done

	rm -rf ${A_output_file}
	rm -rf ${B_output_file}

      done

      echo "bl2 end"
      else
        echo "${BL2_BIN} not found!!!"
      fi

      # Process BL31 with Python tool (Real DDR)
      if [ -e ${BL31_BIN} ];then
      echo "bl31 start (Real DDR)..."
      echo "bl31.bin: ${BL31_BIN}"
      if [ -e "${PYTHON_SCRIPT}" ]; then
        python3 "${PYTHON_SCRIPT}" "${BL31_BIN}" "${BL31_ADDR}"
        echo "load_bl31: $(ls -l load_bl31)"
        echo "pwd: $(pwd)"
        echo "load_bl31: $(ls -l ${PWD}/load_bl31)"
        if [ -d "${PWD}/load_bl31" ]; then
          find "${PWD}/load_bl31" -mindepth 1 -maxdepth 1 -exec cp -r {} ./c_build/load_bl31/ \;
        fi
        if [ -d "${PWD}/script_real_ddr" ]; then
          cp ${PWD}/script_real_ddr/*.tcl ./script
        fi
        # Clean up temporary directories
        rm -rf ${PWD}/load_bl31 ${PWD}/script_real_ddr
      else
        echo "Python script ${PYTHON_SCRIPT} not found!"
      fi
      echo "bl31 end"
      else
        echo "${BL31_BIN} not found!!!"
      fi

      # Process BL32 with Python tool (Real DDR)
      if [ -e ${BL32_BIN} ];then
      echo "bl32 start (Real DDR)..."
      echo "bl32.bin: ${BL32_BIN}"
      if [ -e "${PYTHON_SCRIPT}" ]; then
        python3 "${PYTHON_SCRIPT}" "${BL32_BIN}" "${BL32_ADDR}"
        echo "load_bl32: $(ls -l load_bl32)"
        echo "pwd: $(pwd)"
        echo "load_bl32: $(ls -l ${PWD}/load_bl32)"
        if [ -d "${PWD}/load_bl32" ]; then
          find "${PWD}/load_bl32" -mindepth 1 -maxdepth 1 -exec cp -r {} ./c_build/load_bl32/ \;
        fi
        if [ -d "${PWD}/script_real_ddr" ]; then
          cp ${PWD}/script_real_ddr/*.tcl ./script
        fi
        # Clean up temporary directories
        rm -rf ${PWD}/load_bl32 ${PWD}/script_real_ddr
      else
        echo "Python script ${PYTHON_SCRIPT} not found!"
      fi
      echo "bl32 end"
      else
        echo "${BL32_BIN} not found!!!"
      fi

      # Process U-Boot with Python tool (Real DDR)
      if [ -e ${UBOOT_BIN} ];then
      echo "uboot start (Real DDR)..."
      echo "u-boot-raw.bin: ${UBOOT_BIN}"
      if [ -e "${PYTHON_SCRIPT}" ]; then
        python3 "${PYTHON_SCRIPT}" "${UBOOT_BIN}" "${UBOOT_ADDR}"
        if [ -d "load_u-boot-raw" ]; then
         find "${PWD}/load_u-boot-raw" -mindepth 1 -maxdepth 1 -exec cp -r {} ./c_build/load_u-boot-raw/ \;
        fi
        if [ -d "script_real_ddr" ]; then
          cp script_real_ddr/*.tcl ./script
        fi
        # Clean up temporary directories
        rm -rf temp_u-boot-raw script_real_ddr
      else
        echo "Python script ${PYTHON_SCRIPT} not found!"
      fi
      echo "uboot end"
      else
        echo "${UBOOT_BIN} not found!!!"
      fi

      # Process Kernel Image with Python tool (Real DDR)
      if [ -e ${IMAGE_BIN} ];then
      echo "image start (Real DDR)..."
      echo "image.bin: ${IMAGE_BIN}"
      if [ -e "${PYTHON_SCRIPT}" ]; then
        python3 "${PYTHON_SCRIPT}" "${IMAGE_BIN}" "${IMAGE_ADDR}"
        if [ -d "load_Image" ]; then
          find "${PWD}/load_Image" -mindepth 1 -maxdepth 1 -exec cp -r {} ./c_build/load_Image/ \;
        fi
        if [ -d "script_real_ddr" ]; then
          cp script_real_ddr/*.tcl ./script
        fi
        # Clean up temporary directories
        rm -rf temp_Image script_real_ddr
      else
        echo "Python script ${PYTHON_SCRIPT} not found!"
      fi
      echo "image end"
      else
        echo "${IMAGE_BIN} not found!!!"
      fi

      # Process RAMDisk with Python tool (Real DDR)
      if [ -e ${RAMDISK_BIN} ];then
      echo "to ramdisk start (Real DDR)..."
      echo "ramdisk.bin: ${RAMDISK_BIN}"
      if [ -e "${PYTHON_SCRIPT}" ]; then
        # Get the base filename without extension to determine temp directory name
        RAMDISK_BASENAME=$(basename "${RAMDISK_BIN}")
        RAMDISK_NAME="${RAMDISK_BASENAME%%.*}"
        LOAD_DIR="load_${RAMDISK_NAME}"
        python3 "${PYTHON_SCRIPT}" "${RAMDISK_BIN}" "${RAMDISK_ADDR}"
        if [ -d "${LOAD_DIR}" ]; then
          find "${PWD}/${LOAD_DIR}" -mindepth 1 -maxdepth 1 -exec cp -r {} ./c_build/load_${RAMDISK_NAME}/ \;
        else
          echo "Warning: ${LOAD_DIR} directory not found!"
        fi
        if [ -d "script_real_ddr" ]; then
          cp script_real_ddr/*.tcl ./script
        fi
        # Clean up temporary directories
       # rm -rf temp_boot script_real_ddr
      else
        echo "Python script ${PYTHON_SCRIPT} not found!"
      fi
      echo "ramdisk end"
      else  
        echo "${RAMDISK_BIN} not found!!!"
      fi

      # Process DTB with Python tool (Real DDR)
      if [ -e ${DTB_BIN} ];then
      echo "dtb start (Real DDR)..."
      echo "dtb.bin: ${DTB_BIN}"
      if [ -e "${PYTHON_SCRIPT}" ]; then
        python3 "${PYTHON_SCRIPT}" "${DTB_BIN}" "${DTB_ADDR}"
        if [ -d "load_cv84x6_palladium" ]; then
          find "${PWD}/load_cv84x6_palladium" -mindepth 1 -maxdepth 1 -exec cp -r {} ./c_build/load_cv84x6_palladium/ \;
        fi
        if [ -d "script_real_ddr" ]; then
          cp script_real_ddr/*.tcl ./script
        fi
        # Clean up temporary directories
        rm -rf load_cv84x6_palladium script_real_ddr
      else
        echo "Python script ${PYTHON_SCRIPT} not found!"
      fi
      echo "dtb end"
      else
        echo "${DTB_BIN} not found!!!"
      fi

      # Move all generated TCL scripts to script directory
      mv *.tcl ./script/ 2>/dev/null || true

      # Generate a helper TCL to load all backdoor scripts at once
      # Usage example in simulator workspace:
      #   source ../script/load_all.tcl
      local master_tcl="./script/load_all.tcl"
      {
        echo "force rstn 1'b0"
        echo "force u_chip_top.DUMMY0 1'h0"
        echo "force u_chip_top.DUMMY1 1'h0"
        echo "force u_chip_top.DUMMY2 1'h0"
        echo "force u_chip_top.DUMMY3 1'h0"

        # Source common reload/load scripts if they exist
        for tcl in \
          reload_rom.tcl \
          reload_sram.tcl \
          load_boot.tcl \
          load_u-boot-raw.tcl \
          load_Image.tcl \
          load_cv84x6_palladium.tcl \
          reload_bl31.tcl \
          reload_bl32.tcl \
          reload_uboot.tcl
        do
          echo "if { \[file exists \"../script/${tcl}\"] } { source ../script/${tcl} }"
        done

        echo "force rstn 1'b1"
      } > "${master_tcl}"

      rm -rf ./workspace

    popd
 
    tar -zcvf pld_backdoor_84x6_bring_up_real_ddr.tgz backdoor/{c_build,script}
    rm -rf backdoor
    md5sum pld_backdoor_84x6_bring_up_real_ddr.tgz
    echo "Real DDR backdoor package created: pld_backdoor_84x6_bring_up_real_ddr.tgz"
  popd
)}



function build_backdoor_bmtest_file_real_ddr
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bmtest
  local ROM_BIN="${TOP_DIR}/rom/cvi_rom/rom/build/cv84x6/bl1.bin"
  local BL2_BIN="${TOP_DIR}/fsbl/build/edge_84x6_palladium/bl2.bin"
  local BMTEST_BIN="${TOP_DIR}/bmtest/cvi_bmtest/cv84x6/out/bmtest.bin"

  
  # DDR memory addresses 
  local BMTEST_ADDR="0x1000000000"

  
  # Python conversion script path
  local PYTHON_SCRIPT="${TOP_DIR}/build/tools/cv84x6/pld_tools/84x6_real_ddr_axi2dram_lp5_r2.py"


    read -p "Pls input db version (example:0.39/0.40/0.41):" input_version

    if ! echo "$input_version" | grep -qE '^[0-9]+\.[0-9]+$'; then
        echo "!!! =Input version invalid! Pls input format like: 0.40"
        popd
        return 1
    fi

    local tpu_sram_ver
    tpu_sram_ver=$(echo "$input_version 0.59" | awk '{
        if ($1 >= $2) print "HIGH_VERSION";
        else print "LOW_VERSION";
    }')

  
  pushd "$OUTPUT_DIR"
    if [ -e backdoor ]; then
        rm -rf backdoor
    fi

    if [ -e pld_backdoor_84x6_bring_up_real_ddr.tgz ]; then
        rm -f pld_backdoor_84x6_bring_up_real_ddr.tgz
    fi

    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build/rom,c_build/sram,c_build/load_bmtest,script}

      # Copy common scripts
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ./script
      fi
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ./script
      fi

      # Process ROM 
      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      echo "ROM PATH: ${ROM_BIN}"
      dd if=${ROM_BIN} of=./workspace/bootrom_0.bin bs=64k count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_1.bin bs=64k skip=1 count=1
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_0.bin > ./c_build/rom/bootrom0.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_1.bin > ./c_build/rom/bootrom1.bin.text

      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1}" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1} -file ../c_build/rom/bootrom1.bin.text" >> reload_rom.tcl
      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

      # Process BL2
      if [ -e ${BL2_BIN} ];then
      echo "============================ bmtest: load bmtest.bin to sram offset: 256KB ============================="
      chunk_size=8192 #8KB
      input_file=${BL2_BIN}
      bl2_file_index="bl2_"
      file_size=$(stat -c %s "${BL2_BIN}")
      touch reload_sram.tcl

      # Determine if the file is aligned to 8KB
      remainder=$(expr $file_size % $chunk_size)
      if [ $remainder -eq 0 ]; then
         echo "file is aligned to $chunk_size"
      else
         padding=$(expr $chunk_size - $remainder)
         dd if=/dev/zero bs=1 count=$padding >> "$input_file" 2>/dev/null
         echo "dd $padding size to $input_file for aligned to $chunk_size"
      fi

      num_chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
      if (( num_chunks % 2 != 0 )); then
            dd if=/dev/zero bs=1 count=$chunk_size >> "$input_file" 2>/dev/null
            num_chunks=$(( num_chunks + 1 ))
      fi
      echo "num block is ${num_chunks}"

      for ((i = 0; i < num_chunks; i++)); do
        offset=$((i * chunk_size))
        output_file="./workspace/${bl2_file_index}${i}.bin"
        text_output_file="./c_build/sram/${bl2_file_index}${i}.bin.text"
        tmp_text_output_file="./c_build/sram/_${bl2_file_index}${i}.bin.text"

        # Extract the chunk
        dd if="${input_file}" of="${output_file}" bs=$chunk_size skip=$i count=1

        # Generate hexdump for the chunk
        hexdump -v -e '8/4 "%08x"' -e '"\n"' "$output_file" > "$tmp_text_output_file"
        awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$tmp_text_output_file" > "$text_output_file"
        rm -rf "$tmp_text_output_file"

      # 4 array 2lane 16bank 2slice
      local bank=$(expr $i / 2)
      local slice=$(expr $i % 2)
      echo "bank ${bank} lane ${lane}"
      if [ "$tpu_sram_ver" = "HIGH_VERSION" ]; then
	echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_0_0.ram_core}" >> reload_sram.tcl

	echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_1_0.ram_core}" >> reload_sram.tcl

	echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_0_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}_0.bin.text" >> reload_sram.tcl

	echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_1_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}_1.bin.text" >> reload_sram.tcl

	echo "memory -dump %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_0_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}dump.txt -start 0 -end 0x7f" >> dump_sram.tcl

	echo "memory -dump %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x128_1_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}dump.txt -start 0 -end 0x7f" >> dump_sram.tcl
      else
      echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x256_0_0.ram_core}" >> reload_sram.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.\gen_array_4[0]"\
".u_array_wrapper .u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.\gen_multi_lane[0]"\
".u_lane .lmem.u_lmem_slice.\gen_sram_bank[$bank]"\
".u_lmem_bank .\gen_sram_slice[$slice]"\
".u_ram0 .u_mem_u_tpu_lmem_256x256_0_0.ram_core} -file ../c_build/sram/${bl2_file_index}${i}_.bin.text" >> reload_sram.tcl
      fi
      done

      for ((j = 0; j < num_chunks; j+=2)); do
        A_input_file="./c_build/sram/${bl2_file_index}${j}.bin.text"
        B_input_file="./c_build/sram/${bl2_file_index}$((j+1)).bin.text"
        A_output_file="./c_build/sram/${bl2_file_index}${j}_.bin.text"
        B_output_file="./c_build/sram/${bl2_file_index}$((j+1))_.bin.text"

        for ((i=1; i<=256; i++)); do
            line=$(sed -n "${i}p" ${A_input_file})
            if (( i % 2 == 1 )); then
                echo "$line" >> ${A_output_file}
            else
                echo "$line" >> ${B_output_file}
            fi
        done

        for ((i=1; i<=256; i++)); do
            line=$(sed -n "${i}p" ${B_input_file})
            if (( i % 2 == 1 )); then
                echo "$line" >> ${A_output_file}
            else
                echo "$line" >> ${B_output_file}
            fi
        done

        rm -rf ${A_input_file}
        rm -rf ${B_input_file}

	if [ "$tpu_sram_ver" = "HIGH_VERSION" ]; then
		A_0_output_file="./c_build/sram/${bl2_file_index}${j}_0.bin.text"
		A_1_output_file="./c_build/sram/${bl2_file_index}${j}_1.bin.text"
		B_0_output_file="./c_build/sram/${bl2_file_index}$((j+1))_0.bin.text"
		B_1_output_file="./c_build/sram/${bl2_file_index}$((j+1))_1.bin.text"
		for ((i=1; i<=256; i++)); do
			# A
			line=$(sed -n "${i}p" ${A_output_file})  # read colume i
			CLEAN_LINE=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

			PART0=${CLEAN_LINE:0:32}
			PART0_PADDED=$(printf "%-32s" "$PART0" | sed 's/ /0/g')

			PART1=${CLEAN_LINE:32:32}
			PART1_PADDED=$(printf "%-32s" "$PART1" | sed 's/ /0/g')

			echo "$PART0_PADDED" >> "$A_1_output_file"
			echo "$PART1_PADDED" >> "$A_0_output_file"

			# B
			line=$(sed -n "${i}p" ${B_output_file})  # read colume i
			CLEAN_LINE=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

			PART0=${CLEAN_LINE:0:32}
			PART0_PADDED=$(printf "%-32s" "$PART0" | sed 's/ /0/g')

			PART1=${CLEAN_LINE:32:32}
			PART1_PADDED=$(printf "%-32s" "$PART1" | sed 's/ /0/g')

			echo "$PART0_PADDED" >> "$B_1_output_file"
			echo "$PART1_PADDED" >> "$B_0_output_file"
		done

		rm -rf ${A_output_file}
		rm -rf ${B_output_file}
	fi
      done

      echo "bl2 end"
      else
        echo "${BL2_BIN} not found!!!"
      fi

      # Process BL31 with Python tool (Real DDR)
      if [ -e ${BMTEST_BIN} ];then
      echo "bmtest start (Real DDR)..."
      echo "bmtest.bin: ${BMTEST_BIN}"
      if [ -e "${PYTHON_SCRIPT}" ]; then
        python3 "${PYTHON_SCRIPT}" "${BMTEST_BIN}" "${BMTEST_ADDR}"
        echo "load_bmtest: $(ls -l load_bmtest)"
        echo "pwd: $(pwd)"
        echo "load_bmtest: $(ls -l ${PWD}/load_bmtest)"
        if [ -d "${PWD}/load_bmtest" ]; then
          find "${PWD}/load_bmtest" -mindepth 1 -maxdepth 1 -exec cp -r {} ./c_build/load_bmtest/ \;
        fi
        if [ -d "${PWD}/script_real_ddr" ]; then
          cp ${PWD}/script_real_ddr/*.tcl ./script
        fi
        # Clean up temporary directories
        rm -rf ${PWD}/load_bmtest ${PWD}/script_real_ddr
      else
        echo "Python script ${PYTHON_SCRIPT} not found!"
      fi
      echo "bmtest end"
      else
        echo "${BMTEST_BIN} not found!!!"
      fi
     
      # Move all generated TCL scripts to script directory
      mv *.tcl ./script/ 2>/dev/null || true
      rm -rf ./workspace

    popd
 
    tar -zcvf build_backdoor_bmtest_file_real_ddr.tgz backdoor/{c_build,script}
    rm -rf backdoor
    md5sum build_backdoor_bmtest_file_real_ddr.tgz
    echo "Real DDR backdoor package created: build_backdoor_bmtest_file_real_ddr.tgz"
  popd
)}

function build_backdoor_bmtest_file_fake_ddr
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bmtest
  local ROM_BIN="/media/cvitek/martin.xuan/edge_sdk/84x6/bl1.bin"
  local BMTEST_BIN="/media/cvitek/martin.xuan/bmtest/cvi_bmtest/cv84x6/out/bmtest.bin"

  pushd "$OUTPUT_DIR"
    if [ -e backdoor ]; then
        rm -rf backdoor
    fi

    if [ -e pld_backdoor_bmtest_fake_ddr.tgz ]; then
        rm -f pld_backdoor_bmtest_fake_ddr.tgz
    fi

    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build/rom,c_build/fake_ddr,script}

      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/reset.tcl ./script
      fi
      if [ -e ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ]; then
        cp ${TOP_DIR}/build/tools/cv184x/pld_tools/ip_proc.sh ./script
      fi

      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      echo "ROM: ${ROM_BIN}"
      dd if=${ROM_BIN} of=./workspace/bootrom_0.bin bs=64k count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_1.bin bs=64k skip=1 count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_2.bin bs=64k skip=2 count=1
      dd if=${ROM_BIN} of=./workspace/bootrom_3.bin bs=64k skip=3 count=1
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_0.bin > ./c_build/rom/bootrom0.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_1.bin > ./c_build/rom/bootrom1.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_2.bin > ./c_build/rom/bootrom2.bin.text
      hexdump -v -e '1/4 "%08x\n"' ./workspace/bootrom_3.bin > ./c_build/rom/bootrom3.bin.text

      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1}" >> reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom2}" >> reload_rom.tcl
      echo "memory -reset {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom3}" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom1} -file ../c_build/rom/bootrom1.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom2} -file ../c_build/rom/bootrom2.bin.text" >> reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_hsperi_sys.u_hsperi_module.ahb_rom.brom3} -file ../c_build/rom/bootrom3.bin.text" >> reload_rom.tcl

      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

      if [ -e ${BMTEST_BIN} ];then
      echo "bmtest start..."
      echo "bmtest.bin: ${BMTEST_BIN}"
      local BMTEST_BIN_TMP=./c_build/fake_ddr/_bmtest.bin.text
#       hexdump -v -e '1/4 "%08x\n"' ${BMTEST_BIN} > ./c_build/fake_ddr/bmtest.bin.text
#       awk '{ printf "%s%s%s%s\n",  substr($0, 7, 2), substr($0, 5, 2), substr($0, 3, 2), substr($0, 1, 2) }' "$BMTEST_BIN_TMP" > "./c_build/fake_ddr/bmtest.bin.text"
#       echo "memory -reset {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram}" >> reload_fake_ddr.tcl
	hexdump -v -e '8/4 "%08x"' -e '"\n"' ${BMTEST_BIN} > "$BMTEST_BIN_TMP"
	awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$BMTEST_BIN_TMP" > "./c_build/fake_ddr/bmtest.bin.text"
      echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/fake_ddr/bmtest.bin.text -start 0x0" >> reload_fake_ddr.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl1.u_fake_ddr_sram.bram} -file ../c_build/fake_ddr/bmtest.bin.text -start 0x0" >> reload_fake_ddr.tcl
      echo "memory -dump %readmemh {u_chip_top.chip_core.A_ddr_sys_0_pr_wrap.u_ddr_chip.fake_lpddrctl0.u_fake_ddr_sram.bram} -file ../c_build/fake_ddr/bmtest.bin.text -start 0x0 -end 0x100" >> dump_fake_ddr.tcl
      rm -rf ${BMTEST_BIN_TMP}
      echo "bmtest end"
      else
        echo "${BMTEST_BIN} not found!!!"
      fi

      mv *.tcl ./script

      popd
    tar -zcvf pld_backdoor_bmtest_fake_ddr.tgz backdoor/{c_build,script}
    rm -rf backdoor
    md5sum pld_backdoor_bmtest_fake_ddr.tgz
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
      chunk_size=8192 #8KB
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
        # d256 w256
        # [255-224] [223-192] [191-160] [159-128] [127-96] [95-64] [63-32] [31-0]
        hexdump -v -e '8/4 "%08x"' -e '"\n"' "$output_file" > "$tmp_text_output_file"
        awk '{ printf "%s%s%s%s%s%s%s%s\n", substr($1,57,8), substr($1,49,8), substr($1,41,8), substr($1,33,8), substr($1,25,8), substr($1,17,8), substr($1,9,8), substr($1,1,8) }' "$tmp_text_output_file" > "$text_output_file"
        rm -rf "$tmp_text_output_file"


      # 4 array 2lane 16bank 2slice
      local bank=$(expr $i / 2)
      local slice=$(expr $i % 2)
      echo "bank ${bank} lane ${lane}"
      echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.gen_array_4[0]"\
	".u_array_wrapper.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[0]"\
	".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]]"\
	".u_lmem_bank.gen_sram_slice[$slice]"\
	".u_ram0.u_mem_u_tpu_lmem_256x256_0_0.uut.mem_core_array}" >> reload_sram.tcl
      echo "memory -reset {u_chip_top.chip_core.A_tpu_sys_pr_wrap.u_tpu_sys_pwr_wrap.u_tpu_sys.u_txp_sys_pr_wrap_0.u_txp_sys_pwr_wrap.u_txp_sys.u_tpu_pr_wrap.u_tpu_pwr_wrap.u_tpu.arrays_grp_left.gen_array_4[0]"\
	".u_array_wrapper.u_array_pr_wrap.u_array_pwr_wrap.u_array_wrap.u_array.u_qlane.gen_multi_lane[0]"\
	".u_lane.lmem.u_lmem_slice.gen_sram_bank[$bank]]"\
	".u_lmem_bank.gen_sram_slice[$slice]"\
	".u_ram0.u_mem_u_tpu_lmem_256x256_0_0.uut.mem_core_array} -file ../c_build/sram/${bl2_file_index}${i}.bin.text" >> reload_sram.tcl

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
  build_backdoor_bmtest_file_real_ddr
else
  build_backdoor_bmtest_file
fi
  build_backdoor_for_linux
)}

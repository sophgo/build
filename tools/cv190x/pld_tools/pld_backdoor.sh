#!/bin/bash
#
# Usage:
#    The common functions for envsetup_soc.sh
#
# Partition generation :
# pack_backdoor -> pack (bl1/bmtest) for PLD backdoor.
#

USE_BMTEST=no
USE_LINUX=yes

function print_error()
{
  printf "\e[1;31;47m\tERROR\t %s \e[0m\n" "$1"
}

function print_notice()
{
  printf "\e[1;34;47m %s \e[0m\n" "$1"
}

function build_backdoor_bmtest_file
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  # bl1 --> bl2(ddr init) --> bmtest(ddr)

  local ROM_BIN="${TOOLS_PATH}/cv190x/pld_tools/bl1.bin"
  local BL2_BIN="${TOOLS_PATH}/cv190x/pld_tools/bl2.bin"
  local BMTEST_BIN="/media/cvitek/aoxing.wang/cvi_bmtest/phobos3/out/bmtest.bin"
  local BMTEST_ADDR=0x80000000
  #local DATA_BIN="${TOP_DIR}/data.bin"
  #local DATA_ADDR=0x81000000
  echo "ROM_BIN:${ROM_BIN}"
  pushd "$OUTPUT_DIR"
    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build/rom,c_build/sram,c_build/ddr,script}
      if [ -e ${TOP_DIR}/build/tools/cv190x/pld_tools/ip_proc.sh ]; then
        cp ${TOP_DIR}/build/tools/cv190x/pld_tools/ip_proc.sh ./script
      fi

      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      hexdump -v -e '1/4 "%08x\n"' ${ROM_BIN} > ./c_build/rom/bootrom0.bin.text
      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

if [ -e ${BL2_BIN} ];then
    echo "============================ BL2: load bl2.bin to VC SRAM ============================="
    
    # 获取文件大小（字节）
    file_size=$(wc -c < ${BL2_BIN})
    split_threshold=$((40 * 1024))  # 40KB
    
    # 创建临时目录
    mkdir -p $OUTPUT_DIR/temp
    tmp_dir=$OUTPUT_DIR/temp
    
    if [ $file_size -gt $split_threshold ]; then
        echo "BL2_BIN size exceeds 40KB, splitting into two parts..."
        
        # 分割文件
        split -b ${split_threshold} ${BL2_BIN} ${tmp_dir}/bl2_split_
        
        # 重命名分割后的文件
        mv ${tmp_dir}/bl2_split_aa ${tmp_dir}/bl2_0.bin
        mv ${tmp_dir}/bl2_split_ab ${tmp_dir}/bl2_1.bin
        
        # 处理第一个分割文件 (40KB)
        pushd $TOP_DIR/build/tools/cv190x/pld_tools
        bl2_0_file_name0="bl2_0_0.text"
        bl2_0_file_name1="bl2_0_1.text"
        python3 splite_bl2.py ${tmp_dir}/bl2_0.bin ${bl2_0_file_name0} ${bl2_0_file_name1}
        popd
        
        # 处理第二个分割文件 (剩余部分)
        pushd $TOP_DIR/build/tools/cv190x/pld_tools
        bl2_1_file_name0="bl2_1_0.text"
        bl2_1_file_name1="bl2_1_1.text"
        python3 splite_bl2.py ${tmp_dir}/bl2_1.bin ${bl2_1_file_name0} ${bl2_1_file_name1}
        popd
        
        # 生成TCL命令
        pushd $TOP_DIR/build/tools/cv190x/pld_tools
        echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf0.h264_lbuf0.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_0.MEMORY} -file ../c_build/sram/${bl2_0_file_name0}" >> reload_sram.tcl
        echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf0.h264_lbuf0.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_1.MEMORY} -file ../c_build/sram/${bl2_0_file_name1}" >> reload_sram.tcl
        echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf1.h264_lbuf1.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_0.MEMORY} -file ../c_build/sram/${bl2_1_file_name0}" >> reload_sram.tcl
        echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf1.h264_lbuf1.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_1.MEMORY} -file ../c_build/sram/${bl2_1_file_name1}" >> reload_sram.tcl
        
        # 移动生成的文件
        mv ${bl2_0_file_name0} ${bl2_0_file_name1} ${bl2_1_file_name0} ${bl2_1_file_name1} $OUTPUT_DIR/backdoor/c_build/sram
        mv reload_sram.tcl $OUTPUT_DIR/backdoor/script
        popd
        
    else
        echo "BL2_BIN size is within 40KB, processing as single file..."
        pushd $TOP_DIR/build/tools/cv190x/pld_tools
        bl2_file_name0="bl2_0.text"
        bl2_file_name1="bl2_1.text"
        python3 splite_bl2.py ${BL2_BIN} ${bl2_file_name0} ${bl2_file_name1}
        
        # 生成TCL命令
        echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf0.h264_lbuf0.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_0.MEMORY} -file ../c_build/sram/${bl2_file_name0}" >> reload_sram.tcl
        echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf0.h264_lbuf0.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_1.MEMORY} -file ../c_build/sram/${bl2_file_name1}" >> reload_sram.tcl
        
        # 移动生成的文件
        mv ${bl2_file_name0} ${bl2_file_name1} $OUTPUT_DIR/backdoor/c_build/sram
        mv reload_sram.tcl $OUTPUT_DIR/backdoor/script
        popd
    fi
    
    # 清理临时文件
    rm -rf ${tmp_dir}
else
    echo "${BL2_BIN} not found!!!"
fi

      if [ -e ${BMTEST_BIN} ];then
      echo "============================ bmtest: load bmtest.bin to ddr offset: ${BMTEST_ADDR} ============================="

      local bl3_file_name="${BMTEST_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv190x/pld_tools/
      python3 real_ddr_axi2dram.py ${BMTEST_BIN} ${BMTEST_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "bmtest.bin not found!!!"
      fi

      if [ -e ${DATA_BIN} ];then
      echo "============================ data: load data.bin to ddr offset: ${DATA_ADDR} ============================="
      
      local data_file_name="${DATA_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv190x/pld_tools/
      python3 real_ddr_axi2dram.py ${DATA_BIN} ${DATA_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "bmtest.bin not found!!!"
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

  local ROM_BIN="${TOOLS_PATH}/cv190x/pld_tools/bl1.bin"
  local BL2_BIN="${TOOLS_PATH}/cv190x/pld_tools/bl2.bin"
  local BL31_ADDR=0x80000000
  local BL31_BIN="${OUTPUT_DIR}/fw_payload_uboot.bin"
  local DATA_BIN="${OUTPUT_DIR}/ramboot.itb"
  local DATA_ADDR=0x90000000

  pushd "$OUTPUT_DIR"
    command mkdir -p backdoor
    pushd backdoor
      rm -rf ./workspace
      rm -rf ./c_build/rom
      rm -rf ./c_build/sram
      rm -rf ./c_build/ddr
      rm -rf ./script
      command mkdir -p {workspace,c_build/rom,c_build/sram,c_build/ddr,script}

      if [ -e ${ROM_BIN} ]; then
      echo "rom start..."
      hexdump -v -e '1/4 "%08x\n"' ${ROM_BIN} > ./c_build/rom/bootrom0.bin.text
      echo "memory -reset {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0}" > reload_rom.tcl
      echo "memory -load %readmemh {u_chip_top.chip_core.hsperi_system.u_hsperi_module.ahb_rom.brom0} -file ../c_build/rom/bootrom0.bin.text" >> reload_rom.tcl
      echo "rom end"
      else
        echo "${ROM_BIN} not found!!!"
      fi

  if [ -e ${BL2_BIN} ];then
      echo "============================ BL2: load bl2.bin to VC SRAM ============================="
      
      # 获取文件大小（字节）
      file_size=$(wc -c < ${BL2_BIN})
      split_threshold=$((40 * 1024))  # 40KB
      
      # 创建临时目录
      mkdir -p $OUTPUT_DIR/temp
      tmp_dir=$OUTPUT_DIR/temp
      
      if [ $file_size -gt $split_threshold ]; then
          echo "BL2_BIN size exceeds 40KB, splitting into two parts..."
          
          # 分割文件
          split -b ${split_threshold} ${BL2_BIN} ${tmp_dir}/bl2_split_
          
          # 重命名分割后的文件
          mv ${tmp_dir}/bl2_split_aa ${tmp_dir}/bl2_0.bin
          mv ${tmp_dir}/bl2_split_ab ${tmp_dir}/bl2_1.bin
          
          # 处理第一个分割文件 (40KB)
          pushd $TOP_DIR/build/tools/cv190x/pld_tools
          bl2_0_file_name0="bl2_0_0.text"
          bl2_0_file_name1="bl2_0_1.text"
          python3 splite_bl2.py ${tmp_dir}/bl2_0.bin ${bl2_0_file_name0} ${bl2_0_file_name1}
          popd
          
          # 处理第二个分割文件 (剩余部分)
          pushd $TOP_DIR/build/tools/cv190x/pld_tools
          bl2_1_file_name0="bl2_1_0.text"
          bl2_1_file_name1="bl2_1_1.text"
          python3 splite_bl2.py ${tmp_dir}/bl2_1.bin ${bl2_1_file_name0} ${bl2_1_file_name1}
          popd
          
          # 生成TCL命令
          pushd $TOP_DIR/build/tools/cv190x/pld_tools
          echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf0.h264_lbuf0.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_0.MEMORY} -file ../c_build/sram/${bl2_0_file_name0}" >> reload_sram.tcl
          echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf0.h264_lbuf0.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_1.MEMORY} -file ../c_build/sram/${bl2_0_file_name1}" >> reload_sram.tcl
          echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf1.h264_lbuf1.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_0.MEMORY} -file ../c_build/sram/${bl2_1_file_name0}" >> reload_sram.tcl
          echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf1.h264_lbuf1.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_1.MEMORY} -file ../c_build/sram/${bl2_1_file_name1}" >> reload_sram.tcl
          
          # 移动生成的文件
          mv ${bl2_0_file_name0} ${bl2_0_file_name1} ${bl2_1_file_name0} ${bl2_1_file_name1} $OUTPUT_DIR/backdoor/c_build/sram
          mv reload_sram.tcl $OUTPUT_DIR/backdoor/script
          popd
          
      else
          echo "BL2_BIN size is within 40KB, processing as single file..."
          pushd $TOP_DIR/build/tools/cv190x/pld_tools
          bl2_file_name0="bl2_0.text"
          bl2_file_name1="bl2_1.text"
          python3 splite_bl2.py ${BL2_BIN} ${bl2_file_name0} ${bl2_file_name1}
          
          # 生成TCL命令
          echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf0.h264_lbuf0.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_0.MEMORY} -file ../c_build/sram/${bl2_file_name0}" >> reload_sram.tcl
          echo "memory -load %readmemh {u_chip_top.chip_core.A_vc_pr_wrap.A_vc_pwr_wrap.vc_sys.vc_sys_core.h264e_top.u_coda980_msvc_lb_top.en_shd_h264_lbuf0.h264_lbuf0.u_spsram1296x256e8_wrap.u_mem_u_sram_0_wsp_1.MEMORY} -file ../c_build/sram/${bl2_file_name1}" >> reload_sram.tcl
          
          # 移动生成的文件
          mv ${bl2_file_name0} ${bl2_file_name1} $OUTPUT_DIR/backdoor/c_build/sram
          mv reload_sram.tcl $OUTPUT_DIR/backdoor/script
          popd
      fi
      
      # 清理临时文件
      rm -rf ${tmp_dir}
  else
      echo "${BL2_BIN} not found!!!"
  fi

      if [ -e ${BL31_BIN} ];then
      echo "============================ BL31: load bl31.bin to ddr offset: ${BL31_ADDR} ============================="

      pushd $TOP_DIR/build/tools/cv190x/pld_tools/
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
      pushd $TOP_DIR/build/tools/cv190x/pld_tools/
      python3 real_ddr_axi2dram.py ${DATA_BIN} ${DATA_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "${DATA_BIN} not found!!!"
      fi

      if [ -e ${DATA1_BIN} ];then
      echo "============================ data1: load data1.bin to ddr offset: ${DATA1_ADDR} ============================="
      
      local data_file_name="${DATA1_BIN%.bin}"
      pushd $TOP_DIR/build/tools/cv190x/pld_tools/
      python3 real_ddr_axi2dram.py ${DATA1_BIN} ${DATA1_ADDR}
      mv *.text $OUTPUT_DIR/backdoor/c_build/ddr
      mv *.tcl $OUTPUT_DIR/backdoor/script
      popd
      else
        echo "${DATA1_BIN} not found!!!"
      fi
      mv *.tcl ./script
    popd
    tar -zcvf pld_backdoor_linux.tgz backdoor/{c_build,script}
    md5sum pld_backdoor_linux.tgz
  popd
)}

function pack_backdoor
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  if [ "$USE_BMTEST" = "yes" ]; then
    build_backdoor_bmtest_file
  fi
  if [ "$USE_LINUX" = "yes" ]; then
    build_backdoor_for_linux
  fi
)}

# pack_backdoor

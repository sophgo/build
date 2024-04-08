#!/bin/bash
#
# Usage:
#    The common functions for envsetup_soc.sh
#
# Partition generation :
# pack_backdoor -> pack (bl1/bl2/bl31/uboot/kernel/ramdisk/dtb) for PLD backdoor.
#

function build_backdoor_quickboot_file
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  CHIP_ARCH_LOWER=$(echo "${CHIP_ARCH}" | tr A-Z a-z)

  local TFA_BIN="$COMMON_TOOLS_PATH/pld_tool/TFA/bl*.bin"
  local UBOOT_BIN="$UBOOT_PATH/build/$PROJECT_FULLNAME/u-boot.bin"
  local IMAGE_BIN="$RAMDISK_PATH/build/$PROJECT_FULLNAME/workspace/Image"
  local DTB_BIN="$RAMDISK_PATH/build/$PROJECT_FULLNAME/workspace/${PROJECT_FULLNAME}.dtb"
  local RAMDISK_BIN="$RAMDISK_PATH/build/$PROJECT_FULLNAME/workspace/boot.cpio.gz.img"

  local PLD_SRAM_MEMTOOL="$COMMON_TOOLS_PATH/pld_tool/sophon_pld_sram_memtool_v1"
  local PLD_DDR_MEMTOOL="$COMMON_TOOLS_PATH/pld_tool/sophon_pld_ddr_mem_tool"

  pushd "$OUTPUT_DIR"
    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build,script}
      # copy tfa bin(bl1/bl2/bl31)
      cp -rf ${TFA_BIN} ./

      local bl2_size=`ls -l ./bl2.bin | awk '{print $5}'`
      ${PLD_SRAM_MEMTOOL} 0 ./bl2.bin $bl2_size bl2 0 ../c_build/ 1
      
      local bl31_size=`ls -l ./bl31.bin | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ./bl31.bin $bl31_size bl31 0 ../c_build/ 1
      mv ./reload_ddr.tcl ./workspace/reload_ddr_tmp.tcl
	  echo "###bl31 end###" >> ./workspace/reload_ddr_tmp.tcl

      local uboot_size=`ls -l ${UBOOT_BIN} | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ${UBOOT_BIN} $uboot_size uboot 0x40000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "###u-boot end###" >> ./workspace/reload_ddr_tmp.tcl

      local image_size=`ls -l ${IMAGE_BIN} | awk '{print $5}'`
	  ${PLD_DDR_MEMTOOL} 0 ${IMAGE_BIN} $image_size image 0x4000000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "###Image end###" >> ./workspace/reload_ddr_tmp.tcl

      local ramdisk_size=`ls -l ${RAMDISK_BIN} | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ${RAMDISK_BIN} $ramdisk_size ramdisk 0x5000000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "###ramdisk end###" >> ./workspace/reload_ddr_tmp.tcl

      local dtb_size=`ls -l ${DTB_BIN} | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ${DTB_BIN} $dtb_size dtb 0x6000000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "###dtb end###" >> ./workspace/reload_ddr_tmp.tcl

      mv ./workspace/reload_ddr_tmp.tcl ./reload_ddr.tcl
      rm -rf ./workspace
      mv *.h ./c_build
      mv *.tcl ./script

    popd
    tar -zcvf pld_backdoor_realddr_quickBoot.tgz backdoor/{c_build,script}
    rm -rf backdoor
  popd
)}

function build_backdoor_normalboot_file
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  local TFA_BIN="$COMMON_TOOLS_PATH/pld_tool/TFA/bl*.bin"
  local UBOOT_BIN="$UBOOT_PATH/build/$PROJECT_FULLNAME/u-boot.bin"
  local BOOTITB_BIN="$OUTPUT_DIR/boot.itb"
  # local BOOTITB_BIN="$TOP_DIR/install/soc_sophon_palladium_c906/fw_payload_linux.bin"

  local PLD_SRAM_MEMTOOL="$COMMON_TOOLS_PATH/pld_tool/sophon_pld_sram_memtool_v1"
  local PLD_DDR_MEMTOOL="$COMMON_TOOLS_PATH/pld_tool/sophon_pld_ddr_mem_tool"

  pushd "$OUTPUT_DIR"
    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build,script}
      # copy Image(bl1/bl2/bl31/u-boot.bin/Image/dtb/boot.cpio.gz.img/boot.itb)
      cp -rf ${TFA_BIN} ./
      # cp $TOP_DIR/rom/build/sophon/bl1.bin ./
      # cp $TOP_DIR/fsbl/build/sophon_palladium/bl2.bin ./

      local bl2_size=`ls -l ./bl2.bin | awk '{print $5}'`
      ${PLD_SRAM_MEMTOOL} 0 ./bl2.bin $bl2_size bl2 0 ../c_build/ 1
      
      local bl31_size=`ls -l ./bl31.bin | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ./bl31.bin $bl31_size bl31 0 ../c_build/ 1
      mv ./reload_ddr.tcl ./workspace/reload_ddr_tmp.tcl
	  echo "###bl31 end###" >> ./workspace/reload_ddr_tmp.tcl

      local uboot_size=`ls -l ${UBOOT_BIN} | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ${UBOOT_BIN} $uboot_size uboot 0x40000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "###u-boot end###" >> ./workspace/reload_ddr_tmp.tcl

      local bootitb_size=`ls -l ${BOOTITB_BIN} | awk '{print $5}'`
	  ${PLD_DDR_MEMTOOL} 0 ${BOOTITB_BIN} $bootitb_size bootitb 0x4000000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "###Bootitb end###" >> ./workspace/reload_ddr_tmp.tcl

      mv ./workspace/reload_ddr_tmp.tcl ./reload_ddr.tcl
      rm -rf ./workspace
      mv *.h ./c_build
      mv *.tcl ./script

    popd
    tar -zcvf pld_backdoor_realddr_normalBoot.tgz backdoor/{c_build,script}
    rm -rf backdoor
  popd
)}

function build_backdoor_c906_file
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  local TFA_BIN="$COMMON_TOOLS_PATH/pld_tool/TFA/bl*.bin"
  local UBOOT_BIN="$UBOOT_PATH/build/$PROJECT_FULLNAME/u-boot.bin"
  local BOOTITB_BIN="$TOP_DIR/install/soc_sophon_palladium_c906/fw_payload_linux.bin"

  local PLD_SRAM_MEMTOOL="$COMMON_TOOLS_PATH/pld_tool/sophon_pld_sram_memtool_v1"
  local PLD_DDR_MEMTOOL="$COMMON_TOOLS_PATH/pld_tool/sophon_pld_ddr_mem_tool"

  pushd "$OUTPUT_DIR"
    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build,script}
      # copy Image(bl1/bl2/bl31/u-boot.bin/Image/dtb/boot.cpio.gz.img/boot.itb)
      cp -rf ${TFA_BIN} ./
      cp $TOP_DIR/rom/build/sophon/bl1.bin ./
      cp $TOP_DIR/fsbl/build/sophon_palladium/bl2.bin ./

      local bl2_size=`ls -l ./bl2.bin | awk '{print $5}'`
      ${PLD_SRAM_MEMTOOL} 0 ./bl2.bin $bl2_size bl2 0 ../c_build/ 1
      
      local bl31_size=`ls -l ./bl31.bin | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ./bl31.bin $bl31_size bl31 0 ../c_build/ 1
      mv ./reload_ddr.tcl ./workspace/reload_ddr_tmp.tcl
	  echo "###bl31 end###" >> ./workspace/reload_ddr_tmp.tcl

      local uboot_size=`ls -l ${UBOOT_BIN} | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ${UBOOT_BIN} $uboot_size uboot 0x40000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "###u-boot end###" >> ./workspace/reload_ddr_tmp.tcl

      local bootitb_size=`ls -l ${BOOTITB_BIN} | awk '{print $5}'`
	  ${PLD_DDR_MEMTOOL} 0 ${BOOTITB_BIN} $bootitb_size bootitb 0x4000000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "###Bootitb end###" >> ./workspace/reload_ddr_tmp.tcl

      mv ./workspace/reload_ddr_tmp.tcl ./reload_ddr.tcl
      rm -rf ./workspace
      mv *.h ./c_build
      mv *.tcl ./script

    popd
    tar -zcvf pld_backdoor_realddr_c906Boot.tgz backdoor/{c_build,script}
    rm -rf backdoor
  popd
)}

function build_backdoor_bmtest_file
{(
  print_notice "Run ${FUNCNAME[0]}() function"

  local TFA_BIN="$COMMON_TOOLS_PATH/pld_tool/TFA/bl*.bin"
  # local BMTEST_A53_BIN="$TOP_DIR/cvi_bmtest/sophon/out/sophon_PALLADIUM_spi_nand.bin"
  # local BMTEST_A53_BIN="$TOP_DIR/cvi_bmtest/sophon/out/sophon_PALLADIUM_riscv.bin"
  local BMTEST_A53_BIN="$TOP_DIR/cvi_bmtest/sophon/bmtest_a53.bin"
  local BMTEST_C906_BIN="$TOP_DIR/cvi_bmtest/sophon/bmtest_c906.bin"
  local BMTEST_SCALAR0_BIN="$TOP_DIR/cvi_bmtest/sophon/bmtest_scalar0.bin"
  local BMTEST_SCALAR1_BIN="$TOP_DIR/cvi_bmtest/sophon/bmtest_scalar1.bin"

  local PLD_SRAM_MEMTOOL="$COMMON_TOOLS_PATH/pld_tool/sophon_pld_sram_memtool_v1"
  local PLD_DDR_MEMTOOL="$COMMON_TOOLS_PATH/pld_tool/sophon_pld_ddr_mem_tool"

  pushd "$OUTPUT_DIR"
    command mkdir -p backdoor
    pushd backdoor
      command mkdir -p {workspace,c_build,script}
      # copy Image(bl1/bl2/bl31/u-boot.bin/Image/dtb/boot.cpio.gz.img/boot.itb)
      cp -rf ${TFA_BIN} ./
      # cp $TOP_DIR/rom/build/sophon/bl1.bin ./
      # cp $TOP_DIR/fsbl/build/sophon_palladium/bl2.bin ./

      local bl2_size=`ls -l ./bl2.bin | awk '{print $5}'`
      ${PLD_SRAM_MEMTOOL} 0 ./bl2.bin $bl2_size bl2 0 ../c_build/ 1

      local bl31_size=`ls -l ./bl31.bin | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ./bl31.bin $bl31_size bl31 0 ../c_build/ 1
      mv ./reload_ddr.tcl ./workspace/reload_ddr_tmp.tcl
	  echo "### bl31 end ###" >> ./workspace/reload_ddr_tmp.tcl

      local bmtest_size=`ls -l ${BMTEST_A53_BIN} | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ${BMTEST_A53_BIN} $bmtest_size bmtest_a53 0x40000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "### bmtest_a53 end ###" >> ./workspace/reload_ddr_tmp.tcl

      local bmtest_size=`ls -l ${BMTEST_C906_BIN} | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ${BMTEST_C906_BIN} $bmtest_size bmtest_c906 0x8040000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "### bmtest_c906 end ###" >> ./workspace/reload_ddr_tmp.tcl

      local bmtest_size=`ls -l ${BMTEST_SCALAR0_BIN} | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ${BMTEST_SCALAR0_BIN} $bmtest_size bmtest_scalar0 0x10040000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "### bmtest_scalar0 end ###" >> ./workspace/reload_ddr_tmp.tcl

      local bmtest_size=`ls -l ${BMTEST_SCALAR1_BIN} | awk '{print $5}'`
      ${PLD_DDR_MEMTOOL} 0 ${BMTEST_SCALAR1_BIN} $bmtest_size bmtest_scalar1 0x18040000 ../c_build/ 1
      cat ./reload_ddr.tcl >> ./workspace/reload_ddr_tmp.tcl
      echo "### bmtest_scalar1 end ###" >> ./workspace/reload_ddr_tmp.tcl

      mv ./workspace/reload_ddr_tmp.tcl ./reload_ddr.tcl
      rm -rf ./workspace
      mv *.h ./c_build
      mv *.tcl ./script

    popd
    tar -zcvf pld_backdoor_realddr_bmtest.tgz backdoor/{c_build,script}
    rm -rf backdoor
  popd
)}

function pack_backdoor
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  build_backdoor_quickboot_file
  build_backdoor_normalboot_file
  build_backdoor_c906_file
  build_backdoor_bmtest_file
)}

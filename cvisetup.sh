#!/bin/bash
function _build_default_env()
{
  # Please keep these default value!!!
  BRAND=${BRAND:-cvitek}
  DEBUG=${DEBUG:-0}
  RELEASE_VERSION=${RELEASE_VERSION:-0}
  BUILD_VERBOSE=${BUILD_VERBOSE:-1}
  ATF_BL32=${ATF_BL32:-1}
  UBOOT_VBOOT=${UBOOT_VBOOT:-0}
  COMPRESSOR=${COMPRESSOR:-xz}
  COMPRESSOR_UBOOT=${COMPRESSOR_UBOOT:-lzma} # or none to disable
  MULTI_PROCESS_SUPPORT=${MULTI_PROCESS_SUPPORT:-0}
  ENABLE_BOOTLOGO=${ENABLE_BOOTLOGO:-0}
  TPU_REL=${TPU_REL:-0} # TPU release build
  SENSOR=${SENSOR:-sony_imx327}
}

function gettop()
{
  local TOPFILE=build/cvisetup.sh
  if [ -n "$TOP" -a -f "$TOP/$TOPFILE" ] ; then
    # The following circumlocution ensures we remove symlinks from TOP.
    (cd "$TOP"; PWD= /bin/pwd)
  else
    if [ -f $TOPFILE ] ; then
      # The following circumlocution (repeated below as well) ensures
      # that we record the true directory name and not one that is
      # faked up with symlink names.
      PWD= /bin/pwd
    else
      local HERE=$PWD
      T=
      while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        \cd ..
	T=$(PWD= /bin/pwd -P)
      done
      \cd "$HERE"
      if [ -f "$T/$TOPFILE" ]; then
        echo "$T"
      fi
    fi
  fi
}

function _build_fsbl_env()
{
  export FSBL_PATH
}

function build_fsbl()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_uboot_env
  _build_opensbi_env
  cd "$BUILD_PATH" || return
  make fsbl-build
)}

function clean_fsbl()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_uboot_env
  cd "$BUILD_PATH" || return
  make fsbl-clean
)}

function _build_atf_env()
{
  export ATF_BL32 FAKE_BL31_32
}

function build_atf()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_atf_env
  cd "$BUILD_PATH" || return
  make arm-trusted-firmware
)}

function clean_atf()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_atf_env
  cd "$BUILD_PATH" || return
  make arm-trusted-firmware-clean
)}

function _build_uboot_env()
{
  _build_atf_env
  _build_fsbl_env
  export UBOOT_OUTPUT_FOLDER IMGTOOL_PATH FLASH_PARTITION_XML FIP_BIN_PATH
  export UBOOT_VBOOT RELEASE_VERSION ENABLE_BOOTLOGO STORAGE_TYPE COMPRESSOR_UBOOT
  export PANEL_TUNING_PARAM PANEL_LANE_NUM_TUNING_PARAM PANEL_LANE_SWAP_TUNING_PARAM
}

function build_fip_pre()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_uboot_env
  cd "$BUILD_PATH" || return
  make fip-pre-merge
)}

function build_rtos()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  cd "$BUILD_PATH" || return
  make rtos
)}

function clean_rtos()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  cd "$BUILD_PATH" || return
  make rtos-clean
)}

function menuconfig_uboot()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_uboot_env
  cd "$BUILD_PATH" || return
  make u-boot-menuconfig || return "$?"
)}

function _link_uboot_logo()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  cd "$BUILD_PATH" || return
  if [[ x"${PANEL_TUNING_PARAM}" =~ x"I80" ]]; then
    ln -sf "$COMMON_TOOLS_PATH"/bootlogo/logo_320x240.BMP "$COMMON_TOOLS_PATH"/bootlogo/logo.jpg
  fi
)}

function build_uboot()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_uboot_env
  _build_opensbi_env
  _link_uboot_logo

  cd "$BUILD_PATH" || return
  [[ "$CHIP_ARCH" == CV182X ]] || [[ "$CHIP_ARCH" == CV183X ]] && \
    cp -f "$OUTPUT_DIR"/fip_pre/fip_pre_${ATF_KEY_SEL}.bin \
    "$OUTPUT_DIR"/fip_pre/fip_pre.bin

  make u-boot
)}

function build_uboot_env_tools()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_uboot_env
  cd "$BUILD_PATH" || return
  make u-boot-env-tools
)}

function clean_uboot()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_uboot_env
  cd "$BUILD_PATH" || return
  make u-boot-clean
)}

function _build_kernel_env()
{
  export KERNEL_OUTPUT_FOLDER RAMDISK_OUTPUT_FOLDER SYSTEM_OUT_DIR
}

function menuconfig_kernel()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_kernel_env
  cd "$BUILD_PATH" || return
  make kernel-menuconfig || return "$?"
)}

function setconfig_kernel()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_kernel_env
  cd "$BUILD_PATH" || return
  make kernel-setconfig "SCRIPT_ARG=$1" || return "$?"
)}

# shellcheck disable=SC2120
function build_kernel()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_kernel_env
  cd "$BUILD_PATH" || return
  make kernel || return "$?"

  # generate boot.itb image.
  if [[ ${1} != noitb ]]; then
    pack_boot || return "$?"
  fi
)}

function clean_kernel()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_kernel_env
  cd "$BUILD_PATH" || return
  make kernel-clean
)}

function build_bld()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  cd "$BUILD_PATH" || return
  make bld
)}

function clean_bld()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  cd "$BUILD_PATH" || return
  make bld-clean
)}

function _build_middleware_env()
{
  export MULTI_PROCESS_SUPPORT
}

function build_middleware()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_middleware_env
  cd "$BUILD_PATH" || return

  make "$ROOTFS_DIR"

  mkdir -p "$SYSTEM_OUT_DIR"/usr/bin
  mkdir -p "$SYSTEM_OUT_DIR"/usr/lib
  mkdir -p "$SYSTEM_OUT_DIR"/lib

  pushd $MW_PATH
    rm -rf lib
    if [ -d $(echo ${CHIP_ARCH} | tr A-Z a-z)/lib_"$SDK_VER" ];
    then
        ln -s $(echo ${CHIP_ARCH} | tr A-Z a-z)/lib_"$SDK_VER" lib
    else
        ln -s lib_"$SDK_VER" lib
    fi

    if [ -d $(echo ${CHIP_ARCH} | tr A-Z a-z)/ko ];
    then
        rm -rf ko
        ln -s $(echo ${CHIP_ARCH} | tr A-Z a-z)/ko ko
    fi
  popd

  pushd "$MW_PATH"/component/isp
    make all || return "$?"
  popd

  pushd "$MW_PATH"/sample
    make all || return "$?"
    find ./ -type f \( -iname "sample_*" ! -iname "*.*" \) -exec cp '{}' $SYSTEM_OUT_DIR/usr/bin \;
  popd

  # copy mw lib
  cp -af "$MW_PATH"/lib/*.so*  "$SYSTEM_OUT_DIR"/usr/lib
  cp -af "$MW_PATH"/lib/3rd/*.so* "$SYSTEM_OUT_DIR"/usr/lib
  # copy libsophon lib
  cp -rf "$MW_PATH"/lib/libsophon-0.4.9  "$SYSTEM_OUT_DIR"/usr/lib/
  # copy ko
  mkdir -p "$SYSTEM_OUT_DIR"/ko
  cp -af "$MW_PATH"/ko/* "$SYSTEM_OUT_DIR"/ko/

  # add sdk version
  echo "SDK_VERSION=${SDK_VER}" > "$SYSTEM_OUT_DIR"/sdk-release
)}


function clean_middleware()
{
  print_notice "Run ${FUNCNAME[0]}() function "
  pushd "$MW_PATH"/sample
  make clean
  popd
  pushd "$MW_PATH"/component/isp
  make clean
  popd
}

function build_bm1688_sdk {
  pushd ${TPU_SDK_PATH}
  cp -af lib/*.so*  "$SYSTEM_OUT_DIR"/lib/
  popd
}

function clean_ramdisk()
{
  rm -rf "${RAMDISK_PATH:?}"/"$RAMDISK_OUTPUT_BASE"
  rm -rf "$SYSTEM_OUT_DIR"
  rm -rf "$ROOTFS_DIR"
}

UPDATE_TYPES=(
sdcard
tftp
)

function revert_package()
{
  SCRIPTS_DIR=${TOP_DIR}/build/scripts/
  mkdir -p $OUTPUT_DIR/package_update/update/sdcard
  mkdir -p $OUTPUT_DIR/package_edge
  cp -r $SCRIPTS_DIR/revert_package.sh $OUTPUT_DIR/package_update/update/sdcard
  sdcard_file="$OUTPUT_DIR/sdcard.tgz"

  if [ -f "$sdcard_file" ]; then
    echo "the sdcard.tgz exists."
    pushd $OUTPUT_DIR
    tar -zxf sdcard.tgz -m -C ./package_update/
    cp -r ./package_update/sdcard/* ./package_update/update/sdcard/
    cp -r ./package_update/sdcard/*.bin $OUTPUT_DIR/package_edge/
    cd ./package_update/update/sdcard
    ./revert_package.sh boot data rootfs rootfs_rw recovery

    cd ../
    sudo rm -rf ./*.tgz
    mv ./sdcard/*.tgz ./
    sudo rm -rf ./sdcard
    cp -r ./* $OUTPUT_DIR/package_edge/
    popd
    echo "revert package finished!"
  else
    echo "sdcard.tgz does not exist."
    echo "please copy sdcard.tgz to ${OUTPUT_DIR}/ and try again."
  fi
}

function build_update()
{
  SCRIPTS_DIR=${TOP_DIR}/build/scripts/

  for i in ${UPDATE_TYPES[@]}
  do
    if [ "$i" == "$1" ]; then
      local UPDATE_TYPE=$1
    fi
  done
  if [ -z "$UPDATE_TYPE" ]; then
    echo please specify an update type:
    for i in ${UPDATE_TYPES[@]}
    do
      echo -e "\t$i"
    done
    return
  fi

  pushd $SCRIPTS_DIR/
  if [ ! -e ./mk_gpt ]; then
    pushd mk-gpt
    make
    popd
  fi
  echo packing update image...

    ./bm_make_package.sh $UPDATE_TYPE ./partition32G.xml "$OUTPUT_DIR"/package_edge
  popd

  pushd $OUTPUT_DIR/package_edge/$1
  cp $SCRIPTS_DIR/local_update.sh .
  md5sum * > md5.txt
  popd

}

function build_all()
{
  # build bsp
  build_uboot || return $?
  build_kernel || return $?
  build_middleware || return $?
  if [ "$TPU_REL" = 1 ]; then
    build_bm1688_sdk || return $?
  fi
  pack_access_guard_turnkey_app || return $?
  pack_ipc_turnkey_app || return $?
  pack_boot || return $?
  pack_cfg || return $?
  pack_rootfs || return $?
  pack_data
  pack_system || return $?
  copy_tools
  pack_upgrade
}

function clean_all()
{
  clean_uboot
  clean_kernel
  clean_ramdisk
  clean_middleware
}

# shellcheck disable=SC2120
function envs_sdk_ver()
{
  if [ -n "$1" ]; then
    SDK_VER="$1"
  fi

  if [ "$SDK_VER" = 64bit ]; then
    CROSS_COMPILE="$CROSS_COMPILE_64"
    CROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_64"
    SYSROOT_PATH="$SYSROOT_PATH_64"
  elif [ "$SDK_VER" = 32bit ]; then
    CROSS_COMPILE="$CROSS_COMPILE_32"
    CROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_32"
    SYSROOT_PATH="$SYSROOT_PATH_32"
  elif [ "$SDK_VER" = uclibc ]; then
    CROSS_COMPILE="$CROSS_COMPILE_UCLIBC"
    CROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_UCLIBC"
    SYSROOT_PATH="$SYSROOT_PATH_UCLIBC"
  elif [ "$SDK_VER" = glibc_riscv64 ]; then
    CROSS_COMPILE="$CROSS_COMPILE_GLIBC_RISCV64"
    CROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_GLIBC_RISCV64"
    SYSROOT_PATH="$SYSROOT_PATH_GLIBC_RISCV64"
  elif [ "$SDK_VER" = musl_riscv64 ]; then
    CROSS_COMPILE="$CROSS_COMPILE_MUSL_RISCV64"
    CROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_MUSL_RISCV64"
    SYSROOT_PATH="$SYSROOT_PATH_MUSL_RISCV64"
  else
    echo -e "Invalid SDK_VER=${SDK_VER}"
    exit 1
  fi

  TPU_OUTPUT_PATH="$OUTPUT_DIR"/tpu_"$SDK_VER"
  # ramdisk packages PATH
  pushd $BUILD_PATH || return $?
  CVI_TARGET_PACKAGES_LIBDIR=$(make print-target-packages-libdir)
  CVI_TARGET_PACKAGES_INCLUDE=$(make print-target-packages-include)
  popd
  export CVI_TARGET_PACKAGES_LIBDIR
  export CVI_TARGET_PACKAGES_INCLUDE

  OSS_TARBALL_PATH="$TPU_OUTPUT_PATH"/third_party
  TPU_SDK_INSTALL_PATH="$TPU_OUTPUT_PATH"/cvitek_tpu_sdk
  IVE_SDK_INSTALL_PATH="$TPU_OUTPUT_PATH"/cvitek_ive_sdk
  IVS_SDK_INSTALL_PATH="$TPU_OUTPUT_PATH"/cvitek_ivs_sdk
  AI_SDK_INSTALL_PATH="$TPU_OUTPUT_PATH"/cvitek_ai_sdk
  CNV_SDK_INSTALL_PATH="$TPU_OUTPUT_PATH"/cvitek_cnv_sdk
  TPU_MODEL_PATH="$TPU_OUTPUT_PATH"/models
  IVE_CMODEL_INSTALL_PATH="$TPU_OUTPUT_PATH"/tools/ive_cmodel
}

function cvi_setup_env()
{
  local _tmp ret

  _build_default_env

  _tmp=$(python3 "${TOP_DIR}/build/scripts/boards_scan.py" --gen-board-env="${CHIP}_${BOARD}")
  ret=$?
  [[ "$ret" == 0 ]] || return "$ret"

  # shellcheck disable=SC1090
  source <(echo "${_tmp}")

  if [[ "$CHIP_ARCH" == "CV183X" ]];then
  export  CVIARCH="CV183X"
  fi
  if [[ "$CHIP_ARCH" == "CV182X" ]];then
  export  CVIARCH="CV182X"
  fi
  if [[ "$CHIP_ARCH" == "CV181X" ]];then
  export  CVIARCH="CV181X"
  fi
  if [[ "$CHIP_ARCH" == "CV180X" ]];then
  export  CVIARCH="CV180X"
  fi
  if [[ "$CHIP_ARCH" == "SOPHON" ]];then
  export  CVIARCH="SOPHON"
  fi

  export BRAND BUILD_VERBOSE DEBUG PROJECT_FULLNAME
  export OUTPUT_DIR ATF_PATH BM_BLD_PATH OPENSBI_PATH UBOOT_PATH FREERTOS_PATH
  export KERNEL_PATH RAMDISK_PATH OSDRV_PATH TOOLS_PATH COMMON_TOOLS_PATH

  PROJECT_FULLNAME="$CHIP"_"$BOARD"

  # output folder path
  INSTALL_PATH="$TOP_DIR"/install
  OUTPUT_DIR="$INSTALL_PATH"/soc_"$PROJECT_FULLNAME"
  ROOTFS_DIR="$OUTPUT_DIR"/rootfs
  SYSTEM_OUT_DIR="$OUTPUT_DIR"/rootfs/mnt/system

  # source file folders
  FSBL_PATH="$TOP_DIR"/fsbl
  ATF_PATH="$TOP_DIR"/arm-trusted-firmware
  UBOOT_PATH="$TOP_DIR/$UBOOT_SRC"
  FREERTOS_PATH="$TOP_DIR"/freertos
  ALIOS_PATH="$TOP_DIR"/alios
  KERNEL_PATH="$TOP_DIR"/"$KERNEL_SRC"
  RAMDISK_PATH="$TOP_DIR"/ramdisk
  BM_BLD_PATH="$TOP_DIR"/bm_bld
  TOOLCHAIN_PATH="$TOP_DIR"/host-tools
  OSS_PATH="$TOP_DIR"/oss
  OPENCV_PATH="$TOP_DIR"/opencv
  APPS_PATH="$TOP_DIR"/apps
  MW_PATH="$TOP_DIR"/middleware/"$MW_VER"
  ISP_TUNING_PATH="$TOP_DIR"/isp_tuning
  TPU_SDK_PATH="$TOP_DIR"/tpu-kernel
  IVE_SDK_PATH="$TOP_DIR"/ive
  IVS_SDK_PATH="$TOP_DIR"/ivs
  CNV_SDK_PATH="$TOP_DIR"/cnv
  ACCESSGUARD_PATH="$TOP_DIR"/access-guard-turnkey
  IPC_APP_PATH="$TOP_DIR"/framework/applications/ipc
  AI_SDK_PATH="$TOP_DIR"/cviai
  CVI_PIPELINE_PATH="$TOP_DIR"/cvi_pipeline
  OPENSBI_PATH="$TOP_DIR"/opensbi
  TOOLS_PATH="$BUILD_PATH"/tools
  COMMON_TOOLS_PATH="$TOOLS_PATH"/common
  VENC_PATH="$MW_PATH"/modules/venc
  IMGTOOL_PATH="$COMMON_TOOLS_PATH"/image_tool
  EMMCTOOL_PATH="$COMMON_TOOLS_PATH"/emmc_tool
  SCRIPTTOOL_PATH="$COMMON_TOOLS_PATH"/scripts
  ROOTFSTOOL_PATH="$COMMON_TOOLS_PATH"/rootfs_tool
  SPINANDTOOL_PATH="$COMMON_TOOLS_PATH"/spinand_tool
  BOOTLOGO_PATH="$COMMON_TOOLS_PATH"/bootlogo/logo.jpg

  # subfolder path for buidling, chosen accroding to .gitignore rules
  UBOOT_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"
  RAMDISK_OUTPUT_BASE=build/"$PROJECT_FULLNAME"
  KERNEL_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"
  RAMDISK_OUTPUT_FOLDER="$RAMDISK_OUTPUT_BASE"/workspace

  # toolchain
  export CROSS_COMPILE_64=aarch64-linux-gnu-
  export CROSS_COMPILE_32=arm-linux-gnueabihf-
  export CROSS_COMPILE_UCLIBC=arm-cvitek-linux-uclibcgnueabihf-
  export CROSS_COMPILE_64_NONOS=aarch64-elf-
  export CROSS_COMPILE_64_NONOS_RISCV64=riscv64-unknown-elf-
  export CROSS_COMPILE_GLIBC_RISCV64=riscv64-unknown-linux-gnu-
  export CROSS_COMPILE_MUSL_RISCV64=riscv64-unknown-linux-musl-
  export CROSS_COMPILE="$CROSS_COMPILE_64"

  # toolchain path
  CROSS_COMPILE_PATH_64="$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu
  CROSS_COMPILE_PATH_32="$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf
  CROSS_COMPILE_PATH_UCLIBC="$TOOLCHAIN_PATH"/gcc/arm-cvitek-linux-uclibcgnueabihf
  CROSS_COMPILE_PATH_64_NONOS="$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-elf
  CROSS_COMPILE_PATH_64_NONOS_RISCV64="$TOOLCHAIN_PATH"/gcc/riscv64-elf-x86_64
  CROSS_COMPILE_PATH_GLIBC_RISCV64="$TOOLCHAIN_PATH"/gcc/riscv64-linux-x86_64
  CROSS_COMPILE_PATH_MUSL_RISCV64="$TOOLCHAIN_PATH"/gcc/riscv64-linux-musl-x86_64
  CROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_64"

  # add toolchain path
  pathprepend "$CROSS_COMPILE_PATH_64"/bin
  pathprepend "$CROSS_COMPILE_PATH_32"/bin
  pathprepend "$CROSS_COMPILE_PATH_64_NONOS"/bin
  pathprepend "$CROSS_COMPILE_PATH_64_NONOS_RISCV64"/bin
  pathprepend "$CROSS_COMPILE_PATH_GLIBC_RISCV64"/bin
  pathprepend "$CROSS_COMPILE_PATH_MUSL_RISCV64"/bin
  pathappend "$CROSS_COMPILE_PATH_UCLIBC"/bin

  # sysroot
  SYSROOT_PATH_64="$RAMDISK_PATH"/sysroot/sysroot-glibc-linaro-2.23-2017.05-aarch64-linux-gnu
  SYSROOT_PATH_32="$RAMDISK_PATH"/sysroot/sysroot-glibc-linaro-2.23-2017.05-arm-linux-gnueabihf
  SYSROOT_PATH_UCLIBC="$RAMDISK_PATH"/sysroot/sysroot-uclibc
  SYSROOT_PATH_GLIBC_RISCV64="$RAMDISK_PATH"/sysroot/sysroot-glibc-riscv64
  SYSROOT_PATH_MUSL_RISCV64="$RAMDISK_PATH"/sysroot/sysroot-musl-riscv64
  SYSROOT_PATH="$SYSROOT_PATH_64"

  # envs setup for specific ${SDK_VER}
  envs_sdk_ver

  if [ "${STORAGE_TYPE}" == "spinand" ]; then
    PAGE_SUFFIX=2k
    if [ ${NANDFLASH_PAGESIZE} == 4096 ]; then
      PAGE_SUFFIX=4k
    fi

    if [[ "$ENABLE_ALIOS" != "y" ]]; then
      pushd "$BUILD_PATH"/boards/"${CHIP_ARCH,,}"/"$PROJECT_FULLNAME"/partition/
      ln -fs ../../../default/partition/partition_spinand_page_"$PAGE_SUFFIX".xml \
        partition_"$STORAGE_TYPE".xml
      popd
    fi
  fi

  # configure flash partition table
  if [ -z "${STORAGE_TYPE}" ]; then
    FLASH_PARTITION_XML="$BUILD_PATH"/boards/default/partition/partition_none.xml
  else
    FLASH_PARTITION_XML="$BUILD_PATH"/boards/"${CHIP_ARCH,,}"/"$PROJECT_FULLNAME"/partition/partition_"$STORAGE_TYPE".xml
    if ! [ -e "$FLASH_PARTITION_XML" ]; then
      print_error "${FLASH_PARTITION_XML} does not exist!!"
      return 1
    fi
  fi
}

cvi_print_env()
{
  echo -e ""
  echo -e "\e[1;32m====== Environment Variables ======= \e[0m\n"
  echo -e "  PROJECT: \e[34m$PROJECT_FULLNAME\e[0m, DDR_CFG=\e[34m$DDR_CFG\e[0m"
  echo -e "  CHIP_ARCH: \e[34m$CHIP_ARCH\e[0m, DEBUG=\e[34m$DEBUG\e[0m"
  echo -e "  SDK VERSION: \e[34m$SDK_VER\e[0m, RPC=\e[34m$MULTI_PROCESS_SUPPORT\e[0m"
  echo -e "  ATF options: ATF_KEY_SEL=\e[34m$ATF_KEY_SEL\e[0m, BL32=\e[34m$ATF_BL32\e[0m"
  echo -e "  Linux source folder:\e[34m$KERNEL_SRC\e[0m, Uboot source folder: \e[34m$UBOOT_SRC\e[0m"
  echo -e "  CROSS_COMPILE_PREFIX: \e[34m$CROSS_COMPILE\e[0m"
  echo -e "  ENABLE_BOOTLOGO: $ENABLE_BOOTLOGO"
  echo -e "  Flash layout xml: $FLASH_PARTITION_XML"
  echo -e "  Sensor tuning bin: $SENSOR_TUNING_PARAM"
  echo -e "  Output path: \e[33m$OUTPUT_DIR\e[0m"
  echo -e ""
}

function pack_access_guard_turnkey_app()
{
  if [[ -d "$ACCESSGUARD_PATH" ]] && [[ "$BUILD_TURNKEY_ACCESSGUARD" = "y" ]]; then
    mkdir -p "$SYSTEM_OUT_DIR"/data
    cp -a  ${ACCESSGUARD_PATH}/install "$SYSTEM_OUT_DIR"/data/
  fi
}

function pack_ipc_turnkey_app()
{
  if [[ -d "$IPC_APP_PATH" ]] && [[ "$BUILD_TURNKEY_IPC" = "y" ]]; then
    mkdir -p "$SYSTEM_OUT_DIR"/data
    cp -a  ${IPC_APP_PATH}/install "$SYSTEM_OUT_DIR"/data/
  fi
}

function print_usage()
{
  printf "  -------------------------------------------------------------------------------------------------------\n"
  printf "    Usage:\n"
  printf "    (1)\33[94m menuconfig \33[0m- Use menu to configure your board.\n"
  printf "        ex: $ menuconfig\n\n"
  printf "    (2)\33[96m defconfig \$CHIP_ARCH \33[0m- List EVB boards(\$BOARD) by CHIP_ARCH.\n"
  "${BUILD_PATH}/scripts/boards_scan.py" --list-chip-arch
  printf "        ex: $ defconfig sophon\n\n"
  printf "    (3)\33[92m defconfig \$BOARD\33[0m - Choose EVB board settings.\n"
  printf "        ex: $ defconfig cv186ah_wevb_emmc\n"
  printf "  -------------------------------------------------------------------------------------------------------\n"
}

TOP_DIR=$(gettop)
BUILD_PATH="$TOP_DIR/build"
export TOP_DIR BUILD_PATH
"${BUILD_PATH}/scripts/boards_scan.py" --gen-build-kconfig
"${BUILD_PATH}/scripts/gen_sensor_config.py"
"${BUILD_PATH}/scripts/gen_panel_config.py"

# import common functions
# shellcheck source=./common_functions.sh
source "$TOP_DIR/build/common_functions.sh"

print_usage

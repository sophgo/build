#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
PASS=0
FAIL=2
ERROR=0

function cvi_important_msg()
{
  echo -e "${GREEN}$1${NC}"
}

function cvi_error_msg()
{
  echo -e "${RED}$1${NC}"
  return $FAIL
}

function cvi_error_check()
{
  if [[ $? == 0 ]]; then
    cvi_important_msg "$1 pass"
    return $PASS
  else
    ERROR=$(("$ERROR" | 0x1))
    cvi_error_msg "$1 failed, ERROR=$ERROR"
    return $FAIL
  fi
}

function build_sdk_ver()
{
  #$1 : destination for sw sdk
  #$2 : destination for board tools
  envs_sdk_ver

  local install_sdk_dir="$1"/sdk/
  local install_sdk_ver_dir="$1"/sdk/"${SDK_VER}"
  local install_extra_ver_dir="$1"/extra/"${SDK_VER}"
  local install_internal_ver_dir="$1"/internal/"${SDK_VER}"
  mkdir -p "$install_sdk_ver_dir"
  mkdir -p "$install_extra_ver_dir"
  mkdir -p "$install_internal_ver_dir"

  # clean first
  clean_kernel
  clean_middleware
  clean_libsophon
  clean_3rd_party
  clean_bm1686_sdk
  clean_cvi_rtsp
  #clean_pqtool_server

  # build all sdk
  build_kernel
  build_3rd_party
  build_libsophon
  build_middleware
  build_cvi_rtsp
  build_bm1686_sdk
  #build_pqtool_server

  # pack board tools
  copy_board_tools "$2"

  # pack 3rd party
  mkdir -p "$install_extra_ver_dir"/3rd_party
  cp -a "$OSS_TARBALL_PATH"/* "$install_extra_ver_dir"/3rd_party/

  # pack tpu / ive / ivs /ai sdk
#  if [ ! -d $TPU_OUTPUT_PATH ];then
#  echo "$TPU_OUTPUT_PATH  is null."
  pushd "$TPU_OUTPUT_PATH"
    # tpu sdk
    tar zcf "$install_internal_ver_dir"/cvitek_tpu_sdk_internal."$SDK_VER".tar.gz cvitek_tpu_sdk
    rm -f cvitek_tpu_sdk/include/bmruntime.h
    rm -f cvitek_tpu_sdk/include/bmruntime_bmkernel.h
    rm -rf cvitek_tpu_sdk/include/bmkernel
    rm -rf cvitek_tpu_sdk/include/cvikernel
    rm -rf cvitek_tpu_sdk/include/cvimath
    rm -rf cvitek_tpu_sdk/include/runtime
    tar zcf "$install_extra_ver_dir"/cvitek_tpu_sdk.tar.gz cvitek_tpu_sdk
    # ive sdk
    [[ -d cvitek_ive_sdk ]] && tar zcf "$install_extra_ver_dir"/cvitek_ive_sdk.tar.gz cvitek_ive_sdk
    # ivs sdk
    [[ -d cvitek_ivs_sdk ]] && tar zcf "$install_extra_ver_dir"/cvitek_ivs_sdk.tar.gz cvitek_ivs_sdk
    #ai sdk
    tar zcf "$install_internal_ver_dir"/cvitek_ai_sdk_internal."$SDK_VER".tar.gz cvitek_ai_sdk
    rm -rf cvitek_ai_sdk/regression
    tar zcf "$install_extra_ver_dir"/cvitek_ai_sdk.tar.gz cvitek_ai_sdk
  popd
#  fi

  # package mw sdk
  pushd "$MW_PATH"
    make package DESTDIR=install
    cp install/kernel_header.tar.gz "$install_sdk_ver_dir"/
    cp install/mw.tar.gz "$install_extra_ver_dir"/
  popd

  # package mmf included mw, tpu, ive, ivs, ai sdk
  mkdir -p ./tmp_sdk/mmf
  pushd ./tmp_sdk
    tar -xhzf "$install_extra_ver_dir"/mw.tar.gz -C mmf
    tar -xhzf "$install_extra_ver_dir"/cvitek_tpu_sdk.tar.gz
    rm -f cvitek_tpu_sdk/README.md
    rm -f cvitek_tpu_sdk/*.sh
    cp -a cvitek_tpu_sdk/* mmf/
    [[ -f "$install_extra_ver_dir"/cvitek_ive_sdk.tar.gz ]] && tar xhzf "$install_extra_ver_dir"/cvitek_ive_sdk.tar.gz
    [[ -d cvitek_ive_sdk ]] && cp -a cvitek_ive_sdk/* mmf/
    [[ -f "$install_extra_ver_dir"/cvitek_ivs_sdk.tar.gz ]] && tar xhzf "$install_extra_ver_dir"/cvitek_ivs_sdk.tar.gz
    [[ -d cvitek_ivs_sdk ]] && cp -a cvitek_ivs_sdk/* mmf/
    tar xhzf "$install_extra_ver_dir"/cvitek_ai_sdk.tar.gz
    cp -a cvitek_ai_sdk/* mmf/
    pushd mmf
      tar zcf "$install_sdk_ver_dir"/mmf.tar.gz ./*
    popd
  popd
  rm -rf ./tmp_sdk

  # pack sysroot
  mkdir -p ./tmp_sysroot
  pushd ./tmp_sysroot
    cp -a "$SYSROOT_PATH" cvitek_sysroot
    tar zcf "$install_sdk_ver_dir"/cvitek_sysroot.tar.gz cvitek_sysroot
  popd
  rm -rf ./tmp_sysroot
}

function build_all_sdk_ver()
{
  if [[ "$CHIP_ARCH" == SOPHON ]]; then
    setconfig TOOLCHAIN_GLIBC_ARM64=y
    build_sdk_ver "$@"
  fi
  #if [[ "$CHIP_ARCH" == CV183X ]]; then
  #  setconfig TOOLCHAIN_GLIBC_ARM64=y
  #  build_sdk_ver "$@"
  #fi

  #if [[ "$ARCH" == arm* ]]; then
  #  setconfig TOOLCHAIN_GLIBC_ARM=y
  #  build_sdk_ver "$@"
  #fi

  if [[ "$CHIP_ARCH" == CV182X ]] || [[ "$CHIP_ARCH" == CV183X ]]; then
    setconfig TOOLCHAIN_UCLIBC_ARM=y
    build_sdk_ver "$@"
  fi

  if [[ "$CVIARCH" == CV181X ]] && [[ "$ARCH" == riscv ]]; then
    setconfig TOOLCHAIN_GLIBC_RISCV64=y
    build_sdk_ver "$@"
    setconfig TOOLCHAIN_MUSL_RISCV64=y
    build_sdk_ver "$@"
  fi

  if [[ "$CVIARCH" == CV180X ]] && [[ "$ARCH" == riscv ]]; then
    echo "setconfig CV180X"
    setconfig TOOLCHAIN_GLIBC_RISCV64=y
    build_sdk_ver "$@"
    setconfig TOOLCHAIN_MUSL_RISCV64=y
    build_sdk_ver "$@"
  fi
}

function build_all_fip_bin()
{
  install_dir_board="$1"/fip_bin
  mkdir -p "$install_dir_board"

  generate_fip_bin

  pushd "$TOP_DIR"/install
    find ./ -maxdepth 2 \( -name 'tpu*' -o -name 'elf' -o -name 'system' -o -name 'rootfs' -o -name 'rawimages' \) -type d -exec rm -rf {} \;
    find ./ -maxdepth 4 \( -name 'bl1.*' -o -name 'u-boot.bin' -o -name '*.txt' -o -name '*.emmc*' -o -name '*.spinand*' \) -type f -exec rm -rf {} \;
    cp -a ./* "$install_dir_board"/
    find "$install_dir_board"/ -maxdepth 2 -name 'fip*.bi' -type f -exec rm -rf {} \;
    find "$install_dir_board"/ -maxdepth 2 -name 'fip_pre' -type d -exec rm -rf {} \;
  popd
}

function build_all_fip_pre_bin()
{
  install_dir_board="$1"/fip_pre_bin
  mkdir -p "$install_dir_board"

  # copy fip_pre.bin
  pushd "$install_dir_board"
  cp -a "$TOP_DIR"/install/* .
  find ./ -maxdepth 2 \( -name 'tools' \) -type d -exec rm -rf {} \;
  delFiles=("*.bin" "*.xml" "*.itb" "gpt.img")
  for file in "${delFiles[@]}";do
    find ./ -name "$file" -type f -printf 'removing %p from sdk\n' -prune -exec rm -rf {} \;
  done

  # rename fip_pre
  find ./ -name fip_pre_default.bi -exec mv {} {}n \;
  find ./ -name fip_pre_key1.bi -exec mv {} {}n \;
  popd
}

function build_all_ko()
{(
  # $1 chip_arch for building kernel driver
  #[[ "$CHIP_ARCH" == CV182X ]] && chip_list=("${chip_cv182x[@]}")
  #[[ "$CHIP_ARCH" == CV183X ]] && chip_list=("${chip_cv183x[@]}")
  [[ "$CHIP_ARCH" == SOPHON ]] && chip_list=("${chip_sophon[@]}")
  [[ "$CVIARCH" == CV181X ]] && chip_list=("${chip_cv181x[@]}")
  [[ "$CVIARCH" == CV180X ]] && chip_list=("${chip_cv180x[@]}")

  for c in "${!chip_list[@]}"; do
    export CHIP=${chip_list[$c]}
    local -a 'board_sel=("${'"${CHIP}"'_board_sel[@]}")'
    for b in "${!board_sel[@]}"; do
      export BOARD=${board_sel[$b]}
      # ignore non linux board
      [[ "$BOARD" = *os* || "$BOARD" = *wdmb* ]] && continue
      (
        cd "$TOP_DIR" || exit
        source build/envsetup_soc.sh
        defconfig "${chip_list[$c]}"_"${board_sel[$b]}"
        build_kernel; build_osdrv
        output_path=$1/"${chip_list[$c]}"_"${board_sel[$b]}"
        mkdir -p "$output_path"/3rd
        find "$OSDRV_PATH"/interdrv/"$MW_VER" -name '*.ko' -exec cp {} "$output_path" \;
        find "$OSDRV_PATH"/extdrv -name '*.ko' -exec cp {} "$output_path"/3rd/ \;
        [[ -d "$OSDRV_PATH"/extdrv/wireless/bcmdhd/AP6201BM_4.2/Wi-Fi ]] && \
          cp -f "$OSDRV_PATH"/extdrv/wireless/bcmdhd/AP6201BM_4.2/Wi-Fi/* "$output_path"/3rd/
        distclean_all
      )
    done
  done
)}

function build_shrink_and_normal_ko()
{
  [[ "$CVIARCH" != "CV181X" ]] && [[ "$CVIARCH" != "CV180X" ]] && return $PASS

  envs_sdk_ver
  local sdk_path="$TOP_DIR"/"${TAG}"_source

  setconfig FAST_IMAGE_TYPE=0 && build_rtos
  #setconfig FAST_IMAGE_TYPE=1 && build_rtos

  buildConfig=("y" "n")
  for config in "${buildConfig[@]}";do
    setconfig BUILD_FOR_DEBUG=${config}
    clean_kernel;clean_osdrv;
    build_kernel;build_osdrv;

    if [[ "$config" != "y" ]]; then
      mkdir -p "$sdk_path"/middleware/"$MW_VER"/ko_shrink/3rd
      pushd  "$sdk_path"/middleware/"$MW_VER"
      find "$OSDRV_PATH"/interdrv/"$MW_VER" -name '*.ko' -exec cp {} ko_shrink/ \;
      find "$OSDRV_PATH"/extdrv -name '*.ko' -exec cp {} ko_shrink/3rd/ \;
      [[ -d "$OSDRV_PATH"/extdrv/wireless/bcmdhd/AP6201BM_4.2/Wi-Fi ]] && \
        cp -f "$OSDRV_PATH"/extdrv/wireless/bcmdhd/AP6201BM_4.2/Wi-Fi/* ko_shrink/3rd/
      popd
    else
      mkdir -p "$sdk_path"/middleware/"$MW_VER"/ko/3rd
      pushd  "$sdk_path"/middleware/"$MW_VER"
      find "$OSDRV_PATH"/interdrv/"$MW_VER" -name '*.ko' -exec cp {} ko/ \;
      find "$OSDRV_PATH"/extdrv -name '*.ko' -exec cp {} ko/3rd/ \;
      [[ -d "$OSDRV_PATH"/extdrv/wireless/bcmdhd/AP6201BM_4.2/Wi-Fi ]] && \
        cp -f "$OSDRV_PATH"/extdrv/wireless/bcmdhd/AP6201BM_4.2/Wi-Fi/* ko/3rd/
      popd
    fi
  done
}

function copy_board_tools
{(
local FUNCTION_TEST_TOOLS=(
  "cvi_test"
  "ipc_test"
  "cvi_h264_dec"
  "cvi_h265_dec"
  "cvi_h265_enc_test"
  "cvi_jpg_codec"
  "cvi_rtsp.tar.gz"
  "vpss_ut_client"
  "vpss_ut"
  "vi_ut_client"
  "vi_ut"
)

local OTHER_TOOLS=(
  "isp_tool_daemon.tar.gz"
  "res.rar"
  "cvi_auto_play"
  "cvi_auto_record"
  "cvi_auto_special"
)

  output_path="$board_tools_path"
  [[ ! -z "$1" ]] && output_path="$1"/"$SDK_VER"

  mkdir -p "$output_path"/ut_bin
  mkdir -p "$output_path"/sample_bin

  pushd $TOP_DIR
  # Function Test tools
  for bin_tool in "${FUNCTION_TEST_TOOLS[@]}"; do
    find ./ \( -path './middleware/'"$MW_VER"'/*' -o -path './cvi_rtsp*' \) \
        -a -name "$bin_tool" -type f -exec cp {} "$output_path"/"$bin_tool"."$SDK_VER" \;
  done

  SAMPLE=$(find ./ \( -path './middleware/*' \) -a -name "sample_*" -type f -perm -111 -exec basename {} \;)
  for sample in ${SAMPLE[@]}; do
    find ./ \( -path './middleware/'"$MW_VER"'/*' \) -a -name "$sample" -type f \
        -exec cp {} "$output_path"/sample_bin/"$sample"."$SDK_VER" \;
  done

  UT_TOOLS=./middleware/v2/self_test/auto_test
  cp -rf ${UT_TOOLS} "$output_path"/ut_bin/auto_test."$SDK_VER"

  # Other Test tools
  for other_tool in ${OTHER_TOOLS[@]}; do
    find ./ \( -path './middleware/*'  \) \
        -a -name "$other_tool" -type f -exec cp {} "$output_path"/"$other_tool"."$SDK_VER" \;
  done

  popd

)}

function repo_build()
{
  DATE=$(date '+%Y%m%d')
  TPU_REL=1

  build_all

  printf "Copy bin to the FTP release path\n"
  install_dir="$1"
  rm -rf "$install_dir"

  local pc_tools_path="$install_dir"/tools/pc
  local board_tools_path="$install_dir"/tools/board
  mkdir -p "$pc_tools_path"

  # copy CviBurn/ CviPQtool to install folder
  [[ -f "$TOP_DIR"/__CviBurn/CviBurn_1.0.0.zip ]] && cp -f "$TOP_DIR"/__CviBurn/CviBurn_1.0.0.zip "$pc_tools_path"
  [[ -f "$TOP_DIR"/__CviPQtool/CviPQtool_"${DATE}".zip ]] && cp -f "$TOP_DIR"/__CviPQtool/CviPQtool_"${DATE}".zip \
      "$pc_tools_path"

  # build sdk package, including mw/tpu/ive/ivs/ai, for both 64bit and 32bit
  [[ "$QUICK_RELEASE" = 0 ]] && build_all_sdk_ver "$install_dir"
  # build rls/debug ko
  #[[ "$QUICK_RELEASE" = 0 ]] && build_shrink_and_normal_ko

  # mkdir for release folder
  mkdir -p "$install_dir"/../internal
  mkdir -p "$install_dir"/../sdk_release
  [[ "$QUICK_RELEASE" = 0 ]] && mv -f "$install_dir"/internal "$install_dir"/../
  [[ "$QUICK_RELEASE" = 0 ]] && mv -f "$install_dir"/sdk "$install_dir"/../sdk_release
  [[ "$QUICK_RELEASE" = 0 ]] && mv -f "$install_dir"/extra "$install_dir"/../sdk_release

  print_notice "Finished ${FUNCNAME[0]}() function"
}

function repo_build_fip()
{
  install_dir_board="$1"/fip_boards
  mkdir -p "$install_dir_board"

  generate_fip_bin

  pushd "$TOP_DIR"/install
    find ./ -maxdepth 2 \( -name 'tpu*' -o -name 'elf' -o -name 'system' -o -name 'rootfs' -o -name 'rawimages' \) -type d -exec rm -rf {} \;
    find ./ -maxdepth 4 \( -name 'bl1.*' -o -name 'u-boot.bin' -o -name '*.txt' -o -name '*.emmc*' -o -name '*.spinand*' \) -type f -exec rm -rf {} \;
    cp -a ./* "$install_dir_board"/
    find "$install_dir_board"/ -maxdepth 2 -name 'fip*.bi' -type f -exec rm -rf {} \;
    find "$install_dir_board"/ -maxdepth 2 -name 'fip_pre' -type d -exec rm -rf {} \;
  popd
}

function add_source_to_sdk_package()
{
  cvi_important_msg " prepare sdk source code"

  local sdk_path="$TOP_DIR"/"${TAG}"_source
  local sdk_atf_path="$TOP_DIR"/"${TAG}"_source_atf
  local tmp_dir
  mkdir -p "$SDK_RELEASE_PATH"

  #  middleware folder
  mkdir -p "$sdk_path"/middleware/"$MW_VER"/ko/3rd
  mkdir -p "$sdk_path"/middleware/"$MW_VER"/3rdparty
  mkdir -p "$sdk_path"/middleware/"$MW_VER"/include

  pushd  "$sdk_path"/middleware/"$MW_VER"
    install_mw_sdk_ver=("32bit" "64bit" "uclibc" "glibc_riscv64" "musl_riscv64")
    for sdk_ver in "${install_mw_sdk_ver[@]}";do
      if [[ -f "$SDK_RELEASE_PATH"/sdk/"$sdk_ver"/mmf.tar.gz ]]; then
        tmp_dir=$(mktemp -d)
        tar -xf "$SDK_RELEASE_PATH"/sdk/"$sdk_ver"/mmf.tar.gz -C "$tmp_dir"
        cp -a "$tmp_dir"/lib lib_"$sdk_ver"
        cp -a "$tmp_dir"/include/* include
        rm -rf "${tmp_dir:?}"
      fi
    done
    cp -f "$MW_PATH"/modules/sys/include/devmem.h include/
    cp -a "$MW_PATH"/sample .
    rm -rf sample/tpu
    rm -rf sample/multivenc
    cp -LR "$MW_PATH"/component .
    rm -rf component/panel/"$CHIP"/customer
    cp -rf "$MW_PATH"/Makefile.param .
    [[ "$CVIARCH" == CV181X ]] || [[ $CVIARCH == CV180X ]] || [[ "$CVIARCH" == SOPHON ]] && cp -rf "$MW_PATH"/pkgconfig .

    find "$OSDRV_PATH"/interdrv/"$MW_VER" -name '*.ko' -exec cp {} ko/ \;
    find "$OSDRV_PATH"/extdrv -name '*.ko' -exec cp {} ko/3rd/ \;
    [[ -d "$OSDRV_PATH"/extdrv/wireless/bcmdhd/AP6201BM_4.2/Wi-Fi ]] && \
      cp -f "$OSDRV_PATH"/extdrv/wireless/bcmdhd/AP6201BM_4.2/Wi-Fi/* ko/3rd/
  popd

  # libsophon folder
  pushd "$LIBSOPHON_PATH"/install/
  # copy ko
  cp -rf libsophon-0.4.9/data/bmtpu.ko "$sdk_path"/middleware/"$MW_VER"/ko/
  rm -rf libsophon-0.4.9/data/bmtpu.ko
  # copy bin/.h/.so/.a
  cp -rf libsophon-0.4.9 "$sdk_path"/middleware/"$MW_VER"/lib_"$SDK_VER"/
  popd

  # build folder
  mkdir -p "$sdk_path"/build/scripts
  cp -a "$BUILD_PATH"/tools "$sdk_path"/build/
  cp -a "$BUILD_PATH"/cvisetup.sh "$sdk_path"/build/
  cp -a "$BUILD_PATH"/common_functions.sh "$sdk_path"/build/
  cp -a "$BUILD_PATH"/Makefile "$sdk_path"/build/
  sed -i "/OSDRV/d" "$sdk_path"/build/Makefile
  cp -a "$BUILD_PATH"/Kconfig "$sdk_path"/build/
  rm -rf "$BUILD_PATH"/scripts/__pycache__
  cp -a "$BUILD_PATH"/scripts "$sdk_path"/build/
  [[ -f "$sdk_path"/build/scripts/rtos.mk ]] && sed -i "s/install//g" "$sdk_path"/build/scripts/rtos.mk
  cp -a "$BUILD_PATH"/boards "$sdk_path"/build/
  cp -a "$BUILD_PATH"/sensors "$sdk_path"/build/
  cp -a "$BUILD_PATH"/panels "$sdk_path"/build/

  cp -a "$KERNEL_PATH" "$sdk_path"/
  cp -a "$UBOOT_PATH" "$sdk_path"/
  cp -a "$RAMDISK_PATH" "$sdk_path"/
  cp -a "$TOOLCHAIN_PATH" "$sdk_path"/
  [[ "$CVIARCH" == CV181X ]] || [[ $CVIARCH == CV180X ]] && [[ -d $FREERTOS_PATH/cvitek/install ]] && \
    mkdir -p "$sdk_path"/freertos/cvitek && release_freertos "$sdk_path"
  #The fsbl source code is released by .o files, so do not called fsbl
  [[ "$CVIARCH" == SOPHON ]] || [[ $CVIARCH == CV180X ]] && "$FSBL_PATH"/release.sh "$sdk_path"
  [[ "$CVIARCH" == CV181X ]] || [[ $CVIARCH == CV180X ]] && clean_opensbi && cp -a "$OPENSBI_PATH" "$sdk_path"/

  [[ -d "$ACCESSGUARD_PATH" ]] && [[ "$BUILD_TURNKEY_ACCESSGUARD" == y ]] && \
    cp -a "$ACCESSGUARD_PATH" "$sdk_path"/

  [[ -d "$IPC_APP_PATH" ]] && [[ "$BUILD_TURNKEY_IPC" == y ]] && mkdir -p "$sdk_path"/framework/applications && \
    cp -a "$IPC_APP_PATH" "$sdk_path"/framework/applications/

  # isp_tuning folder
  mkdir -p "$sdk_path"/isp_tuning
  cp -a "$ISP_TUNING_PATH"/"${CHIP_ARCH,,}" "$sdk_path"/isp_tuning
  cp -a "$ISP_TUNING_PATH"/copyBin.sh "$sdk_path"/isp_tuning

  # patch/clean kernel source(vip, tpu, vcodec not for release)
  pushd "$sdk_path"/"$KERNEL_SRC"
  mkdir -p "$sdk_path"/middleware/"$MW_VER"/include/linux
  [[ "$CHIP_ARCH" == CV182X ]] || [[ "$CHIP_ARCH" == CV183X ]] && \
      cp -rf "$OSDRV_PATH"/interdrv/"$MW_VER"/vip/chip/"${CHIP_ARCH,,}"/uapi/* \
      "$sdk_path"/middleware/"$MW_VER"/include/linux/
  [[ "$CVIARCH" == CV181X ]] || [[ $CVIARCH == CV180X ]] && \
      cp -rf "$OSDRV_PATH"/interdrv/"$MW_VER"/include/chip/"${CVIARCH,,}"/uapi/linux/* \
      "$sdk_path"/middleware/"$MW_VER"/include/linux/
  [[ $CVIARCH == SOPHON ]] && \
      cp -rf "$OSDRV_PATH"/interdrv/"$MW_VER"/include/chip/cv186x/uapi/linux/* \
      "$sdk_path"/middleware/"$MW_VER"/include/linux/
  [[ "$CVIARCH" == CV181X ]] || [[ $CVIARCH == CV180X ]] || [[ $CVIARCH == SOPHON ]] && \
      cp -rf "$OSDRV_PATH"/interdrv/"$MW_VER"/include/common/uapi/linux/* \
      "$sdk_path"/middleware/"$MW_VER"/include/linux/
  cp -rf "$OSDRV_PATH"/interdrv/"$MW_VER"/usb/gadget/function/f_cvg.h* \
      "$sdk_path"/middleware/"$MW_VER"/include/linux/
  popd

  #tpu-kernel folder
  mkdir -p "$sdk_path"/tpu-kernel
  cp -rf ${TPU_SDK_PATH}/* "$sdk_path"/tpu-kernel
}

function del_unused_files()
{
  cvi_important_msg " delete unused files"
  local sdk_path="$TOP_DIR"/"$TAG"_source
  local sdk_atf_path="$TOP_DIR"/"${TAG}"_source_atf

  pushd "$sdk_path"
  rm -rf ramdisk/build
  rm -rf ramdisk/tools
  rm -rf "$KERNEL_SRC"/build
  rm -rf "$UBOOT_SRC"/build
  find -name '.git' -printf 'removing %p from ramdisk\n' -prune -exec rm -rf {} \;
  delFiles=(".git*" "*.cmd" "*.swp" "*.tmp")
  for file in "${delFiles[@]}";do
    find -name "$file" -type f -printf 'removing %p from sdk\n' -prune -exec rm -rf {} \;
  done
  popd

  if [[ "$RELEASE_ATF_SOUCE" == release ]]; then (
    cd "$sdk_atf_path"
    rm -rf arm-trusted-firmware/build
  ) fi

  pushd "$sdk_path"/middleware/"$MW_VER"
    delFiles=("*.o" "*.d")
      for file in "${delFiles[@]}";do
      find -name "$file" -type f -printf 'removing %p from sdk\n' -prune -exec rm -rf {} \;
    done
  popd
}

# shellcheck disable=SC2120
function pack_sdk_source()
{(
  cvi_important_msg " pack the whole source"
  local sdk_path="$TOP_DIR"/"$TAG"_source
  local sdk_atf_path="$TOP_DIR"/"${TAG}"_source_atf

  # Do not tar host-tools.tar.gz for save FTP space
  if [[ "$1" = cp_host_tools ]]; then
    pushd "$sdk_path"
    tar zcf "$SDK_RELEASE_PATH"/host-tools.tar.gz host-tools
    rm -rf host-tools
    popd
  fi

  pushd "$sdk_path"/../
  tar zcf "$SDK_RELEASE_PATH"/"$TAG"_source.tar.gz "$TAG"_source
  cvi_error_check "${TAG}_source.tar.gz packing"
  if [[ "$ERROR" == "$PASS" ]]; then
    cvi_important_msg "output file path: $PWD/${TAG}_source.tar.gz packing"
  fi
  if [[ "$RELEASE_ATF_SOUCE" == release ]]; then
    tar zcf "$SDK_RELEASE_PATH"/"$TAG"_source_atf.tar.gz "$TAG"_source_atf
  fi
  popd
)}

function generate_fip_bin()
{(
  source build/build_bin.sh

  #[[ "$CHIP_ARCH" == CV182X ]] && chip_list=("${chip_cv182x[@]}")
  #[[ "$CHIP_ARCH" == CV183X ]] && chip_list=("${chip_cv183x[@]}")
  [[ "$CHIP_ARCH" == SOPHON ]] && chip_list=("${chip_sophon[@]}" "${chip_bm1688[@]}" "${chip_cv186ah[@]}")
  [[ "$CVIARCH" == CV181X ]] && chip_list=("${chip_cv181x[@]}")
  [[ "$CVIARCH" == CV180X ]] && chip_list=("${chip_cv180x[@]}")

  for c in "${!chip_list[@]}"; do
    export CHIP=${chip_list[$c]}
    local -a 'board_sel=("${'"${CHIP}"'_board_sel[@]}")'
    for b in "${!board_sel[@]}"; do
      export BOARD=${board_sel[$b]}
      if [[ "$BOARD" = *rtos* ]] || [[ "$BOARD" = *alios* ]]; then
        continue
      fi
      (
        cd "$TOP_DIR" || exit
        source build/envsetup_soc.sh
        defconfig "${chip_list[$c]}"_"${board_sel[$b]}"

        # generate fip.bin w/o uboot
        clean_uboot; build_uboot

        command mv install/soc_"${chip_list[$c]}"_"${board_sel[$b]}"/fip.bin \
          install/soc_"${chip_list[$c]}"_"${board_sel[$b]}"/fip_default.bin

        # cv182x/ cv183x chips need to generate fip_pre.bin
        if [[ "$CHIP_ARCH" == CV182X ]] || [[ "$CHIP_ARCH" == CV183X ]]; then
          command mv install/soc_"${chip_list[$c]}"_"${board_sel[$b]}"/fip_pre/fip_pre.bin \
            install/soc_"${chip_list[$c]}"_"${board_sel[$b]}"/fip_pre/fip_pre_default.bi
        fi
        # cv183x chips need to generate KEY1 fip_pre.bin
        if [[ "$CHIP_ARCH" == CV183X ]]; then
          setconfig ATF_KEY_SEL_key1=y
          build_uboot
          command mv install/soc_"${chip_list[$c]}"_"${board_sel[$b]}"/fip_pre/fip_pre.bin \
            install/soc_"${chip_list[$c]}"_"${board_sel[$b]}"/fip_pre/fip_pre_key1.bi
          command mv install/soc_"${chip_list[$c]}"_"${board_sel[$b]}"/fip.bin \
            install/soc_"${chip_list[$c]}"_"${board_sel[$b]}"/fip_key1.bin
        fi
        # copy .xml for usb download
        copy_tools
      )
    done
  done
)}

function generate_sdk_source()
{
  if [[ -z "$1" ]]; then
    cvi_error_msg "Please enter sdk source path !"
  else
    SDK_RELEASE_PATH=$1
  fi
  if [[ -d "$2" ]]; then
    cvi_important_msg "Found fip_pre_bin_path $2 !"
    FIP_PRE_BIN_PATH="$2"
  fi

  add_source_to_sdk_package "$FIP_PRE_BIN_PATH"
  del_unused_files
  pack_sdk_source

  cvi_important_msg "build release package sucessfully"
}

function release_freertos()
{
  if [ "$1" = "" ];then
    cvi_error_msg "Please enter sdk release path !"
    OUTPUT_PATH="$TOP_DIR"/"${TAG}"_source
  fi
  OUTPUT_PATH=$1

  if [ "${FREERTOS_PATH}" = "" ];then
    cvi_error_msg "FREERTOS_PATH is error."
    exit 1;
  fi

  if [ ! -d ${OUTPUT_PATH}/freertos/cvitek ]; then
    mkdir -p ${OUTPUT_PATH}/freertos/cvitek
  fi

  cp -rf ${FREERTOS_PATH}/cvitek/task ${OUTPUT_PATH}/freertos/cvitek
  cp -rf ${FREERTOS_PATH}/cvitek/install ${OUTPUT_PATH}/freertos/cvitek/
  cp -rf ${FREERTOS_PATH}/cvitek/scripts ${OUTPUT_PATH}/freertos/cvitek/
  #Delete temporary files generated during compilation
  [[ -d ${OUTPUT_PATH}/freertos/cvitek/build ]] && rm -rf ${OUTPUT_PATH}/freertos/cvitek/build

  local txt="#!/bin/bash\nset -e\n
TOP_DIR=\"\$( cd \"\$(dirname \"\$0\")\" ; pwd -P )\"\n
TOOLCHAIN_FILE_PATH=\$TOP_DIR/scripts/toolchain-riscv64-elf.cmake\n
BUILD_FREERTOS_PATH=\$TOP_DIR/build\n
BUILD_ENV_PATH=\$BUILD_PATH\n
INSTALL_PATH=\$TOP_DIR/install\n
RUN_TYPE=CVIRTOS\nRUN_CHIP=cv181x\nRUN_ARCH=riscv64\n
if [ ! -e \$BUILD_FREERTOS_PATH/task ]; then\n
    mkdir -p \$BUILD_FREERTOS_PATH/task\n
fi\n
if [ -f \$TOP_DIR/task/isp/libisp.a ]; then\n
    mkdir -p \$BUILD_FREERTOS_PATH/task/isp\n
    cp \$TOP_DIR/task/isp/libisp.a \$BUILD_FREERTOS_PATH/task/isp\n
    cp \$TOP_DIR/task/isp/libisp.a \$INSTALL_PATH/lib/\n
fi\n
pushd \$BUILD_FREERTOS_PATH/task\n
cmake -G Ninja -DCHIP=\$RUN_CHIP \
 -DRUN_ARCH=\$RUN_ARCH \
 -DRUN_TYPE=\$RUN_TYPE \
 -DTOP_DIR=\$TOP_DIR  \
 -DBUILD_ENV_PATH=\$BUILD_ENV_PATH \
 -DBOARD_FPGA=n \
 -DCMAKE_TOOLCHAIN_FILE=\$TOOLCHAIN_FILE_PATH \
 \$TOP_DIR/task\n
cmake --build . --target install -- -v\n
cmake --build . --target cvirtos.bin -- -v\n
popd\n
cp \$TOP_DIR/install/bin/cvirtos.bin ../cvirtos.bin"
  echo -e ${txt} > ${OUTPUT_PATH}/freertos/cvitek/build_cv181x.sh
  echo -e ${txt} > ${OUTPUT_PATH}/freertos/cvitek/build_cv180x.sh
  chmod +x ${OUTPUT_PATH}/freertos/cvitek/build_cv181x.sh
  chmod +x ${OUTPUT_PATH}/freertos/cvitek/build_cv180x.sh
  sed -i "s/RUN_CHIP=cv181x/RUN_CHIP=cv180x/g" ${OUTPUT_PATH}/freertos/cvitek/build_cv180x.sh

  if [ -f ${FREERTOS_PATH}/cvitek/build/task/isp/libisp.a ]; then
  cp -rf ${FREERTOS_PATH}/cvitek/build/task/isp/libisp.a ${OUTPUT_PATH}/freertos/cvitek/task/isp/
  fi

  pushd ${OUTPUT_PATH}/freertos/cvitek/task
  sed -i "s/add_subdirectory(isp)//g" CMakeLists.txt
  popd
}

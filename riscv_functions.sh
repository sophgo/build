#!/bin/bash
#
# For cv181x_c906
#
function _build_opensbi_env()
{
  export OPENSBI_PATH
}

function clean_opensbi()
{
  if [[ "$CHIP_ARCH" == CV181X ]]; then
    print_notice "Run ${FUNCNAME[0]}() function"
    _build_opensbi_env

    cd "$BUILD_PATH" || return "$?"
    make opensbi-clean
  fi
}

function build_opensbi_kernel()
{(
  export _BUILD_OPENSBI_KERNEL_=y
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_kernel_env
  _build_opensbi_env

  cd "$BUILD_PATH" || return "$?"
  # make riscv-cpio || return "$?"
  make clean-memory-map || return "$?"
  build_bmcpu || return "$?"
  build_kernel || return "$?"
  build_ramboot || return "$?"
  ${Q}cp ${RAMDISK_PATH}/${RAMDISK_OUTPUT_FOLDER}/boot.cpio ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/
  make kernel-setconfig SCRIPT_ARG="INITRAMFS_SOURCE="boot.cpio"" || return "$?"
  make kernel || return "$?"
  make kernel-dts || return "$?"
  make kernel-setconfig SCRIPT_ARG="INITRAMFS_SOURCE=""" || return "$?"
  make opensbi-kernel || return "$?"
)}

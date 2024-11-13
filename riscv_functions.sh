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
  print_notice "Run ${FUNCNAME[0]}() function"
  create_ramdisk_folder || return "$?"
  _build_kernel_opensbi_env
  cd "$BUILD_PATH" || return
  make kernel || return "$?"
  # generate boot.itb image.
  if [[ ${1} != noitb ]]; then
    pack_boot || return "$?"
  fi
  cd "$BUILD_PATH" || return
  make ramboot
  
  cd "$BUILD_PATH" || return "$?"
  make opensbi-kernel || return "$?"
  pack_payload || return "$?"
)}

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
  local TOPFILE=build/envsetup_soc.sh
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


update_files_if_newer() {
    local filename_pattern="$1"
    local source_path="$2"
    local target_path="$3"


    if [[ ! -d "$source_path" ]]; then
        return 1
    fi

    if [[ ! -d "$target_path" ]]; then
        mkdir -p "$target_path" || { echo "Failed to create target path."; return 1; }
    fi

    local expanded_patterns
    expanded_patterns=$(eval echo "$source_path/$filename_pattern")

    local files=($expanded_patterns)

    for source_file in "${files[@]}"; do
        if [[ ! -e "$source_file" ]]; then
            #echo "No files matching pattern in $source_path."
            continue
        fi

        local target_file="${target_path}/$(basename "$source_file")"

        if [[ ! -e "$target_file" ]]; then
            echo "update $target_file"
            cp "$source_file" "$target_file" || echo "update failed."
            continue
        fi

        local source_mtime=$(stat -c %Y "$source_file")
        local target_mtime=$(stat -c %Y "$target_file")

        if [[ "$source_mtime" -gt "$target_mtime" ]]; then
            echo "update  $target_file"
            cp "$source_file" "$target_file" || echo "update failed."
        fi
    done
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
  export UBOOT_VBOOT RELEASE_VERSION ENABLE_BOOTLOGO STORAGE_TYPE COMPRESSOR_UBOOT KERNEL_BOOT_TYPE
  export PANEL_TUNING_PARAM PANEL_LANE_NUM_TUNING_PARAM PANEL_LANE_SWAP_TUNING_PARAM
}

function _build_br2_env()
{
  export BUILDROOT_PATH
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

function menuconfig_buildroot()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_br2_env
  cd "$BUILD_PATH" || return
  make menuconfig-br2 || return "$?"
)}

function savedefconfig_br2()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_br2_env
  cd "$BUILD_PATH" || return
  make savedefconfig-br2 || return "$?"
)}

function build_br2_package()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_br2_env
  cd "$BUILD_PATH" || return
  make build_package-br2 || return "$?"
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
  cd "$BUILD_PATH" || return
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
  if [ -n $_BUILD_OPENSBI_KERNEL_ ]; then
    make kernel || return "$?"
  else
    make _BUILD_OPENSBI_KERNEL_=y kernel || return "$?"
  fi

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

  pushd "$MW_PATH"
  make all -j$(nproc)
  test $? -ne 0 && print_notice "build middleware failed !!" && popd && return 1
  if ! grep -q '^CONFIG_ROOTFS_UBUNTU=y' "${TOP_DIR}"/build/.config; then
    make install DESTDIR="$SYSTEM_OUT_DIR"
  else
    make packdeb
  fi
  popd

  # add sdk version
  echo "SDK_VERSION=${SDK_VER}" > "$SYSTEM_OUT_DIR"/sdk-release
)}

function clean_middleware()
{
  pushd "$MW_PATH"
  make clean
  make uninstall
  popd
}

function build_v4l2_isp()
{
  source ${TOP_DIR}/middleware/${MW_VER}/modules/isp/cv186x/v4l2_adapter/build_v4l2_isp.sh
  if [ ! "$?" -eq 0 ]; then
	  echo "build_v4l2_isp fail! Exit ..."
	  return 1
  fi
  if [ -d "$TOP_DIR/buildroot" ]; then
    mkdir -p "$TOP_DIR/buildroot/dl/sglib"
    update_files_if_newer "sophon-soc-libisp_*_arm64.tar.gz" "${TOP_DIR}/middleware/v2/modules/isp/cv186x/v4l2_adapter" "$TOP_DIR/buildroot/dl/sglib"
  fi
}

function clean_v4l2_isp()
{
	export V4L2_ISP_ENABLE=1
	cd ${TOP_DIR}/middleware/${MW_VER}/modules/isp/cv186x/
	rm -rf v4l2_adapter/sophon-soc-libisp*
	make clean
	cd isp-tool-daemon-v4l2
	make clean
	export V4L2_ISP_ENABLE=0
}


# 拉取解压sophon-sdk
function build_bm1686_sdk {
    # bm1686 tpu_kernel
    echo "build_bm1686_sdk"
}
function clean_bm1686_sdk {
	rm -rf ${TPU_SDK_PATH}
}

function clean_tdl_sdk()
{
  pushd "$TDL_SDK_PATH"
  ./build_tdl_sdk.sh clean
  popd
}

function build_tdl_sdk()
{
  if [ ! -e "$TPU_SDK_INSTALL_PATH" ]; then
    echo "$TPU_SDK_INSTALL_PATH not present, run build_tpu_sdk first"
    return 1
  fi
  clean_tdl_sdk

  pushd "$TDL_SDK_PATH"
  ./build_tdl_sdk.sh all
  test "$?" -ne 0 && print_notice "${FUNCNAME[0]}() failed !!" && popd && return 1
  if grep -q '^CONFIG_ROOTFS_UBUNTU=y' "${TOP_DIR}"/build/.config; then
    rm -rf pkg_root install/${CHIP_ARCH}/*.deb
    create_debian_dir tdlsdk pkg_root 1.0.0 arm64
    cp -a install/$CHIP_ARCH/* pkg_root/opt/sophon/tdlsdk
    dpkg-deb --build pkg_root install/${CHIP_ARCH}/tdlsdk_1.0.0_arm64.deb
    rm -rf pkg_root 
    echo "package tdlsdk done"
    fi
  popd
}

function build_osdrv()
{(
  print_notice "Run ${FUNCNAME[0]}() ${1} function"

  cd "$BUILD_PATH" || return
  make "$ROOTFS_DIR"

  local osdrv_target="$1"
  if [ -z "$osdrv_target" ]; then
    osdrv_target=all
  fi

  pushd "$OSDRV_PATH"
  make KERNEL_DIR="$KERNEL_PATH"/"$KERNEL_OUTPUT_FOLDER" INSTALL_DIR="$SYSTEM_OUT_DIR"/ko "$osdrv_target" || return "$?"
  popd
)}

function clean_osdrv()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  pushd "$OSDRV_PATH"
  make KERNEL_DIR="$KERNEL_PATH"/"$KERNEL_OUTPUT_FOLDER" INSTALL_DIR="$SYSTEM_OUT_DIR"/ko clean || return "$?"
  popd
}

function clean_libsophon()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  if [ -d "${TPU_SDK_INSTALL_PATH}" ]; then
    find "${TPU_SDK_INSTALL_PATH}" \
      -maxdepth 1 -type d -name "libsophon-*" \
      -exec rm -rf {} \;
    find "${TPU_SDK_INSTALL_PATH}" \
      -maxdepth 1 -type l -name "libsophon-*" \
      -exec rm -rf {} \;
  fi

  if [ -d "$SYSTEM_OUT_DIR"/usr/lib ]; then
    find "$SYSTEM_OUT_DIR"/usr/lib \
      -maxdepth 1 -type d -name "libsophon-*" \
      -exec rm -rf {} \;
    find "$SYSTEM_OUT_DIR"/usr/lib \
      -maxdepth 1 -type l -name "libsophon-*" \
      -exec rm -rf {} \;
  fi

  if [ -f "$SYSTEM_OUT_DIR"/ko/bmtpu.ko ]; then
    rm -f "$SYSTEM_OUT_DIR"/ko/bmtpu.ko
  fi

  if [ -d "$LIBSOPHON_PATH"/install ]; then
    rm -rf "$LIBSOPHON_PATH"/install/*
  fi
  rm -rf "$LIBSOPHON_PATH"/build
}

function clean_bmsophon()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  rm -rf "$LIBSOPHON_PATH"/pcie_build
}



function build_bmsophon()
{
  clean_bmsophon
  print_notice "Run ${FUNCNAME[0]}() function"

  local _static_lib=OFF
  local _install_prefix="$LIBSOPHON_PATH"/pcie_build/install
  if ! grep -q '^CONFIG_ROOTFS_UBUNTU=y' "${TOP_DIR}"/build/.config; then
    _static_lib=ON
    _install_prefix="$SYSTEM_OUT_DIR"/usr/lib
  fi

  local lib_dir="$LIBSOPHON_PATH"/3rdparty/soc/
  local toolchain_file="$LIBSOPHON_PATH"/toolchain-aarch64-linux.cmake

  pushd "$LIBSOPHON_PATH" || return

  cmake \
    -B pcie_build \
    -G Ninja \
    -DPLATFORM=pcie_arm64 \
    -DSOC_LINUX_DIR="$KERNEL_PATH"/build/"$SIDE_TYPE"_"$BOARD" \
    -DLIB_DIR="${lib_dir}" \
    -DCROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_64_631" \
    -DCMAKE_TOOLCHAIN_FILE="${toolchain_file}" \
    -DBUILD_STATIC_LIB="${_static_lib}" \
    -DCMAKE_INSTALL_PREFIX="${_install_prefix}" \
    -DDEBUG=OFF \
    -DCMAKE_BUILD_TYPE=Release \

  cmake --build pcie_build --parallel "$(nproc)"
  cmake --build pcie_build --target driver
  cmake --build pcie_build --target package --parallel "$(nproc)"
}

function clean_amd64_bmsophon()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  rm -rf "$LIBSOPHON_PATH"/amd64_build
}



function build_amd64_bmsophon()
{
  clean_amd64_bmsophon
  print_notice "Run ${FUNCNAME[0]}() function"

  local _install_prefix="$LIBSOPHON_PATH"/build/install

  pushd "$LIBSOPHON_PATH" || return

  cmake \
    -B amd64_build \
    -G Ninja \
    -DPLATFORM=pcie \
    -DCMAKE_INSTALL_PREFIX="${_install_prefix}" \
    -DDEBUG=OFF \
    -DCMAKE_BUILD_TYPE=Release \

  cmake --build amd64_build --parallel "$(nproc)"
  cmake --build amd64_build --target driver
  cmake --build amd64_build --target package --parallel "$(nproc)"
}

function build_bmtpu()
{
    pushd "$LIBSOPHON_PATH"/driver || return
    make SOC_LINUX_DIR="$KERNEL_PATH"/"$KERNEL_OUTPUT_FOLDER" SOC_MODE=1
    popd
}

function build_libsophon()
{
  clean_libsophon
  print_notice "Run ${FUNCNAME[0]}() function"

  local _static_lib=OFF
  local _install_prefix="$LIBSOPHON_PATH"/build/install
  if ! grep -q '^CONFIG_ROOTFS_UBUNTU=y' "${TOP_DIR}"/build/.config; then
    _static_lib=ON
    _install_prefix="$SYSTEM_OUT_DIR"/usr/lib
  fi

  local lib_dir="$LIBSOPHON_PATH"/3rdparty/soc/
  local toolchain_file="$LIBSOPHON_PATH"/toolchain-aarch64-linux.cmake
  if grep -q '^CONFIG_TOOLCHAIN_GLIBC_ARM64_V930=y' ${TOP_DIR}/build/.config; then
    lib_dir="$LIBSOPHON_PATH"/3rdparty/lib930/
    toolchain_file="$LIBSOPHON_PATH"/toolchain-aarch64-linux-930.cmake
  elif grep -q '^CONFIG_TOOLCHAIN_GLIBC_ARM64_V1131=y' ${TOP_DIR}/build/.config; then
    lib_dir="$LIBSOPHON_PATH"/3rdparty/lib1131/
    toolchain_file="$LIBSOPHON_PATH"/toolchain-aarch64-linux-1131.cmake
  fi

  pushd "$LIBSOPHON_PATH" || return

  cmake \
    -B build \
    -G Ninja \
    -DPLATFORM=soc \
    -DSOC_LINUX_DIR="$KERNEL_PATH"/build/"$SIDE_TYPE"_"$BOARD" \
    -DLIB_DIR="${lib_dir}" \
    -DCROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_64" \
    -DCMAKE_TOOLCHAIN_FILE="${toolchain_file}" \
    -DBUILD_STATIC_LIB="${_static_lib}" \
    -DCMAKE_INSTALL_PREFIX="${_install_prefix}" \
    -DDEBUG=OFF \
    -DCMAKE_BUILD_TYPE=Release \

  cmake --build build --parallel "$(nproc)"
  cmake --build build --target driver --verbose

  cmake --build build --target package install --parallel "$(nproc)"
  if [ "${BUILD_DOC}" == "1" ]; then
    cmake --build build --target doc
    cmake --build build --target rtdoc
    pushd libsophav/bmcv || return
    CHIP=bm1688 make doc
    popd
  fi

  if [ -d "$TOP_DIR/buildroot" ]; then
     mkdir -p "$TOP_DIR/buildroot/dl/sglib"
     update_files_if_newer "libsophon_soc_*_aarch64.tar.gz" "$LIBSOPHON_PATH/build" "$TOP_DIR/buildroot/dl/sglib"
  fi

  [ "$SIDE_TYPE" = edge ] && return

  cp -af "${_install_prefix}"/libsophon-* "$TPU_SDK_INSTALL_PATH" || return
  cp -af "$LIBSOPHON_PATH"/build/driver/sg_aarch64_soc_device/bmtpu.ko "$SYSTEM_OUT_DIR"/ko || return
  LIBSOPHON_VERSION=$(grep "CMAKE_PROJECT_VERSION:STATIC" < "${LIBSOPHON_PATH}"/build/CMakeCache.txt | awk -F '=' '{print $2}') || { echo "Failed to get version"; return; }
  rsync -av --ignore-existing "${lib_dir}/lib/" "${_install_prefix}/libsophon-${LIBSOPHON_VERSION}/lib/"
  if [ ! -d "$LIBSOPHON_PATH"/install/libsophon-${LIBSOPHON_VERSION} ]; then
    mkdir -p "$LIBSOPHON_PATH"/install #some modules use it
    cp -af "${_install_prefix}"/libsophon-* "$LIBSOPHON_PATH"/install || return
  fi
  if [ ! -d "$LIBSOPHON_PATH"/install/libsophon-0.4.9 ]; then
    ln -sf libsophon-${LIBSOPHON_VERSION} "$LIBSOPHON_PATH"/install/libsophon-0.4.9
  fi
  if [ ! -d "${_install_prefix}"/libsophon-0.4.9 ]; then
    ln -sf libsophon-${LIBSOPHON_VERSION} "${_install_prefix}"/libsophon-0.4.9
  fi
  if [ ! -d "$TPU_SDK_INSTALL_PATH"/libsophon-0.4.9 ]; then
    ln -sf libsophon-${LIBSOPHON_VERSION} "$TPU_SDK_INSTALL_PATH"/libsophon-0.4.9
  fi
  popd

}

function build_nvr_edge
{
  print_notice "Run ${FUNCNAME[0]}() function"
  local _nvr_edge_path="${TOP_DIR}/frameworks/nvr_edge"
  local toolchain_file="$_nvr_edge_path"/toolchain-aarch64-linux-1131.cmake
  pushd ${_nvr_edge_path} || return 1

  cmake \
    -B build \
    -DTARGET_ARCH=soc \
    -DCMAKE_TOOLCHAIN_FILE="$toolchain_file" \
    -DCROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_64" \

  cmake --build build --parallel "$(nproc || echo 1)" || { popd; return 1; }

  release_nvr_tgz
  release_nvr_deb
  popd
}

function build_debian_based_rootfs
{
  print_notice "Run ${FUNCNAME[0]}() function"

  setup_debian_env || { ret=$?; echo "Error: setup_debian_env failed with exit code $ret"; return $ret; }
  fetch_debian_based_rootfs || { ret=$?; echo "Error: fetch_debian_based_rootfs failed with exit code $ret"; return $ret; }
  local version=$(grep Version $DISTRO_OVERLAY_DIR/$CVIARCH/sophgo-fs/DEBIAN/control | cut -d ' ' -f 2)
  mkdir -p "${EDGE_ROOTFS_DIR}"/home/linaro/debs
  dpkg-deb -b "${DISTRO_OVERLAY_DIR}/${CVIARCH}/sophgo-fs" \
    "${EDGE_ROOTFS_DIR}/home/linaro/debs/sophgo-bsp-rootfs_${version}_arm64.deb"

  mkdir -p ${BSP_DEBS}
  mkdir -p ${SDK_DEBS}
  mkdir -p ${MOD_DEBS}
  rm -rf "${BSP_DEBS}"/linux*.deb
  rm -rf "${SDK_DEBS}"/linux-image*.deb

  shopt -s nullglob
  if [ "$KERNEL_SRC" = "linux-common" ]; then
    update_files_if_newer "linux*.deb" "${TOP_DIR}/linux-common/build" "${BSP_DEBS}"
  elif [ "$KERNEL_SRC" = "linux_5.10" ]; then
    update_files_if_newer "linux*.deb" "${TOP_DIR}/linux_5.10/build" "${BSP_DEBS}"
  else
    echo "error, KERNEL_SRC should be 'linux-common' or 'linux_5.10'. " >&2
  fi

  if [ "$SIDE_TYPE" = "device" ]; then
    update_files_if_newer "middleware_*.deb" "${TOP_DIR}/middleware/${MW_VER}" "${SDK_DEBS}"
    update_files_if_newer "tdlsdk_*.deb" "${TOP_DIR}/tdl_sdk/install/${CHIP_ARCH}" "${SDK_DEBS}"
  elif [ "$SIDE_TYPE" = "edge" ]; then
    update_files_if_newer "sophon-media-soc-sophon-{ffmpeg,opencv,gstreamer,sample}_*_arm64.deb" "${TOP_DIR}/sophon_media/buildit" "${SDK_DEBS}"
    update_files_if_newer "sophon-soc-libisp*arm64.deb" "${TOP_DIR}/middleware/v2/modules/isp/cv186x/v4l2_adapter" "${SDK_DEBS}"

  else
    echo "error, SIDE_TYPE should be 'device' or 'edge'。" >&2
  fi
  update_files_if_newer "sophon-soc-libsophon*.deb" "${TOP_DIR}/libsophon/build" "${SDK_DEBS}"

  shopt -u nullglob

  echo copy overlay file to rootfs...
  sudo cp -rf \
    "$DISTRO_OVERLAY_DIR"/common/rootfs/* \
    "$DISTRO_OVERLAY_DIR"/"$CVIARCH"/rootfs/* \
    "${EDGE_ROOTFS_DIR}"

  python $COMMON_TOOLS_PATH/image_tool/mkcvipart_edge.py $FLASH_PARTITION_XML "${EDGE_ROOTFS_DIR}/etc/" --fw_env
  # copy customer's debs
  find "${TOP_DIR}"/ubuntu/bootloader-arm64/distro/debs \
    -name *.deb -exec cp -f {} "${MOD_DEBS}" \;

  mkdir -p "${EDGE_ROOTFS_DIR}"/home/linaro/bsp-debs
  find "${BSP_DEBS}" -maxdepth 1 -type f -exec sudo cp -f {} "${EDGE_ROOTFS_DIR}"/home/linaro/bsp-debs \;
  find "${SDK_DEBS}" -maxdepth 1 -type f -exec sudo cp -f {} "${EDGE_ROOTFS_DIR}"/home/linaro/debs \;
  find "${MOD_DEBS}" -maxdepth 1 -type f -exec sudo cp -f {} "${EDGE_ROOTFS_DIR}"/home/linaro/debs \;

  echo install packages...
sudo chroot "${EDGE_ROOTFS_DIR}" /bin/bash << EOT
#!/bin/bash

echo -e "LC_ALL=C.UTF-8\n" > /etc/default/locale
echo "Defaults timestamp_timeout=43200" | tee -a /etc/sudoers

for deb_dir in /debs /home/linaro/debs; do
  retries=0
  if [  -d \${deb_dir} ] && [ \$(ls \${deb_dir}/*.deb | wc -l) -gt 0 ]; then
    while [ \${retries} -lt 3 ]; do
      sleep 1
      if dpkg -i -R \${deb_dir}; then
        break
      fi
      retries=\$((retries + 1))
    done
  fi

  if [ \${retries} -eq 3 ]; then
    exit 1
  fi

  for file in \${deb_dir}/*; do
    file=\$(basename \${file})
    if  [ "\${file##*.}" == "whl" ]; then
        pip3 install --no-index --find-links=file://\${deb_dir} \${file%%-*}
    fi
  done
  rm -rf \${deb_dir}
done
systemctl disable apt-daily.timer apt-daily-upgrade.timer
systemctl disable apt-daily.service apt-daily-upgrade.service
systemctl disable unattended-upgrades.service
systemctl mask unattended-upgrades.service apt-daily.service apt-daily-upgrade.service

EOT

  echo packing rootfs...
  pushd "${EDGE_ROOTFS_DIR}"
  sudo chown 1000:1000 -R data
  popd
}

function build_sdk_rootfs()
{
  echo "BOARD value is: '${BOARD}'"
  if ! grep -q '^CONFIG_ROOTFS_UBUNTU=y' "${TOP_DIR}"/build/.config; then
    pack_cfg || { ret=$?; echo "Error: pack_cfg failed with exit code $ret"; return $ret; }
    pack_rootfs || { ret=$?; echo "Error: pack_rootfs failed with exit code $ret"; return $ret; }
    pack_data || { ret=$?; echo "Error: pack_data failed with exit code $ret"; return $ret; }
    pack_system || { ret=$?; echo "Error: pack_system failed with exit code $ret"; return $ret; }
    pack_gpt || { ret=$?; echo "Error: pack_gpt failed with exit code $ret"; return $ret; }
    copy_tools || { ret=$?; echo "Error: copy_tools failed with exit code $ret"; return $ret; }
    pack_upgrade || { ret=$?; echo "Error: pack_upgrade failed with exit code $ret"; return $ret; }
  else
    build_debian_based_rootfs || { ret=$?; echo "Error: build_debian_based_rootfs failed with exit code $ret"; return $ret; }

    if [ "${target}" != "regression" ]; then
        build_edge_package || { ret=$?; echo "Error: build_edge_package failed with exit code $ret"; return $ret; }
    fi
  fi

}

function build_sophon_media(){
  if [ ! -d "${TOP_DIR}/sophon_media" ]; then
    return 0
  fi

  print_notice "Run ${FUNCNAME[0]}() function"
  MEDIA_DEBUG="off"
  if [ "$MEDIA_DEBUG" = "on" ]; then
    CMAKE_BUILD_TYPE="Debug"
  else
    CMAKE_BUILD_TYPE="Release"
  fi
  mkdir -p ${TOP_DIR}/sophon_media/buildit
  pushd ${TOP_DIR}/sophon_media/buildit
  GCC_V="1131"
  if grep -q '^CONFIG_TOOLCHAIN_GLIBC_ARM64_V930=y' ${TOP_DIR}/build/.config; then
    #source build/build_cmake.sh 930 soc
    GCC_V="930"
  elif grep -q '^CONFIG_TOOLCHAIN_GLIBC_ARM64_V1131=y' ${TOP_DIR}/build/.config; then
    #source build/build_cmake.sh 1131 soc
    GCC_V="1131"
  elif grep -q '^CONFIG_TOOLCHAIN_GLIBC_ARM64=y' ${TOP_DIR}/build/.config; then
    #source build/build_cmake.sh 630 soc
    GCC_V="630"
  fi
  cmake -DPLATFORM=soc -DGCC_VERSION=$GCC_V -DSUBTYPE=asic \
	-DCMAKE_INSTALL_PREFIX=../install \
	-DDEBUG=$MEDIA_DEBUG \
        -DCMAKE_BINARY_DIR=${TOP_DIR}/sophon_media/buildit \
	-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE ..
  cmake --build . --target all -- -j`nproc`
  cmake --build . --target sophon_sample
  cmake --build . --target package
  popd

  if [ -d "$TOP_DIR/buildroot" ]; then
     mkdir -p "$TOP_DIR/buildroot/dl/sglib"
     update_files_if_newer "sophon-media-soc_*_aarch64.tar.gz" "${TOP_DIR}/sophon_media/buildit" "$TOP_DIR/buildroot/dl/sglib"
  fi
}

function build_pcie_arm64_sophon_media(){
  print_notice "Run ${FUNCNAME[0]}() function"
  MEDIA_DEBUG="off"
  if [ "$MEDIA_DEBUG" = "on" ]; then
    CMAKE_BUILD_TYPE="Debug"
  else
    CMAKE_BUILD_TYPE="Release"
  fi
  mkdir -p ${TOP_DIR}/sophon_media/pcie_arm64_buildit
  pushd ${TOP_DIR}/sophon_media/pcie_arm64_buildit
  GCC_V="630"
  cmake -DPLATFORM=pcie_arm64 -DGCC_VERSION=$GCC_V -DSUBTYPE=asic \
        -DCMAKE_INSTALL_PREFIX=../pcie_arm64_install \
        -DDEBUG=$MEDIA_DEBUG \
        -DCMAKE_BINARY_DIR=${TOP_DIR}/sophon_media/pcie_amr64_buildit \
        -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE ..
  cmake --build . --target all -- -j`nproc`
  cmake --build . --target sophon_sample
  cmake --build . --target package
  popd
}

function build_pcie_amd64_sophon_media(){
  print_notice "Run ${FUNCNAME[0]}() function"
  MEDIA_DEBUG="off"
  if [ "$MEDIA_DEBUG" = "on" ]; then
    CMAKE_BUILD_TYPE="Debug"
  else
    CMAKE_BUILD_TYPE="Release"
  fi
  mkdir -p ${TOP_DIR}/sophon_media/pcie_amd64_buildit
  pushd ${TOP_DIR}/sophon_media/pcie_amd64_buildit
  cmake -DPLATFORM=pcie -DSUBTYPE=asic \
        -DCMAKE_INSTALL_PREFIX=../pcie_amd64_install \
        -DDEBUG=$MEDIA_DEBUG \
        -DCMAKE_BINARY_DIR=${TOP_DIR}/sophon_media/pcie_amd64_buildit \
        -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE ..
  cmake --build . --target all -- -j`nproc`
  cmake --build . --target sophon_sample
  cmake --build . --target package
  popd
}


function clean_sophon_media(){
  print_notice "Run ${FUNCNAME[0]}() function"
  if [ ! -d "${TOP_DIR}/sophon_media" ]; then
    return 0
  fi

  pushd ${TOP_DIR}/sophon_media
  rm -rf *buildit *install
  popd
}

function clean_distro() {
  if [ -d "${TOP_DIR}/ubuntu/distro" ]; then
    find "${TOP_DIR}/ubuntu/distro" \
      -name "distro_*.tgz" -delete
  fi
}

function clean_nvr_edge(){
  print_notice "Run ${FUNCNAME[0]}() function"
  if [ ! -d "${TOP_DIR}/frameworks/nvr_edge" ]; then
    return 0
  fi

  pushd ${TOP_DIR}/frameworks/nvr_edge
  rm -rf build
  rm -rf nvr_edge_*
  popd
}

download_and_verify_file() {
    local file_url="$1"
    local file_path="$2"
    local expected_md5="$3"
    local download_tool="$4"

    echo "Processing file: $(basename "$file_path")"

    if [ ! -e "$file_path" ]; then
        echo "Downloading file..."
        case $download_tool in
            "wget")
                wget -q --show-progress "$file_url" -O "$file_path"
                ;;
            "dfss")
                python -m dfss --url="$file_url"
                local filename=$(basename "$file_url")
                if [ -f "$filename" ]; then
                    mv "$filename" "$file_path"
                fi
                ;;
            *)
                echo "Unsupported download tool: $download_tool"
                return 1
                ;;
        esac
    else
        local current_md5=$(md5sum "$file_path" | awk '{print $1}')
        if [ "$current_md5" != "$expected_md5" ]; then
            echo "File exists but MD5 mismatch, re-downloading..."
            rm -f "$file_path"
            case $download_tool in
                "wget") wget -q --show-progress "$file_url" -O "$file_path" ;;
                "dfss")
                    python -m dfss --url="$file_url"
                    local filename=$(basename "$file_url")
                    [ -f "$filename" ] && mv "$filename" "$file_path"
                    ;;
            esac
        else
            echo "File exists and MD5 matches, skipping download."
        fi
    fi

    local final_md5=$(md5sum "$file_path" | awk '{print $1}')
    if [ "$final_md5" != "$expected_md5" ]; then
        echo "Error: File $(basename "$file_path") MD5 verification failed after download."
        echo "Expected MD5: $expected_md5"
        echo "Actual MD5: $final_md5"
        return 1
    fi

    echo "File verification successful."
    return 0
}

function setup_debian_env() {
    SUPPORTED_DISTROS=("jammy" "focal" "debian" "bookworm")
    DISTRO=${BUILD_ROOTFS_NAME:-jammy}
    SUPPORTED=0
    for d in "${SUPPORTED_DISTROS[@]}"; do
        if [ "$d" = "$DISTRO" ]; then
            SUPPORTED=1
            break
        fi
    done

    if [ $SUPPORTED -eq 0 ]; then
        echo "warning:not support DISTRO: '$DISTRO',use default 'jammy'"
        export DISTRO="jammy"
    fi
    export ROOT_TOP_DIR="$TOP_DIR"/ubuntu
    export ROOT_OUT_DIR=${ROOT_TOP_DIR}/install/soc_${CVIARCH}
    export EDGE_ROOTFS_DIR=${ROOT_TOP_DIR}/install/soc_${CVIARCH}/rootfs
    export DISTRO_OVERLAY_DIR="${TOP_DIR}"/ubuntu/bootloader-arm64/distro/overlay

    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "bookworm" ]; then
        export DISTRO_MD5="aebaa36fee0119bca6f286858117764f"
        export DISTRO_URL="open@sophgo.com:/gemini-sdk/rootfs/bookworm_${DISTRO_MD5}.tgz"
        export FETCH_CMD="dfss"
    else
        case "$DISTRO" in
            "focal")
                export DISTRO_MD5="f93ebbaa47adb3231aef80661e9d01bf"
                ;;
            "jammy")
                export DISTRO_MD5="c6d415287309d0f61f05186621e5bb58"
                ;;
        esac
        export DISTRO_URL="open@sophgo.com:/gemini-sdk/rootfs/distro_${DISTRO}_${DISTRO_MD5}.tgz"
        export FETCH_CMD="dfss"
    fi

  export BSP_DEBS=${ROOT_OUT_DIR}/bsp-debs
  export SDK_DEBS=${ROOT_OUT_DIR}/sdk-debs
  export MOD_DEBS=${ROOT_OUT_DIR}/mod-debs
}

function fetch_debian_based_rootfs() {
    sudo rm -rf "${EDGE_ROOTFS_DIR}"
    mkdir -p "${EDGE_ROOTFS_DIR}"

    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "bookworm" ]; then
        local download_dir="${TOP_DIR}/ubuntu/bookworm"
        local file_path="${download_dir}/bookworm.tgz"
        mkdir -p "$download_dir"
        cd "$download_dir"

        download_and_verify_file "$DISTRO_URL" "$file_path" "$DISTRO_MD5" "$FETCH_CMD" || return 1
        zcat "$file_path" | sudo tar -C "${EDGE_ROOTFS_DIR}" -x -f -
    else
        local download_dir="${TOP_DIR}/ubuntu/distro"
        local file_path="${download_dir}/distro_${DISTRO}.tgz"
        mkdir -p "$download_dir"

        download_and_verify_file "$DISTRO_URL" "$file_path" "$DISTRO_MD5" "$FETCH_CMD" || return 1
        zcat "$file_path" | sudo tar -C "${EDGE_ROOTFS_DIR}" -x -f -
    fi
}

function build_edge_sdk() {
  print_notice "Run ${FUNCNAME[0]}() function"

  build_uboot || { ret=$?; echo "Error: build_uboot failed with exit code $ret"; return $ret; }
  build_kernel || { ret=$?; echo "Error: build_kernel failed with exit code $ret"; return $ret; }
  build_osdrv || { ret=$?; echo "Error: build_osdrv failed with exit code $ret"; return $ret; }
  build_ramboot || { ret=$?; echo "Error: build_ramboot failed with exit code $ret"; return $ret; }
  build_v4l2_isp || { ret=$?; echo "Error: build_v4l2_isp failed with exit code $ret"; return $ret; }

  if [ "${target}" == "regression" ]; then
    build_libsophon || { echo "Error: build_libsophon failed with exit code $?"; return $?; }
  else
    build_libsophon || { ret=$?; echo "Error: build_libsophon failed with exit code $ret"; return $ret; }
    build_sophon_media || { ret=$?; echo "Error: build_sophon_media failed with exit code $ret"; return $ret; }
    ## build pcie deb
    if [[ -z "$MINI_BUILD" ]]; then
    	build_bmsophon || { ret=$?; echo "Error: build_bmsophon failed with exit code $ret"; return $ret; }
    	build_amd64_bmsophon || { ret=$?; echo "Error: build_amd64_bmsophon failed with exit code $ret"; return $ret; }
    	build_pcie_arm64_sophon_media || { ret=$?; echo "Error: build_pcie_arm64_sophon_media failed with exit code $ret"; return $ret; }
    	build_pcie_amd64_sophon_media || { ret=$?; echo "Error: build_pcie_amd64_sophon_media failed with exit code $ret"; return $ret; }
    fi
  fi
}

function build_edge_package(){
  cd ${TOP_DIR}
  cp ${TOP_DIR}/ubuntu/bootloader-arm64/scripts/ota_update.sh ${TOP_DIR}/build/scripts
  build_package
}

function build_edge_all(){
  local target=${1:-all}

  build_edge_sdk || { ret=$?; echo "Error: build_edge_sdk failed with exit code $ret"; return $ret; }
  build_sdk_rootfs || { ret=$?; echo "Error: build_sdk_rootfs failed with exit code $ret"; return $ret; }
}

function clean_edge_all(){
  clean_uboot
  clean_kernel
  clean_osdrv
  clean_ramdisk
  clean_v4l2_isp
  cd ${TOP_DIR}
  clean_libsophon
  clean_bmsophon
  clean_amd64_bmsophon
  clean_sophon_media
  rm -rf ${TOP_DIR}/ubuntu/install

  if grep -q '^CONFIG_ROOTFS_BUILD_FROM_BR2=y' ${TOP_DIR}/build/.config; then
	clean_rootfs || return $?
  fi
}

function build_bmcpu()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  if [ ! -d "$BMCPU_PATH"/build ]; then
    mkdir -p "$BMCPU_PATH"/build
  fi

  pushd "$BMCPU_PATH"/build || return "$?"
  rm -rf "$BMCPU_PATH"/build/*
  cmake -DCMAKE_TOOLCHAIN_FILE=$BMCPU_PATH/riscv_linux.cmake -DPLATFORM=bm1688 ..
  make
  cp -f $BMCPU_PATH/build/app/bmcpu/bmcpu $RAMDISK_PATH/initramfs/glibc_riscv64/bin/bmcpu || return "$?"
  popd
}

function clean_bmcpu()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  rm -rf "$BMCPU_PATH"/build/*
  rm -rf "$BMCPU_PATH"/install/*
}

function _build_cvi_pipeline_env()
{
  export SYSTEM_OUT_DIR CROSS_COMPILE_PATH_32 CROSS_COMPILE_PATH_64 CROSS_COMPILE_PATH_UCLIBC
}

function build_cvi_pipeline()
{
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_cvi_pipeline_env

  pushd "$CVI_PIPELINE_PATH"
  ./build.sh "1"
  ./install_base_pkg.sh prebuilt "$(pwd)/install"
  ./download_models.sh "$(pwd)/install/cvi_models"
  make install DESTDIR="$(pwd)/install/system" LIBC_PATH="$TOOLCHAIN_PATH/gcc/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/lib/"
  popd
}

function clean_cvi_pipeline()
{
  pushd "$CVI_PIPELINE_PATH"
  make clean
  rm -rf cvi_pipeline.tar.gz
  rm -rf prebuilt/*
  popd
}

function _build_cvi_rtsp_env()
{
  export CROSS_COMPILE
}


function build_cvi_rtsp()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _build_cvi_rtsp_env

  cd "$CVI_RTSP_PATH" || return
  mkdir -p prebuilt
  cp ${OSS_TARBALL_PATH}/live555.tar.gz prebuilt/
  BUILD_SERVICE=1 MW_DIR=${MW_PATH} ./build.sh
  test $? -ne 0 && print_notice "build_cvi_rtsp failed !!" && return 1
  BUILD_SERVICE=1 make install DESTDIR="$(pwd)/install"
  make package DESTDIR="$(pwd)/install"

  if [[ "$FLASH_SIZE_SHRINK" != "y" ]]; then
    BUILD_SERVICE=1 make install DESTDIR="${SYSTEM_OUT_DIR}/usr"
  fi
)}

function clean_cvi_rtsp()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  cd "$CVI_RTSP_PATH" || return
  BUILD_SERVICE=1 make clean
)}

function build_pqtool_server()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  cd "$PQTOOL_SERVER_PATH" || return
  make all SDK_VER="$SDK_VER" MULTI_PROCESS_SUPPORT="$MULTI_PROCESS_SUPPORT"

  if [ "$?" -ne 0 ]; then
    print_notice "build pqtool_server failed !!"
    return 1
  fi

  if [[ "$FLASH_SIZE_SHRINK" != "y" ]]; then
    make install DESTDIR="$SYSTEM_OUT_DIR"
  fi
  cd "$PQTOOL_SERVER_V2_PATH" || return
  ./build.sh || { print_notice "build_pqtool_server v2 failed !!"; return 1; }
)}

function clean_pqtool_server()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  cd "$PQTOOL_SERVER_PATH" || return
  make clean
  make uninstall DESTDIR="$SYSTEM_OUT_DIR"
  cd "$PQTOOL_SERVER_V2_PATH" || return
  make clean
)}

function build_3rd_party()
{
  mkdir -p "$OSS_TARBALL_PATH"

  if [ -d "${OSS_PATH}/oss_release_tarball" ]; then
    echo "oss prebuilt tarball found!"
  else
    echo "Try to download oss_release_tarball.tar tarball ..."
    #wget ...
    #tar -xvf ${OSS_PATH}/oss_release_tarball.tar -C ${OSS_PATH}
  fi
  echo "cp -rpf ${OSS_PATH}/oss_release_tarball/${SDK_VER}/*  ${OSS_TARBALL_PATH}"
  cp -rpf ${OSS_PATH}/oss_release_tarball/${SDK_VER}/*  ${OSS_TARBALL_PATH}

  local oss_list=(
    "zlib"
    "glog"
    "flatbuffers"
    "opencv"
    "live555"
    "sqlite3"
    "ffmpeg"
    "thttpd"
    "openssl"
    "libwebsockets"
    "json-c"
    "nanomsg"
    "miniz"
    "uv"
    "cvi-json-c"
    "cvi-miniz"
    "curl"
    "opencv4.5"
    "stb"
    "nlohmannjson"
    "kissfft"
    "kaldi-native-fbank"
    "googletest"
    "eigen"
  )

  for name in "${oss_list[@]}"
  do
    if [ -f "${OSS_TARBALL_PATH}/${name}.tar.gz" ]; then
      echo "$name found"
      "$OSS_PATH"/run_build.sh -n "$name" -e -t "$OSS_TARBALL_PATH" -i "$TPU_SDK_INSTALL_PATH"
        echo "$name successfully downloaded and untared."
    else
      echo "$name not found"
    fi
  done
}


function clean_3rd_party()
{
  rm -rf "$OSS_PATH"/build
  rm -rf "$OSS_TARBALL_PATH"
}

function clean_ramdisk()
{
  rm -rf "${RAMDISK_PATH:?}"/"$RAMDISK_OUTPUT_BASE"
  rm -rf "$SYSTEM_OUT_DIR"
  rm -rf "$ROOTFS_DIR"
}

function build_access_guard_turnkey_app()
{(
  if [[ -d "$ACCESSGUARD_PATH" ]] && [[ "$BUILD_TURNKEY_ACCESSGUARD" = "y" ]]; then
    export SDK_PATH=$(pwd)
    export TOOLCHAIN_PATH="$CROSS_COMPILE_PATH_64"/bin/
    export TOOLCHAIN_PATH_32="$CROSS_COMPILE_PATH_32"/bin/
    export SDK_INSTALL_PATH="$OUTPUT_DIR"
    export KERNEL_INC="$KERNEL_PATH"/build/"$SIDE_TYPE"_"$BOARD"/usr/include/
    ln -sf "$SDK_INSTALL_PATH"/tpu_* "$SDK_INSTALL_PATH"/tpu
    pushd "$ACCESSGUARD_PATH"
      source build.sh
      access_guard_build || return 1
      access_guard_install || return 1
      mkdir -p "$SYSTEM_OUT_DIR"/data
      cp -a  ${ACCESSGUARD_PATH}/install "$SYSTEM_OUT_DIR"/data/
    popd
  fi
)}

function clean_access_guard_turnkey_app()
{(
  if [[ -d "$ACCESSGUARD_PATH" ]] && [[ "$BUILD_TURNKEY_ACCESSGUARD" = "y" ]]; then
    export SDK_PATH=$(pwd)
    export TOOLCHAIN_PATH="$CROSS_COMPILE_PATH_64"/bin/
    export TOOLCHAIN_PATH_32="$CROSS_COMPILE_PATH_32"/bin/
    export SDK_INSTALL_PATH="$OUTPUT_DIR"
    export KERNEL_INC="$KERNEL_PATH"/build/"$SIDE_TYPE"_"$BOARD"/usr/include/
    pushd "$ACCESSGUARD_PATH"
    source build.sh
    access_guard_clean
    popd
  fi
)}

function build_ipc_app()
{
  print_notice "Run ${FUNCNAME[0]}() function"
  if [[ -d "$IPC_APP_PATH" ]] && [[ "$BUILD_TURNKEY_IPC" = "y" ]]; then
    pushd "$IPC_APP_PATH"
        make clean; make; make ipc_install || return $?
        if [[ -f "$OUTPUT_DIR"/ipc_install.tar.gz ]] ; then
            rm "$OUTPUT_DIR"/ipc_install.tar.gz
        fi
        pushd install
        tar -czvf "$OUTPUT_DIR"/ipc_install.tar.gz "${IPC_APP_PATH}"/install/ipc_install || return $?
        popd
    popd
  fi
}

function clean_ipc_app()
{
  print_notice "Run ${FUNCNAME[0]}() function"
  if [[ -d "$IPC_APP_PATH" ]] && [[ "$BUILD_TURNKEY_IPC" = "y" ]]; then
    pushd "$IPC_APP_PATH"
        make clean
        if [[ -f "$OUTPUT_DIR"/ipc_install.tar.gz ]] ; then
            rm "$OUTPUT_DIR"/ipc_install.tar.gz
        fi
    popd
  fi
}

function prepare_git_hook()
{
   print_notice "Run ${FUNCNAME[0]}() function"
   if [[ -d ".git" ]]; then
	mkdir -p .git/hooks
	cp ${TOP_DIR}/build/hook/commit-msg .git/hooks/
	chmod +x .git/hooks/commit-msg
	cp ${TOP_DIR}/build/hook/prepare-commit-msg .git/hooks/
	chmod +x .git/hooks/prepare-commit-msg
   else
	print_notice "Abort .git is not exist !!!"
   fi
}

UPDATE_TYPES=(
sdcard
tftp
usb
)

# 传入 sdcard.tgz 文件路径，在当前目录生成 sdcard_out 并解包还原。
# 用法: revert_sdcard_package <path_to_sdcard.tgz>
function revert_sdcard_package()
{
	local SCRIPTS_DIR="${TOP_DIR}/build/scripts/"
	local input_tgz="${1:?usage: revert_sdcard_package <path_to_sdcard.tgz>}"
	local sdcard_tgz out tmp source_partition_xml

	sdcard_tgz="$(cd "$(dirname "$input_tgz")" && pwd)/$(basename "$input_tgz")" || return 1
	out="$PWD/sdcard_out"
	tmp="$PWD/.revert_sdcard_tmp"

	if [ ! -f "$sdcard_tgz" ]; then
		echo "sdcard.tgz does not exist: $sdcard_tgz" >&2
		return 1
	fi

	rm -rf "$tmp" "$out"
	mkdir -p "$tmp/package_update/update/sdcard" "$out"
	cp -r "$SCRIPTS_DIR/revert_package.sh" "$tmp/package_update/update/sdcard/"

	pushd "$PWD" || return 1
	tar -zxf "$sdcard_tgz" -m -C "$tmp/package_update/"
	source_partition_xml="$tmp/package_update/sdcard/partition32G_sector.xml"
	if [ ! -f "$source_partition_xml" ]; then
		echo "partition32G_sector.xml not found in sdcard.tgz" >&2
		popd
		rm -rf "$tmp"
		return 1
	fi
	cp -r "$tmp/package_update/sdcard/"* "$tmp/package_update/update/sdcard/"
	shopt -s nullglob
	for f in "$tmp/package_update/sdcard/"*.bin; do
		cp -r "$f" "$out/"
	done
	shopt -u nullglob
	cd "$tmp/package_update/update/sdcard" || { popd; return 1; }
	./revert_package.sh boot data rootfs rootfs_rw recovery

	cd ../
	sudo rm -rf ./*.tgz
	mv ./sdcard/*.tgz ./
	sudo rm -rf ./sdcard

	shopt -s nullglob
	for tgz in ./*.tgz; do
		part_name="$(basename "$tgz" .tgz)"
		mkdir -p "$out/$part_name"
		tar -zxf "$tgz" -C "$out/$part_name"
	done
	shopt -u nullglob

	cp -f "$source_partition_xml" "$out/"
	popd || return 1

	rm -rf "$tmp"
	echo "revert_sdcard_package finished: $out"
}

function rebuild_sdcard_package()
{
	local SCRIPTS_DIR="${TOP_DIR}/build/scripts/"
	local pkg_dir="${1:?usage: rebuild_sdcard_package <sdcard_out_dir>}"
	local partition_xml part
	local parts=(boot data rootfs rootfs_rw recovery misc)
	local created_tgz=()

	pkg_dir="$(cd "$pkg_dir" && pwd)" || return 1
	partition_xml="$pkg_dir/partition32G_sector.xml"

	if [ ! -f "$partition_xml" ]; then
		echo "partition32G_sector.xml not found in: $pkg_dir" >&2
		return 1
	fi

	pushd "$pkg_dir" || return 1

	rm -rf sdcard sdcard.tgz

	for part in "${parts[@]}"; do
		if [ -d "$part" ]; then
			tar -zcf "${part}.tgz" -C "$part" . || { popd; return 1; }
			created_tgz+=("${part}.tgz")
		fi
	done

	pushd "$SCRIPTS_DIR" || { popd; return 1; }
	if [ ! -e ./mk_gpt ]; then
		pushd mk-gpt || { popd; popd; return 1; }
		make || { popd; popd; popd; return 1; }
		popd || { popd; popd; return 1; }
	fi

	./bm_make_package_sectors.sh sdcard "$partition_xml" "$pkg_dir" || { popd; popd; return 1; }
	popd || { popd; return 1; }

	if [ ! -d "$pkg_dir/sdcard" ]; then
		echo "failed to generate $pkg_dir/sdcard" >&2
		popd
		return 1
	fi

	pushd "$pkg_dir/sdcard" || { popd; return 1; }
	cp "$SCRIPTS_DIR/local_update.sh" .
	cp "$SCRIPTS_DIR/ota_update.sh" .
	cp "$SCRIPTS_DIR/update_partition_gpt.sh" .
	cp "$SCRIPTS_DIR/update_gpt" .
	cp "$SCRIPTS_DIR/check_partition_start_sector.sh" .
	md5sum * > md5.txt
	popd || { popd; return 1; }

	tar -zcf sdcard.tgz sdcard || { popd; return 1; }

	for part in "${created_tgz[@]}"; do
		rm -f "$part"
	done

	popd || return 1
	echo "rebuild_sdcard_package finished: $pkg_dir/sdcard.tgz"
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

	./bm_make_package_sectors.sh $UPDATE_TYPE ./partition32G_sector.xml "$OUTPUT_DIR"/package_edge
	popd

	pushd $OUTPUT_DIR/package_edge/$1
	cp $SCRIPTS_DIR/local_update.sh .
	cp $SCRIPTS_DIR/ota_update.sh .
	cp $SCRIPTS_DIR/update_partition_gpt.sh .
	cp $SCRIPTS_DIR/update_gpt .
	cp $SCRIPTS_DIR/check_partition_start_sector.sh .
	md5sum * > md5.txt
	popd

}

function gen_sd_image()
{
    _build_kernel_env
    _build_uboot_env
    echo "Using partition xml: $FLASH_PARTITION_XML"
    python ${TOP_DIR}/build/tools/common/image_tool/mk_sd_image.py $FLASH_PARTITION_XML $OUTPUT_DIR
}

function build_package()
{
    sudo rm -rf $PACKAGE_OUTPUT_DIR
    mkdir -p $PACKAGE_OUTPUT_DIR
    mkdir -p $PACKAGE_OUTPUT_DIR/boot
    mkdir -p $PACKAGE_OUTPUT_DIR/rootfs_rw
    mkdir -p $PACKAGE_OUTPUT_DIR/bsp-debs
    mkdir -p $PACKAGE_OUTPUT_DIR/pcie
    mkdir -p $PACKAGE_OUTPUT_DIR/pcie/arm64
    mkdir -p $PACKAGE_OUTPUT_DIR/pcie/x86
    mkdir -p $PACKAGE_OUTPUT_DIR/nvr_release

    cp -rf $RAMDISK_PATH/$RAMDISK_OUTPUT_FOLDER/boot.itb $PACKAGE_OUTPUT_DIR/boot/
    cp -rf $RAMDISK_PATH/$RAMDISK_OUTPUT_FOLDER/multi.its $PACKAGE_OUTPUT_DIR/boot/
    cp -rf $OUTPUT_DIR/fip.bin $PACKAGE_OUTPUT_DIR/boot/
    cp -rf $HDCP_KEY_PATH/hdcp_key.bin $PACKAGE_OUTPUT_DIR/boot/
    cp -rf $BOOTLOGO_PATH/soph_logo.bmp $PACKAGE_OUTPUT_DIR/boot/

    cp -rf $OUTPUT_DIR/fip.bin $PACKAGE_OUTPUT_DIR/
    cp -rf $OUTPUT_DIR/ramboot.itb $PACKAGE_OUTPUT_DIR/
    update_files_if_newer "libsophon_0.4.*_aarch64.tar.gz" "$LIBSOPHON_PATH/pcie_build" "$PACKAGE_OUTPUT_DIR/pcie/arm64"
    update_files_if_newer "sophon-driver_*_arm64.deb" "$LIBSOPHON_PATH/pcie_build" "$PACKAGE_OUTPUT_DIR/pcie/arm64"
    update_files_if_newer "sophon-libsophon_*_arm64.deb" "$LIBSOPHON_PATH/pcie_build" "$PACKAGE_OUTPUT_DIR/pcie/arm64"
    update_files_if_newer "sophon-libsophon-dev_*_arm64.deb" "$LIBSOPHON_PATH/pcie_build" "$PACKAGE_OUTPUT_DIR/pcie/arm64"

    update_files_if_newer "sophon-media_*_aarch64.tar.gz" "${TOP_DIR}/sophon_media/pcie_arm64_buildit" "$PACKAGE_OUTPUT_DIR/pcie/arm64"
    update_files_if_newer "sophon-media-sophon*_arm64.deb" "${TOP_DIR}/sophon_media/pcie_arm64_buildit" "$PACKAGE_OUTPUT_DIR/pcie/arm64"

    update_files_if_newer "libsophon_*_x86_64.tar.gz" "$LIBSOPHON_PATH/amd64_build" "$PACKAGE_OUTPUT_DIR/pcie/x86"
    update_files_if_newer "sophon-driver_*_amd64.deb" "$LIBSOPHON_PATH/amd64_build" "$PACKAGE_OUTPUT_DIR/pcie/x86"
    update_files_if_newer "sophon-libsophon_*_amd64.deb" "$LIBSOPHON_PATH/amd64_build" "$PACKAGE_OUTPUT_DIR/pcie/x86"
    update_files_if_newer "sophon-libsophon-dev_*_amd64.deb" "$LIBSOPHON_PATH/amd64_build" "$PACKAGE_OUTPUT_DIR/pcie/x86"

    update_files_if_newer "sophon-media_*_x86_64.tar.gz" "${TOP_DIR}/sophon_media/pcie_amd64_buildit" "$PACKAGE_OUTPUT_DIR/pcie/x86"
    update_files_if_newer "sophon-media-sophon*_amd64.deb" "${TOP_DIR}/sophon_media/pcie_amd64_buildit" "$PACKAGE_OUTPUT_DIR/pcie/x86"

    update_files_if_newer "sophon-media-soc_*_aarch64.tar.gz" "${TOP_DIR}/sophon_media/buildit" "$OUTPUT_DIR/package_edge"
    update_files_if_newer "libsophon_soc_*_aarch64.tar.gz" "$LIBSOPHON_PATH/build" "$OUTPUT_DIR/package_edge"
    update_files_if_newer "sophon-soc-libisp_*_arm64.tar.gz" "${TOP_DIR}/middleware/v2/modules/isp/cv186x/v4l2_adapter" "$OUTPUT_DIR/package_edge"

    mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "${KERNEL_BOOT_TYPE} Boot Script" \
            -d ${TOP_DIR}/build/boot.cmd.${KERNEL_BOOT_TYPE} ${OUTPUT_DIR}/boot.scr.${KERNEL_BOOT_TYPE}
    cp -rf ${OUTPUT_DIR}/boot.scr.${KERNEL_BOOT_TYPE} $PACKAGE_OUTPUT_DIR/boot/
    pushd $PACKAGE_OUTPUT_DIR

    tar -zcvf boot.tgz -C boot .
    mv ramboot.itb recovery.itb
    tar -zcvf recovery.tgz recovery.itb

    sudo cp -rf  $OUTPUT_DIR/rootfs/mnt/system "${EDGE_ROOTFS_DIR}"/mnt/

    mkdir -p rootfs_rw/overlay/home/linaro
    sudo mv "${EDGE_ROOTFS_DIR}"/home/linaro/* rootfs_rw/overlay/home/linaro
    sudo chown 1000:1000 -R rootfs_rw/overlay/home/linaro

    sudo mkdir -p rootfs_rw/overlay/opt
    sudo mv "${EDGE_ROOTFS_DIR}"/opt/* rootfs_rw/overlay/opt/
    sudo tar -zcf .rootfs_rw.tgz -C rootfs_rw .
    sudo mv .rootfs_rw.tgz "${EDGE_ROOTFS_DIR}"/root/
    sudo tar -zcf rootfs.tgz --exclude=home/linaro/bsp-debs -C "${EDGE_ROOTFS_DIR}" .
    sudo tar -zcf rootfs_rw.tgz -C rootfs_rw .

    mkdir -p $PACKAGE_OUTPUT_DIR/data
    rsync -av $ROOT_TOP_DIR/bootloader-arm64/distro/data/ $PACKAGE_OUTPUT_DIR/data/
    tar -zcf data.tgz -C data .
    popd

    find "${BSP_DEBS}" -maxdepth 1 -type f -exec sudo cp -f {} "${PACKAGE_OUTPUT_DIR}/bsp-debs" \;
    find "${SDK_DEBS}" -maxdepth 1 -type f -exec sudo cp -f {} "${PACKAGE_OUTPUT_DIR}/bsp-debs" \;
    find "${MOD_DEBS}" -maxdepth 1 -type f -exec sudo cp -f {} "${PACKAGE_OUTPUT_DIR}/bsp-debs" \;
    update_files_if_newer "sophon-media-soc-sophon-{ffmpeg,opencv,gstreamer,sample}-dev_*_arm64.deb" "${TOP_DIR}/sophon_media/buildit" "${PACKAGE_OUTPUT_DIR}/bsp-debs"

    pushd $PACKAGE_OUTPUT_DIR
    build_update sdcard
    tar -zcf sdcard.tgz sdcard
    if [[ -z "$MINI_BUILD" ]]; then
      build_update usb
      tar -zcf usb.tgz usb
      build_update tftp
      tar -zcf tftp.tgz tftp
    fi
    popd
}


# shellcheck disable=SC2120
function build_device_all()
{(
  build_uboot || return $?
  build_kernel || return $?
  build_osdrv || return $?
  build_3rd_party || return $?
  build_libsophon || return $?
  build_middleware || return $?
  build_ramboot || return $?
  if [[ "$BOARD" != "fpga" ]] && [[ "$BOARD" != "palladium" ]]; then
    build_cvi_rtsp || return $?
    if [ "$TPU_REL" = 1 ]; then
      build_bm1686_sdk || return $?
      build_tdl_sdk || return $?
    fi
    build_pqtool_server || return $?
    build_access_guard_turnkey_app || return $?
    build_ipc_app || return $?
  fi
  build_sdk_rootfs || { ret=$?; echo "Error: build_sdk_rootfs failed with exit code $ret"; return $ret; }
)}

function release_nvr_deb()
{
  top_level_dir_name="nvr_edge"

  current_dir=${PWD}
  top_level_path=""
  while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/$top_level_dir_name" ]; then
          top_level_path="$current_dir/$top_level_dir_name"
          break
      fi
      current_dir="$(dirname "$current_dir")"
  done


  if [ -z "$top_level_path" ]; then
      echo "Error: Directory '$top_level_dir_name' not found."
      return 1
  fi

  release_nvr_tgz nvr_edge 1

  version_file="$top_level_path/VERSION"
  if [ -f "$version_file" ]; then
      version=$(tr -d '\n' < "$version_file")
  else
      version="0.1.0"
  fi

  package_name="nvr_edge"
  architecture="arm64"
  maintainer="yihu.wang <yihu.wang@sophgo.com>"
  description="1688 NVR Application Package"

  temp_dir=$(mktemp -d)
  deb_dir="$temp_dir/${package_name}-${version}"
  mkdir -p "$deb_dir/DEBIAN"

  mkdir -p "$deb_dir/opt/sophon/${package_name}_${version}/lib"
  mkdir -p "$deb_dir/opt/sophon/${package_name}_${version}/bin"
  mkdir -p "$deb_dir/opt/sophon/${package_name}_${version}/assets"
  mkdir -p "$deb_dir/opt/sophon/${package_name}_${version}/yolov11"

  release_name="nvr_edge_release_$version"
  release_dir="$top_level_path/$release_name"

  if [ ! -d "$release_dir" ]; then
      echo "Error: Release directory '$release_dir' not found."
      echo "Please run build.sh and release.sh first."
      return 1
  fi

  cp -r "$release_dir/lib/"*       "$deb_dir/opt/sophon/${package_name}_${version}/lib"
  cp -r "$release_dir/bin/"*       "$deb_dir/opt/sophon/${package_name}_${version}/bin"
  cp -r "$release_dir/assets/"*    "$deb_dir/opt/sophon/${package_name}_${version}/assets"
  cp -r "$release_dir/yolov11/"*   "$deb_dir/opt/sophon/${package_name}_${version}/yolov11"
  cp "$release_dir/srs.tar.gz"  "$deb_dir/opt/sophon/${package_name}_${version}/srs.tar.gz"

  cat > "$deb_dir/opt/sophon/${package_name}_${version}/bin/nvr" <<EOF
#!/bin/bash

cd /opt/sophon/${package_name}_${version}/bin

case "\$1" in
    --stop)
        ./stop.sh
        ;;
    --start)
        ./start.sh
        ;;
    --check)
        ./check_status.sh
        ;;
    --help)
        echo "Usage: nvr [OPTION]"
        echo "Options:"
        echo "  --stop    Stop the service"
        echo "  --start   Start the service"
        echo "  --check   Check the service status"
        echo "  --help    Display this help message"
        ;;
    *)
        echo "Invalid option: \$1"
        echo "Use --help for usage information."
        ;;
esac
EOF

  chmod +x "$deb_dir/opt/sophon/${package_name}_${version}/bin/nvr"

  control_file="$deb_dir/DEBIAN/control"
  cat > "$control_file" <<EOF
Package: nvr-edge
Version: $version
Architecture: $architecture
Maintainer: $maintainer
Description: $description
EOF

  postinst_file="$deb_dir/DEBIAN/postinst"
  cat > "$postinst_file" <<EOF
#!/bin/bash
chmod 755 /opt/sophon/${package_name}_${version}/bin/*
ln -sf /opt/sophon/${package_name}_${version}/bin/nvr /usr/local/bin/nvr_edge
ln -sf /opt/sophon/${package_name}_${version}/bin/conf /etc/nvr_edge
EOF
  chmod 755 "$postinst_file"

  prerm_file="$deb_dir/DEBIAN/prerm"
  cat > "$prerm_file" <<EOF
#!/bin/bash

/usr/local/bin/nvr_edge --stop
EOF
  chmod 755 "$prerm_file"

  postrm_file="$deb_dir/DEBIAN/postrm"
  cat > "$postrm_file" <<EOF
#!/bin/bash
set -e

if [ "\$1" = "purge" ] || [ "\$1" = "remove" ]; then
    rm -f /usr/local/bin/nvr_edge
    rm -rf /opt/sophon/${package_name}_${version}
    rm -f /etc/nvr_edge
fi

EOF
  chmod 755 "$postrm_file"

  dpkg-deb --build "$deb_dir" "$top_level_path/${package_name}_${version}_${architecture}.deb"

  rm -rf "$temp_dir"

  echo "Debian package created: $top_level_path/${package_name}_${version}_${architecture}.deb"
}

function release_nvr_tgz()
{
  top_level_dir_name="$1"
  if [ -z "$1" ]; then
      top_level_dir_name="nvr_edge"
  fi

  current_dir=${PWD}
  top_level_path=""
  while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/$top_level_dir_name" ]; then
          top_level_path="$current_dir/$top_level_dir_name"
          break
      fi
      current_dir="$(dirname "$current_dir")"
  done

  if [ -z "$top_level_path" ]; then
      echo "Error: Directory '$top_level_dir_name' not found."
      return 1
  fi
  echo "$top_level_path"
  version_file="$top_level_path/VERSION"
  if [ -f "$version_file" ]; then
      version=$(cat "$version_file" | tr -d '\n')
      release_name="nvr_edge_release_$version"
  else
      version="nvr_edge_release"
      release_name="nvr_edge_release"
  fi

  release_dir="$top_level_path/$release_name"
  if [ -d "$release_dir" ]; then
      echo "Warning: Directory '$release_dir' already exists. Deleting it."
      rm -rf "$release_dir"
  fi
  mkdir -p "$release_dir/lib"
  mkdir -p "$release_dir/assets"
  mkdir -p "$release_dir/bin"

  cp -r $top_level_path/build/lib/* "$release_dir/lib"
  cp "$top_level_path/3rdparty/bm_reactor/lib/libbm_reactor.so" "$release_dir/lib"
  cp "$top_level_path/nvr_gui/awtk/lib/libawtk.so" "$release_dir/lib"
  cp -r $top_level_path/samples/assets/* "$release_dir/assets"
  cp -r $top_level_path/samples/build/* "$release_dir/bin"
  cp -r "$top_level_path/conf" "$release_dir/bin"
  cp -r $top_level_path/samples/yolov11 "$release_dir/"
  cp -r $top_level_path/scripts/start.sh "$release_dir/bin/start.sh"
  cp -r $top_level_path/scripts/stop.sh "$release_dir/bin/stop.sh"
  cp -r $top_level_path/scripts/check_status.sh "$release_dir/bin/check_status.sh"
  cp -r $top_level_path/srs.tar.gz "$release_dir/srs.tar.gz"


  if [ -z "$2" ]; then
    echo "Release operating..."
    tar -czf "${release_name}.tar.gz" "$release_name"
    echo "Release package created: $top_level_path/${release_name}.tar.gz"
  fi

}

function clean_device_all()
{
  clean_uboot
  clean_opensbi
  clean_rtos
  clean_libsophon
  clean_bmcpu
  [[ "$ATF_SRC" == y ]] && clean_atf
  clean_kernel
  clean_ramdisk
  clean_3rd_party
  if [ "$TPU_REL" = 1 ]; then
    clean_bm1686_sdk
    clean_tdl_sdk
  fi
  clean_access_guard_turnkey_app
  clean_ipc_app
  clean_middleware
  clean_osdrv
  clean_cvi_rtsp
  clean_pqtool_server
  rm -rf ${TOP_DIR}/ubuntu/install
}

function distclean_all()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  clean_all
  repo forall -c "git clean -dfx"
)}

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
  AI_SDK_INSTALL_PATH="$TPU_OUTPUT_PATH"/cvitek_ai_sdk
  CNV_SDK_INSTALL_PATH="$TPU_OUTPUT_PATH"/cvitek_cnv_sdk
  TPU_MODEL_PATH="$TPU_OUTPUT_PATH"/models
  IVE_CMODEL_INSTALL_PATH="$TPU_OUTPUT_PATH"/tools/ive_cmodel
}

function update_setup_env()
{
	TOP_DIR="$BACKUP_TOP_DIR"
	OUTPUT_DIR="$BACKUP_OUTPUT_DIR"
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

  export BRAND BUILD_VERBOSE DEBUG PROJECT_FULLNAME BACKUP_TOP_DIR BACKUP_OUTPUT_DIR
  export OUTPUT_DIR ATF_PATH BM_BLD_PATH OPENSBI_PATH UBOOT_PATH FREERTOS_PATH
  export KERNEL_PATH RAMDISK_PATH OSDRV_PATH TOOLS_PATH COMMON_TOOLS_PATH LIBSOPHON_PATH BMCPU_PATH

  PROJECT_FULLNAME="$SIDE_TYPE"_"$BOARD"

  # output folder path
  INSTALL_PATH="$TOP_DIR"/install
  OUTPUT_DIR="$INSTALL_PATH"/soc_"$PROJECT_FULLNAME"
  ROOTFS_DIR="$OUTPUT_DIR"/rootfs
  SYSTEM_OUT_DIR="$OUTPUT_DIR"/rootfs/mnt/system
  BACKUP_OUTPUT_DIR="$OUTPUT_DIR"
  BACKUP_TOP_DIR="$TOP_DIR"

  # source file folders
  FSBL_PATH="$TOP_DIR"/fsbl
  ATF_PATH="$TOP_DIR"/arm-trusted-firmware
  UBOOT_PATH="$TOP_DIR/$UBOOT_SRC"
  FREERTOS_PATH="$TOP_DIR"/freertos
  ALIOS_PATH="$TOP_DIR"/alios
  KERNEL_PATH="$TOP_DIR"/"$KERNEL_SRC"
  OSDRV_PATH="$TOP_DIR"/osdrv
  LIBSOPHON_PATH="$TOP_DIR"/libsophon
  BMCPU_PATH="$TOP_DIR"/bmcpu
  RAMDISK_PATH="$TOP_DIR"/ramdisk
  BUILDROOT_PATH="$TOP_DIR"/buildroot
  BR2_OVERLAY_PATH="$TOP_DIR"/buildroot/board/sophgo/
  BM_BLD_PATH="$TOP_DIR"/bm_bld
  TOOLCHAIN_PATH="$TOP_DIR"/host-tools
  OSS_PATH="$TOP_DIR"/oss
  OPENCV_PATH="$TOP_DIR"/opencv
  APPS_PATH="$TOP_DIR"/apps
  MW_PATH="$TOP_DIR"/middleware/"$MW_VER"
  PQTOOL_SERVER_PATH="$MW_PATH"/modules/isp/cv186x/isp-tool-daemon/isp_daemon_tool #TODO change "sophon" to "${CHIP_ARCH,,}"
  PQTOOL_SERVER_V2_PATH="$TOP_DIR"/isp-tool-daemon
  ISP_TUNING_PATH="$TOP_DIR"/isp_tuning
  TPU_SDK_PATH="$TOP_DIR"/tpu-kernel
  CNV_SDK_PATH="$TOP_DIR"/cnv
  ACCESSGUARD_PATH="$TOP_DIR"/access-guard-turnkey
  IPC_APP_PATH="$TOP_DIR"/framework/applications/ipc
  TDL_SDK_PATH="$TOP_DIR"/tdl_sdk
  CVI_PIPELINE_PATH="$TOP_DIR"/cvi_pipeline
  CVI_RTSP_PATH="$TOP_DIR"/cvi_rtsp
  OPENSBI_PATH="$TOP_DIR"/opensbi
  TOOLS_PATH="$BUILD_PATH"/tools
  COMMON_TOOLS_PATH="$TOOLS_PATH"/common
  VENC_PATH="$MW_PATH"/modules/venc
  IMGTOOL_PATH="$COMMON_TOOLS_PATH"/image_tool
  EMMCTOOL_PATH="$COMMON_TOOLS_PATH"/emmc_tool
  SCRIPTTOOL_PATH="$COMMON_TOOLS_PATH"/scripts
  ROOTFSTOOL_PATH="$COMMON_TOOLS_PATH"/rootfs_tool
  SPINANDTOOL_PATH="$COMMON_TOOLS_PATH"/spinand_tool
  BOOTLOGO_PATH="$COMMON_TOOLS_PATH"/bootlogo
  HDCP_KEY_PATH="$COMMON_TOOLS_PATH"/hdcp_key

  # subfolder path for buidling, chosen accroding to .gitignore rules
  UBOOT_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"
  RAMDISK_OUTPUT_BASE=build/"$PROJECT_FULLNAME"
  KERNEL_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"
  RAMDISK_OUTPUT_FOLDER="$RAMDISK_OUTPUT_BASE"/workspace

  PACKAGE_OUTPUT_DIR="$OUTPUT_DIR"/package_edge

  # toolchain
  if [ "$TOOLCHAIN_GLIBC_ARM64_V930" == "y" ]; then
	export CROSS_COMPILE_64=aarch64-linux-
  elif [ "$TOOLCHAIN_GLIBC_ARM64_V1131" == "y" ]; then
	export CROSS_COMPILE_64=aarch64-none-linux-gnu-
  else
	export CROSS_COMPILE_64=aarch64-linux-gnu-
  fi
  export CROSS_COMPILE_64_631=aarch64-linux-gnu-

  export CROSS_COMPILE_32=arm-linux-gnueabihf-
  export CROSS_COMPILE_UCLIBC=arm-cvitek-linux-uclibcgnueabihf-
  export CROSS_COMPILE_64_NONOS=aarch64-elf-
  export CROSS_COMPILE_64_NONOS_RISCV64=riscv64-unknown-elf-
  export CROSS_COMPILE_GLIBC_RISCV64=riscv64-unknown-linux-gnu-
  export CROSS_COMPILE_MUSL_RISCV64=riscv64-unknown-linux-musl-
  export CROSS_COMPILE="$CROSS_COMPILE_64"

  # toolchain path
  if [ "$TOOLCHAIN_GLIBC_ARM64_V930" == "y" ]; then
	CROSS_COMPILE_PATH_64="$TOOLCHAIN_PATH"/gcc/gcc-buildroot-9.3.0-aarch64-linux-gnu
  elif [ "$TOOLCHAIN_GLIBC_ARM64_V1131" == "y" ]; then
	CROSS_COMPILE_PATH_64="$TOOLCHAIN_PATH"/gcc/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu
  else
	CROSS_COMPILE_PATH_64="$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu
  fi
  CROSS_COMPILE_PATH_64_631="$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu
  CROSS_COMPILE_PATH_32="$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf
  CROSS_COMPILE_PATH_UCLIBC="$TOOLCHAIN_PATH"/gcc/arm-cvitek-linux-uclibcgnueabihf
  CROSS_COMPILE_PATH_64_NONOS="$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-elf
  CROSS_COMPILE_PATH_64_NONOS_RISCV64="$TOOLCHAIN_PATH"/gcc/riscv64-elf-x86_64
  CROSS_COMPILE_PATH_GLIBC_RISCV64="$TOOLCHAIN_PATH"/gcc/riscv64-linux-x86_64
  CROSS_COMPILE_PATH_MUSL_RISCV64="$TOOLCHAIN_PATH"/gcc/riscv64-linux-musl-x86_64
  export CROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_64"

  # add toolchain path
  pathprepend "$CROSS_COMPILE_PATH_64"/bin
  pathprepend "$CROSS_COMPILE_PATH_64_631"/bin
  pathprepend "$CROSS_COMPILE_PATH_32"/bin
  pathprepend "$CROSS_COMPILE_PATH_64_NONOS"/bin
  pathprepend "$CROSS_COMPILE_PATH_64_NONOS_RISCV64"/bin
  pathprepend "$CROSS_COMPILE_PATH_GLIBC_RISCV64"/bin
  pathprepend "$CROSS_COMPILE_PATH_MUSL_RISCV64"/bin
  pathappend "$CROSS_COMPILE_PATH_UCLIBC"/bin

  # Check ccache is enable or not
  pathremove "$BUILD_PATH"/output/bin
  rm -rf "$BUILD_PATH"/output/bin/
  if [ "$USE_CCACHE" == "y" ];then
    if command -v ccache &> /dev/null;then
      mkdir -p "$BUILD_PATH"/output/bin
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/aarch64-elf-gcc
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/aarch64-elf-g++
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/aarch64-elf-c++
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/aarch64-linux-gnu-gcc
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/aarch64-linux-gnu-g++
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/aarch64-linux-gnu-c++
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/arm-linux-gnueabihf-gcc
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/arm-linux-gnueabihf-g++
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/arm-linux-gnueabihf-c++
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/arm-cvitek-linux-uclibcgnueabihf-gcc
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/arm-cvitek-linux-uclibcgnueabihf-g++
      ln -s "$(which ccache)" "$BUILD_PATH"/output/bin/arm-cvitek-linux-uclibcgnueabihf-c++
      pathprepend "$BUILD_PATH"/output/bin
    else
      echo "You have enabled ccache but there is no ccache in your PATH. Please cheack!"
      USE_CCACHE="n"
    fi
  fi

  # sysroot
  if [ "$TOOLCHAIN_GLIBC_ARM64_V930" == "y" ]; then
	SYSROOT_PATH_64="$RAMDISK_PATH"/sysroot/sysroot-gcc-buildroot-9.3.0-aarch64-linux-gnu
  elif [ "$TOOLCHAIN_GLIBC_ARM64_V1131" == "y" ]; then
	SYSROOT_PATH_64="$RAMDISK_PATH"/sysroot/sysroot-gcc-buildroot-11.3.0-aarch64-linux-gnu
  else
	SYSROOT_PATH_64="$RAMDISK_PATH"/sysroot/sysroot-glibc-linaro-2.23-2017.05-aarch64-linux-gnu
  fi
  SYSROOT_PATH_32="$RAMDISK_PATH"/sysroot/sysroot-glibc-linaro-2.23-2017.05-arm-linux-gnueabihf
  SYSROOT_PATH_64_631="$RAMDISK_PATH"/sysroot/sysroot-glibc-linaro-2.23-2017.05-aarch64-linux-gnu
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

function croot()
{
    cd $TOP_DIR
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

function print_usage()
{
  printf "  -------------------------------------------------------------------------------------------------------\n"
  printf "    Usage:\n"
  printf "    (1)\33[94m menuconfig \33[0m- Use menu to configure your board.\n"
  printf "        ex: $ menuconfig\n\n"
  printf "    (2)\33[96m defconfig \$CHIP_ARCH \33[0m- List EVB boards(\$BOARD) by CHIP_ARCH.\n"
  "${BUILD_PATH}/scripts/boards_scan.py" --list-side-arch
  printf "        ex: $ defconfig edge\n\n"
  printf "    (3)\33[92m defconfig \$BOARD\33[0m - Choose EVB board settings.\n"
  printf "        ex: $ defconfig edge_wevb_emmc\n"
  printf "  -------------------------------------------------------------------------------------------------------\n"
}

TOP_DIR=$(gettop)
BUILD_PATH="$TOP_DIR/build"
SOC_LINUX_HEADER_DIR=$(pwd)/linux_deb

if [ "$KERNEL_SRC" = "linux-common" ]; then
  KERNEL_HEADER_FILE=$(pwd)/linux-common/build
else
  KERNEL_HEADER_FILE=$(pwd)/linux_5.10/build
fi

export TOP_DIR BUILD_PATH SOC_LINUX_HEADER_DIR KERNEL_HEADER_FILE
"${BUILD_PATH}/scripts/boards_scan.py" --gen-build-kconfig
"${BUILD_PATH}/scripts/gen_sensor_config.py"
"${BUILD_PATH}/scripts/gen_panel_config.py"

# import common functions
# shellcheck source=./common_functions.sh
source "$TOP_DIR/build/common_functions.sh"
# shellcheck source=./release_functions.sh
source "$TOP_DIR/build/release_functions.sh"
# shellcheck source=./riscv_functions.sh
source "$TOP_DIR/build/riscv_functions.sh"
# shellcheck source=./alios_functions.sh
source "$TOP_DIR/build/alios_functions.sh"
# pack backdoor file for PLD env
source "$TOP_DIR/build/pld_backdoor.sh"
source "$TOP_DIR/build/deb_utils.sh"

print_usage

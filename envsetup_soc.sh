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

function _build_br2_env()
{
  export BUILDROOT_PATH BR2_OVERLAY_PATH
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

function _prepare_buildroot_()
{(
  if [ ! -d "${BUILDROOT_PATH}" ]; then
    echo "buildroot directory does not exist. Exit..."
    # echo "buildroot directory does not exist. Cloning from GitHub..."
    # git clone -b 2023.11.x --single-branch https://github.com/buildroot/buildroot.git ${BUILDROOT_PATH}
  else
    echo "buildroot directory already exists."
  fi
)}
export -f _prepare_buildroot_

function menuconfig_buildroot()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _prepare_buildroot_
  _build_br2_env
  cd "$BUILD_PATH" || return
  make menuconfig-br2 || return "$?"
)}

function savedefconfig_br2()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  _prepare_buildroot_
  _build_br2_env
  cd "$BUILD_PATH" || return
  make savedefconfig-br2 || return "$?"
)}

function build_br2_package()
{(
  if [ -z "$1" ];then
	echo "Usage: ${FUNCNAME[0]} package_name"
	exit 1
  fi
  print_notice "Run ${FUNCNAME[0]}() function"
  _prepare_buildroot_
  _build_br2_env
  pushd "$BUILDROOT_PATH" || return
  make $1 || return "$?"
  popd
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
  make install DESTDIR="$SYSTEM_OUT_DIR"
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

# 设置sophon-sdk信息
function get_bm_sdk_info {
    bm_root_dir=ftp://172.28.141.89/athena2
    bm_user_name=AI
    bm_user_psword=SophgoRelease2022
    bm_date_ID=latest_release
    bm_sdk_name=tpu_kernel
    bm_chip_name=$1
    bm_build_type=$2
}

# 拉取解压sophon-sdk
function build_bm1686_sdk {
    # bm1686 tpu_kernel
    get_bm_sdk_info 1686 daily_build
    tpu_kernel_file_name=tpu-kernel-tpulv6_v*.tar.gz
    tpu_kernel_full_path=$bm_root_dir/tpu-kernel/$bm_build_type/$bm_date_ID/$tpu_kernel_file_name

    echo "Try to download ${tpu_kernel_file_name} ..."
    wget -P ${TPU_SDK_PATH} ${tpu_kernel_full_path} --ftp-user $bm_user_name --ftp-password $bm_user_psword -q
    mkdir -p ${TPU_SDK_PATH}/
    tar -xzf ${TPU_SDK_PATH}/$tpu_kernel_file_name -C ${TPU_SDK_PATH}/ --strip-components 1
    echo "Extract"

    rm -rf ${TPU_SDK_PATH}/${tpu_kernel_file_name}
}
function clean_bm1686_sdk {
	rm -rf ${TPU_SDK_PATH}
}

function clean_ai_sdk()
{
    rm -rf "$AI_SDK_INSTALL_PATH"
    rm -rf "$AI_SDK_PATH"/tmp/_deps
}

function build_ai_sdk()
{
  if [ ! -e "$TPU_SDK_INSTALL_PATH" ]; then
    echo "$TPU_SDK_INSTALL_PATH not present, run build_tpu_sdk first"
    return 1
  fi

  if [ "$SDK_VER" = 64bit ]; then
    HOST_TOOL_PATH="$CROSS_COMPILE_PATH_64"
  elif [ "$SDK_VER" = 32bit ]; then
    HOST_TOOL_PATH="$CROSS_COMPILE_PATH_32"
  elif [ "$SDK_VER" = uclibc ]; then
    HOST_TOOL_PATH="$CROSS_COMPILE_PATH_UCLIBC"
  elif [ "$SDK_VER" = glibc_riscv64 ]; then
    HOST_TOOL_PATH="$CROSS_COMPILE_PATH_GLIBC_RISCV64"
  elif [ "$SDK_VER" = musl_riscv64 ]; then
    HOST_TOOL_PATH="$CROSS_COMPILE_PATH_MUSL_RISCV64"
  else
    echo "Unknown SDK_VER=$SDK_VER"
    return 1
  fi
  local SDK_PATH=
  local SDK_INSTALL_PATH=

  SDK_PATH="$AI_SDK_PATH"
  SDK_INSTALL_PATH="$AI_SDK_INSTALL_PATH"
  pushd "$SDK_PATH"
  HOST_TOOL_PATH="$HOST_TOOL_PATH" \
  MW_PATH="$MW_PATH" \
  CHIP_ARCH="$CHIP_ARCH" \
  OPENCV_INSTALL_PATH="$TPU_SDK_INSTALL_PATH" \
  TRACER_INSTALL_PATH="$IVE_SDK_INSTALL_PATH" \
  TPU_SDK_INSTALL_PATH="$TPU_SDK_INSTALL_PATH" \
  IVE_SDK_INSTALL_PATH="$IVE_SDK_INSTALL_PATH" \
  AI_SDK_INSTALL_PATH="$AI_SDK_INSTALL_PATH" \
  IVS_SDK_INSTALL_PATH="$IVS_SDK_INSTALL_PATH" \
  CNV_SDK_INSTALL_PATH="$CNV_SDK_INSTALL_PATH" \
  SYSTEM_OUT_DIR="$SYSTEM_OUT_DIR" \
  KERNEL_HEADER_PATH="$KERNEL_PATH"/"$KERNEL_OUTPUT_FOLDER"/usr/ \
      scripts/sdk_release.sh
  test "$?" -ne 0 && print_notice "${FUNCNAME[0]}() failed !!" && popd && return 1
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
}

function build_libsophon()
{
  clean_libsophon
  print_notice "Run ${FUNCNAME[0]}() function"

  local _static_lib=OFF
  local _install_prefix="$LIBSOPHON_PATH"/build/install
  if ! grep -q '^CONFIG_ROOTFS_DEBIAN=y' "${TOP_DIR}"/build/.config && ! grep -q '^CONFIG_ROOTFS_UBUNTU=y' "${TOP_DIR}"/build/.config; then
    _static_lib=ON
    _install_prefix="$SYSTEM_OUT_DIR"/usr/lib
  fi

  local lib_dir="$LIBSOPHON_PATH"/3rdparty/soc/
  local toolchain_file="$LIBSOPHON_PATH"/toolchain-aarch64-linux.cmake
  if grep -q '^CONFIG_TOOLCHAIN_GLIBC_ARM64_V930=y' ${TOP_DIR}/build/.config; then
    lib_dir="$LIBSOPHON_PATH"/3rdparty/lib930/
    toolchain_file="$LIBSOPHON_PATH"/toolchain-aarch64-linux-930.cmake
  fi

  pushd "$LIBSOPHON_PATH" || return

  cmake \
    -B build \
    -G Ninja \
    -DPLATFORM=soc \
    -DSOC_LINUX_DIR="$KERNEL_PATH"/build/"$CHIP"_"$BOARD" \
    -DLIB_DIR="${lib_dir}" \
    -DCROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_64" \
    -DCMAKE_TOOLCHAIN_FILE="${toolchain_file}" \
    -DBUILD_STATIC_LIB="${_static_lib}" \
    -DCMAKE_INSTALL_PREFIX="${_install_prefix}" \
    -DDEBUG=OFF \
    -DCMAKE_BUILD_TYPE=Release \

  cmake --build build --parallel "$(nproc)"
  cmake --build build --target driver

  if grep -q '^CONFIG_ROOTFS_DEBIAN=y' "${TOP_DIR}"/build/.config || grep -q '^CONFIG_ROOTFS_UBUNTU=y' "${TOP_DIR}"/build/.config; then
    cmake --build build --target package --parallel "$(nproc)"
    if [ "${BUILD_DOC}" == "1" ]; then
      cmake --build build --target doc
      cmake --build build --target rtdoc
      pushd libsophav/bmcv || return
      CHIP=bm1688 make doc
      popd
    fi
  else
    cmake --build build --target install --parallel "$(nproc)"
    cp -af "${_install_prefix}"/libsophon-* "$TPU_SDK_INSTALL_PATH" || return
    cp -af "$LIBSOPHON_PATH"/build/driver/sg_aarch64_soc_device/bmtpu.ko "$SYSTEM_OUT_DIR"/ko || return
    LIBSOPHON_VERSION=$(grep "CMAKE_PROJECT_VERSION:STATIC" < "${LIBSOPHON_PATH}"/build/CMakeCache.txt | awk -F '=' '{print $2}') || { echo "Failed to get version"; return; }
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
  fi
  popd
}

function build_bm1688_rootfs()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  build_bm1688_overlay || { ret=$?; echo "Error: build_bm1688_overlay failed with exit code $ret"; return $ret; }
  local version=$(grep Version $DISTRO_OVERLAY_DIR/$CVIARCH/sophgo-fs/DEBIAN/control | cut -d ' ' -f 2)
  mkdir -p "${EDGE_ROOTFS_DIR}"/home/linaro/debs
  dpkg-deb -b "${DISTRO_OVERLAY_DIR}/${CVIARCH}/sophgo-fs" \
    "${EDGE_ROOTFS_DIR}/home/linaro/debs/sophgo-bsp-rootfs_${version}_arm64.deb"

  echo copy overlay file to rootfs...
  sudo cp -rf \
    "$DISTRO_OVERLAY_DIR"/common/rootfs/* \
    "$DISTRO_OVERLAY_DIR"/"$CVIARCH"/rootfs/* \
    "${EDGE_ROOTFS_DIR}"

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
  if [  -d \${deb_dir} ] && [ \$(ls \${deb_dir}/*.deb | wc -l) -gt 0 ]; then
    retries=0
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

EOT

  echo packing rootfs...
  pushd "${EDGE_ROOTFS_DIR}"
  sudo chown 1000:1000 -R data
  popd
}

function build_sophon_media(){
  if [ ! -d "${TOP_DIR}/sophon_media" ]; then
    return 0
  fi

  print_notice "Run ${FUNCNAME[0]}() function"
  pushd ${TOP_DIR}/sophon_media
  if grep -q '^CONFIG_TOOLCHAIN_GLIBC_ARM64_V930=y' ${TOP_DIR}/build/.config; then
    source build/build_cmake.sh 930
  else
    source build/build_cmake.sh
  fi
  popd
}

function clean_sophon_media(){
  if [ ! -d "${TOP_DIR}/sophon_media" ]; then
    return 0
  fi

  print_notice "Run ${FUNCNAME[0]}() function"
  pushd ${TOP_DIR}/sophon_media
  cmake --build buildit --target clean
  popd
}

function clean_distro() {
  if [ -d "${TOP_DIR}/ubuntu/distro" ]; then
    find "${TOP_DIR}/ubuntu/distro" \
      -name "distro_*.tgz" -delete
  fi
}

function build_bm1688_env() {
  export DISTRO=${DISTRO:-focal}
  export ROOT_TOP_DIR="$TOP_DIR"/ubuntu
  export ROOT_OUT_DIR=${ROOT_TOP_DIR}/install/soc_${CVIARCH}
  export EDGE_ROOTFS_DIR=${ROOT_TOP_DIR}/install/soc_${CVIARCH}/rootfs
  export DISTRO_OVERLAY_DIR="${TOP_DIR}"/ubuntu/bootloader-arm64/distro/overlay
  export DISTRO_MD5="28ad82b4cf01327b1f81d3d193923424"

  export BSP_DEBS=${ROOT_OUT_DIR}/bsp-debs
  export SDK_DEBS=${ROOT_OUT_DIR}/sdk-debs
  export MOD_DEBS=${ROOT_OUT_DIR}/mod-debs
}

function build_bm1688_overlay() {
  sudo rm -rf "${EDGE_ROOTFS_DIR}"
  mkdir -p "${EDGE_ROOTFS_DIR}"

  if grep -q '^CONFIG_ROOTFS_DEBIAN=y' ${TOP_DIR}/build/.config; then
      mkdir -p ${TOP_DIR}/ubuntu/bookworm
      cd ${TOP_DIR}/ubuntu/bookworm
      if [ ! -e "${TOP_DIR}/ubuntu/bookworm/bookworm.tgz" ]; then
          python -m dfss --url=open@sophgo.com:/gemini-sdk/rootfs/bookworm.tgz
      fi
      zcat "${TOP_DIR}/ubuntu/bookworm/bookworm.tgz" |\
         sudo tar -C "${EDGE_ROOTFS_DIR}" -x -f -
  else
    mkdir -p "${TOP_DIR}"/ubuntu/distro
    if [ ! -e "${TOP_DIR}/ubuntu/distro/distro_${DISTRO}.tgz" ]; then
      echo "load distro_${DISTRO}.tgz ..."
      cd ${TOP_DIR}/ubuntu/distro
	  python -m dfss --url=open@sophgo.com:/gemini-sdk/rootfs/distro_${DISTRO}.tgz
    else
        FILE_MD5=$(md5sum "${TOP_DIR}/ubuntu/distro/distro_${DISTRO}.tgz" | awk '{print $1}')
        if [ "$FILE_MD5" != "$DISTRO_MD5" ]; then
            echo "update distro_${DISTRO}.tgz ..."
            rm -f "${TOP_DIR}/ubuntu/distro/distro_${DISTRO}.tgz"
			cd ${TOP_DIR}/ubuntu/distro
            python -m dfss --url=open@sophgo.com:/gemini-sdk/rootfs/distro_${DISTRO}.tgz
        fi
    fi
    zcat "${TOP_DIR}/ubuntu/distro/distro_${DISTRO}.tgz" |\
		sudo tar -C "${EDGE_ROOTFS_DIR}" -x -f -
  fi

}

function build_bm1688_sdk() {
  print_notice "Run ${FUNCNAME[0]}() function"
  local preinstall_sdks="$*"

  for _dir in "${BSP_DEBS}" "${SDK_DEBS}"; do
    mkdir -p "${_dir}"
  done
  mkdir -p ${MOD_DEBS}

  # update linux kernel debs
  shopt -s nullglob
  matched_deb_files=("${TOP_DIR}/linux_5.10/build/"*.deb)
  if [ ${#matched_deb_files[@]} -gt 0 ]; then
    rm -f "${BSP_DEBS}"/*.deb
  fi
  shopt -u nullglob
  cp -f "${TOP_DIR}"/linux_5.10/build/*.deb ${BSP_DEBS}

  # copy libsophon debs
  if [[ "${preinstall_sdks}" == *"libsophon"* ]]; then
    build_libsophon || return $?
    cp -f "${TOP_DIR}"/libsophon/build/sophon-soc-libsophon*.deb ${SDK_DEBS}
  fi

  # copy sophon_media debs
  if [[ "${preinstall_sdks}" == *"sophon_media"* ]]; then
    cp middleware/v2/modules/isp/cv186x/v4l2_adapter/sophon-soc-libisp*arm64.deb ${SDK_DEBS}
    if [ -d "${TOP_DIR}"/sophon_media ]; then
      cp "${TOP_DIR}"/sophon_media/media_release/sophon[_-]media-soc-sophon-{ffmpeg,opencv,gstreamer,sample}_1.8.0_arm64.deb ${SDK_DEBS}
    fi
  fi

  # copy sophliteos debs
  if [[ "${preinstall_sdks}" == *"sophliteos"* ]]; then
    cp "${TOP_DIR}"/sophliteos/release/sophliteos_soc_*_sdk.deb "${SDK_DEBS}"
    cp "${TOP_DIR}"/sophliteos/release/bmssm_soc_*_SDK.deb "${SDK_DEBS}"
  fi

  # copy customer's debs
  find "${TOP_DIR}"/ubuntu/bootloader-arm64/distro/debs \
    -name *.deb -exec cp -f {} "${MOD_DEBS}" \;
}

function build_bm1688_package(){
  cd ${TOP_DIR}
  cp ${TOP_DIR}/ubuntu/bootloader-arm64/scripts/local_update.sh ${TOP_DIR}/build/scripts
  build_package
  if [ -d "$OUTPUT_DIR"/package_edge ]; then
    echo copy sdk files...
    sudo cp -f "$LIBSOPHON_PATH"/build/libsophon_soc_*_aarch64.tar.gz "$OUTPUT_DIR"/package_edge
    if [ -d "${TOP_DIR}"/sophon_media ]; then
      sudo cp -f "${TOP_DIR}"/sophon_media/media_release/sophon-media-soc_*_aarch64.tar.gz "$OUTPUT_DIR"/package_edge 2>/dev/null
    fi
  fi

}

function build_bm1688_edge()
{
  build_uboot || { ret=$?; echo "Error: build_uboot failed with exit code $ret"; return $ret; }
  build_kernel || { ret=$?; echo "Error: build_kernel failed with exit code $ret"; return $ret; }
  build_osdrv || { ret=$?; echo "Error: build_osdrv failed with exit code $ret"; return $ret; }
  build_ramboot || { ret=$?; echo "Error: build_ramboot failed with exit code $ret"; return $ret; }
  build_v4l2_isp || { ret=$?; echo "Error: build_v4l2_isp failed with exit code $ret"; return $ret; }
}

function build_bm1688_all(){
  local target=${1:-all}

  build_bm1688_env || { ret=$?; echo "Error: build_bm1688_env failed with exit code $ret"; return $ret; }
  build_bm1688_edge || { ret=$?; echo "Error: build_bm1688_edge failed with exit code $ret"; return $ret; }

  if [ "${target}" == "regression" ]; then
    build_bm1688_sdk libsophon || { echo "Error: build_bm1688_sdk libsophon failed with exit code $?"; return $?; }
  else
    #build_bm1688_sdk libsophon sophon_media sophliteos || { echo "Error: build_bm1688_sdk failed with exit code $?"; return $?; }
    build_bm1688_sdk libsophon || { ret=$?; echo "Error: build_bm1688_sdk libsophon failed with exit code $ret"; return $ret; }
    build_bm1688_sdk sophon_media || { ret=$?; echo "Error: build_bm1688_sdk sophon_media failed with exit code $ret"; return $ret; }
    build_bm1688_sdk sophliteos || { ret=$?; echo "Error: build_bm1688_sdk sophliteos failed with exit code $ret"; return $ret; }
  fi

  if grep -q '^CONFIG_ROOTFS_BUILD_FROM_BR2=y' ${TOP_DIR}/build/.config; then
    pack_rootfs || { ret=$?; echo "Error: pack_rootfs failed with exit code $ret"; return $ret; }
  else
    build_bm1688_rootfs || { ret=$?; echo "Error: build_bm1688_rootfs failed with exit code $ret"; return $ret; }

	if [ "${target}" != "regression" ]; then
        build_bm1688_package || { ret=$?; echo "Error: build_bm1688_package failed with exit code $ret"; return $ret; }
	fi
  fi
}

function clean_bm1688_all(){
  clean_edge_pack    || return $?
  clean_libsophon    || return $?
  clean_sophon_media || return $?

  if grep -q '^CONFIG_ROOTFS_BUILD_FROM_BR2=y' ${TOP_DIR}/build/.config; then
	clean_rootfs || return $?
  fi
  cd ${TOP_DIR}
  rm -rf ubuntu/install
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
)}

function clean_pqtool_server()
{(
  print_notice "Run ${FUNCNAME[0]}() function"
  cd "$PQTOOL_SERVER_PATH" || return
  make clean
  make uninstall DESTDIR="$SYSTEM_OUT_DIR"
)}

function build_3rd_party()
{
  mkdir -p "$OSS_TARBALL_PATH"

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
  )

  for name in "${oss_list[@]}"
  do
    if [ -f "${OSS_TARBALL_PATH}/${name}.tar.gz" ]; then
      echo "$name found"
    else
      echo "Try to download $name tarball ..."
      wget ftp://swftp:cvitek@${FTP_SERVER_IP}/sw_rls/third_party/latest/${SDK_VER}/${name}.tar.gz \
          -T 3 -t 3 -q -P ${OSS_TARBALL_PATH}
      if [ -f "${OSS_TARBALL_PATH}/${name}.tar.gz" ]; then
        "$OSS_PATH"/run_build.sh -n "$name" -e -t "$OSS_TARBALL_PATH" -i "$TPU_SDK_INSTALL_PATH"
        echo "$name successfully downloaded and untared."
      else
        echo "No prebuilt tarball, build oss $name"
        "$OSS_PATH"/run_build.sh -n "$name" -t "$OSS_TARBALL_PATH" -r "$SYSROOT_PATH" -s "$SDK_VER"
      fi
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
    export KERNEL_INC="$KERNEL_PATH"/build/"$CHIP"_"$BOARD"/usr/include/
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
    export KERNEL_INC="$KERNEL_PATH"/build/"$CHIP"_"$BOARD"/usr/include/
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



function build_edge_pack()
{
    build_uboot || { ret=$?; echo "Error: build_uboot failed with exit code $ret"; return $ret; }
    build_kernel || { ret=$?; echo "Error: build_kernel failed with exit code $ret"; return $ret; }
    build_osdrv || { ret=$?; echo "Error: build_osdrv failed with exit code $ret"; return $ret; }
    build_ramboot || { ret=$?; echo "Error: build_ramboot failed with exit code $ret"; return $ret; }
    build_v4l2_isp || { ret=$?; echo "Error: build_v4l2_isp failed with exit code $ret"; return $ret; }
}

function clean_edge_pack()
{
    clean_uboot || return $?
    clean_kernel || return $?
    clean_osdrv || return $?
    clean_ramdisk || return $?
    clean_v4l2_isp || return $?
}

function build_package()
{
    sudo rm -rf $PACKAGE_OUTPUT_DIR
    mkdir $PACKAGE_OUTPUT_DIR
    mkdir $PACKAGE_OUTPUT_DIR/boot
    mkdir $PACKAGE_OUTPUT_DIR/rootfs_rw
    mkdir $PACKAGE_OUTPUT_DIR/bsp-debs

    cp -rf $RAMDISK_PATH/$RAMDISK_OUTPUT_FOLDER/boot.itb $PACKAGE_OUTPUT_DIR/boot/
    cp -rf $RAMDISK_PATH/$RAMDISK_OUTPUT_FOLDER/multi.its $PACKAGE_OUTPUT_DIR/boot/
    cp -rf $OUTPUT_DIR/fip.bin $PACKAGE_OUTPUT_DIR/boot/
    cp -rf $BOOTLOGO_PATH $PACKAGE_OUTPUT_DIR/boot/

    cp -rf $OUTPUT_DIR/fip.bin $PACKAGE_OUTPUT_DIR/
    cp -rf $OUTPUT_DIR/ramboot.itb $PACKAGE_OUTPUT_DIR/

    mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "eMMC Boot Script" \
            -d ${TOP_DIR}/build/boot.cmd.emmc ${OUTPUT_DIR}/boot.scr.emmc
    cp -rf ${OUTPUT_DIR}/boot.scr.emmc $PACKAGE_OUTPUT_DIR/boot/
    pushd $PACKAGE_OUTPUT_DIR

    tar -zcvf boot.tgz -C boot .
    mv ramboot.itb recovery.itb
    tar -zcvf recovery.tgz recovery.itb

    echo "stty cols 160" >> "${EDGE_ROOTFS_DIR}"/home/linaro/.bashrc
    echo "stty cols 160" >> "${EDGE_ROOTFS_DIR}"/root/.bashrc
    sudo cp -rf  $OUTPUT_DIR/rootfs/mnt/system "${EDGE_ROOTFS_DIR}"/mnt/

    mkdir -p rootfs_rw/overlay/home/linaro
    cp -rf "${EDGE_ROOTFS_DIR}"/home/linaro/bsp-debs rootfs_rw/overlay/home/linaro
    sudo chown 1000:1000 -R rootfs_rw/overlay/home/linaro

    sudo tar -zcf rootfs.tgz --exclude=home/linaro/bsp-debs -C "${EDGE_ROOTFS_DIR}" .
    sudo tar -zcf .rootfs_rw.tgz -C rootfs_rw .
    sudo mv .rootfs_rw.tgz rootfs_rw/
    sudo tar -zcf rootfs_rw.tgz -C rootfs_rw .
    popd

    find "${BSP_DEBS}" -maxdepth 1 -type f -exec sudo cp -f {} "${PACKAGE_OUTPUT_DIR}/bsp-debs" \;
    find "${SDK_DEBS}" -maxdepth 1 -type f -exec sudo cp -f {} "${PACKAGE_OUTPUT_DIR}/bsp-debs" \;
    find "${MOD_DEBS}" -maxdepth 1 -type f -exec sudo cp -f {} "${PACKAGE_OUTPUT_DIR}/bsp-debs" \;

    pushd $PACKAGE_OUTPUT_DIR
    build_update sdcard
    tar -zcf sdcard.tgz sdcard
    build_update usb
    tar -zcf usb.tgz usb
    build_update tftp
    tar -zcf tftp.tgz tftp
    popd
}


# shellcheck disable=SC2120
function build_all()
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
      build_ai_sdk || return $?
    fi
    build_pqtool_server || return $?
    build_access_guard_turnkey_app || return $?
    build_ipc_app || return $?
  fi
  pack_cfg || return $?
  pack_rootfs || return $?
  pack_data || return $?
  pack_system || return $?
  copy_tools || return $?
  pack_upgrade || return $?
)}

function clean_all()
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
    clean_ai_sdk
  fi
  clean_access_guard_turnkey_app
  clean_ipc_app
  clean_middleware
  clean_osdrv
  clean_cvi_rtsp
  clean_pqtool_server
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

  PROJECT_FULLNAME="$CHIP"_"$BOARD"

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
  BR2_OVERLAY_PATH="$BUILDROOT_PATH"/board/sophgo/
  BM_BLD_PATH="$TOP_DIR"/bm_bld
  TOOLCHAIN_PATH="$TOP_DIR"/host-tools
  OSS_PATH="$TOP_DIR"/oss
  OPENCV_PATH="$TOP_DIR"/opencv
  APPS_PATH="$TOP_DIR"/apps
  MW_PATH="$TOP_DIR"/middleware/"$MW_VER"
  PQTOOL_SERVER_PATH="$MW_PATH"/modules/isp/cv186x/isp-tool-daemon/isp_daemon_tool #TODO change "sophon" to "${CHIP_ARCH,,}"
  ISP_TUNING_PATH="$TOP_DIR"/isp_tuning
  TPU_SDK_PATH="$TOP_DIR"/tpu-kernel
  CNV_SDK_PATH="$TOP_DIR"/cnv
  ACCESSGUARD_PATH="$TOP_DIR"/access-guard-turnkey
  IPC_APP_PATH="$TOP_DIR"/framework/applications/ipc
  AI_SDK_PATH="$TOP_DIR"/tdl_sdk
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
  BOOTLOGO_PATH="$COMMON_TOOLS_PATH"/bootlogo/soph_logo.bmp

  # subfolder path for buidling, chosen accroding to .gitignore rules
  UBOOT_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"
  RAMDISK_OUTPUT_BASE=build/"$PROJECT_FULLNAME"
  KERNEL_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"
  RAMDISK_OUTPUT_FOLDER="$RAMDISK_OUTPUT_BASE"/workspace

  PACKAGE_OUTPUT_DIR="$OUTPUT_DIR"/package_edge

  # toolchain
  if [ "$TOOLCHAIN_GLIBC_ARM64_V930" == "y" ]; then
	export CROSS_COMPILE_64=aarch64-linux-
  else
	export CROSS_COMPILE_64=aarch64-linux-gnu-
  fi

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
  else
	CROSS_COMPILE_PATH_64="$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu
  fi
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
  else
	SYSROOT_PATH_64="$RAMDISK_PATH"/sysroot/sysroot-glibc-linaro-2.23-2017.05-aarch64-linux-gnu
  fi
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
  build_bm1688_env
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
  "${BUILD_PATH}/scripts/boards_scan.py" --list-chip-arch
  printf "        ex: $ defconfig sophon\n\n"
  printf "    (3)\33[92m defconfig \$BOARD\33[0m - Choose EVB board settings.\n"
  printf "        ex: $ defconfig cv186ah_wevb_emmc\n"
  printf "  -------------------------------------------------------------------------------------------------------\n"
}

TOP_DIR=$(gettop)
BUILD_PATH="$TOP_DIR/build"
SOC_LINUX_HEADER_DIR=$(pwd)/linux_deb
KERNEL_HEADER_FILE=$(pwd)/linux_5.10/build
export TOP_DIR BUILD_PATH SOC_LINUX_HEADER_DIR KERNEL_HEADER_FILE
"${BUILD_PATH}/scripts/boards_scan.py" --gen-build-kconfig
"${BUILD_PATH}/scripts/gen_sensor_config.py"
"${BUILD_PATH}/scripts/gen_panel_config.py"
export FTP_SERVER_IP=${FTP_SERVER_IP:-10.80.0.5}

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


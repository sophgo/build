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
    bm_root_dir=ftp://172.28.141.89/sophon-sdk
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
    tpu_kernel_file_name=tpu-kernel-tpul_v6_v*.tar.gz
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
  test "$?" -ne 0 && print_notice "${FUNCNAME[0]}() failed !!" && popd return 1
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

function build_libsophon()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  if [ ! -d "$LIBSOPHON_PATH"/build ]; then
    mkdir -p "$LIBSOPHON_PATH"/build
  fi

  pushd "$LIBSOPHON_PATH"/build || return
  # rm -rf "$LIBSOPHON_PATH"/build/*

  cmake -DPLATFORM=soc \
        -DSOC_LINUX_DIR="$KERNEL_PATH"/build/"$CHIP"_"$BOARD" \
        -DLIB_DIR="$LIBSOPHON_PATH"/3rdparty/soc/ \
        -DCROSS_COMPILE_PATH="$CROSS_COMPILE_PATH_64" \
        -DCMAKE_TOOLCHAIN_FILE="$LIBSOPHON_PATH"/toolchain-aarch64-linux.cmake \
        -DBUILD_STATIC_LIB=ON \
        -DCMAKE_INSTALL_PREFIX="$LIBSOPHON_PATH"/install ..

  make
  make driver
  make install
  make package

  if [ ! -d "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9/data ]; then
    mkdir -p "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9/data
  fi
  if [ ! -d "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9/lib ]; then
    mkdir -p "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9/lib
  fi
  if [ ! -d "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9/bin ]; then
    mkdir -p "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9/bin
  fi
  if [ ! -d "$SYSTEM_OUT_DIR"/ko ]; then
    mkdir -p "$SYSTEM_OUT_DIR"/ko
  fi
  mkdir -p ${TPU_SDK_INSTALL_PATH}

  cp -rf "$LIBSOPHON_PATH"/install/libsophon-0.4.9/data/*_os.bin "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9/data || return
  cp -rf "$LIBSOPHON_PATH"/install/libsophon-0.4.9/lib/* "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9/lib || return
  cp -rf "$LIBSOPHON_PATH"/install/libsophon-0.4.9/bin/* "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9/bin || return
  cp -rf "$LIBSOPHON_PATH"/install/libsophon-0.4.9 "$TPU_SDK_INSTALL_PATH" || return
  # cp *.deb "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.9
  cp -f "$LIBSOPHON_PATH"/build/driver/sg_aarch64_soc_device/bmtpu.ko "$SYSTEM_OUT_DIR"/ko || return

  popd
}

function clean_libsophon()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  rm -rf ${TPU_SDK_INSTALL_PATH}
  rm -rf "$LIBSOPHON_PATH"/build/*
  rm -rf "$LIBSOPHON_PATH"/install/*
  rm -rf "$SYSTEM_OUT_DIR"/usr/lib/libsophon-0.4.4
  rm -rf "$SYSTEM_OUT_DIR"/ko/bmtpu.ko
}


function build_bm1688_rootfs()
{
    ROOT_TOP_DIR="$TOP_DIR"/ubuntu
    DISTRO=${DISTRO:-focal}
    ROOT_OUT_DIR=${ROOT_TOP_DIR}/install/soc_${CVIARCH}
    # out-of-tree path
    DEB_INSTALL_DIR="$ROOT_OUT_DIR"/bsp-debs
    DISTRO_DIR="$ROOT_TOP_DIR"/distro
    DISTRO_BASE_PKT="$DISTRO_DIR"/distro_${DISTRO}.tar
    DISTRO_MOD_DIR="$ROOT_TOP_DIR"/bootloader-arm64/distro
    DISTRO_OVERLAY_DIR="$ROOT_TOP_DIR"/bootloader-arm64/distro/overlay
    echo cleanup previous build...
    mkdir -p "$ROOT_OUT_DIR"/rootfs
    sudo rm -rf "$ROOT_OUT_DIR"/rootfs
    rm -f "$ROOT_OUT_DIR"/rootfs.tgz
    mkdir "$ROOT_OUT_DIR"/rootfs

    echo copy distro rootfs files from ${DISTRO_BASE_PKT}...
    sudo tar -xf "$DISTRO_BASE_PKT" -C "$ROOT_OUT_DIR"/rootfs

    echo copy linux debs...
    sudo mkdir -p "$ROOT_OUT_DIR"/rootfs/home/linaro
    sudo cp -r "$DEB_INSTALL_DIR" "$ROOT_OUT_DIR"/rootfs/home/linaro/

    local version=$(echo $(cat /$DISTRO_OVERLAY_DIR/$CVIARCH/sophgo-fs/DEBIAN/control | grep Version) | cut -d ' ' -f 2)
    echo "$DISTRO_OVERLAY_DIR/$CVIARCH/rootfs/home/linaro/debs/"
    rm -rf ${DISTRO_OVERLAY_DIR}/${CVIARCH}/rootfs/home/linaro/debs/sophgo-bsp-rootfs*.arm64.deb
    dpkg-deb -b "$DISTRO_OVERLAY_DIR"/"$CVIARCH"/sophgo-fs \
        "$DISTRO_OVERLAY_DIR/$CVIARCH"/rootfs/home/linaro/debs/sophgo-bsp-rootfs_${version}_arm64.deb

    echo copy overlay file to rootfs...
    if [ -d "$DISTRO_OVERLAY_DIR"/common/rootfs ]; then
        echo copy common rootfs overlay files...
        sudo cp -rf "$DISTRO_OVERLAY_DIR"/common/rootfs/* "$ROOT_OUT_DIR"/rootfs
    fi
    if [ -d "$DISTRO_OVERLAY_DIR"/"$CVIARCH"/rootfs ]; then
        echo copy project rootfs overlay files...
        sudo cp -rf "$DISTRO_OVERLAY_DIR"/"$CVIARCH"/rootfs/* "$ROOT_OUT_DIR"/rootfs
    fi
    # debs will be installed later after chroot and then deleted
    sudo cp -rf "$DISTRO_MOD_DIR"/debs "$ROOT_OUT_DIR"/rootfs

    if [ "$PRODUCT" != "" ] && [ -d "$DISTRO_OVERLAY_DIR"/"$PRODUCT"/debs ]; then
        echo copy product "$PRODUCT" debs overlay files...
        sudo cp -rf "$DISTRO_OVERLAY_DIR"/"$PRODUCT"/debs/* "$ROOT_OUT_DIR"/rootfs/debs/
    fi

    echo install packages...
    pushd "$ROOT_OUT_DIR"/rootfs
# following lines must not be started with space or tab.
# install bsp images first, so it won't run flash_update
sudo chroot . /bin/bash << "EOT"

if [  -d /debs ] && [ $(ls /debs/*.deb | wc -l) -gt 0 ]; then
    dpkg -i -R /debs
    while [ $? -ne 0 ];
    do
        sleep 1
        dpkg -i -R /debs
    done
fi
for file in /debs/*
do
    file=$(basename $file)
    if  [ "${file##*.}" == "whl" ]; then
        pip3 install --no-index --find-links=file:///debs ${file%%-*}
    fi
done
rm -rf /debs

if [  -d /home/linaro/debs ] && [ $(ls /home/linaro//debs/*.deb | wc -l) -gt 0 ]; then
    dpkg -i -R /home/linaro/debs
    while [ $? -ne 0 ];
    do
        sleep 1
        dpkg -i -R /home/linaro/debs
    done
fi

echo -e "LC_ALL=C.UTF-8\n" > /etc/default/locale


exit
EOT
    popd

    echo packing rootfs...
    pushd "$ROOT_OUT_DIR"/rootfs
    sudo chown 1000:1000 -R data
    sudo tar -czf ../rootfs.tgz *
    popd
}
function build_sophon_media(){
	pushd ${TOP_DIR}/sophon_media
	source build/build_cmake.sh
	popd
}



function update_bm1688_debs(){
  cd ${TOP_DIR}
  BSP_DEBS1=${TOP_DIR}/ubuntu/bootloader-arm64/distro/overlay/$CVIARCH/rootfs/home/linaro/bsp-debs
  BSP_DEBS2=${TOP_DIR}/ubuntu/bootloader-arm64/distro/overlay/$CVIARCH/rootfs/home/linaro/debs
  BSP_DEBS3=${TOP_DIR}/ubuntu/install/soc_$CVIARCH/bsp-debs
  SOPHLITEOS_DIR=${TOP_DIR}/sophliteos/release
  cd ${TOP_DIR}/ubuntu/
  if [  -e "${TOP_DIR}/ubuntu/install" ]; then
     rm -rf ${TOP_DIR}/ubuntu/install
  fi

  if [ ! -e "${TOP_DIR}/ubuntu/distro/distro_focal.tar" ]; then
    pushd ${TOP_DIR}/ubuntu/distro
    cat distro_focal.tar.* > distro_focal.tar
	popd
  fi
  cd ${TOP_DIR}

  mkdir -p ${BSP_DEBS1}
  cp linux_5.10/build/*.deb ${BSP_DEBS1}
  mkdir -p ${BSP_DEBS2}
  cp libsophon/build/sophon-soc-libsophon*.deb ${BSP_DEBS2}
  cp sophon_media/buildit/sophon[_-]media-soc-sophon-{ffmpeg_,opencv_,sample}*_arm64.deb ${BSP_DEBS2}
  cp middleware/v2/modules/isp/cv186x/v4l2_adapter/sophon-soc-libisp*arm64.deb ${BSP_DEBS2}
  mkdir -p ${BSP_DEBS3}
  pushd ${TOP_DIR}/ubuntu/
  cp ${SOPHLITEOS_DIR}/sophliteos_soc_*_sdk.deb ${BSP_DEBS2}
  cp ${SOPHLITEOS_DIR}/bmssm_soc_*_SDK.deb       ${BSP_DEBS2}
  popd
  ln -sf ${TOP_DIR}/host-tools/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu ${TOP_DIR}/ubuntu/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu
}



function pack_bm1688_rootfs(){
  cd ${TOP_DIR}
  cp ${TOP_DIR}/ubuntu/install/soc_$CVIARCH/rootfs.tgz  ${TOP_DIR}/install/soc_bm1688_wevb_emmc/
  cp ${TOP_DIR}/ubuntu/bootloader-arm64/scripts/local_update.sh ${TOP_DIR}/build/scripts
  #source build/envsetup_soc.sh
  #defconfig bm1688_wevb_emmc
  build_package
}

function build_bm1688_edge()
{
  cd ${TOP_DIR}
  build_edge_pack
}

function build_bm1688_all(){
     build_sophon_media || $? return
     build_bm1688_edge || $? return
     build_libsophon || $? return
     update_bm1688_debs || $? return
     build_bm1688_rootfs || $? return
     pack_bm1688_rootfs || $? return
}


function build_bmcpu()
{
  print_notice "Run ${FUNCNAME[0]}() function"

  if [ ! -d "$BMCPU_PATH"/build ]; then
    mkdir -p "$BMCPU_PATH"/build
  fi

  pushd "$BMCPU_PATH"/build || return "$?"
  rm -rf "$BMCPU_PATH"/build/*
  cmake -DCMAKE_TOOLCHAIN_FILE=$BMCPU_PATH/riscv_linux.cmake -DPLATFORM=sophon -DCORE_ID=${CORE_ID:-0} ..
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
    build_uboot || return $?
    build_kernel || return $?
    build_osdrv || return $?
    build_ramboot || return $?
    build_v4l2_isp || return $?
    #rename deb
    pushd ${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}
    export LOCALVERSION=-tag-
    KERNELRELEASE=`make kernelrelease`
    pushd ${KERNEL_PATH}/build
    mv linux-headers-${KERNELRELEASE}_*.deb linux-headers-${KERNELRELEASE}.deb
    mv linux-image-${KERNELRELEASE}-dbg_*.deb linux-image-${KERNELRELEASE}-dbg.deb
    mv linux-image-${KERNELRELEASE}_*.deb linux-image-${KERNELRELEASE}.deb
    popd
    popd
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

    PACKAGE_OUTPUT_DIR="$OUTPUT_DIR"/package_edge
    sudo rm -rf $PACKAGE_OUTPUT_DIR
    mkdir $PACKAGE_OUTPUT_DIR
    mkdir $PACKAGE_OUTPUT_DIR/boot

    cp -rf $RAMDISK_PATH/$RAMDISK_OUTPUT_FOLDER/boot.itb $PACKAGE_OUTPUT_DIR/boot/
    cp -rf $RAMDISK_PATH/$RAMDISK_OUTPUT_FOLDER/multi.its $PACKAGE_OUTPUT_DIR/boot/
    cp -rf $OUTPUT_DIR/fip.bin $PACKAGE_OUTPUT_DIR//boot/

    cp -rf $OUTPUT_DIR/fip.bin $PACKAGE_OUTPUT_DIR/
    cp -rf $OUTPUT_DIR/ramboot.itb $PACKAGE_OUTPUT_DIR/

    mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "eMMC Boot Script" \
            -d ${TOP_DIR}/build/boot.cmd.emmc ${OUTPUT_DIR}/boot.scr.emmc
    cp -rf ${OUTPUT_DIR}/boot.scr.emmc $PACKAGE_OUTPUT_DIR/boot/
    pushd $PACKAGE_OUTPUT_DIR
    pushd boot
    tar -zcvf ../boot.tgz *
    popd
    mv ramboot.itb recovery.itb
    tar -zcvf recovery.tgz  recovery.itb

    if ! [ -e "../rootfs.tgz" ]; then
      print_error "edge rootfs.tgz does not exist!!"
      return 1
    fi

    mkdir rootfs
    sudo tar -zxf ../rootfs.tgz -C ./rootfs
    sudo cp -rf  $OUTPUT_DIR/rootfs/mnt/system rootfs/mnt/
    cd rootfs
    sudo tar -zcf rootfs.tgz *
    mv rootfs.tgz ../
    cd ..
    popd

    build_update sdcard
    build_update tftp
    build_update usb
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
  AI_SDK_PATH="$TOP_DIR"/cviai
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
  BOOTLOGO_PATH="$COMMON_TOOLS_PATH"/bootlogo/logo.jpg

  # subfolder path for buidling, chosen accroding to .gitignore rules
  UBOOT_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"
  RAMDISK_OUTPUT_BASE=build/"$PROJECT_FULLNAME"
  KERNEL_OUTPUT_FOLDER=build/"$PROJECT_FULLNAME"
  RAMDISK_OUTPUT_FOLDER="$RAMDISK_OUTPUT_BASE"/workspace

  PACKAGE_OUTPUT_DIR="$OUTPUT_DIR"/package_edge

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

print_usage

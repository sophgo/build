# Test SDK on target board

## download SDK

```sh
git clone -b sg200x-evb git@github.com:sophgo/sophpi.git
./sophpi/scripts/repo_clone.sh --gitclone sophpi/scripts/subtree_cv184x-v6.x.xml
```

## setup build parameter

### Initialize environment
```sh
source build/envsetup_soc.sh
  -------------------------------------------------------------------------------------------------------
    Usage:
    (1) menuconfig - Use menu to configure your board.
        ex: $ menuconfig

    (2) defconfig $CHIP_ARCH - List EVB boards($BOARD) by CHIP_ARCH.
       ** cv184x ** -> ['cv184x', 'cv1840cp', 'cv1841cp', 'cv1842cp', 'cv1842hp', 'cv1843hp']
        ex: $ defconfig cv184x

    (3) defconfig $BOARD - Choose EVB board settings.
        ex: $ defconfig cv1842hp_wevb_0014a_spinor
        ex: $ defconfig cv1842cp_wevb_0015a_spinand
  -------------------------------------------------------------------------------------------------------
```

### Select the target board.
```sh
defconfig cv1842hp_wevb_0014a_spinor
  ====== Environment Variables ======= 

    PROJECT: cv1842hp_wevb_0014a_spinor, DDR_CFG=ddr3_2133_x16
    CHIP_ARCH: CV184X, DEBUG=0
    SDK VERSION: musl_arm, RPC=0
    ATF options: ATF_KEY_SEL=default, BL32=1
    Linux source folder:linux_5.10, Uboot source folder: u-boot-2021.10
    ENABLE_DUAL_OS: y
    CROSS_COMPILE_PREFIX: arm-none-linux-musleabihf-
    PACK_BOOTLOGO: n
    Flash layout xml: build/boards/cv184x/cv1842hp_wevb_0014a_spinor/partition/partition_spinor.xml
    Sensor tuning bin: cvsens_cv2003
    Output path: install/soc_cv1842hp_wevb_0014a_spinor
```

### Graphical interface configuration compilation parameters
```sh
menuconfig
```

## build images

```sh
clean_all && build_all
```

## get images under install folder, the images will be placed under folder named as PCBA model name

```sh
ls install/soc_cv1842hp_wevb_0014a_spinor
```

## following are commmands after source build/cvisetup.sh

  - build_kernel
  - build_uboot
  - build_rtt
  - build_ramboot
  - build_osdrv
  - build_3rd_party
  - build_libsophon
  - build_middleware
  - build_cvi_rtsp
  - build_tpu_kernel
  - build_ive_sdk
  - build_ivs_sdk
  - build_tdl_sdk
  - build_pqtool_server
  - build_access_guard_turnkey_app
  - build_ipc_app
  - pack_cfg
  - pack_rootfs
  - pack_data
  - pack_system
  - copy_tools
  - pack_upgrade
  - menuconfig
  - menuconfig_kernel
  - menuconfig_uboot
  - menuconfig_rtt
  - clean_uboot
  - clean_rtt
  - clean_alios
  - clean_rtos
  - clean_atf
  - clean_kernel
  - clean_ramdisk
  - clean_3rd_party
  - clean_tpu_kernel
  - clean_ive_sdk
  - clean_ivs_sdk
  - clean_tpu_sdk
  - clean_tdl_sdk
  - clean_cnv_sdk
  - clean_access_guard_turnkey_app
  - clean_ipc_app
  - clean_middleware
  - clean_osdrv
  - clean_libsophon
  - clean_cvi_rtsp
  - clean_pqtool_server

## Contribution

- If you have any questions, feel free to submit an issue for feedback.
- We welcome pull requests and code contributions.

## Release

| Version   | Date       |  Updated                                   |
|----------|----------------|--------------------------------------------|
| v6.1.0   | 2025-05-30     | CV184X SDK 首次发布|
| v6.2.0   | 2025-06-23     | 支持单双系统|
| v6.2.1   | 2025-07-19     | 支持64bit工具链|
| v6.2.2   | 2025-08-01     | 更新内存分配|
| v6.3.0   | 2025-08-29     | 单系统适配RT-Thread|

## License

1. Project license: BSD 2-Clause (applies to code developed by Sophgo Technologies Inc.)
  - See LICENSE at repository root.
2. Third-party code and licenses:
  - Some files include SPDX-License-Identifier: eCos-2.0.
  - Some files include SPDX-License-Identifier: ISC.
  - These files remain under their original licenses. We keep their original headers and attributions.
3. How to identify licenses in this repo:
  - Files may contain SPDX-License-Identifier headers indicating their specific license.
  - If a file has an SPDX header, that header controls for that file.
  - If a file has no explicit header and is authored by Sophgo Technologies Inc, it is covered by BSD 2-Clause.
4. License texts:
  - eCos-2.0: LICENSES/eCos-2.0.txt (or see https://spdx.org/licenses/eCos-2.0.html)
  - ISC: LICENSES/ISC.txt (or see https://spdx.org/licenses/ISC.html)

# Test SDK on target board

##unzip sdk
##host-tools.tar.gz contain toolchain that you just need to do one time

```sh
cd ~/
#unzip tool chain
tar zxvf <working_dir>/host-tools.tar.gz

#unzip SDK source
cd sdk_release
tar zxf cv1835_v1.3.0_source.tar.gz
cd cv1835_v1.3.0_source/

#make a symbolic link to SDK source folder
ln -s ~/host-tools/
```

##setup build parameter

```sh
source build/cvisetup.sh
```
====================================
 Supported SoCs
====================================
0:  cv1822
1:  cv1829
2:  cv1832
3:  cv1835
4:  cv1838

=> Select SoC (default: cv1835):3

====================================
 Supported SoC platform
====================================
0:  asic

=> Select SoC platform (default: asic): 0

====================================
cv1835 supported boards
====================================
0:  wevb_0001a (EMMC 8GB + LPDDR4 1GB)
1:  wevb_0002a (EMMC 8GB + DDR3 1GB)
2:  wevb_0002a_spinand (SPI-NAND 256MB + DDR3 1GB)
3:  wevb_0002a_ddr3x16 (EMMC 8GB + DDR3 16bit 512MB)
4:  wdmb_0001a_spinand ((board 38) SPI-NAND 256MB + DDR3L 512MB)
7:  wevb_0003a ()
8:  wevb_0002a_spinor ()


=> Select the board number: 1

##after all slections are done, build environment parameters will be shown below

Setup environment variables is done

====== Environment Variables =======
  CHIP=cv1835, SUBTYPE=asic, BOARD=wevb_0002a, DEBUG=0, TAG=
  project: cv1835_asic_wevb_0002a
  u-boot options: UBOOT_VBOOT=0 ENABLE_BOOTLOGO=0
  kernel config: cv1835_asic_evb
  gcc comipler: <working_dir>/sdk_release/2020-11-03_source/host-tools/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
  output path: <working_dir>/sdk_release/2020-11-03_source/install/soc_cv1835_asic_wevb_0002a
  image options: compression=1
  file system options: storage type=spinand


##build images

```sh
build_all
```

##get images under install folder, the images will be placed under folder named as PCBA model name

```sh
cd install
ls
```
##it will show the PCBA that user have been build before

 - soc_cv1835_asic_wevb_0001a
 - soc_cv1835_asic_wevb_0002a
 - soc_cv1835_asic_wdmb_0001a_spinand

##following are commmands after source build/cvisetup.sh

 - build_fip
 - build_all
 - build_kernel
 - build_middleware
 - build_middleware_32
 - build_ramboot
 - build_uboot
 - clean_all
 - clean_middleware
 - clean_uboot
 - clean_all_32
 - clean_middleware_32
 - clean_kernel
 - clean_ramdisk
 - pack_boot
 - pack_gpt
 - pack_system
 - pack_cfg
 - pack_rootfs
 - pack_upgrade

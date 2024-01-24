#!/bin/bash
function gettop
{
    local TOPFILE=pld_tool/compile.sh
    if [ -n "$TOP" -a -f "$TOP/$TOPFILE" ] ; then
     # The following circumlocution ensures we remove symlinks from TOP.
     (cd $TOP; PWD= /bin/pwd)
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
         T=`PWD= /bin/pwd -P`
       done
       \cd $HERE

       if [ -f "$T/$TOPFILE" ]; then
         echo $T
       fi
     fi
    fi
}

TOPDIR=$(gettop)
#pushd $TOPDIR/rom
#make -j20
#popd
#build_fsbl
#build_kernel
#build_ramboot

pushd $TOPDIR/pld_tool
rm -rf target
mkdir -p target
cp $TOPDIR/../bl1.bin target/
cp $TOPDIR/../bl2.bin target/
cp $TOPDIR/../bl31.bin target/
cp $TOPDIR/u-boot-2021.10/build/athena2_palladium/u-boot.bin target/
cp $TOPDIR/ramdisk/build/athena2_palladium/workspace/Image target/
cp $TOPDIR/ramdisk/build/athena2_palladium/workspace/boot.cpio.gz.img target/
cp $TOPDIR/ramdisk/build/athena2_palladium/workspace/athena2_palladium.dtb target/

pushd target
mkdir -p backdoor
pushd backdoor
mkdir -p workspace
mkdir -p c_build
mkdir -p script
#hexdump -ve '"%08x\n"' ../target/bl1.bin > bl1.bin.text

bl2_size=`ls -l $TOPDIR/pld_tool/target/bl2.bin | awk '{print $5}'`
$TOPDIR/pld_tool/athena2_pld_sram_memtool_v1 0 $TOPDIR/pld_tool/target/bl2.bin $bl2_size bl2 0 ../c_build/ 1

bl31_size=`ls -l $TOPDIR/pld_tool/target/bl31.bin | awk '{print $5}'`
$TOPDIR/pld_tool/athena2_pld_ddr_mem_tool 0 $TOPDIR/pld_tool/target/bl31.bin $bl31_size bl31 0 ../c_build/ 1
mv $TOPDIR/pld_tool/target/backdoor/reload_ddr.tcl $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl
echo "###bl31 end###" >> $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl

uboot_size=`ls -l $TOPDIR/pld_tool/target/u-boot.bin | awk '{print $5}'`
$TOPDIR/pld_tool/athena2_pld_ddr_mem_tool 0 $TOPDIR/pld_tool/target/u-boot.bin $uboot_size uboot 0x40000 ../c_build/ 1
cat $TOPDIR/pld_tool/target/backdoor/reload_ddr.tcl >> $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl
echo "###u-boot end###" >> $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl

image_size=`ls -l $TOPDIR/pld_tool/target/Image | awk '{print $5}'`
$TOPDIR/pld_tool/athena2_pld_ddr_mem_tool 0 $TOPDIR/pld_tool/target/Image $image_size image 0x4000000 ../c_build/ 1
cat $TOPDIR/pld_tool/target/backdoor/reload_ddr.tcl >> $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl
echo "###Image end###" >> $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl

ramdisk_size=`ls -l $TOPDIR/pld_tool/target/boot.cpio.gz.img | awk '{print $5}'`
$TOPDIR/pld_tool/athena2_pld_ddr_mem_tool 0 $TOPDIR/pld_tool/target/boot.cpio.gz.img $ramdisk_size ramdisk 0x5000000 ../c_build/ 1
cat $TOPDIR/pld_tool/target/backdoor/reload_ddr.tcl >> $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl
echo "###ramdisk end###" >> $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl

dtb_size=`ls -l $TOPDIR/pld_tool/target/athena2_palladium.dtb | awk '{print $5}'`
$TOPDIR/pld_tool/athena2_pld_ddr_mem_tool 0 $TOPDIR/pld_tool/target/athena2_palladium.dtb $dtb_size dtb 0x6000000 ../c_build/ 1
cat $TOPDIR/pld_tool/target/backdoor/reload_ddr.tcl >> $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl
echo "###dtb end###" >> $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl

mv $TOPDIR/pld_tool/target/backdoor/workspace/reload_ddr_tmp.tcl $TOPDIR/pld_tool/target/backdoor/reload_ddr.tcl
rm -rf $TOPDIR/pld_tool/target/backdoor/workspace

mv *.h c_build
mv *.tcl script
popd
tar -zcvf pld_backdoor_realddr.tgz backdoor/
mv pld_backdoor_realddr.tgz ..
popd
rm -rf target


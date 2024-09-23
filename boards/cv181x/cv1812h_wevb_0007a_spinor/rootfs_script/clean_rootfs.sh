#!/bin/bash

SYSTEM_DIR=$1
cp $SYSTEM_DIR/mnt/system/usr/bin/alios_cli $SYSTEM_DIR/bin/
rm -rf $SYSTEM_DIR/mnt/system/usr
rm -rf $SYSTEM_DIR/mnt/system/lib
rm -rf $SYSTEM_DIR/mnt/system/lib/libsns_gc*
rm -rf $SYSTEM_DIR/mnt/system/lib/libsns_imx*
rm -rf $SYSTEM_DIR/mnt/system/lib/libsns_sc*
rm -rf $SYSTEM_DIR/mnt/system/lib/libcipher.so

rm -rf $SYSTEM_DIR/mnt/system/m2m-deinterlace.ko
rm -rf $SYSTEM_DIR/mnt/system/efivarfs.ko

du -sh $SYSTEM_DIR/* |sort -rh

rm -rf $SYSTEM_DIR/etc/init.d/S23ntp
rm -rf $SYSTEM_DIR/bin/ntpd
find $SYSTEM_DIR/mnt/system/ko/ ! -name cv181x_clock_cooling.ko ! -name cv181x_tpu.ko ! -name cv181x_base.ko ! -name cv181x_sys.ko ! -name cvi_ipcm.ko ! -name cv181x_ive.ko ! -name loadsystemko.sh -type f -exec rm -rf {} \;

if [ $BUILD_FOR_DEBUG != "y" ]
then
#del dmesg cmd if CONFIG_PRINTK=n
#sed -i "/dmesg/d" $SYSTEM_DIR/mnt/system/ko/loadsystemko.sh

#del debugfs node
sed -i "/debugfs/d" $SYSTEM_DIR/etc/fstab
fi

du -sh $SYSTEM_DIR/* |sort -rh

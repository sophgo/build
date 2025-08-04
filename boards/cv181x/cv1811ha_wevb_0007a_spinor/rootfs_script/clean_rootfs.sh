#!/bin/bash
SYSTEM_DIR=$1
cp $SYSTEM_DIR/mnt/system/usr/bin/alios_cli $SYSTEM_DIR/bin/
rm -rf $SYSTEM_DIR/mnt/system/usr
rm -rf $SYSTEM_DIR/mnt/system/lib

if [ "$FASTBOOT" = "y" ]
then
rm -rf $SYSTEM_DIR/etc/init.d/S01syslogd
rm -rf $SYSTEM_DIR/etc/init.d/S02klogd
rm -rf $SYSTEM_DIR/etc/init.d/S02sysctl
rm -rf $SYSTEM_DIR/etc/init.d/S11defer_init
rm -rf $SYSTEM_DIR/etc/init.d/S20urandom
rm -rf $SYSTEM_DIR/etc/init.d/S40network
rm -rf $SYSTEM_DIR/etc/init.d/S23ntp
rm -rf $SYSTEM_DIR/etc/init.d/S99user
rm -rf $SYSTEM_DIR/etc/init.d/P02crond
fi


du -sh $SYSTEM_DIR/* |sort -rh
du -sh $SYSTEM_DIR/mnt/* |sort -rh
du -sh $SYSTEM_DIR/mnt/system/* |sort -rh
du -sh $SYSTEM_DIR/mnt/system/lib/*  |sort -rh
du -sh $SYSTEM_DIR/mnt/system/data/install/* |sort -rh
du -sh $SYSTEM_DIR/usr/* |sort -rh

#!/bin/bash

SYSTEM_DIR=$1
if [[ ${STORAGE_TYPE} == "spinor" ]];then
rm -rf $SYSTEM_DIR/mnt/system/usr/*
rm -rf $SYSTEM_DIR/mnt/system/lib/*
fi

sed -i "/sophon_tpu/d" $SYSTEM_DIR/mnt/system/ko/loadsystemko.sh
rm -rf $SYSTEM_DIR/mnt/system/ko/sophon_tpu.ko

du -sh $SYSTEM_DIR/* |sort -rh
du -sh $SYSTEM_DIR/mnt/* |sort -rh
du -sh $SYSTEM_DIR/mnt/system/* |sort -rh
du -sh $SYSTEM_DIR/mnt/system/lib/*  |sort -rh
du -sh $SYSTEM_DIR/mnt/system/data/install/* |sort -rh
du -sh $SYSTEM_DIR/usr/* |sort -rh

#!/bin/bash

SYSTEM_DIR=$1
if [[ ${STORAGE_TYPE} != "emmc" ]];then
rm -rf $SYSTEM_DIR/mnt/system/usr/*
rm -rf $SYSTEM_DIR/mnt/system/lib/*
fi

du -sh $SYSTEM_DIR/* |sort -rh
du -sh $SYSTEM_DIR/mnt/* |sort -rh
du -sh $SYSTEM_DIR/mnt/system/* |sort -rh
du -sh $SYSTEM_DIR/mnt/system/lib/*  |sort -rh
du -sh $SYSTEM_DIR/mnt/system/data/install/* |sort -rh
du -sh $SYSTEM_DIR/usr/* |sort -rh

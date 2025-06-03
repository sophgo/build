#!/bin/bash

SYSTEM_DIR=$1
cp $SYSTEM_DIR/system/usr/bin/alios_cli $SYSTEM_DIR/bin/
rm -rf $SYSTEM_DIR/system/usr
rm -rf $SYSTEM_DIR/system/lib

du -sh $SYSTEM_DIR/* |sort -rh

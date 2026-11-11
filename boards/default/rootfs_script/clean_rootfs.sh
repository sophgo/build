#!/bin/bash

SYSTEM_DIR=$1
rm -f $SYSTEM_DIR/system/usr/lib/libz*
rm -f $SYSTEM_DIR/system/lib/libz*

rm -f $SYSTEM_DIR/system/usr/lib/3rd/libcvi*
rm -f $SYSTEM_DIR/system/usr/lib/3rd/libmad*
rm -f $SYSTEM_DIR/system/usr/lib/3rd/libmp3*
rm -f $SYSTEM_DIR/system/usr/lib/3rd/libopencv*
rm -f $SYSTEM_DIR/system/usr/lib/libopencv*
rm -f $SYSTEM_DIR/system/usr/lib/libcvi_rtsp.so
rm -f $SYSTEM_DIR/system/data/install/lib/libcvi_rtsp.so
rm -f $SYSTEM_DIR/system/usr/lib/libcvikernel.so
rm -f $SYSTEM_DIR/system/usr/lib/*.a
rm -f $SYSTEM_DIR/system/lib/*.a
rm -f $SYSTEM_DIR/system/usr/lib/libgst*
rm -f $SYSTEM_DIR/system/usr/lib/libg*
rm -f $SYSTEM_DIR/system/usr/lib/gstreamer-1.0/libgst*
rm -f $SYSTEM_DIR/system/data/install/lib/libcrypto.so*
rm -f $SYSTEM_DIR/system/data/install/lib/libssl.so*
rm -f $SYSTEM_DIR/system/data/install/lib/libcvi_protobuf.so*
rm -f $SYSTEM_DIR/system/data/install/lib/libprotobuf-lite.so*
rm -f $SYSTEM_DIR/system/usr/lib/libcviai*
rm -f $SYSTEM_DIR/system/usr/lib/libraw_replay.so*
rm -f $SYSTEM_DIR/system/usr/lib/libraw_replay_offline.so*
rm -f $SYSTEM_DIR/system/usr/lib/libraw_dump.so*
rm -f $SYSTEM_DIR/system/usr/lib/libcvi_ive_tpu.so*
rm -rf $SYSTEM_DIR/system/usr/lib/gio
rm -rf $SYSTEM_DIR/system/usr/lib/glib*
rm -rf $SYSTEM_DIR/system/usr/lib/gstreamer-1.0*
rm -rf $SYSTEM_DIR/system/usr/libexec*
cp $SYSTEM_DIR/system/usr/bin/alios_cli $SYSTEM_DIR/bin/
rm -rf $SYSTEM_DIR/system/usr/bin
rm -f $SYSTEM_DIR/system/usr/lib/libcvimath.so
rm -f $SYSTEM_DIR/system/usr/lib/libcviruntime.so
rm -f $SYSTEM_DIR/system/usr/lib/libcnpy.so
rm -f $SYSTEM_DIR/system/usr/lib/libcipher.so

rm -f $SYSTEM_DIR/system/lib/libcipher.so*
rm -f $SYSTEM_DIR/system/lib/libraw_replay.so*
rm -f $SYSTEM_DIR/system/lib/libmad.so*
rm -f $SYSTEM_DIR/system/lib/libmp3*
rm -f $SYSTEM_DIR/system/lib/libnanomsg*

rm -rf $SYSTEM_DIR/etc/init.d/S01syslogd
rm -rf $SYSTEM_DIR/etc/init.d/S02klogd
rm -rf $SYSTEM_DIR/etc/init.d/S40network
rm -rf $SYSTEM_DIR/etc/init.d/S23ntp
rm -f $SYSTEM_DIR/bin/ntpd

#del 3rdparty lib
#del thttpd/libwebsockets lib
rm -f $SYSTEM_DIR/system/lib/libthttpd*
rm -f $SYSTEM_DIR/system/lib/libwebsocket*
rm -f $SYSTEM_DIR/system/usr/lib/libcvi_ispd2.so
rm -f $SYSTEM_DIR/system/usr/lib/libisp.so
rm -f $SYSTEM_DIR/system/usr/lib/libisp_ipc_client.so
rm -f $SYSTEM_DIR/system/usr/lib/libae.so
rm -f $SYSTEM_DIR/system/usr/lib/libawb.so
rm -f $SYSTEM_DIR/system/usr/lib/libcvi_audio.so
rm -f $SYSTEM_DIR/system/usr/lib/libcvi_bin.so
rm -f $SYSTEM_DIR/system/usr/lib/libsys.so
rm -f $SYSTEM_DIR/system/usr/lib/libvi.so
rm -f $SYSTEM_DIR/system/usr/lib/libcvi_ssp.so
rm -f $SYSTEM_DIR/system/usr/lib/libsns_full.so

if [ "$OSDRV_BUILD_IN" == "y" ]
then
find $SYSTEM_DIR/system/ko/ -type f -exec rm -rf {} \;
fi
#del opencv lib
rm -f $SYSTEM_DIR/system/lib/libopencv*
#del ffmpeg lib
rm -f $SYSTEM_DIR/system/lib/libav*
#del openssl
rm -f $SYSTEM_DIR/system/lib/libssl*
rm -f $SYSTEM_DIR/system/lib/libcrypto*

rm -f $SYSTEM_DIR/system/lib/*.so*

du -sh $SYSTEM_DIR/* |sort -rh
du -sh $SYSTEM_DIR/system/* |sort -rh
du -sh $SYSTEM_DIR/system/lib/*  |sort -rh
du -sh $SYSTEM_DIR/system/data/install/* |sort -rh
du -sh $SYSTEM_DIR/usr/* |sort -rh

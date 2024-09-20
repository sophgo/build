# CVITEK SDK Release #
----------

## v1.3.1 ##
2021/01/05

**Git revision:**

project arm-trusted-firmware/
c194891699ba6431af58f27a6a15f476f0c5a135 Hide the CHIP information

project bm_bld/
86057a0ffac49b062ea44489fc5ccd4c4ed6e3c5 Add CV1822 ASIC

project build/
7e6aa47ea379379f9ebabb0f526a4e9fac32c7ef [Feature] remove defconfig modification.

project cnpy/
351f6a43543e83a3ca8558d261261df2449e8990 fix build warning

project cvi_pipeline/
8ae60a44a52bd749bcc228e3f1d2ad45cc453f5a Remove the venc duplicate BS_MODE definition

project tdl_sdk/
01baca393d35c02be4adf0a3a6dc1bbef8dbd573 [core] Fix memory leak

project cvibuilder/
3e53436052c9b4501b09b45be3a5477a76eb637e add data_format in cvimodel

project cvikernel/
acf5c1745b0ae81b801b21dc0385826d8440b536 Extend decompress api

project cvimath/
93a0a9af364d65237817fcbfa4f9cca299d5bfff [cmake] Add static lib

project cviruntime/
1c92ffa6755182ae6fdaa15b2729bbe0b240138b fix sample error

project flatbuffers/
6da1cf79d90eb242e7da5318241d42279a3df3ba [rust] Add use declarations to Rust-generated bindings for imported FB definitions (#5645)

project host-tools/
8b4adafa1a2ef50193f60ddf0319bcb00d1bc62a Revert "[DS-5/gator] Add libstreamline_annoate.a/.so and streamline_annoate.h"

project isp_tuning/
379ae46f4e2be1122dea0d3043f9818caeb73f06 [CV1835] MW_ISP: Adjust input of out folder path

project ive/
437cc7685a3ebc04b8d1c240d07450ac32f6da5c [tpu_data] Fix RGB package support when image source is from middleware

project ive/3rdparty/tracer/
ca2cef2a7684d382bccc1c6ef43c569cc3e2ec97 [scripts] Add scripts

project ivs/
8132e820da325dd73f5b455a95c1e638a3f2dea6 add ifelse for tracer selection

project linux-linaro-stable/
12de3bc387394d350394ba98c4b10d1af125bd47 Merge "audio: fix IOCTL: SET_DAC_VOL fail" into cv183x_v1.3.0

project middleware/
bb207669e5af9ab68f618db1b95927bbe2712a2f [Bug][Sensor] fix ISP_SNS_OBJ_S not initialized function pointer

project opencv/
70db6c9c2819618571f6ca5a2dbd90884b29908f fix 32_compileErr png_init_filter_functions_neon

project oss/
8e8033a6b023ec6cc2666915ab953a5f4ccbb2c2 update submodule for live555

project oss/ffmpeg/
e8bde30c25e3997e680210e4904fe2e8696fe415 Merge "[Feature] Supprt file segment slice to reduce FAT32 fragment problem"

project oss/flatbuffers/
6da1cf79d90eb242e7da5318241d42279a3df3ba [rust] Add use declarations to Rust-generated bindings for imported FB definitions (#5645)

project oss/glog/
96d2bcc313e3c53a93b2ae172ff632ffd7983886 Revert "[OSS][GLOG] enable so and fix unused warning"

project oss/live555/
bfb090d9f81aec200299220ef1c09de6d33f9170 include sysroot

project oss/opencv/
70db6c9c2819618571f6ca5a2dbd90884b29908f fix 32_compileErr png_init_filter_functions_neon

project oss/openssl/
d447fff5163f09577367a368882de8dae8f7500b remove submodules

project oss/sqlite3/
601f3b084eaaac76e95bdd87fab1c9a9482da5c2 import sqlite3 as 20200918 download release tarball

project oss/thttpd/
5acc3be31a2bc09bb5f26fa92d824d5eeae2a3f1 update with Sam's modification, and compile as lib rather than exe file

project oss/zlib/
e827145fbbe6773408dc7601ef1d063442bed2b9 import zlib 1.2.11

project ramdisk/
e8adfb7b2c439fdf3f1fa2d42e770aced087b68c Merge "[Bug] correct cv183x_wdt.ko path." into cv183x_v1.3.0

project u-boot/
1112f44ea918231634cde83dfdb38a412141a258 Merge "[vdec][jpeg] support 32-byte aligned stride" into cv183x_v1.3.0

**Fixed Bug List**
1. 2109: [CV1835+IMX335]开启宽动态亮区发绿
2. 2108: [CV183x]Release SDK编译出来的FW无法正常运行
3. 2107: 升级重启之前reset uboot env
4. 2105: [Infinova CV1838] Release SDK Repo内的.git需删除
5. 2084: 对于部分屏driver ic，dcs cmd只能通过mipi tx data lane0来发
6. 2072: [1838_EVB][Library] Lack of libanl.so.1 and libnsl.so.1 at 32bit Version
7. 2071: [1838_EVB][System]can't read '/mnt/system/ko/kernel/drivers/watchdog/cv183x_wdt.ko': No such file or directory
8. 2066: [CV1835][世邦][Panel] 更换logo size 到 800*1280后，显示异常
9. 2043: vcodec 測項跑到vdec時候, ssh 會randomly 斷線無法繼續驗證
10. 2035: [1835_EVB][System] cvi-spif 10000000.cvi-spif: device scan failed
11. 1990: [Bug][Sensor] fix ISP_SNS_OBJ_S not initialized function pointer
12. 1980: [SPINAND]第一次寫的區域內有壞塊，所以會往後跳一個block，第二次寫的時候，把第一次寫的資料蓋掉了
13. 1982: 修正null pointer access
14. 1922: 修正rgbee np lut data type
15. 1887: [cv183x][Audio]no-data issue, can not get stream by cvi_aenc_getstream
16. 1875: [Infinova_CV1838]OSD RGN区域，在画面上呈左右两边对称显示
17. 1855: [Infinova_CV1838]【IMX334】需补充实现VCodec接口
18. 1848: 升级FW后第一次开机正常，再次开机后挂载分区失败，文件系统出错

**New Support Feature List**

1. 2036: Seperate lmap config for sensor A/B
2. 2016: [Infinova CV1838] Release SDK需要一起释放cvi_vip_isp_ext.h头文件
3. 1884: [osdrv][cv183x][vip] feat: sc support custom csc, add add bl16 and refine
4. 1873: Enable LTM/Fusion with linear mode requested by tuning team.
5. 1862: [cv183x] Add API for reading chip version
6. 1858: Add eFuse API
7. 1823: [吉为门禁考勤Turnkey] H264 video encode/decode porting to Giwei branch and sample code provide
8. 1822: [keytop_CV1835][IMX327]venc bind mode (with vpss/vi)实现
9. 1821: [Infinova_CV1838]VI-VPSS/VPSS-Venc多路bind mode （6路码流同时bind）
10. 1820: [keytop_CV1835][IMX327]需完善MMF proc fs信息
11. 1818: [Infinova_CV1838][IMX334]智能编码支持编码复杂度
12. 1817: [Infinova_CV1838][IMX334]ROI支持智能关联检测、动态调整区域
13. 1816: [Infinova_CV1838][IMX334]6路码流分别设置ROI感兴趣区域QP参数、编码等级和名称
14. 1815: [keytop_CV1835][IMX327]需完善VENC系统proc fs信息

## v1.3.0 ##
2020/10/23

**Git revision:**

    project arm-trusted-firmware/
    655d731f3ed472ecf0585a6df34524755b5c82f4 Add support for CV1829

    project bm_bld/
    ca6b9f4980185380a5c55c60398e575b9568ce10 Update DDR config

    project build/
    ce1e8fec4e84b2d713a26ab2e30350b33fff91f3 [sdk_script] Fixed build flow issue.

    project cnv/
    d67749cea96c2e81a1a25502601616461bbd24c9 close switch case which not be used

    project cvi_pipeline/
    2a3755bc7f62f4f91b76d018db636ab2f295e1be workaround to support chip cv182x

    project tdl_sdk/
    60941654c6ef9de848c5fe77c23ea4b6f6eb7ad6 [cmake] Fix header not found

    project cviruntime/
    87303b0ddbb304217abc0dd37123d663dfc0b9a1 fix ssd detection error

    project host-tools/
    8b4adafa1a2ef50193f60ddf0319bcb00d1bc62a Revert "[DS-5/gator] Add libstreamline_annoate.a/.so and streamline_annoate.h"

    project isp_tuning/
    fa6893a1e23ceab6681d7ba0879d8aaa6f468889 [CV1835] ISP_TUNING: Check-in .bin & .json

    project ive/
    62edde0cddeb0d87bae52a80d68e03aede712002 [dma] Fix crash when image size is large

    project ive/3rdparty/tracer/
    ca2cef2a7684d382bccc1c6ef43c569cc3e2ec97 [scripts] Add scripts

    project ivs/
    8132e820da325dd73f5b455a95c1e638a3f2dea6 add ifelse for tracer selection

    project linux-linaro-stable/
    12b73818d2777a04b38f944c21a5147e9b023f65 [USB] Enable the vbus irq after all initializaton is done.

    project llvm-project/
    1893ef5dff98ebb8d3f9cb2005ef492d450ca0f5 fix python interpreter not read from system default

    project llvm-project/llvm/projects/mlir/
    33cfd66f8221c44fe1c8f7eeeb240fc08cdabc45 update submodule

    project llvm-project/llvm/projects/mlir/externals/cmodel/
    76c8cd5368964dee79f086f8e67e52273cc04f71 not to check if high bits of base gaddr is zero in cmodel

    project llvm-project/llvm/projects/mlir/externals/cvibuilder/
    79b23f0ed7422061b163a270ef340547649e4b94 update version number

    project llvm-project/llvm/projects/mlir/externals/cvikernel/
    eab556250cf5f4999415d2d72bea88460e48a5b0 set res0_b_str register for tiu_depthwise_conv

    project llvm-project/llvm/projects/mlir/externals/cvimath/
    93a0a9af364d65237817fcbfa4f9cca299d5bfff [cmake] Add static lib

    project llvm-project/llvm/projects/mlir/externals/cviruntime/
    87303b0ddbb304217abc0dd37123d663dfc0b9a1 fix ssd detection error

    project llvm-project/llvm/projects/mlir/externals/profiling/
    3f052984b5aa4a577fee0e051a74a9d2cc8c5088 Refine profiler and fix uninitialized bug

    project llvm-project/llvm/projects/mlir/third_party/caffe/
    0baedbf8f52fe13595fb387bc0232bc1d4235ba1 add yolo_v4 attribute for detection layer

    project llvm-project/llvm/projects/mlir/third_party/cnpy/
    693cb0e78bc23f83ab79091bd09e0d1898a29f91 fix npz_save, when shape size is zero, skip it and warning

    project llvm-project/llvm/projects/mlir/third_party/flatbuffers/
    6da1cf79d90eb242e7da5318241d42279a3df3ba [rust] Add use declarations to Rust-generated bindings for imported FB definitions (#5645)

    project llvm-project/llvm/projects/mlir/third_party/opencv/
    70db6c9c2819618571f6ca5a2dbd90884b29908f fix 32_compileErr png_init_filter_functions_neon

    project llvm-project/llvm/projects/mlir/third_party/pybind11/
    d7eb3fa976a98402c25c9c46eac48bd15a8e9ab7 fix python lib reader wrong

    project llvm-project/llvm/projects/mlir/third_party/systemc-2.3.3/
    866d1c888d8d597648ce31ca0dc5a2ae2e2199a6 Initial commit: Accelera's SystemC 2.3.3

    project middleware/
    d1df6fb21f0bc8b9f0df55e0511b9bce14eb25aa [sensor]Add SmartSens SC3335 support

    project oss/
    c8706fe8118342520daa7bda94146a2325c74b01 update ffmpeg and build script

    project oss/ffmpeg/
    01506c290adb6d033e0167b95e52d37bc5ceedeb avcodec/ffwavesynth: Cleanup generically after init failure

    project oss/flatbuffers/
    6da1cf79d90eb242e7da5318241d42279a3df3ba [rust] Add use declarations to Rust-generated bindings for imported FB definitions (#5645)

    project oss/glog/
    96d2bcc313e3c53a93b2ae172ff632ffd7983886 Revert "[OSS][GLOG] enable so and fix unused warning"

    project oss/live555/
    dd1cade64e30df43e16d7c070c4d86dd5aba0a3a add PHONY for install/all/clean in Makefile

    project oss/opencv/
    70db6c9c2819618571f6ca5a2dbd90884b29908f fix 32_compileErr png_init_filter_functions_neon

    project oss/sqlite3/
    601f3b084eaaac76e95bdd87fab1c9a9482da5c2 import sqlite3 as 20200918 download release tarball

    project oss/zlib/
    e827145fbbe6773408dc7601ef1d063442bed2b9 import zlib 1.2.11

    project ramdisk/
    bcc040c280de327f03dcb8e9e9ce5f09d3998cf6 Remove core power setting code in S00upate script

    project u-boot/
    168a5988d5f47b21314f254595f2cddb2f9ad834 Fix select die command issue for winbond spinand

**Fixed Bug List**

1. 0000722: [1835_EVB][ISP] Error in isp_tool_daemon: corrupted double-linked list: 0x0000007f780008b0

2. 0001388: [1835_EVB][SDK_SYS] SYS ION test failed

3. 0001390: [1832_EVB][SDK_SYS] SYS ION test failed

4. 0001416: [1835_EVB][32bit][ISP] CVI_VIP_MIPI_TX_SET_CMD: Operation not permitted while first run sample_dsi

5. 0001457: [1838_EVB][32bit][System]mount: mounting /dev/loop0 on /mnt/isp/param failed: Bad message

6. 0001464: [1835_EVB][Audio] record.raw&vqeplay.raw recorded files failed

7. 0001485: [1832_EVB][32bit][APP]Functional.app32.AISDK.pipeline_ci test fail

8. 0001543: [1832][32bit][ISP]Kernel panic while run CviIspTool.sh and viewed by VLC player

9. 0001542: [1835][64bit][ISP]Kernel panic while run CviIspTool.sh and viewed by VLC player

11. 0001540: [1832][32bit][JPUDRV] Physical memory allocation error size=15728640 happened while run AISDK.pipeline_ci

12. 0001538: [1835_EVB][64bit][Multistream]Internal error: Oops: 96000004 while run ch1

13. 0001539: [1835_EVB][64bit][Multistream][ERR] vdi_get_vdi_info = 1043, lock failed, vdi 0x7f9ecf9890

14. 0001545: [1832][32bit][ISP]Failed to load plugin '/mnt/system/usr/lib/gstreamer-1.0/libgstalsa.so': libasound.so.2

15. 0001576: [1835_EVB][Audio]Call trace happened while run sample_audio 0 then press ctrl+c

16. 0001577: [1835_EVB][Audio] sample_audio 9顯示參數與 algorithm layer 不一致

17. 0001578: [1835_EVB][Audio] sample_audio_nr顯示可調參數與 algorithm layer 不一致

**Middleware**

1. Support streaming from vpss instead of vi in tuning mode

2. Support configuration of 3A statistics through tuning tools

3. Support for tuning dual sensors in tuning mode

4. Add new API CVI_SYS_MmapCache()

5. VPSS supports per chn scaling coefficient

6. Support VPSS crop to 4x4

7. Support VPSS normalize Y-only

8. Support GDC black light

**Driver**

vip

1. support 4K WDR

2. support DPCM for tile

3. support HSV tuning interface

cif

1. Support BT1120/BT601

2. Support burst I2C control for VIP

3. Add MAC clock 200MHz option

4. Refine the sublvds sensor stream on sequence

vcodec

1. [vdec] Support H.264 Decoder
    * SDK API
    * Multi-Decoding

2. [venc] sample_venc supports customized size of encoding

system

1. Add one package(upgrade.zip) for images update.

**CviPQ Tool v1.3.13**

1. Modify BrightnessNoiseLeve range of 3DNR page

2. Rename SatCoringLinear parameters of HSV page

3. Add parameters to WB Attr and Exposrue Attr pages

4. Add CoarseFltScale parameter to DRC page

5. Fix gamma page user interface distortion issue

6. Update calibration dll

## v1.2.0 ##
2020/7/28

**Git revision:**

    project arm-trusted-firmware/
    5754daf33140d051516a971988909cee94d38cfb Merge "1. Add BL1 from rom_cv1835 2. Add cv1822"

    project bm_bld/
    cfd08bada104f56c92883a922db316d652f57f4b Fix tpu fab setting in LPDDR4

    project build/
    c0d6a54a862a7b0f0cdfbd662773c605def19f22 Set aarch64 toolchain for strip commands.

    project cvi_pipeline/
    b489532eac16503c1e79d71e862271e8e12c1336 Fisheye mode support scaling down with Vpss Binding Mode

    project host-tools/
    b711034358b6f8c99a690a941d82ebd8b455a14e [DS-5/gator] Add libstreamline_annoate.a/.so and streamline_annoate.h

    project ive/
    0f2d0fa2d1bbfe465d517f6946693a59b0477937 [tracer] Update tracer lib name

    project ive/3rdparty/tracer/
    ca2cef2a7684d382bccc1c6ef43c569cc3e2ec97 [scripts] Add scripts

    project ivs/
    8132e820da325dd73f5b455a95c1e638a3f2dea6 add ifelse for tracer selection

    project linux-linaro-stable/
    6c18e3d3997cf83c62f1a644c444b2de5e608a3b add uac1 support

    project llvm-project/
    1893ef5dff98ebb8d3f9cb2005ef492d450ca0f5 fix python interpreter not read from system default

    project llvm-project/llvm/projects/mlir/
    d417efa1a50f7f231e51d78b416fb7ccb2120b98 Revert "align sigmoid lut method with backend"

    project llvm-project/llvm/projects/mlir/externals/backend/
    3c9ada0ba6878ae4ea08adb052587ba5f0d78157 Revert "revert conv_kernel.cpp changes for performance"

    project llvm-project/llvm/projects/mlir/externals/cmodel/
    44c232bc43bae9213b9753a0325e1ae4f548271e assert if failed to allocate large size memory

    project llvm-project/llvm/projects/mlir/externals/cvibuilder/
    6fa025090d8f87a2dce8cc3b7fd454b1629e87dd add version enum  define in cvimodel.fbs

    project llvm-project/llvm/projects/mlir/externals/cvikernel/
    29ccaa856eeb2b48f357a043d70adb544063a170 Check per-channel data alignment

    project llvm-project/llvm/projects/mlir/externals/cvimath/
    bc33c34ac6523b40d3e5dd27049748fdbe8b6012 1. remove bm_init_chip and change to bm_init function. 2. rename cv1880v2 to cv183x

    project llvm-project/llvm/projects/mlir/externals/cviruntime/
    2ac8e5b61562ab633d91e46006cdaae8f7047399 refine runtime code

    project llvm-project/llvm/projects/mlir/externals/profiling/
    b80733b37a7f89fbe9715d35abb8fa1902bad884 Print load/store byte count on screen

    project llvm-project/llvm/projects/mlir/third_party/caffe/
    935043579aba3947307c4efd94fe38cff17ea7bc add axpy layer

    project llvm-project/llvm/projects/mlir/third_party/cnpy/
    693cb0e78bc23f83ab79091bd09e0d1898a29f91 fix npz_save, when shape size is zero, skip it and warning

    project llvm-project/llvm/projects/mlir/third_party/flatbuffers/
    6da1cf79d90eb242e7da5318241d42279a3df3ba [rust] Add use declarations to Rust-generated bindings for imported FB definitions (#5645)

    project llvm-project/llvm/projects/mlir/third_party/opencv/
    70db6c9c2819618571f6ca5a2dbd90884b29908f fix 32_compileErr png_init_filter_functions_neon

    project llvm-project/llvm/projects/mlir/third_party/pybind11/
    d7eb3fa976a98402c25c9c46eac48bd15a8e9ab7 fix python lib reader wrong

    project llvm-project/llvm/projects/mlir/third_party/systemc-2.3.3/
    866d1c888d8d597648ce31ca0dc5a2ae2e2199a6 Initial commit: Accelera's SystemC 2.3.3

    project middleware/
    6779e6030d90497887ff058b2c2835525168b325 [Description]:Sample rate  8k 16k vqe failure [RootCause]:new audio algorithm not success [Solution]:need further unit test, rollback to 202001 version in 32bit [module]:audio [updated by]:vincent.yu [mantis id]:1221 [update type]:bug fix

    project oss/
    d99103870871347e07d380570931825e5b6c414f update README

    project oss/flatbuffers/
    6da1cf79d90eb242e7da5318241d42279a3df3ba [rust] Add use declarations to Rust-generated bindings for imported FB definitions (#5645)

    project oss/glog/
    96d2bcc313e3c53a93b2ae172ff632ffd7983886 Revert "[OSS][GLOG] enable so and fix unused warning"

    project oss/opencv/
    70db6c9c2819618571f6ca5a2dbd90884b29908f fix 32_compileErr png_init_filter_functions_neon

    project oss/zlib/
    e827145fbbe6773408dc7601ef1d063442bed2b9 import zlib 1.2.11

    project ramdisk/
    b0de3382d64e4e4ade0b28711a8df014f0179273 Fix mantis 0001213

    project u-boot/
    84d7dddf0738248395ff90361cdc159661b127ca net: add support of reading MAC address from eMMC or efuse


**Fixed Bug List**

1. 0001055:[1835_EVB][SD_script][64bit] SD scripts not correct after burned image

2. 0001062:[1835_EVB][ISP][64bit]Failed to boot up VPU(coreIdx: 0, productId: 9)

3. 0001064:[CV1835][TPU][64/32bit]YoloDetectionFunc::run(): Assertion `bottom_count == 3' failed.

4. 0001065:[CV1835][TPU][64/32bit]RetinaFaceDetectionFunc::run(): Assertion `bottom_count == 9' failed.

5. 0001066:[CV1835][ISP][64bit] Segmentation fault happened while PQ tool enter Preview\Get Single Image

6. 0001076:[CV1835][ISP][Dual_lens][Level]:4 [Func]:isp_blc_param_reg [Line]:635 [Info]:Sensor get blc fail. Use API blc value. always loop

7. 0001078:[CV1835][WiFi][64/32bit]can't insert '/mnt/system/ko/3rd/8188fu.ko': invalid module format

8. 0001081:[CV1835][spinand][32bit]UBIFS error (ubi2:0 pid 19777): ubifs_write_inode: can't write inode 1328, error -30

9. 0001082:[CV1835][Encode][32bit] Some encode(264/265) test scripts errors

10. 0001083:[CV1835][ntpd][64/32bit]Time not update after executed ntpd

11. 0001085:[CV1835][Audio][64/32bit]System hang happened while sample_rate set as 12k

12. 0001086:[CV1835][Audio][64/32bit]Lack of vqeplay.raw and vqeplay.wav  while sample_rate set as 11.025k/22.05k/32k/48k

13. 0001184:[CV1835][Audio][32bit] Sample rate 設為16k時, 開頭會有爆音

14. 0001183:[CV1835][Audio][32bit] Sample rate 設為8k時, 有二次爆音及雜音

15. 0001213:[CV1835][System][64/32bit]Can't check if filesystem is mounted due to missing mtab file

16. 0001203:[CV1835][System][64/32bit] insmod: can't read '/mnt/system/ko/cv183x_wdt.ko': No such file or directory

17. 0001173:[CV1835][64/32bit][IVE] All IVE test applications run failed

18. 0001179:[CV1835][Audio][32bit] Call trace happened after sample_audio 0

19. 0000991:[1835_EVB][Boot]Call trace happened while running sample_audio 5

20. 0001003:[1835_EVB][Audio]Pop noise happened while sample_rate set as 11.025k

21. 0001174:[CV1835][64/32bit][IVS] IVS(sample_refdiff) test command run failed)

22. 0001183: [CV1835][Audio][32bit] Sample rate 設為8k時, 有二次爆音及雜音

23. 0001220: [CV1835][Audio][32bit] Sample rate 設為8k/16k時, 會有 speech_algo error, size is not 160.

24. 0001221: [CV1835][Audio][32bit] Sample rate 設為8k/16k時, vqeplay.wav 錄音內容不符合來源


**Middleware**

1. Add VI data path for pico640 thermal sensor

2. Add Signal handler for SIGINT and SIGTERM

3. vo support pause/resume

4. vpss support assigned channel's frame

5. sys support buffer from tpu-sdk

6. Fix gdc could output black

7. Add PICO640, SC200AI sensor driver

8. [OS08A20] Add delay to skip the unstable frame

9. [IMX307] Correct the WDR mode parameters

10. [F35/F23/OS08a20] Correct the gain calculation error

11. fix audio decode and audio get frame buffer overlap error

12. Add AAC-ADTS encode interface

13. update default tuning setting for better image quality

14. update wdr algrothm

15. update 3dnr parameters to reduce motion blur that in dark region

16. optimize awb algorithm

17. optimize system performance

18. remove old gstreamer plugins

19. fix bug "dynamic DPC can't take effect"

20. support the sensor F35

21. change GoP of streaming from 1 to 60 to reduce bit rate

22. fix bug "parameter TnrStrength0  of 3DNR might overflow"

23. support 4k streaming

24. new api CVI_ISP_GetPubAttr()


**Driver**

isp

1. Add VI data path for pico640 thermal sensor

2. Add debug dump info into /proc/vi

3. Add ISP CCF control for power saving

4. Fix ISP tuning and flow control issues for 4K tile and non-tile

mipi-tx

1. Fix dcs packet NG if dsi-lane changed

2. DTS to decide gpio used for panel reset/pwm/power

3. Fix audio pll accidentially closed on mipi_tx enabled

vip

1. display support i80

2. scaler support 4K

3. Fix ko can't be rmmod/insmod

cif

1. Add mipi-rx attribute to control the hs-settle time

2. Add TTL format of RX for 3S thermal sensor module

3. [Issue Fixed] MCLK1 PINMUX shall be configured

vcodec

1. Support H264/H265 VBR, dynamic clock gating and  multi-stream encoding.

2. Support JPEG CBR

storage

1. Support spinand Winbond W25N01GV 1Gbit/ Winbond W25M02GV 1Gbit/ GD5F2GQ5UExxH 3.3v 2Gbit.


**Tuning tool**

1. supports dual sensor

2. Y-Sharpen could be configured in more detail

3. add raw info to capture function

4. fix read raw file issue

5. apply gamma of raw image preview


## v1.1.0 ##
2020/6/9

**Git revision:**

    arm-trusted-firmware:
    5754daf33140d051516a971988909cee94d38cfb Merge "1. Add BL1 from rom_cv1835 2. Add cv1822"

    bm_bld:
    c502649e8a2cb070d5b06cdca76b883db90f6668 Merge "CV1882 FPGA Linux bringup"

    build:
    7a5645bb3458f060c7a844d284a788685c8ed69a fixed mantis issue -

    linux-linaro-stable:
    c194479646d24e6d351df4afd904b495a4c47515 Merge "fix(vip/isp): fix memory leak issue" into cv1835_v1.1.0

    middleware:
    cab61181c7c3ef27ec39cca4ad7dfea5f2159342 [venc][vc] disable log files

    ramdisk:
    cc2d7113430e792f64da8be8fb87dde76d0822b8 [cvidaemon] move cvidaemon to system partition (from rootfs)

    u-boot:
    0014104bb71f7d46c0a3bc9f5c1b3b1f9e2967c6 Refine bootlogo for reserved memory

    ive:
    656ab5417a9f25fd5e42e14bf696c39e9df335ad [ive] Use standard variable typedef instead

    ive/3rdparty/tracer:
    9dc45f3d304d3a89191d3ef7b514195dbd49e790 [cmake] Now tracer is a dynamic library

    opencv:
    70db6c9c2819618571f6ca5a2dbd90884b29908f fix 32_compileErr png_init_filter_functions_neon

    llvm-project:
    1893ef5dff98ebb8d3f9cb2005ef492d450ca0f5 fix python interpreter not read from system default

    llvm-project/llvm/projects/mlir:
    79f69b80f9e59a83d9a88b0924b77bfb5dd6d3c8 update cviruntime submodule

    cvibuilder:
    f2ec639672255d59d4db31c6ef920fdbbe27e786 add weight_map info and ssd fbs

    cvikernel:
    39455ae749cd77a528716150de6cdaf6352368d8 [RUNTIME] separate different header_magic

    cviruntime:
    01d185fcfec5ac49f01c6664c9ec31894cf19245 Merge "add copyright in header for release"

    flatbuffers:
    6da1cf79d90eb242e7da5318241d42279a3df3ba [rust] Add use declarations to Rust-generated bindings for imported FB definitions (#5645)

    cnpy:
    c065627c1a372bac87db156cf5cb6f436c5fab45 generate share lib


## v1.0.0 ##
2020/5/1

**Git revision:**

    arm-trusted-firmware:
    c6f242d30415d42b77b9a3df9305d71d08f0f6e8 Set eMMC/SD transfer mode to 50Mhz/4Bit

    bm_bld:
    072bcab081cf6e7e20b0073d7d2c1070efe61268 Update ddr settings for wevb_0004

    build:
    43032d7d081eff1c89b714e8e9c8e7d4e73b165f Add spinand matching string in build_rel

    linux-linaro-stable:
    df20e0eee6764d0e4c750f30e6b2dcf950990179 [Linux] Fixed HS200 tuning failure

    middleware:
    d17042d968fc9628f4c70d6fb1c174231b9834e4 Synchronize with sample_vi

    ramdisk:
    31b4f603f4434917b70afa1400eb3b0e9125574e Merge "[USB] Fix the error message when stopping the gadget."

    u-boot:
    8e4695298ddb51d4d9e419b15a5ad78e8298bfce  Bug Fixed   * (cmd/vo) Correct the format of cmd, startvl, as yuv420.

    ive:
    3dc6271010252b7c98860121ff6ea624fb6c141b [script] Fix formatting not searching all files

    ive/3rdparty/tracer:
    9dc45f3d304d3a89191d3ef7b514195dbd49e790 [cmake] Now tracer is a dynamic library

    opencv:
    013ee9f9d2c6496d53d7c2b9bc3d01476c274c6e fix cmake error with ccache on

    llvm-project:
    1893ef5dff98ebb8d3f9cb2005ef492d450ca0f5 fix python interpreter not read from system default

    llvm-project/llvm/projects/mlir:
    f13d0b5a49181799b3ebf5ee34f922451e05961e commit cviruntime to cv1835_v1.0.0

    cvibuilder:
    f2ec639672255d59d4db31c6ef920fdbbe27e786 add weight_map info and ssd fbs

    cvikernel:
    c52e9a64253cbbd129379ce8a1d96ae0083f7ed3 Add TPU HW configuration to bm1880v2_tpu_cfg.h

    cviruntime:
    85a8595a05a1b0eea5bc0164d365b3243aee997c rename API and add doc to cviruntime APIs

    flatbuffers:
    6da1cf79d90eb242e7da5318241d42279a3df3ba [rust] Add use declarations to Rust-generated bindings for imported FB definitions (#5645)

    cnpy:
    95d6748e99bae9eb7cad431574cf2173b51ff779 update makefile for zlib package path


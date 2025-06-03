#! /bin/bash
echo "Generate ./run_$1/targetRelocate.qel, ./run_$1/pl01.tb_mars3.bp on $1"

echo "targetLocation -import" > targetRelocate.qel

case $1 in
    ra1)
        #10.12.72.11, for multimedia
        echo "targetLocation -add myMBC0     MemBoardCable  sg_qd01_z2 0_T2"   >> targetRelocate.qel
        echo "targetAssign   -add myMBC      myMBC0"                           >> targetRelocate.qel
        echo "0-1" > sg_qd01_ser01.tb_mars3.bp
    ;;

    ra2)
        #10.12.72.13, for multimedia
        echo "targetLocation -add myMBC0     MemBoardCable  sg_qd01_z2 0_T3"   >> targetRelocate.qel
        echo "targetAssign   -add myMBC      myMBC0"                           >> targetRelocate.qel
        echo "2-3" > sg_qd01_ser01.tb_mars3.bp
    ;;

    ra3)
        #10.12.72.14, for SYS/uboot/kernel
        echo "targetLocation -add myMBC0     MemBoardCable  sg_qd01_z2 0_T4"   >> targetRelocate.qel
        echo "targetAssign   -add myMBC      myMBC0"                           >> targetRelocate.qel
        echo "4-5" > sg_qd01_ser01.tb_mars3.bp
    ;;

    ra4)
        # 10.12.72.12, for DDR/TPU
        echo "targetLocation -add myMBC0     MemBoardCable  sg_qd01_z2 0_T5"  >> targetRelocate.qel
        echo "targetAssign   -add myMBC      myMBC0"                           >> targetRelocate.qel
        echo "6-7" > sg_qd01_ser01.tb_mars3.bp
    ;;

    ra5)
        #10.12.72.16, for Hperi/Peri (flash, USB...)
        echo "targetLocation -add myMBC0     MemBoardCable  sg_qd01_z2 0_T6"         >> targetRelocate.qel
        echo "targetAssign   -add myMBC      myMBC0"                                    >> targetRelocate.qel
        echo "8-9" > sg_qd01_ser01.tb_mars3.bp
    ;;

    ra6)
        #10.12.72.15, still 2380
        echo "targetLocation -add myMBC0     MemBoardCable  sg_qd01_z2 0_T7"   >> targetRelocate.qel
        echo "targetAssign   -add myMBC      myMBC0"                           >> targetRelocate.qel
        echo "10-11" > sg_qd01_ser01.tb_mars3.bp
    ;;

    usb_host)
        #10.12.72.15, for for usb
        echo "targetLocation -add myMBC0     MemBoardCable  sg_qd01_z2 0_T6"         >> targetRelocate.qel
        echo "targetAssign   -add myMBC      myMBC0"                                    >> targetRelocate.qel
        echo "targetLocation -add usb3HostSB target_usbhost sg_qd01_z2 0_T37"        >> targetRelocate.qel
        echo "targetAssign   -add VR_HOST_SB usb3HostSB"                                >> targetRelocate.qel
        echo "10-11" > sg_qd01_ser01.tb_mars3.bp
    ;;

    usb_dev)
        #10.12.72.15, for for usb
        echo "targetLocation -add myMBC0     MemBoardCable  sg_qd01_z2 0_T6"         >> targetRelocate.qel
        echo "targetAssign   -add myMBC      myMBC0"                                    >> targetRelocate.qel
        echo "targetLocation -add usb3DevSB usb3Dev sg_qd01_z2 0_T40"                >> targetRelocate.qel
        echo "targetAssign   -add usb3d_sb usb3DevSB"                                   >> targetRelocate.qel
        echo "10-11" > sg_qd01_ser01.tb_mars3.bp
    ;;

    eth)
        #10.12.72.11, for for eth, the speedbridge is 0_T9 and connect to 0_T2
        echo "targetLocation -add myMBC0     MemBoardCable  sg_qd01_z2 0_T2"         >> targetRelocate.qel
        echo "targetAssign   -add myMBC      myMBC0"                                    >> targetRelocate.qel
        echo "targetLocation -add myTPOD1    HSESB_phy      sg_qd01_z2 0_T9"         >> targetRelocate.qel
        echo "targetAssign   -add HSESB_I1   myTPOD1"                                   >> targetRelocate.qel
        echo "0-1" > sg_qd01_ser01.tb_mars3.bp
    ;;

esac


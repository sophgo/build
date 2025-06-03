/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File Name: vc_drv_uapi.h
 * Description:
 */

#ifndef __VC_UAPI_H__
#define __VC_UAPI_H__

#include "osal_ioctl.h"

#define VC_DRV_ENCODER_DEV_NAME         "soph-vc-enc"
#define VC_DRV_DECODER_DEV_NAME         "soph-vc-dec"

#define VC_DRV_IOCTL_MAGIC              'V'
/* encoder ioctl */

#define DRV_VC_VENC_CREATE_CHN              _IOW(VC_DRV_IOCTL_MAGIC, 0, venc_chn_attr_s)
#define DRV_VC_VENC_DESTROY_CHN             _IO(VC_DRV_IOCTL_MAGIC, 1)
#define DRV_VC_VENC_RESET_CHN               _IO(VC_DRV_IOCTL_MAGIC, 2)
#define DRV_VC_VENC_START_RECV_FRAME        _IOW(VC_DRV_IOCTL_MAGIC, 3, venc_recv_pic_param_s)
#define DRV_VC_VENC_STOP_RECV_FRAME         _IO(VC_DRV_IOCTL_MAGIC, 4)
#define DRV_VC_VENC_QUERY_STATUS            _IOR(VC_DRV_IOCTL_MAGIC, 5, venc_chn_status_s)
#define DRV_VC_VENC_SET_CHN_ATTR            _IOW(VC_DRV_IOCTL_MAGIC, 6, venc_chn_attr_s)
#define DRV_VC_VENC_GET_CHN_ATTR            _IOR(VC_DRV_IOCTL_MAGIC, 7, venc_chn_attr_s)
#define DRV_VC_VENC_GET_STREAM              _IOR(VC_DRV_IOCTL_MAGIC, 8, venc_stream_ex_s)
#define DRV_VC_VENC_RELEASE_STREAM          _IOW(VC_DRV_IOCTL_MAGIC, 9, venc_stream_s)
#define DRV_VC_VENC_INSERT_USERDATA         _IOW(VC_DRV_IOCTL_MAGIC, 10, venc_user_data_s)
#define DRV_VC_VENC_SEND_FRAME              _IOW(VC_DRV_IOCTL_MAGIC, 11, video_frame_info_ex_s)
#define DRV_VC_VENC_SEND_FRAMEEX            _IOW(VC_DRV_IOCTL_MAGIC, 12, user_frame_info_ex_s)
#define DRV_VC_VENC_REQUEST_IDR             _IOW(VC_DRV_IOCTL_MAGIC, 13, unsigned char)
#define DRV_VC_VENC_SET_ROI_ATTR            _IOW(VC_DRV_IOCTL_MAGIC, 14, venc_roi_attr_s)
#define DRV_VC_VENC_GET_ROI_ATTR            _IOR(VC_DRV_IOCTL_MAGIC, 15, venc_roi_attr_s)
#define DRV_VC_VENC_SET_H264_TRANS          _IOW(VC_DRV_IOCTL_MAGIC, 16, venc_h264_trans_s)
#define DRV_VC_VENC_GET_H264_TRANS          _IOR(VC_DRV_IOCTL_MAGIC, 17, venc_h264_trans_s)
#define DRV_VC_VENC_SET_H264_ENTROPY        _IOW(VC_DRV_IOCTL_MAGIC, 18, venc_h264_entropy_s)
#define DRV_VC_VENC_GET_H264_ENTROPY        _IOR(VC_DRV_IOCTL_MAGIC, 19, venc_h264_entropy_s)
#define DRV_VC_VENC_SET_H264_VUI            _IOW(VC_DRV_IOCTL_MAGIC, 20, venc_h264_vui_s)
#define DRV_VC_VENC_GET_H264_VUI            _IOR(VC_DRV_IOCTL_MAGIC, 21, venc_h264_vui_s)
#define DRV_VC_VENC_SET_H265_VUI            _IOW(VC_DRV_IOCTL_MAGIC, 22, venc_h265_vui_s)
#define DRV_VC_VENC_GET_H265_VUI            _IOR(VC_DRV_IOCTL_MAGIC, 23, venc_h265_vui_s)
#define DRV_VC_VENC_SET_JPEG_PARAM          _IOW(VC_DRV_IOCTL_MAGIC, 24, venc_jpeg_param_s)
#define DRV_VC_VENC_GET_JPEG_PARAM          _IOR(VC_DRV_IOCTL_MAGIC, 25, venc_jpeg_param_s)
#define DRV_VC_VENC_GET_RC_PARAM            _IOR(VC_DRV_IOCTL_MAGIC, 26, venc_rc_param_s)
#define DRV_VC_VENC_SET_RC_PARAM            _IOW(VC_DRV_IOCTL_MAGIC, 27, venc_rc_param_s)
#define DRV_VC_VENC_SET_REF_PARAM           _IOW(VC_DRV_IOCTL_MAGIC, 28, venc_ref_param_s)
#define DRV_VC_VENC_GET_REF_PARAM           _IOR(VC_DRV_IOCTL_MAGIC, 29, venc_ref_param_s)
#define DRV_VC_VENC_SET_H265_TRANS          _IOW(VC_DRV_IOCTL_MAGIC, 30, venc_h265_trans_s)
#define DRV_VC_VENC_GET_H265_TRANS          _IOR(VC_DRV_IOCTL_MAGIC, 31, venc_h265_trans_s)
#define DRV_VC_VENC_SET_FRAMELOST_STRATEGY _IOW(VC_DRV_IOCTL_MAGIC, 32, venc_framelost_s)
#define DRV_VC_VENC_GET_FRAMELOST_STRATEGY _IOR(VC_DRV_IOCTL_MAGIC, 33, venc_framelost_s)
#define DRV_VC_VENC_SET_SUPERFRAME_STRATEGY _IOW(VC_DRV_IOCTL_MAGIC, 34, venc_superframe_cfg_s)
#define DRV_VC_VENC_GET_SUPERFRAME_STRATEGY _IOR(VC_DRV_IOCTL_MAGIC, 35, venc_superframe_cfg_s)
#define DRV_VC_VENC_SET_CHN_PARAM           _IOW(VC_DRV_IOCTL_MAGIC, 36, venc_chn_param_s)
#define DRV_VC_VENC_GET_CHN_PARAM           _IOR(VC_DRV_IOCTL_MAGIC, 37, venc_chn_param_s)
#define DRV_VC_VENC_SET_MOD_PARAM           _IOW(VC_DRV_IOCTL_MAGIC, 38, venc_param_mod_s)
#define DRV_VC_VENC_GET_MOD_PARAM           _IOR(VC_DRV_IOCTL_MAGIC, 39, venc_param_mod_s)
#define DRV_VC_VENC_ATTACH_VBPOOL           _IOW(VC_DRV_IOCTL_MAGIC, 40, venc_chn_pool_s)
#define DRV_VC_VENC_DETACH_VBPOOL           _IO(VC_DRV_IOCTL_MAGIC, 41)
#define DRV_VC_VENC_SET_CUPREDICTION        _IOW(VC_DRV_IOCTL_MAGIC, 42, venc_cu_prediction_s)
#define DRV_VC_VENC_GET_CUPREDICTION        _IOR(VC_DRV_IOCTL_MAGIC, 43, venc_cu_prediction_s)
#define DRV_VC_VENC_CALC_FRAME_PARAM        _IOW(VC_DRV_IOCTL_MAGIC, 44, venc_frame_param_s)
#define DRV_VC_VENC_SET_FRAME_PARAM         _IOW(VC_DRV_IOCTL_MAGIC, 45, venc_frame_param_s)
#define DRV_VC_VENC_GET_FRAME_PARAM         _IOR(VC_DRV_IOCTL_MAGIC, 46, venc_frame_param_s)
/* decoder ioctl */
#define DRV_VC_VDEC_CREATE_CHN              _IOW(VC_DRV_IOCTL_MAGIC, 47, vdec_chn_attr_s)
#define DRV_VC_VDEC_DESTROY_CHN             _IO(VC_DRV_IOCTL_MAGIC, 48)
#define DRV_VC_VDEC_GET_CHN_ATTR            _IOR(VC_DRV_IOCTL_MAGIC, 49, vdec_chn_attr_s)
#define DRV_VC_VDEC_SET_CHN_ATTR            _IOW(VC_DRV_IOCTL_MAGIC, 50, vdec_chn_attr_s)
#define DRV_VC_VDEC_START_RECV_STREAM       _IO(VC_DRV_IOCTL_MAGIC, 51)
#define DRV_VC_VDEC_STOP_RECV_STREAM        _IO(VC_DRV_IOCTL_MAGIC, 52)
#define DRV_VC_VDEC_QUERY_STATUS            _IOR(VC_DRV_IOCTL_MAGIC, 53, vdec_chn_status_s)
#define DRV_VC_VDEC_RESET_CHN               _IO(VC_DRV_IOCTL_MAGIC, 54)
#define DRV_VC_VDEC_SET_CHN_PARAM           _IOW(VC_DRV_IOCTL_MAGIC, 55, vdec_chn_param_s)
#define DRV_VC_VDEC_GET_CHN_PARAM           _IOR(VC_DRV_IOCTL_MAGIC, 56, vdec_chn_param_s)
#define DRV_VC_VDEC_SEND_STREAM             _IOW(VC_DRV_IOCTL_MAGIC, 57, vdec_stream_ex_s)
#define DRV_VC_VDEC_GET_FRAME               _IOR(VC_DRV_IOCTL_MAGIC, 58, video_frame_info_ex_s)
#define DRV_VC_VDEC_RELEASE_FRAME           _IOW(VC_DRV_IOCTL_MAGIC, 59, video_frame_info_s)
#define DRV_VC_VDEC_ATTACH_VBPOOL           _IOW(VC_DRV_IOCTL_MAGIC, 60, vdec_chn_pool_s)
#define DRV_VC_VDEC_DETACH_VBPOOL           _IO(VC_DRV_IOCTL_MAGIC, 61)
#define DRV_VC_VDEC_SET_MOD_PARAM           _IOW(VC_DRV_IOCTL_MAGIC, 62, vdec_mod_param_s)
#define DRV_VC_VDEC_GET_MOD_PARAM           _IOR(VC_DRV_IOCTL_MAGIC, 63, vdec_mod_param_s)
#define DRV_VC_DECODE_H265_TEST             _IO(VC_DRV_IOCTL_MAGIC, 64)
#define DRV_VC_DECODE_H264_TEST             _IO(VC_DRV_IOCTL_MAGIC, 65)
#define DRV_VC_ENCODE_MAIN_TEST             _IO(VC_DRV_IOCTL_MAGIC, 66)
#define DRV_VC_ENC_DEC_JPEG_TEST            _IO(VC_DRV_IOCTL_MAGIC, 67)

/* encoder slice split */
#define DRV_VC_VENC_SET_H264_SLICE_SPLIT    _IOW(VC_DRV_IOCTL_MAGIC, 68, venc_h264_slice_split_s)
#define DRV_VC_VENC_GET_H264_SLICE_SPLIT    _IOR(VC_DRV_IOCTL_MAGIC, 69, venc_h264_slice_split_s)
#define DRV_VC_VENC_SET_H265_SLICE_SPLIT    _IOW(VC_DRV_IOCTL_MAGIC, 70, venc_h265_slice_split_s)
#define DRV_VC_VENC_GET_H265_SLICE_SPLIT    _IOR(VC_DRV_IOCTL_MAGIC, 71, venc_h265_slice_split_s)
/* encoder ioctl */
#define DRV_VC_VENC_GET_H264_DBLK           _IOR(VC_DRV_IOCTL_MAGIC, 72, venc_h264_dblk_s)
#define DRV_VC_VENC_SET_H264_DBLK           _IOW(VC_DRV_IOCTL_MAGIC, 73, venc_h264_dblk_s)
#define DRV_VC_VENC_GET_H265_DBLK           _IOR(VC_DRV_IOCTL_MAGIC, 74, venc_h265_dblk_s)
#define DRV_VC_VENC_SET_H265_DBLK           _IOW(VC_DRV_IOCTL_MAGIC, 75, venc_h265_dblk_s)

#define DRV_VC_VENC_SET_H264_INTRA_PRED     _IOW(VC_DRV_IOCTL_MAGIC, 76, venc_h264_intra_pred_s)
#define DRV_VC_VENC_GET_H264_INTRA_PRED     _IOR(VC_DRV_IOCTL_MAGIC, 77, venc_h264_intra_pred_s)
#define DRV_VC_VENC_ENC_JPEG_TEST           _IO(VC_DRV_IOCTL_MAGIC, 78)
#define DRV_VC_VDEC_DEC_JPEG_TEST           _IO(VC_DRV_IOCTL_MAGIC, 79)
#define DRV_VC_VDEC_FRAME_ADD_USER          _IOW(VC_DRV_IOCTL_MAGIC, 80, video_frame_info_s)
#define DRV_VC_VENC_SET_CUSTOM_MAP          _IO(VC_DRV_IOCTL_MAGIC, 81)
#define DRV_VC_VENC_GET_INTINAL_INFO        _IO(VC_DRV_IOCTL_MAGIC, 82)
#define DRV_VC_VENC_SET_H265_SAO            _IOW(VC_DRV_IOCTL_MAGIC, 83, venc_h265_sao_s)
#define DRV_VC_VENC_GET_H265_SAO            _IOR(VC_DRV_IOCTL_MAGIC, 84, venc_h265_sao_s)
#define DRV_VC_VENC_GET_HEADER              _IO(VC_DRV_IOCTL_MAGIC, 85)
#define DRV_VC_VENC_GET_EXT_ADDR            _IO(VC_DRV_IOCTL_MAGIC, 86)

#define DRV_VC_VCODEC_SET_CHN               _IOW(VC_DRV_IOCTL_MAGIC, 100, int)
#define DRV_VC_VCODEC_GET_CHN               _IOR(VC_DRV_IOCTL_MAGIC, 101, int)

#define DRV_VC_VENC_SET_MJPEG_PARAM            _IOW(VC_DRV_IOCTL_MAGIC, 102, venc_mjpeg_param_s)
#define DRV_VC_VENC_GET_MJPEG_PARAM            _IOR(VC_DRV_IOCTL_MAGIC, 103, venc_mjpeg_param_s)
#define DRV_VC_VENC_ENABLE_IDR                 _IOW(VC_DRV_IOCTL_MAGIC, 104, unsigned char)
#define DRV_VC_VENC_SET_H265_PRED_UNIT         _IOW(VC_DRV_IOCTL_MAGIC, 105, venc_h265_pu_s)
#define DRV_VC_VENC_GET_H265_PRED_UNIT         _IOR(VC_DRV_IOCTL_MAGIC, 106, venc_h265_pu_s)
#define DRV_VC_VENC_ENABLE_SVC                 _IOW(VC_DRV_IOCTL_MAGIC, 107, unsigned char)
#define DRV_VC_VENC_SET_SVC_PARAM              _IOW(VC_DRV_IOCTL_MAGIC, 108, venc_svc_param_s)
#define DRV_VC_VENC_GET_SVC_PARAM              _IOR(VC_DRV_IOCTL_MAGIC, 109, venc_svc_param_s)
#define DRV_VC_VENC_SET_BACKHOE_HWCFG          _IO(VC_DRV_IOCTL_MAGIC, 114)
#define DRV_VC_VENC_GET_BACKHOE_HWCFG          _IO(VC_DRV_IOCTL_MAGIC, 115)

#endif /* __VC_UAPI_H__ */


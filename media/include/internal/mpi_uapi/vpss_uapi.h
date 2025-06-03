/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File Name: vpss_uapi.h
 * Description:
 */

#ifndef _U_VPSS_UAPI_H_
#define _U_VPSS_UAPI_H_

#include "cvi_comm_vpss.h"
#include "cvi_comm_gdc.h"
#include "cvi_comm_sys.h"
#include "base_uapi.h"

#ifdef __cplusplus
extern "C" {
#endif


struct vpss_grp_cfg {
	VPSS_GRP VpssGrp;
	VPSS_GRP_ATTR_S stGrpAttr;
};

struct vpss_grp_crop_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CROP_INFO_S stCropInfo;
};

struct vpss_grp_frame_cfg {
	VPSS_GRP VpssGrp;
	VIDEO_FRAME_INFO_S stVideoFrame;
};

struct vpss_snd_frm_cfg {
	__u8 VpssGrp;
	VIDEO_FRAME_INFO_S stVideoFrame;
	__s32 s32MilliSec;
};

struct vpss_chn_frm_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	VIDEO_FRAME_INFO_S stVideoFrame;
	int32_t s32MilliSec;
};

struct vpss_chn_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	VPSS_CHN_ATTR_S stChnAttr;
};

struct vpss_en_chn_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
};

struct vpss_chn_crop_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	VPSS_CROP_INFO_S stCropInfo;
};

struct vpss_chn_rot_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	ROTATION_E enRotation;
};

struct vpss_chn_ldc_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	ROTATION_E enRotation;
	VPSS_LDC_ATTR_S stLDCAttr;
	uint64_t meshHandle;
};

struct vpss_chn_align_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	uint32_t u32Align;
};

struct vpss_chn_yratio_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	uint32_t YRatio;
};

struct vpss_chn_coef_level_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	VPSS_SCALE_COEF_E enCoef;
};

struct vpss_chn_draw_rect_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	VPSS_DRAW_RECT_S stDrawRect;
};

struct vpss_chn_convert_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	VPSS_CONVERT_S stConvert;
};

/* prevent mw build error */
struct vpss_get_chn_frm_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	VIDEO_FRAME_INFO_S stFrameInfo;
	int32_t s32MilliSec;
};

// prevent mw build error
struct vpss_chn_wrap_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	VPSS_CHN_BUF_WRAP_S wrap;
};

struct vpss_grp_csc_cfg {
	VPSS_GRP VpssGrp;
	__s32 proc_amp[PROC_AMP_MAX];
	__u8 enable;
	__u16 coef[3][3];
	__u8 sub[3];
	__u8 add[3];
	__u8 scene;
	__u8 is_copy_upsample;
};

struct vpss_chn_csc_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	__u8 enable;
	__u16 coef[3][3];
	__u8 sub[3];
	__u8 add[3];
};

struct vpss_int_normalize {
	__u8 enable;
	__u16 sc_frac[3];
	__u8  sub[3];
	__u16 sub_frac[3];
	__u8 rounding;
};

struct vpss_vb_pool_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	__u32 hVbPool;
};

struct vpss_snap_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	__u32 frame_cnt;
};

struct vpss_bld_cfg {
	__u8 enable;
	__u8 fix_alpha;
	__u8 blend_y;
	__u8 y2r_enable;
	__u16 alpha_factor;
	__u16 alpha_stp;
	__u16 wd;
};

struct vpss_proc_amp_ctrl_cfg {
	PROC_AMP_E type;
	PROC_AMP_CTRL_S ctrl;
};

struct vpss_proc_amp_cfg {
	VPSS_GRP VpssGrp;
	int32_t proc_amp[PROC_AMP_MAX];
};

struct vpss_coverex_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	struct rgn_coverex_cfg cover_cfg;
};

struct vpss_mosaic_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	struct rgn_mosaic_cfg mosaic_cfg;
};

struct vpss_gop_cfg {
	VPSS_GRP VpssGrp;
	VPSS_CHN VpssChn;
	struct rgn_cfg rgn_cfg;
	uint32_t layer;
};

struct _vpss_stitch_cfg {
	uint32_t u32ChnNum;
	VPSS_STITCH_CHN_ATTR_S *pstInput;
	VPSS_STITCH_OUTPUT_ATTR_S stOutput;
	VIDEO_FRAME_INFO_S stVideoFrame;
};

/*for record ISP bindata secne*/
struct vpss_scene {
	VPSS_GRP VpssGrp;
	uint8_t scene;
};


/* Public */
#define VPSS_SET_MODE _IOW('S', 0x00, VPSS_MODE_S)
#define VPSS_GET_MODE _IOR('S', 0x01, VPSS_MODE_S)
#define VPSS_SET_MOD_PARAM _IOW('S', 0x02, VPSS_MOD_PARAM_S)
#define VPSS_GET_MOD_PARAM _IOR('S', 0x03, VPSS_MOD_PARAM_S)

#define VPSS_GET_AVAIL_GROUP _IOR('S', 0x10, VPSS_GRP)
#define VPSS_CREATE_GROUP _IOW('S', 0x11, struct vpss_grp_cfg)
#define VPSS_DESTROY_GROUP _IOW('S', 0x12, VPSS_GRP)
#define VPSS_START_GROUP _IOW('S', 0x13, VPSS_GRP)
#define VPSS_STOP_GROUP _IOW('S', 0x14, VPSS_GRP)
#define VPSS_RESET_GROUP _IOW('S', 0x15, VPSS_GRP)
#define VPSS_SET_GRP_ATTR _IOW('S', 0x16, struct vpss_grp_cfg)
#define VPSS_GET_GRP_ATTR _IOWR('S', 0x17, struct vpss_grp_cfg)
#define VPSS_SET_GRP_CROP _IOW('S', 0x18, struct vpss_grp_crop_cfg)
#define VPSS_GET_GRP_CROP _IOWR('S', 0x19, struct vpss_grp_crop_cfg)
#define VPSS_GET_GRP_FRAME _IOWR('S', 0x1a, struct vpss_grp_frame_cfg)
#define VPSS_SET_RELEASE_GRP_FRAME _IOW('S', 0x1b, struct vpss_grp_frame_cfg)
#define VPSS_SEND_FRAME _IOW('S', 0x1c, struct vpss_snd_frm_cfg)

#define VPSS_SEND_CHN_FRAME _IOW('S', 0x20, struct vpss_chn_frm_cfg)
#define VPSS_SET_CHN_ATTR _IOW('S', 0x21, struct vpss_chn_cfg)
#define VPSS_GET_CHN_ATTR _IOWR('S', 0x22, struct vpss_chn_cfg)
#define VPSS_ENABLE_CHN _IOW('S', 0x23, struct vpss_en_chn_cfg)
#define VPSS_DISABLE_CHN _IOW('S', 0x24, struct vpss_en_chn_cfg)
#define VPSS_SET_CHN_CROP _IOW('S', 0x25, struct vpss_chn_crop_cfg)
#define VPSS_GET_CHN_CROP _IOWR('S', 0x26, struct vpss_chn_crop_cfg)
#define VPSS_SET_CHN_ROTATION _IOW('S', 0x27, struct vpss_chn_rot_cfg)
#define VPSS_GET_CHN_ROTATION _IOWR('S', 0x28, struct vpss_chn_rot_cfg)
#define VPSS_SET_CHN_LDC _IOW('S', 0x29, struct vpss_chn_ldc_cfg)
#define VPSS_GET_CHN_LDC _IOWR('S', 0x2a, struct vpss_chn_ldc_cfg)
#define VPSS_GET_CHN_FRAME _IOWR('S', 0x2b, struct vpss_chn_frm_cfg)
#define VPSS_RELEASE_CHN_FRAME _IOW('S', 0x2c, struct vpss_chn_frm_cfg)
#define VPSS_SET_CHN_ALIGN _IOW('S', 0x2d, struct vpss_chn_align_cfg)
#define VPSS_GET_CHN_ALIGN _IOWR('S', 0x2e, struct vpss_chn_align_cfg)
#define VPSS_SET_CHN_YRATIO _IOW('S', 0x2f, struct vpss_chn_yratio_cfg)
#define VPSS_GET_CHN_YRATIO _IOWR('S', 0x30, struct vpss_chn_yratio_cfg)
#define VPSS_SET_CHN_SCALE_COEFF_LEVEL _IOW('S', 0x31, struct vpss_chn_coef_level_cfg)
#define VPSS_GET_CHN_SCALE_COEFF_LEVEL _IOWR('S', 0x32, struct vpss_chn_coef_level_cfg)
#define VPSS_SHOW_CHN _IOW('S', 0x33, struct vpss_en_chn_cfg)
#define VPSS_HIDE_CHN _IOW('S', 0x34, struct vpss_en_chn_cfg)
#define VPSS_SET_CHN_DRAW_RECT _IOW('S', 0x35, struct vpss_chn_draw_rect_cfg)
#define VPSS_GET_CHN_DRAW_RECT _IOWR('S', 0x36, struct vpss_chn_draw_rect_cfg)
#define VPSS_SET_CHN_CONVERT _IOW('S', 0x37, struct vpss_chn_convert_cfg)
#define VPSS_GET_CHN_CONVERT _IOWR('S', 0x38, struct vpss_chn_convert_cfg)
#define VPSS_ATTACH_VB_POOL _IOW('S', 0x39, struct vpss_vb_pool_cfg)
#define VPSS_DETACH_VB_POOL _IOW('S', 0x40, struct vpss_vb_pool_cfg)
#define VPSS_TRIGGER_SNAP_FRAME _IOW('S', 0x41, struct vpss_snap_cfg)
#define VPSS_SET_COVEREX_CFG _IOW('S', 0x42, struct vpss_coverex_cfg)
#define VPSS_SET_MOSAIC_CFG _IOW('S', 0x43, struct vpss_mosaic_cfg)
#define VPSS_SET_GOP_CFG _IOW('S', 0x44, struct vpss_gop_cfg)
#define VPSS_STITCH _IOWR('S', 0x45, struct _vpss_stitch_cfg)
#define VPSS_SET_CHN_WRAP _IOW('S', 0x48, struct vpss_chn_wrap_cfg)
#define VPSS_GET_CHN_WRAP _IOWR('S', 0x49, struct vpss_chn_wrap_cfg)

/* Internal use */
#define VPSS_SET_GRP_CSC_CFG _IOW('S', 0x70, struct vpss_grp_csc_cfg)
#define VPSS_SET_BLD_CFG _IOW('S', 0x71, struct vpss_bld_cfg)
#define VPSS_GET_AMP_CTRL _IOWR('S', 0x72, struct vpss_proc_amp_ctrl_cfg)
#define VPSS_GET_AMP_CFG _IOWR('S', 0x73, struct vpss_proc_amp_cfg)
#define VPSS_GET_ALL_AMP _IOWR('S', 0x74, VPSS_ALL_PROC_AMP_S)
#define VPSS_GET_SCENE _IOWR('S', 0xd5, struct vpss_scene)
#define VPSS_SET_CHN_CSC_CFG _IOW('S', 0x76, struct vpss_chn_csc_cfg)


#ifdef __cplusplus
}
#endif

#endif /* _U_VPSS_UAPI_H_ */

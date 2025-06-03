/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File Name: vpss_uapi.h
 * Description:
 */

#ifndef _U_VPSS_UAPI_H_
#define _U_VPSS_UAPI_H_

#include "comm_vpss.h"
#include "comm_gdc.h"
#include "comm_sys.h"
#include "base_uapi.h"

#ifdef __cplusplus
extern "C" {
#endif


struct vpss_grp_cfg {
	vpss_grp vpss_grp;
	vpss_grp_attr_s grp_attr;
};

struct vpss_grp_crop_cfg {
	vpss_grp vpss_grp;
	vpss_crop_info_s crop_info;
};

struct vpss_grp_frame_cfg {
	vpss_grp vpss_grp;
	video_frame_info_s video_frame;
};

struct vpss_snd_frm_cfg {
	__u8 vpss_grp;
	video_frame_info_s video_frame;
	__s32 milli_sec;
};

struct vpss_chn_frm_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	video_frame_info_s video_frame;
	int milli_sec;
};

struct vpss_chn_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	vpss_chn_attr_s chn_attr;
};

struct vpss_en_chn_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
};

struct vpss_chn_crop_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	vpss_crop_info_s crop_info;
};

struct vpss_chn_rot_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	rotation_e rotation;
};

struct vpss_chn_ldc_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	rotation_e rotation;
	vpss_ldc_attr_s ldc_attr;
	uint64_t mesh_handle;
};

struct vpss_chn_align_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	uint32_t align;
};

struct vpss_chn_yratio_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	uint32_t y_ratio;
};

struct vpss_chn_coef_level_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	vpss_scale_coef_e coef;
};

struct vpss_chn_draw_rect_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	vpss_draw_rect_s draw_rect;
};

struct vpss_chn_convert_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	vpss_convert_s convert;
};

/* prevent mw build error */
struct vpss_get_chn_frm_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	video_frame_info_s frame_info;
	int milli_sec;
};

// prevent mw build error
struct vpss_chn_wrap_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	vpss_chn_buf_wrap_s wrap;
};

struct vpss_grp_csc_cfg {
	vpss_grp vpss_grp;
	int proc_amp[PROC_AMP_MAX];
	__u8 enable;
	__u16 coef[3][3];
	__u8 sub[3];
	__u8 add[3];
	__u8 scene;
	__u8 is_copy_upsample;
};

struct vpss_chn_csc_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
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
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	__u32 vb_pool;
};

struct vpss_snap_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
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
	proc_amp_e type;
	proc_amp_ctrl_s ctrl;
};

struct vpss_proc_amp_cfg {
	vpss_grp vpss_grp;
	int proc_amp[PROC_AMP_MAX];
};

struct vpss_coverex_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	struct rgn_coverex_cfg rgn_coverex_cfg;
};

struct vpss_mosaic_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	struct rgn_mosaic_cfg rgn_mosaic_cfg;
};

struct vpss_gop_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	struct rgn_cfg rgn_cfg;
	unsigned int layer;
};

struct _vpss_stitch_cfg {
	unsigned int chn_num;
	vpss_stitch_chn_attr_s *input;
	vpss_stitch_output_attr_s output;
	video_frame_info_s video_frame;
};

/*for record ISP bindata secne*/
struct vpss_scene {
	vpss_grp vpss_grp;
	unsigned char scene;
};


/* Public */
#define VPSS_SET_MODE _IOW('S', 0x00, vpss_mode_s)
#define VPSS_GET_MODE _IOR('S', 0x01, vpss_mode_s)
#define VPSS_SET_MOD_PARAM _IOW('S', 0x02, vpss_mod_param_s)
#define VPSS_GET_MOD_PARAM _IOR('S', 0x03, vpss_mod_param_s)

#define VPSS_GET_AVAIL_GROUP _IOR('S', 0x10, vpss_grp)
#define VPSS_CREATE_GROUP _IOW('S', 0x11, struct vpss_grp_cfg)
#define VPSS_DESTROY_GROUP _IOW('S', 0x12, vpss_grp)
#define VPSS_START_GROUP _IOW('S', 0x13, vpss_grp)
#define VPSS_STOP_GROUP _IOW('S', 0x14, vpss_grp)
#define VPSS_RESET_GROUP _IOW('S', 0x15, vpss_grp)
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
#define VPSS_GET_ALL_AMP _IOWR('S', 0x74, vpss_all_proc_amp_s)
#define VPSS_GET_SCENE _IOWR('S', 0xd5, struct vpss_scene)
#define VPSS_SET_CHN_CSC_CFG _IOW('S', 0x76, struct vpss_chn_csc_cfg)

#ifdef __cplusplus
}
#endif

#endif /* _U_VPSS_UAPI_H_ */

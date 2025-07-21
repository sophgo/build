/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File name: ldc_uapi.h
 * Description:
 */

#ifndef _U_LDC_UAPI_H_
#define _U_LDC_UAPI_H_

#include "osal.h"
#include "comm_gdc.h"
#include "comm_vi.h"
#include "comm_vpss.h"

#ifndef __linux__
#include "osal_ioctl.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif


enum cvi_ldc_op {
	CVI_LDC_OP_NONE,
	CVI_LDC_OP_XY_FLIP,
	CVI_LDC_OP_ROT_90,
	CVI_LDC_OP_ROT_270,
	CVI_LDC_OP_LDC,
	CVI_LDC_OP_MAX,
};

struct cvi_ldc_buffer {
	unsigned char pixel_fmt; // 0: Y only, 1: NV21
	unsigned char rot;
	unsigned short bgcolor; // data outside start/end if used in operation

	unsigned short src_width; // src width, including padding
	unsigned short src_height; // src height, including padding

	unsigned int src_y_base;
	unsigned int src_c_base;
	unsigned int dst_y_base;
	unsigned int dst_c_base;

	unsigned int map_base;
};

struct cvi_ldc_rot {
	unsigned long long handle;

	void *usage_param;
	void *vb_in;
	unsigned int pix_format;
	unsigned long long mesh_addr;
	unsigned char sync_io;
	void *cb;
	void *cb_param;
	unsigned int cb_param_size;
	unsigned int mod_id;
	unsigned int rotation;
};

struct gdc_handle_data {
	unsigned long long handle;
};

/*
 * img_in: Input picture
 * img_out: Output picture
 * private_data[4]: RW; Private data of task
 * reserved: RW; Debug information,state of current picture
 */
struct gdc_task_attr {
	unsigned long long handle;

	video_frame_info_s img_in;
	video_frame_info_s img_out;
	unsigned long long private_data[4];
	unsigned int rotation;
	unsigned long long reserved;
	ldc_attr_s ldc_attr;
	unsigned long long mesh_handle;
};

struct gdc_identity_attr {
	unsigned long long handle;
	gdc_identity_attr_s attr;
};

struct gdc_chn_frm_cfg {
	video_frame_info_s video_frame;
	int milli_sec;
	struct gdc_identity_attr identity;
};

struct ldc_vb_pool_cfg {
	mmf_chn_s mmf_chn;
	unsigned int vb_pool;
};

struct ldc_vi_chn_attr {
	vi_pipe vi_pipe;
	vi_chn vi_chn;
	size_s size;
};

struct ldc_vpss_chn_attr {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	size_s size;
};

struct ldc_internal_chn_attr {
	mod_id_e mod;
	union {
		struct ldc_vi_chn_attr vi_chn_attr;
		struct ldc_vpss_chn_attr vpss_chn_attr;
	};
};

struct ldc_vi_chn_ldc_cfg {
	vi_pipe vi_pipe;
	vi_pipe vi_chn;
	rotation_e rotation;
	vi_ldc_attr_s ldc_attr;
	uint64_t mesh_handle;
};

struct ldc_vpss_chn_ldc_cfg {
	vpss_grp vpss_grp;
	vpss_chn vpss_chn;
	rotation_e rotation;
	vpss_ldc_attr_s ldc_attr;
	uint64_t mesh_handle;
};

struct ldc_internal_chn_ldc_cfg {
	mod_id_e mod;
	union {
		struct ldc_vi_chn_ldc_cfg vi_cfg;
		struct ldc_vpss_chn_ldc_cfg vpss_cfg;
	};
};

#define LDC_BEGIN_JOB _IOWR('L', 0x00, struct gdc_handle_data)
#define LDC_END_JOB _IOW('L', 0x01, struct gdc_handle_data)
#define LDC_CANCEL_JOB _IOW('L', 0x02, unsigned long long)
#define LDC_ADD_ROT_TASK _IOW('L', 0x03, struct gdc_task_attr)
#define LDC_ADD_LDC_TASK _IOW('L', 0x04, struct gdc_task_attr)
#define LDC_INIT _IO('L', 0x05)
#define LDC_DEINIT _IO('L', 0x06)
#define LDC_SET_JOB_IDENTITY _IOW('L', 0x07, struct gdc_identity_attr)
#define LDC_GET_WORK_JOB _IOR('L', 0x08, struct gdc_handle_data)
#define LDC_GET_CHN_FRM _IOWR('L', 0x09, struct gdc_chn_frm_cfg)

#define LDC_ATTACH_VB_POOL _IOW('L', 0x0c, struct ldc_vb_pool_cfg)
#define LDC_DETACH_VB_POOL _IOW('L', 0x0d, struct ldc_vb_pool_cfg)
#define LDC_SUSPEND _IO('L', 0x0e)
#define LDC_RESUME _IO('L', 0x0f)
#define LDC_GET_INTER_CHN_ATTR _IOWR('L', 0x10, struct ldc_internal_chn_attr)
#define CVI_LDC_SET_CHN_LDC_CFG _IOWR('L', 0x11, struct ldc_internal_chn_ldc_cfg)

#ifdef __cplusplus
}
#endif

#endif /* _U_LDC_UAPI_H_ */

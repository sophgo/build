/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File Name: ldc_uapi.h
 * Description:
 */

#ifndef _U_TDE_UAPI_H_
#define _U_TDE_UAPI_H_

#include <cvi_comm_tde.h>

#ifdef __cplusplus
extern "C" {
#endif


struct tde_begin_job_cfg {
	TDE_HANDLE handle;
};

struct tde_end_job_cfg {
	TDE_HANDLE handle;
	CVI_BOOL bSync;
	CVI_BOOL bBlock;
	CVI_U32 u32TimeOut;
};

struct tde_cancel_job_cfg {
	TDE_HANDLE handle;
};

struct tde_rotate_cfg {
	TDE_HANDLE handle;
	TDE_SURFACE_S src;
	TDE_SURFACE_S dst;
	TDE_ROTATE_ANGLE_E angle;
};

struct tde_draw_line_cfg {
	TDE_HANDLE handle;
	TDE_SURFACE_S src;
	TDE_SURFACE_S dst;
	TDE_LINE_S line;
};

struct tde_quick_copy_cfg {
	TDE_HANDLE handle;
	TDE_SURFACE_S src;
	TDE_SURFACE_S dst;
};

/* Public */
#define CVI_TDE_BEJIN_JOB _IOR('T', 0x00, struct tde_begin_job_cfg)
#define CVI_TDE_END_JOB _IOW('T', 0x01, struct tde_end_job_cfg)
#define CVI_TDE_WAIT_ALL_DONE _IO('T', 0x02)
#define CVI_TDE_CANCEL_JOB _IOW('T', 0x03, struct tde_cancel_job_cfg)
#define CVI_TDE_ROTATE _IOW('T', 0x04, struct tde_rotate_cfg)
#define CVI_TDE_DRAW_LINE _IOW('T', 0x05, struct tde_draw_line_cfg)
#define CVI_TDE_QUICK_COPY _IOW('T', 0x06, struct tde_quick_copy_cfg)

#ifdef __cplusplus
}
#endif

#endif /* _U_TDE_UAPI_H_ */

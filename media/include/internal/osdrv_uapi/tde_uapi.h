/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File Name: tde_uapi.h
 * Description:
 */

#ifndef _U_TDE_UAPI_H_
#define _U_TDE_UAPI_H_

#include <comm_sys.h>
#include <defines.h>
#include <comm_tde.h>

#ifdef __cplusplus
extern "C" {
#endif


struct tde_begin_job_cfg {
	tde_handle handle;
};

struct tde_end_job_cfg {
	tde_handle handle;
	unsigned char is_sync;
	unsigned char is_block;
	unsigned int timeout;
};

struct tde_cancel_job_cfg {
	tde_handle handle;
};

struct tde_rotate_cfg {
	tde_handle handle;
	tde_surface_s src;
	tde_surface_s dst;
	tde_rotate_angle_e angle;
};

struct tde_draw_line_cfg {
	tde_handle handle;
	tde_surface_s src;
	tde_surface_s dst;
	tde_line_s line;
};

struct tde_quick_copy_cfg {
	tde_handle handle;
	tde_surface_s src;
	tde_surface_s dst;
};

/* Public */
#define TDE_BEJIN_JOB _IOR('T', 0x00, struct tde_begin_job_cfg)
#define TDE_END_JOB _IOW('T', 0x01, struct tde_end_job_cfg)
#define TDE_WAIT_ALL_DONE _IO('T', 0x02)
#define TDE_CANCEL_JOB _IOW('T', 0x03, struct tde_cancel_job_cfg)
#define TDE_ROTATE _IOW('T', 0x04, struct tde_rotate_cfg)
#define TDE_DRAW_LINE _IOW('T', 0x05, struct tde_draw_line_cfg)
#define TDE_QUICK_COPY _IOW('T', 0x06, struct tde_quick_copy_cfg)


#ifdef __cplusplus
}
#endif

#endif /* _U_TDE_UAPI_H_ */

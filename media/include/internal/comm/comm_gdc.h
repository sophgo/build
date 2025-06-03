/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File name: include/comm_gdc.h
 * Description:
 *   Common gdc definitions.
 */

#ifndef __COMM_GDC_H__
#define __COMM_GDC_H__

#ifdef __cplusplus
#if __cplusplus
extern "C" {
#endif
#endif /* __cplusplus */

#include "common.h"
#include "comm_video.h"


#define FISHEYE_MAX_REGION_NUM 4
#define AFFINE_MAX_REGION_NUM 32


#ifdef __arm__
typedef int GDC_HANDLE;
#else
typedef long long GDC_HANDLE;
#endif

/*
 * stimgin: input picture
 * stimgout: output picture
 * au64privatedata[4]: rw; private data of task
 * reserved: rw; debug information,state of current picture
 */
typedef struct _gdc_task_attr_s {
	video_frame_info_s img_in;
	video_frame_info_s img_out;
	unsigned long long privatedata[4];
	unsigned long long reserved;
	char name[32];
} gdc_task_attr_s;

typedef struct _point2f_s {
	float x;
	float y;
} point2f_s;

typedef struct _vi_mesh_attr_s {
	vi_pipe pipe;
	vi_chn chn;
} vi_mesh_attr_s;

typedef struct _vpss_mesh_attr_s {
	vpss_grp grp;
	vpss_chn chn;
} vpss_mesh_attr_s;

typedef struct _mesh_dump_attr_s {
	char in_file_name[128];
	mod_id_e mod_id;
	union {
		vi_mesh_attr_s vi_mesh_attr;
		vpss_mesh_attr_s vpss_mesh_attr;
	};
} mesh_dump_attr_s;

typedef struct _gdc_identity_attr_s {
	char name[32];
	mod_id_e mod_id;
	unsigned int id;
	unsigned char sync_io;
} gdc_identity_attr_s;

#ifdef __cplusplus
#if __cplusplus
}
#endif
#endif /* __cplusplus */

#endif /* __CVI_COMM_GDC_H__ */

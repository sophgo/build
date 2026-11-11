/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File Name: include/comm_vb.h
 * Description:
 *   The common data type defination for VB module.
 */

#ifndef __COMM_VB_H__
#define __COMM_VB_H__

#include "defines.h"
#include "comm_errno.h"

#ifdef __cplusplus
#if __cplusplus
extern "C" {
#endif
#endif /* End of #ifdef __cplusplus */

#define VB_INVALID_POOLID (-1U)
#define VB_INVALID_HANDLE (-1U)
#define VB_STATIC_POOLID (-2U)
#define VB_EXTERNAL_POOLID (-3U)

#define VB_MAX_COMM_POOLS       (16)
#define VB_POOL_MAX_BLK         (128)

/* user ID for VB */
#define VB_MAX_USER VB_UID_BUTT

typedef enum _VB_UID_E {
	VB_UID_VI = 0,
	VB_UID_VO = 1,
	VB_UID_VPSS = 2,
	VB_UID_VENC = 3,
	VB_UID_VDEC = 4,
	VB_UID_H265E = 5,
	VB_UID_H264E = 6,
	VB_UID_JPEGE = 7,
	VB_UID_H264D = 8,
	VB_UID_JPEGD = 9,
	VB_UID_DIS = 10,
	VB_UID_USER = 11,
	VB_UID_AI = 12,
	VB_UID_AENC = 13,
	VB_UID_RC = 14,
	VB_UID_VFMW = 15,
	VB_UID_GDC = 16,
	VB_UID_BUTT,

} VB_UID_E;

/* Generall common pool use this owner id, module common pool use VB_UID as owner id */
#define POOL_OWNER_COMMON -1

/* Private pool use this owner id */
#define POOL_OWNER_PRIVATE -2

typedef unsigned int vb_pool;
typedef uint64_t vb_blk;

/*
 * VB_REMAP_MODE_NONE: no remap.
 * VB_REMAP_MODE_NOCACHE: no cache remap.
 * VB_REMAP_MODE_CACHED: cache remap. flush cache is needed.
 */
typedef enum _vb_remap_mode_e {
	VB_REMAP_MODE_NONE = 0,
	VB_REMAP_MODE_NOCACHE = 1,
	VB_REMAP_MODE_CACHED = 2,
	VB_REMAP_MODE_BUTT
} vb_remap_mode_e;

/*
 * blk_size: size of blk in the pool.
 * u32BlkCnt: number of blk in the pool.
 * enRemapMode: remap mode.
 */
#define MAX_VB_POOL_NAME_LEN (32)
typedef struct _vb_pool_config_s {
	unsigned int blk_size;
	unsigned int blk_cnt;
	vb_remap_mode_e remap_mode;
	char name[MAX_VB_POOL_NAME_LEN];
} vb_pool_config_s;

/*
 * phy_addr: Y/U/V base addr.
 */
typedef struct _vb_user_block_s {
	uint64_t phy_addr[3];
} vb_user_block_s;

/*
 * blk_cnt: number of blk in the pool.
 * user_blk: block addr.
 */
typedef struct _vb_pool_config_ex_s {
	unsigned int blk_cnt;
	vb_user_block_s user_blk[VB_POOL_MAX_BLK];
} vb_pool_config_ex_s;
/*
 * max_pool_cnt: number of common pools used.
 * comm_pool: pool cfg for the pools.
 */
typedef struct _vb_config_s {
	unsigned int max_pool_cnt;
	vb_pool_config_s comm_pool[VB_MAX_COMM_POOLS];
} vb_config_s;



#ifdef __cplusplus
#if __cplusplus
}
#endif
#endif /* __cplusplus */

#endif /* __COMM_VB_H_ */

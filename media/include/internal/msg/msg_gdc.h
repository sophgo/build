#ifndef __MSG_GDC_H__
#define __MSG_GDC_H__

#include "osal.h"
#include "cvi_comm_gdc.h"
#include "cvi_comm_vi.h"
#include "cvi_comm_vpss.h"
#include "msg.h"

typedef enum tagMSG_GDC_CMD_E {
	MSG_CMD_GDC_BEGAIN_JOB = 0,
	MSG_CMD_GDC_END_JOB,
	MSG_CMD_GDC_CANCEL_JOB,
	MSG_CMD_GDC_ADD_ROT_TASK,
	MSG_CMD_GDC_ADD_LDC_TASK,
	MSG_CMD_GDC_SUSPEND,
	MSG_CMD_GDC_RESUME,
	MSG_CMD_GDC_SET_JOB_IDENTITY,
	MSG_CMD_GDC_GET_CHN_FRAME,
	MSG_CMD_GDC_ATTACH_VB_POOL,
	MSG_CMD_GDC_DETACH_VB_POOL,
	MSG_CMD_GDC_GET_WORK_JOB,
} MSG_GDC_CMD_E;

struct gdc_identity_attr {
	__u64 handle;
	GDC_IDENTITY_ATTR_S attr;
};

struct gdc_task_attr {
	__u64 handle;

	struct _VIDEO_FRAME_INFO_S stImgIn;
	struct _VIDEO_FRAME_INFO_S stImgOut;
	__u64 au64privateData[4];
	__u32 enRotation;
	__u64 reserved;
	LDC_ATTR_S stLDCAttr;
	CVI_U64 meshHandle;
};

struct gdc_chn_frm_cfg {
	VIDEO_FRAME_INFO_S VideoFrame;
	CVI_S32 MilliSec;
	struct gdc_identity_attr identity;
};

struct ldc_vb_pool_cfg {
	MMF_CHN_S Chn;
	__u32 VbPool;
};
#endif

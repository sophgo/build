#ifndef __U_VI_UAPI_H__
#define __U_VI_UAPI_H__

#ifdef __cplusplus
	extern "C" {
#endif

#ifdef __KERNEL__
#include <linux/time_types.h>
#endif
#include "cvi_comm_vi.h"
#include "osal_ioctl.h"

#define VI_IOC_MAGIC		'V'
#define VI_IOC_BASE		0x20

#define VI_IOC_G_CTRL		_IOWR(VI_IOC_MAGIC, VI_IOC_BASE, struct vi_ext_control)
#define VI_IOC_S_CTRL		_IOWR(VI_IOC_MAGIC, VI_IOC_BASE + 1, struct vi_ext_control)
#define VI_IOC_SDK_CTRL		_IOWR(VI_IOC_MAGIC, VI_IOC_BASE + 2, struct vi_ext_control)

enum VI_IOCTL {
	VI_IOCTL_HDR,
	VI_IOCTL_STS_MEM,
	VI_IOCTL_STS_GET,
	VI_IOCTL_STS_PUT,
	VI_IOCTL_POST_STS_GET,
	VI_IOCTL_POST_STS_PUT,
	VI_IOCTL_GET_LSC_PHY_BUF,
	VI_IOCTL_GET_CLUT_PHY_BUF,
	VI_IOCTL_GET_TUN_ADDR,
	VI_IOCTL_SET_SNR_INFO,
	VI_IOCTL_SET_SNR_CFG_NODE,
	VI_IOCTL_GET_PIPE_DUMP,
	VI_IOCTL_PUT_PIPE_DUMP,
	VI_IOCTL_HDR_DETAIL_EN,
	VI_IOCTL_GET_SC_ONLINE,
	VI_IOCTL_GET_SCENE_INFO,
	VI_IOCTL_DQEVENT,
	VI_IOCTL_START_STREAMING,
	VI_IOCTL_STOP_STREAMING,
	VI_IOCTL_SET_SLICE_BUF_EN,
	VI_IOCTL_GET_CLUT_TBL_IDX,
	VI_IOCTL_SET_PROC_CONTENT,
	VI_IOCTL_AI_ISP_CFG,
	VI_IOCTL_GET_AI_ISP_RAW,
	VI_IOCTL_PUT_AI_ISP_RAW,
	VI_IOCTL_MAX,
};

enum VI_SDK_CTRL {
	VI_SDK_SET_DEV_NUM,
	VI_SDK_GET_DEV_NUM,
	VI_SDK_ENABLE_PATGEN,
	VI_SDK_SET_DEV_ATTR,
	VI_SDK_GET_DEV_ATTR,
	VI_SDK_SET_DEV_ATTR_EX,
	VI_SDK_GET_DEV_ATTR_EX,
	VI_SDK_ENABLE_DEV,
	VI_SDK_DISABLE_DEV,
	VI_SDK_SET_DEV_BIND_ATTR,
	VI_SDK_GET_DEV_BIND_ATTR,
	VI_SDK_SET_DEV_UNBIND_ATTR,
	VI_SDK_SET_DEV_UNBIND,
	VI_SDK_CREATE_PIPE,
	VI_SDK_DESTROY_PIPE,
	VI_SDK_SET_PIPE_ATTR,
	VI_SDK_GET_PIPE_ATTR,
	VI_SDK_START_PIPE,
	VI_SDK_STOP_PIPE,
	VI_SDK_SET_CHN_ATTR,
	VI_SDK_GET_CHN_ATTR,
	VI_SDK_ENABLE_CHN,
	VI_SDK_DISABLE_CHN,
	VI_SDK_GET_PIPE_STATUS,
	VI_SDK_GET_CHN_STATUS,
	VI_SDK_SET_MOTION_LV,
	VI_SDK_ENABLE_DIS,
	VI_SDK_DISABLE_DIS,
	VI_SDK_SET_DIS_INFO,
	VI_SDK_SET_BYPASS_FRM,
	VI_SDK_SET_PIPE_FRM_SRC,
	VI_SDK_GET_PIPE_FRM_SRC,
	VI_SDK_SEND_PIPE_RAW,
	VI_SDK_SET_DEV_TIMING_ATTR,
	VI_SDK_GET_DEV_TIMING_ATTR,
	VI_SDK_GET_CHN_FRAME,
	VI_SDK_RELEASE_CHN_FRAME,
	VI_SDK_SET_CHN_CROP,
	VI_SDK_GET_CHN_CROP,
	VI_SDK_SET_PIPE_CROP,
	VI_SDK_GET_PIPE_CROP,
	VI_SDK_GET_PIPE_FRAME,
	VI_SDK_RELEASE_PIPE_FRAME,
	VI_SDK_START_SMOOTH_RAWDUMP,
	VI_SDK_STOP_SMOOTH_RAWDUMP,
	VI_SDK_GET_SMOOTH_RAWDUMP,
	VI_SDK_PUT_SMOOTH_RAWDUMP,
	VI_SDK_SET_CHN_ROTATION,
	VI_SDK_GET_CHN_ROTATION,
	VI_SDK_SET_CHN_LDC,
	VI_SDK_GET_CHN_LDC,
	VI_SDK_SET_CHN_FLIP_MIRROR,
	VI_SDK_GET_CHN_FLIP_MIRROR,
	VI_SDK_ATTACH_VB_POOL,
	VI_SDK_DETACH_VB_POOL,
	VI_SDK_GET_PIPE_DUMP_ATTR,
	VI_SDK_SET_PIPE_DUMP_ATTR,
	VI_SDK_DUMP_REGISTER,
	VI_SDK_GET_DEV_STATUS,
	VI_SDK_IOCTL_MAX,
};

struct _vi_sdk_cfg {
	CVI_S32 dev;
	CVI_S32 pipe;
	CVI_S32 chn;
	CVI_U32 size;
	CVI_U32 reserved[1];
	union {
		CVI_S32 value;
		CVI_S64 value64;
		void *ptr;
	};
};

struct vi_ext_control {
	CVI_U32 id;
	CVI_U32 size;
	CVI_U32 reserved[1];
	union {
		CVI_S32 value;
		CVI_S64 value64;
		void *ptr;
	};

	struct _vi_sdk_cfg sdk_cfg;
} __attribute__ ((packed));

struct vi_plane {
	CVI_U64 addr;
};

/*
 * @index:
 * @length: length of planes
 * @planes: to describe buf
 * @reserved
 */
struct vi_buffer {
	CVI_U32 index;
	CVI_U32 length;
	struct vi_plane planes[3];
	CVI_U32 reserved;
};

struct vi_event {
	CVI_U32			dev_id;
	CVI_U32			type;
	CVI_U32			frame_sequence;
	CVI_U64			pts;
};

/*
 * Events
 */
enum VI_EVENT {
	VI_EVENT_BASE,
	VI_EVENT_PRE0_SOF,
	VI_EVENT_PRE1_SOF,
	VI_EVENT_PRE2_SOF,
	VI_EVENT_PRE0_EOF,
	VI_EVENT_PRE1_EOF,
	VI_EVENT_PRE2_EOF,
	VI_EVENT_POST0_EOF,
	VI_EVENT_POST1_EOF,
	VI_EVENT_POST2_EOF,
	VI_EVENT_ISP_PROC_READ,
	VI_EVENT_MAX,
};

enum VI_ISP_CFG_TYPE {
	AI_ISP_CFG_INIT,
	AI_ISP_CFG_DEINIT,
	AI_ISP_CFG_ENABLE,
	AI_ISP_CFG_DISABLE,
};

struct sop_isp_sc_online {
	CVI_U8   raw_num;
	CVI_U8   is_sc_online;
};

struct ip_info {
	CVI_U64 phy_addr; //IP start address
	CVI_U32 size; //IP total registers size
};

struct mlv_info_s {
	CVI_U8	sensor_num;
	CVI_U32	frm_num;
	CVI_U8	mlv;
};

struct vi_chn_rot_cfg {
	VI_PIPE ViPipe;
	VI_CHN ViChn;
	ROTATION_E enRotation;
};

struct vi_chn_ldc_cfg {
	VI_PIPE ViPipe;
	VI_CHN ViChn;
	ROTATION_E enRotation;
	VI_LDC_ATTR_S stLDCAttr;
	CVI_U64 meshHandle;
};

struct vi_chn_flip_mirror_cfg {
	VI_PIPE ViPipe;
	VI_CHN ViChn;
	CVI_BOOL bFlip;
	CVI_BOOL bMirror;
};

struct vi_vb_pool_cfg {
	VI_PIPE ViPipe;
	VI_CHN ViChn;
	CVI_U32 VbPool;
};

struct vi_ai_isp_cfg {
	VI_PIPE ViPipe;
	CVI_U8 ViAiISPType;
	CVI_U64 Reserved[2];
};

struct vi_ai_isp_info {
	VI_PIPE ViPipe;
	CVI_U64 InputAddr[2];
	CVI_U64 OutputAddr[2];
	CVI_U32 Size;
	CVI_U64 Reserved[1];
};

#ifdef __cplusplus
	}
#endif

#endif /* __U_VI_UAPI_H__ */

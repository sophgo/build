#ifndef __U_VI_UAPI_H__
#define __U_VI_UAPI_H__

#ifdef __cplusplus
	extern "C" {
#endif

#ifdef __KERNEL__
#include <linux/time_types.h>
#endif
#include "comm_vi.h"
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
	__s32 dev;
	__s32 pipe;
	__s32 chn;
	__u32 size;
	__u32 reserved[1];
	union {
		__s32 value;
		__s64 value64;
		void *ptr;
	};
};

struct vi_ext_control {
	__u32 id;
	__u32 size;
	__u32 reserved[1];
	union {
		__s32 value;
		__s64 value64;
		void *ptr;
	};

	struct _vi_sdk_cfg sdk_cfg;
} __attribute__ ((packed));

struct vi_plane {
	__u64 addr;
};

/*
 * @index:
 * @length: length of planes
 * @planes: to describe buf
 * @reserved
 */
struct vi_buffer {
	__u32 index;
	__u32 length;
	struct vi_plane planes[3];
	__u32 reserved;
};

struct vi_event {
	__u32			dev_id;
	__u32			type;
	__u32			frame_sequence;
	__u64			pts;
};

/*
 * Events
 */
enum vi_event_e {
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
	VI_EVENT_MAX,
};

enum vi_isp_cfg_type {
	AI_ISP_CFG_INIT,
	AI_ISP_CFG_DEINIT,
	AI_ISP_CFG_ENABLE,
	AI_ISP_CFG_DISABLE,
};

struct sop_isp_sc_online {
	__u8   raw_num;
	__u8   is_sc_online;
};

struct ip_info {
	__u64 phy_addr; //IP start address
	__u32 size; //IP total registers size
};

struct mlv_info_s {
	__u8	sensor_num;
	__u32	frm_num;
	__u8	mlv;
};

struct vi_chn_rot_cfg {
	__s32 vi_pipe;
	__s32 vi_chn;
	rotation_e rotation;
};

struct vi_chn_ldc_cfg {
	__s32 vi_pipe;
	__s32 vi_chn;
	rotation_e rotation;
	vi_ldc_attr_s ldc_attr;
	__u64 mesh_handle;
};

struct vi_chn_flip_mirror_cfg {
	__s32 vi_pipe;
	__s32 vi_chn;
	__u8  flip;
	__u8  mirror;
};

struct vi_vb_pool_cfg {
	__s32 vi_pipe;
	__s32 vi_chn;
	__u32 vb_pool;
};

struct vi_ai_isp_cfg {
	__s32 vi_pipe;
	__u8  vi_ai_isp_type;
	__u64 reserved[2];
};

struct vi_ai_isp_info {
	__s32 vi_pipe;
	__u64 input_addr[2];
	__u64 output_addr[2];
	__u32 size;
	__u64 reserved[1];
};

#ifdef __cplusplus
	}
#endif

#endif /* __U_VI_UAPI_H__ */

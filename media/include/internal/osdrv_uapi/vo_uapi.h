#ifndef __U_VO_UAPI_H__
#define __U_VO_UAPI_H__

#include "comm_vo.h"
#ifdef __cplusplus
	extern "C" {
#endif

#define VO_IOC_MAGIC	'o'
#define VO_IOC_BASE	0x20

#define VO_IOC_G_CTRL		_IOWR(VO_IOC_MAGIC, VO_IOC_BASE, struct vo_ext_control)
#define VO_IOC_S_CTRL		_IOWR(VO_IOC_MAGIC, VO_IOC_BASE + 1, struct vo_ext_control)

enum vo_ioctl_cmd {
	//VO_IOC_S_CTRL
	VO_IOCTL_BASE = 0,
	VO_IOCTL_VB_DONE,
	VO_IOCTL_INTR,
	VO_IOCTL_OUT_CSC,
	VO_IOCTL_PATTERN,
	VO_IOCTL_FRAME_BGCOLOR,
	VO_IOCTL_WINDOW_BGCOLOR,
	VO_IOCTL_ONLINE,
	VO_IOCTL_INTF,
	VO_IOCTL_ENABLE_WIN_BGCOLOR,
	VO_IOCTL_SET_ALIGN = 10,
	VO_IOCTL_SET_RGN,
	VO_IOCTL_SET_CUSTOM_CSC,
	VO_IOCTL_SET_CLK,
	VO_IOCTL_GAMMA_LUT_UPDATE,

	//VO_IOC_G_CTRL
	VO_IOCTL_GET_VLAYER_SIZE,
	VO_IOCTL_GET_INTF_TYPE,
	VO_IOCTL_GAMMA_LUT_READ = 20,

	//VO_IOC_S_SELECTION
	VO_IOCTL_SEL_TGT_COMPOSE,
	VO_IOCTL_SEL_TGT_CROP,

	//VO_IOC_S_DV_TIMINGS
	VO_IOCTL_SET_DV_TIMINGS,
	VO_IOCTL_GET_DV_TIMINGS,
	VO_IOCTL_SET_FMT,

	VO_IOCTL_START_STREAMING,
	VO_IOCTL_STOP_STREAMING,
	VO_IOCTL_ENQ_WAITQ,

	VO_IOCTL_SDK_CTRL,
	VO_IOCTL_MAX,
};

enum vo_sdk_ctrl {
	//DEV CTRL
	VO_SDK_SET_PUBATTR,
	VO_SDK_GET_PUBATTR,
	VO_SDK_SET_LVDSPARAM,
	VO_SDK_GET_LVDSPARAM,
	VO_SDK_SET_BTPARAM,
	VO_SDK_GET_BTPARAM,
	VO_SDK_ENABLE,
	VO_SDK_DISABLE,
	VO_SDK_SUSPEND,
	VO_SDK_RESUME,
	VO_SDK_ISENABLE,
	VO_SDK_GET_PANELSTATUE,
	//LAYER CTRL
	VO_SDK_SET_VIDEOLAYERATTR,
	VO_SDK_GET_VIDEOLAYERATTR,
	VO_SDK_ENABLE_VIDEOLAYER,
	VO_SDK_DISABLE_VIDEOLAYER,
	VO_SDK_SET_DISPLAYBUFLEN,
	VO_SDK_GET_DISPLAYBUFLEN,
	VO_SDK_SET_LAYER_PROC_AMP,
	VO_SDK_GET_LAYER_PROC_AMP,
	VO_SDK_SET_LAYERCSC,
	VO_SDK_GET_LAYERCSC,
	//CHN CTRL
	VO_SDK_SET_CHNATTR,
	VO_SDK_GET_CHNATTR,
	VO_SDK_ENABLE_CHN,
	VO_SDK_DISABLE_CHN,
	VO_SDK_SET_CHNROTATION,
	VO_SDK_GET_CHNROTATION,
	VO_SDK_SET_CHNFRAMERATE,
	VO_SDK_GET_CHNFRAMERATE,
	VO_SDK_GET_CHNPTS,
	VO_SDK_GET_CHNSTATUS,
	VO_SDK_SHOW_CHN,
	VO_SDK_HIDE_CHN,
	VO_SDK_RESUME_CHN,
	VO_SDK_PAUSE_CHN,
	VO_SDK_SEND_FRAME,
	VO_SDK_CLEAR_CHNBUF,
};

struct vo_ext_control {
	unsigned int id;
	unsigned int sdk_id;
	unsigned int size;
	unsigned int reserved[1];
	union {
		int value;
		long long value64;
		void *ptr;
	};
};

struct vo_bt_timings {
	unsigned int width;
	unsigned int height;
	unsigned int interlaced;
	unsigned int polarities;
	unsigned long long pixelclock;
	unsigned int hfrontporch;
	unsigned int hsync;
	unsigned int hbackporch;
	unsigned int vfrontporch;
	unsigned int vsync;
	unsigned int vbackporch;
	unsigned int il_vfrontporch;
	unsigned int il_vsync;
	unsigned int il_vbackporch;
	unsigned int standards;
	unsigned int flags;
	unsigned int reservedd[14];
};

struct vo_dv_timings {
	unsigned int type;
	struct vo_bt_timings bt;
};

struct vo_rect {
	unsigned int left;
	unsigned int top;
	unsigned int width;
	unsigned int height;
};

//vo sdk layer config
struct vo_video_layer_cfg {
	unsigned char layer;
};

struct vo_video_layer_attr_cfg {
	unsigned char layer;
	vo_video_layer_attr_s layer_attr;
};

struct vo_layer_proc_amp_cfg {
	unsigned char layer;
	int proc_amp[PROC_AMP_MAX];
};

struct vo_layer_csc_cfg {
	unsigned char layer;
	vo_csc_s video_csc;
};

struct vo_clear_chn_buf_cfg {
	unsigned char layer;
	unsigned char chn;
	bool clear;
};

struct vo_snd_frm_cfg {
	unsigned char layer;
	unsigned char chn;
	video_frame_info_s video_frame;
	int millisec;
};

struct vo_display_buflen_cfg {
	unsigned char layer;
	unsigned int buflen;
};

struct vo_chn_attr_cfg {
	unsigned char layer;
	unsigned char chn;
	vo_chn_attr_s chn_attr;
};

struct vo_chn_cfg {
	unsigned char layer;
	unsigned char chn;
};

struct vo_chn_frmrate_cfg {
	unsigned char layer;
	unsigned char chn;
	unsigned int frame_rate;
};

struct vo_chn_pts_cfg {
	unsigned char layer;
	unsigned char chn;
	unsigned long long chn_pts;
};

struct vo_chn_status_cfg {
	unsigned char layer;
	unsigned char chn;
	vo_query_status_s status;
};

struct vo_chn_rotation_cfg {
	unsigned char layer;
	unsigned char chn;
	rotation_e rotation;
};

struct vo_panel_status_cfg {
	unsigned char layer;
	unsigned char chn;
	unsigned int is_init;
};

struct vo_dev_cfg {
	unsigned char dev;
	unsigned char enable;
};

struct vo_pub_attr_cfg {
	unsigned char dev;
	vo_pub_attr_s pub_attr;
};

struct vo_lvds_param_cfg {
	unsigned char dev;
	vo_lvds_attr_s lvds_param;
};

struct vo_bt_param_cfg {
	unsigned char dev;
	vo_bt_attr_s bt_param;
};


#ifdef __cplusplus
	}
#endif

#endif /* __U_VO_UAPI_H__ */


/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File Name: comm_vdec.h
 * Description:
 */

#ifndef __COMM_VDEC_H__
#define __COMM_VDEC_H__
#include "defines.h"
#include "comm_video.h"
#include "common.h"
#include "comm_vb.h"

#ifdef __cplusplus
#if __cplusplus
extern "C" {
#endif
#endif /* End of #ifdef __cplusplus */

#define DRV_VDEC_STR_LEN	255
#define DRV_VDEC_MASK_ERR	0x1
#define DRV_VDEC_MASK_WARN	0x2
#define DRV_VDEC_MASK_INFO	0x4
#define DRV_VDEC_MASK_FLOW	0x8
#define DRV_VDEC_MASK_DBG	0x10
#define DRV_VDEC_MASK_MEM	0x80
#define DRV_VDEC_MASK_BS	0x100
#define DRV_VDEC_MASK_SRC	0x200
#define DRV_VDEC_MASK_API	0x400
#define DRV_VDEC_MASK_DISP	0x800
#define DRV_VDEC_MASK_PERF	0x1000
#define DRV_VDEC_MASK_CFG	0x2000
#define DRV_VDEC_MASK_TRACE	0x4000
#define DRV_VDEC_MASK_DUMP_YUV	0x10000
#define DRV_VDEC_MASK_DUMP_BS	0x20000
#define DRV_VDEC_MASK_CURR	(DRV_VDEC_MASK_ERR)


#define IO_BLOCK 1
#define IO_NOBLOCK 0

typedef enum _video_mode_e {
	VIDEO_MODE_STREAM = 0, /* send by stream */
	VIDEO_MODE_FRAME, /* send by frame  */
	VIDEO_MODE_COMPAT, /* One frame supports multiple packets sending. */
	/* The current frame is considered to end when b_end_of_frame is equal to HI_TRUE */
	VIDEO_MODE_BUTT
} video_mode_e;

enum VDEC_BIND_MODE_E {
	VDEC_BIND_DISABLE  = 0,
	VDEC_BIND_VPSS_VO,
	VDEC_BIND_VPSS_VENC,
};

typedef struct _vdec_attr_video_s {
	unsigned int u32_ref_frame_num; /* RW, Range: [0, 16]; reference frame num. */
	unsigned char b_temporal_mvp_enable; /* RW; */
	/* specifies whether temporal motion vector predictors can be used for inter prediction */
	unsigned int u32_tmv_buf_size; /* RW; tmv buffer size(Byte) */
} vdec_attr_video_s;

typedef struct _buffer_info_s {
	unsigned int size;
	unsigned long phys_addr;
	unsigned long virt_addr;
} buffer_info_s;

typedef struct _vdec_buffer_info_s {
	buffer_info_s *bitstream_buffer;
#ifdef __arm__
	__u32 addr_padding1;
#endif
	buffer_info_s *frame_buffer;
#ifdef __arm__
	__u32 addr_padding2;
#endif
	buffer_info_s *y_table_buffer;
#ifdef __arm__
	__u32 addr_padding3;
#endif
	buffer_info_s *c_table_buffer;
#ifdef __arm__
	__u32 addr_padding4;
#endif
	int num_of_dec_fbc;
	int num_of_decwtl;
} vdec_buffer_info_s;


typedef struct _vdec_chn_attr_s {
	payload_type_e en_type; /* RW; video type to be decoded   */
	video_mode_e en_mode; /* RW; send by stream or by frame */
	unsigned int u32_pic_width; /* RW; max pic width */
	unsigned int u32_pic_height; /* RW; max pic height */
	unsigned int u32StreamBufSize; /* RW; stream buffer size(Byte) */
	unsigned int u32_frame_buf_size; /* RW; frame buffer size(Byte) */
	unsigned int u32_frame_buf_cnt;
	compress_mode_e en_compress_mode; /* RW; compress mode */
	unsigned char u8_command_queue_depth; /* RW; command queue depth [0,4]*/
	unsigned char u8_reorder_enable;
	union {
		vdec_attr_video_s
		st_vdec_video_attr; /* structure with video ( h264/h265) */
	};
	vdec_buffer_info_s st_buffer_info;
} vdec_chn_attr_s;

typedef struct _vdec_stream_s {
	unsigned int u32_len; /* W; stream len */
	uint64_t u64_pts; /* W; present time stamp */
	uint64_t u64_dts; /* W; decoded time stamp */
	unsigned char b_end_of_frame; /* W; is the end of a frame */
	unsigned char b_end_of_stream; /* W; is the end of all stream */
	unsigned char b_display; /* W; is the current frame displayed. only valid by VIDEO_MODE_FRAME */
	unsigned char *pu8_addr; /* W; stream address */
} vdec_stream_s;

typedef struct _vdec_userdata_s {
	uint64_t u64_phy_addr; /* R; userdata data phy address */
	unsigned int u32_len; /* R; userdata data len */
	unsigned char b_valid; /* R; is valid? */
	unsigned char *pu8_addr; /* R; userdata data vir address */
} vdec_userdata_s;

typedef struct _vdec_decode_error_s {
	int s32_format_err; /* R; format error. eg: do not support filed */
	int s32_pic_size_err_set; /* R; picture width or height is larger than channel width or height */
	int s32_stream_unsprt; /* R; unsupport the stream specification */
	int s32_pack_err; /* R; stream package error */
	int s32_prtc_inum_err_set; /* R; protocol num is not enough. eg: slice, pps, sps */
	int s32_ref_err_set; /* R; reference num is not enough */
	int s32_pic_buf_size_err_set; /* R; the buffer size of picture is not enough */
	int s32_stream_size_over; /* R; the stream size is too big and force discard stream */
	int s32_vdec_stream_not_release; /* R; the stream not released for too long time */
} vdec_decode_error_s;

typedef struct {
	unsigned int left;   /**< A horizontal pixel offset of top-left corner of rectangle from (0, 0) */
	unsigned int top;    /**< A vertical pixel offset of top-left corner of rectangle from (0, 0) */
	unsigned int right;  /**< A horizontal pixel offset of bottom-right corner of rectangle from (0, 0) */
	unsigned int bottom; /**< A vertical pixel offset of bottom-right corner of rectangle from (0, 0) */
} vdec_rect_s;

typedef struct _seq_initial_info_s {
	int s32_pic_width; /*R; Horizontal picture size in pixel*/
	int s32_pic_height; /*R; Vertical picture size in pixel*/
	int s32_frate_numerator; /*R; The numerator part of frame rate fraction*/
	int s32_frate_denominator; /*R; The denominator part of frame rate fraction*/
	vdec_rect_s  st_pic_crop_rect; /*R; Picture cropping rectangle information*/
	int s32_min_frame_buffer_count; /*R; This is the minimum number of frame buffers required for decoding.*/
	int s32_frame_buf_delay; /*R; the maximum display frame buffer delay for buffering decoded picture reorder.*/
	int s32_profile;/*R; H.265/H.264 : profile_idc*/
	int s32_level;/*R;H.265/H.264 : level_idc*/
	int s32_interlace; /*R; progressive or interlace frame */
	int s32_max_num_ref_frm_flag;/*R; one of the SPS syntax elements in H.264.*/
	int s32_max_num_ref_frm;
	/* When avcIsExtSAR is 0, this indicates aspect_ratio_idc[7:0].
	 * When avcIsExtSAR is 1, this indicates sar_width[31:16] and sar_height[15:0].
	 * If aspect_ratio_info_present_flag = 0, the register returns -1 (0xffffffff).
	 */
	int s32_aspect_rate_info;/**/
	/* R; The bitrate value written in bitstream syntax.
	 * If there is no bitRate, this reports -1.
	 */
	int s32_bit_rate;
	int s32_luma_bitdepth; /*R; bit-depth of luma sample */
	int s32_chroma_bitdepth; /*R; bit-depth of chroma sample */
	unsigned char  u8_core_idx; /*R, 0:ve_core, 1:vd_core0, 2:vd_core1*/
} seq_initial_info_s;

typedef struct _vdec_chn_status_s {
	payload_type_e en_type; /* R; video type to be decoded */
	int u32_left_stream_bytes; /* R; left stream bytes waiting for decode */
	int u32_left_stream_frames; /* R; left frames waiting for decode,only valid for VIDEO_MODE_FRAME */
	int u32_left_pics; /* R; pics waiting for output */
	unsigned char b_start_recvStream; /* R; had started recv stream? */
	/* R; how many frames of stream has been received. valid when send by frame. */
	unsigned int u32_recv_stream_frames;
	/* R; how many frames of stream has been decoded. valid when send by frame. */
	unsigned int u32_decode_stream_frames;
	vdec_decode_error_s st_vdec_eec_err; /* R; information about decode error */
	unsigned int u32_width; /* R; the width of the currently decoded stream */
	unsigned int u32_height; /* R; the height of the currently decoded stream */
	unsigned char u8_free_src_buffer;
	unsigned char u8_busy_src_buffer;
	unsigned char u8_status;
	seq_initial_info_s st_seqinital_info;
} vdec_chn_status_s;

typedef enum _video_dec_mode_e {
	VIDEO_DEC_MODE_IPB = 0,
	VIDEO_DEC_MODE_IP,
	VIDEO_DEC_MODE_I,
	VIDEO_DEC_MODE_BUTT
} video_dec_mode_e;

typedef enum _video_output_order_e {
	VIDEO_OUTPUT_ORDER_DISP = 0,
	VIDEO_OUTPUT_ORDER_DEC,
	VIDEO_OUTPUT_ORDER_BUTT
} video_output_order_e;

typedef struct _vdec_param_video_s {
	int s32_err_threshold; /* RW, Range: [0, 100]; */
	/* threshold for stream error process, 0: discard with any error, 100 : keep data with any error */
	video_dec_mode_e en_dec_mode; /* RW; */
	/* decode mode , 0: deocde IPB frames, 1: only decode I frame & P frame , 2: only decode I frame */
	video_output_order_e en_output_order; /* RW; */
	/* frames output order ,0: the same with display order , 1: the same width decoder order */
	compress_mode_e en_compress_mode; /* RW; compress mode */
	video_format_e en_video_format; /* RW; video format */
} vdec_param_video_s;

typedef struct _vdec_param_picture_s {
	unsigned int u32_alpha; /* RW, Range: [0, 255]; value 0 is transparent. */
	/* [0 ,127]   is deemed to transparent when en_pixel_format is ARGB1555 or
	 * ABGR1555 [128 ,256] is deemed to non-transparent when en_pixel_format is
	 * ARGB1555 or ABGR1555
	 */
	unsigned int u32_hdown_sampling;
	unsigned int u32_vdown_sampling;
	int s32_roi_enable;
	int s32_roi_offset_x;
	int s32_roi_offset_y;
	int s32_roi_offset;
	int s32_roi_width;
	int s32_roi_height;
	int s32_rot_angle;
	int s32_mir_dir;
} vdec_param_picture_s;

typedef struct _vdec_chn_param_s {
	payload_type_e en_type; /* RW; video type to be decoded   */
	pixel_format_e en_pixel_format; /* RW; out put pixel format */
	unsigned int u32_display_frame_num; /* RW, Range: [0, 16]; display frame num */
	union {
		vdec_param_video_s
		st_vdec_video_param; /* structure with video ( h265/h264) */
		vdec_param_picture_s
		st_vdec_picture_param; /* structure with picture (jpeg/mjpeg ) */
	};
} vdec_chn_param_s;

typedef struct _h264_prtcl_param_s {
	int s32_max_slice_num; /* RW; max slice num support */
	int s32_max_sps_num; /* RW; max sps num support */
	int s32_max_pps_num; /* RW; max pps num support */
} h264_prtcl_param_s;

typedef struct _h265_prtcl_param_s {
	int s32_max_slice_segment_num; /* RW; max slice segmnet num support */
	int s32_max_vps_num; /* RW; max vps num support */
	int s32_max_sps_num; /* RW; max sps num support */
	int s32_max_pps_num; /* RW; max pps num support */
} h265_prtcl_param_s;

typedef struct _vdec_prtcl_param_s {
	payload_type_e
	en_type; /* RW; video type to be decoded, only h264 and h265 supported */
	union {
		h264_prtcl_param_s
		st_h264_prtcl_param; /* protocol param structure for h264 */
		h265_prtcl_param_s
		st_h265_prtcl_param; /* protocol param structure for h265 */
	};
} vdec_prtcl_param_s;

typedef struct _vdec_chn_pool_s {
	vb_pool h_pic_vb_pool; /* RW;  vb pool id for pic buffer */
	vb_pool h_tmv_vb_pool; /* RW;  vb pool id for tmv buffer */
} vdec_chn_pool_s;

typedef enum _vdec_evnt_e {
	VDEC_EVNT_STREAM_ERR = 1,
	VDEC_EVNT_UNSUPPORT,
	VDEC_EVNT_OVER_REFTHR,
	VDEC_EVNT_REF_NUM_OVER,
	VDEC_EVNT_SLICE_NUM_OVER,
	VDEC_EVNT_SPS_NUM_OVER,
	VDEC_EVNT_PPS_NUM_OVER,
	VDEC_EVNT_PICBUF_SIZE_ERR,
	VDEC_EVNT_SIZE_OVER,
	VDEC_EVNT_IMG_SIZE_CHANGE,
	VDEC_EVNT_VPS_NUM_OVER,
	VDEC_EVNT_BUTT
} vdec_evnt_e;

typedef enum _vdec_capacity_strategy_e {
	VDEC_CAPACITY_STRATEGY_BY_MOD = 0,
	VDEC_CAPACITY_STRATEGY_BY_CHN = 1,
	VDEC_CAPACITY_STRATEGY_BUTT
} vdec_capacity_strategy_e;

typedef struct _vdec_video_mod_param_s {
	unsigned int u32_max_pic_width;
	unsigned int u32_max_pic_height;
	unsigned int u32_max_slice_num;
	unsigned int u32_vdh_msg_num;
	unsigned int u32_vdh_bin_size;
	unsigned int u32_vdh_ext_mem_level;
} vdec_video_mod_param_s;

typedef struct _vdec_picture_mod_param_s {
	unsigned int u32_max_pic_width;
	unsigned int u32_max_pic_height;
	unsigned char b_support_progressive;
	unsigned char b_dynamic_allocate;
	vdec_capacity_strategy_e en_cap_strategy;
} vdec_picture_mod_param_s;

typedef struct _vdec_mod_param_s {
	vb_source_e en_vdec_vb_source; /* RW, Range: [1, 3];  frame buffer mode  */
	unsigned int u32_mini_buf_mode; /* RW, Range: [0, 1];  stream buffer mode */
	unsigned int u32_parallel_mode; /* RW, Range: [0, 1];  VDH working mode   */
	vdec_video_mod_param_s st_video_mod_param;
	vdec_picture_mod_param_s st_picture_mod_param;
} vdec_mod_param_s;

typedef struct _vdec_user_data_attr_s {
	unsigned char b_enable;
	unsigned int u32_max_user_data_len;
} vdec_user_data_attr_s;

// TODO: refinememt for hardcode
#define ENUM_ERR_VDEC_INVALID_CHNID \
	((int)(0xC0000000L | ((ID_VDEC) << 16) | ((4) << 13) | (2)))
#define ENUM_ERR_VDEC_ERR_INIT \
	((int)(0xC0000000L | ((ID_VDEC) << 16) | ((4) << 13) | (64)))

typedef enum {
	DRV_ERR_VDEC_INVALID_CHNID = ENUM_ERR_VDEC_INVALID_CHNID,
	DRV_ERR_VDEC_ILLEGAL_PARAM,
	DRV_ERR_VDEC_EXIST,
	DRV_ERR_VDEC_UNEXIST,
	DRV_ERR_VDEC_NULL_PTR,
	DRV_ERR_VDEC_NOT_CONFIG,
	DRV_ERR_VDEC_NOT_SUPPORT,
	DRV_ERR_VDEC_NOT_PERM,
	DRV_ERR_VDEC_INVALID_PIPEID,
	DRV_ERR_VDEC_INVALID_GRPID,
	DRV_ERR_VDEC_NOMEM,
	DRV_ERR_VDEC_NOBUF,
	DRV_ERR_VDEC_BUF_EMPTY,
	DRV_ERR_VDEC_BUF_FULL,
	DRV_ERR_VDEC_SYS_NOTREADY,
	DRV_ERR_VDEC_BADADDR,
	DRV_ERR_VDEC_BUSY,
	DRV_ERR_VDEC_SIZE_NOT_ENOUGH,
	DRV_ERR_VDEC_INVALID_VB,
	///========//
	DRV_ERR_VDEC_ERR_INIT = ENUM_ERR_VDEC_ERR_INIT,
	DRV_ERR_VDEC_ERR_INVALID_RET,
	DRV_ERR_VDEC_ERR_SEQ_OPER,
	DRV_ERR_VDEC_ERR_VDEC_MUTEX,
	DRV_ERR_VDEC_ERR_SEND_FAILED,
	DRV_ERR_VDEC_ERR_GET_FAILED,
	DRV_ERR_VDEC_BUTT
} vdec_recode_e_errtype;

#ifdef __cplusplus
#if __cplusplus
}
#endif
#endif /* End of #ifdef __cplusplus */

#endif /* End of #ifndef  __COMM_VDEC_H__ */

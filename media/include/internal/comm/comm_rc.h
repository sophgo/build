/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File Name: include/comm_rc.h
 * Description:
 *   Common rate control definitions.
 */

#ifndef __COMM_RC_H__
#define __COMM_RC_H__

#include "defines.h"

#ifdef __cplusplus
#if __cplusplus
extern "C" {
#endif
#endif /* __cplusplus */

typedef unsigned int DRV_FR32;

/* rc mode */
typedef enum _venc_rc_mode_e {
	VENC_RC_MODE_H264CBR = 1,
	VENC_RC_MODE_H264VBR,
	VENC_RC_MODE_H264AVBR,
	VENC_RC_MODE_H264QVBR,
	VENC_RC_MODE_H264FIXQP,
	VENC_RC_MODE_H264QPMAP,
	VENC_RC_MODE_H264UBR,

	VENC_RC_MODE_MJPEGCBR,
	VENC_RC_MODE_MJPEGVBR,
	VENC_RC_MODE_MJPEGFIXQP,

	VENC_RC_MODE_H265CBR,
	VENC_RC_MODE_H265VBR,
	VENC_RC_MODE_H265AVBR,
	VENC_RC_MODE_H265QVBR,
	VENC_RC_MODE_H265FIXQP,
	VENC_RC_MODE_H265QPMAP,
	VENC_RC_MODE_H265UBR,

	VENC_RC_MODE_BUTT,

} venc_rc_mode_e;

/* qpmap mode*/
typedef enum _venc_rc_qpmap_mode_e {
	VENC_RC_QPMAP_MODE_MEANQP = 0,
	VENC_RC_QPMAP_MODE_MINQP,
	VENC_RC_QPMAP_MODE_MAXQP,

	VENC_RC_QPMAP_MODE_BUTT,
} venc_rc_qpmap_mode_e;

/* the attribute of h264e fixqp*/
typedef struct _venc_h264_fixqp_s {
	unsigned int u32_gop; /* RW; Range:[1, 65536]; the interval of ISLICE. */
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	unsigned int u32_i_qp; ///< qp of the I frame, Range:[0, 51]
	unsigned int u32_p_qp; ///< qp of the P frame, Range:[0, 51]
	unsigned int u32BQp; ///< Not support
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_h264_fixqp_s;

/* the attribute of h264e cbr*/
typedef struct _venc_h264_cbr_s {
	unsigned int u32_gop; /* RW; Range:[1, 65536]; the interval of I Frame. */
	unsigned int u32_stat_time; /* RW; Range:[1, 60]; the rate statistic time, the unit is senconds(s) */
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	unsigned int u32_bit_rate; /* RW; Range:[2, 409600]; average bitrate */
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_h264_cbr_s;

/* the attribute of h264e vbr*/
typedef struct _venc_h264_vbr_s {
	unsigned int u32_gop; /* RW; Range:[1, 65536]; the interval of ISLICE. */
	unsigned int u32_stat_time; /* RW; Range:[1, 60]; the rate statistic time, the unit is senconds(s) */
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	unsigned int u32_max_bit_rate; /* RW; Range:[2, 409600];the max bitrate */
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_h264_vbr_s;

/* the attribute of h264e avbr*/
typedef struct _venc_h264_avbr_s {
	unsigned int u32_gop; /* RW; Range:[1, 65536]; the interval of ISLICE. */
	unsigned int u32_stat_time; /* RW; Range:[1, 60]; the rate statistic time, the unit is senconds(s) */
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	unsigned int u32_max_bit_rate; /* RW; Range:[2, 409600];the max bitrate */
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_h264_avbr_s;

/* the attribute of h264e qpmap*/
typedef struct _venc_h264_qpmap_s {
	unsigned int u32_gop; /* RW; Range:[1, 65536]; the interval of ISLICE. */
	unsigned int u32_stat_time; /* RW; Range:[1, 60]; the rate statistic time, the unit is senconds(s) */
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_h264_qpmap_s;

typedef struct _venc_h264_qvbr_s {
	unsigned int u32_gop; /*the interval of ISLICE. */
	unsigned int u32_stat_time; /* the rate statistic time, the unit is senconds(s) */
	unsigned int u32_src_frame_rate; /* the input frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate; /* the target frame rate of the venc channel */
	unsigned int u32_target_bitrate; /* the target bitrate */
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_h264_qvbr_s;

/* the attribute of h264e ubr*/
typedef struct _venc_h264_ubr_s {
	unsigned int u32_gop; /* RW; Range:[1, 65536]; the interval of I Frame. */
	unsigned int u32_stat_time; /* RW; Range:[1, 60]; the rate statistic time, the unit is senconds(s) */
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	unsigned int u32_bit_rate; /* RW; Range:[2, 409600]; average bitrate */
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_h264_ubr_s;

/* the attribute of h265e qpmap*/
typedef struct _venc_h265_qpmap_s {
	unsigned int u32_gop; /* RW; Range:[1, 65536]; the interval of ISLICE. */
	unsigned int u32_stat_time; /* RW; Range:[1, 60]; the rate statistic time, the unit is senconds(s) */
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	venc_rc_qpmap_mode_e en_qp_map_mode; /* RW;  the QpMap Mode.*/
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_h265_qpmap_s;

typedef struct _venc_h264_cbr_s VENC_H265_CBR_S;
typedef struct _venc_h264_vbr_s VENC_H265_VBR_S;
typedef struct _venc_h264_avbr_s VENC_H265_AVBR_S;
typedef struct _venc_h264_fixqp_s VENC_H265_FIXQP_S;
typedef struct _venc_h264_qvbr_s VENC_H265_QVBR_S;
typedef struct _venc_h264_ubr_s VENC_H265_UBR_S;

/* the attribute of mjpege fixqp*/
typedef struct _venc_mjpeg_fixqp_s {
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	unsigned int u32_qfactor; /* RW; Range:[0,99];image quality. */
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_mjpeg_fixqp_s;

/* the attribute of mjpege cbr*/
typedef struct _venc_mjpeg_cbr_s {
	unsigned int u32_stat_time; /* RW; Range:[1, 60]; the rate statistic time, the unit is senconds(s) */
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	unsigned int u32_bit_rate; /* RW; Range:[2, 409600]; average bitrate */
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_mjpeg_cbr_s;

/* the attribute of mjpege vbr*/
typedef struct _venc_mjpeg_vbr_s {
	unsigned int u32_stat_time; /* RW; Range:[1, 60]; the rate statistic time, the unit is senconds(s) */
	unsigned int u32_src_frame_rate; /* RW; Range:[1, 240]; the input frame rate of the venc channel */
	/* RW; Range:[0.015625, u32SrcFrmRate]; the target frame rate of the venc channel */
	DRV_FR32 fr32_dst_frame_rate;
	unsigned int u32_max_bit_rate; /* RW; Range:[2, 409600];the max bitrate */
	unsigned char b_vari_fps_en; /* RW; Range:[0, 1]; enable variable framerate */
} venc_mjpeg_vbr_s;

/* the attribute of rc*/
typedef struct _venc_rc_attr_s {
	venc_rc_mode_e en_rc_mode; /* RW; the type of rc*/
	union {
		venc_h264_cbr_s st_h264_cbr;
		venc_h264_vbr_s st_h264_vbr;
		venc_h264_avbr_s st_h264_avbr;
		venc_h264_qvbr_s st_h264_qvbr;
		venc_h264_fixqp_s st_h264_fixqp;
		venc_h264_qpmap_s st_h264_qpmap;
		venc_h264_ubr_s st_h264_ubr;

		venc_mjpeg_cbr_s st_mjpeg_cbr;
		venc_mjpeg_vbr_s st_mjpeg_vbr;
		venc_mjpeg_fixqp_s st_mjpeg_fixqp;

		VENC_H265_CBR_S st_h265_cbr;
		VENC_H265_VBR_S st_h265_vbr;
		VENC_H265_AVBR_S st_h265_avbr;
		VENC_H265_QVBR_S st_h265_qvbr;
		VENC_H265_FIXQP_S st_h265_fixqp;
		venc_h265_qpmap_s st_h265_qpmap;
		VENC_H265_UBR_S st_h265_ubr;
	};
} venc_rc_attr_s;

/*the super frame mode*/
typedef enum _venc_superfrm_mode_e {
	SUPERFRM_NONE = 0, /* sdk don't care super frame */
	SUPERFRM_DISCARD, /* the super frame is discarded */
	SUPERFRM_REENCODE, /* the super frame is re-encode */
	SUPERFRM_REENCODE_IDR, /* the super frame is re-encode to IDR */
	SUPERFRM_BUTT
} venc_superfrm_mode_e;

/* The param of H264e cbr*/
typedef struct _venc_param_h264_cbr_s {
	unsigned int u32_min_iprop; /* RW; Range:[1, 100]; the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* RW; Range:(u32_min_iprop, 100]; the max ratio of i frame and p frame */
	unsigned int u32_max_qp; /* RW; Range:(u32_min_qp, 51];the max QP value */
	unsigned int u32_min_qp; /* RW; Range:[0, 51]; the min QP value */
	unsigned int u32_max_iqp; /* RW; Range:(u32_min_iqp, 51]; max qp for i frame */
	unsigned int u32_min_iqp; /* RW; Range:[0, 51]; min qp for i frame */
	int s32_max_re_encode_times; /* RW; Range:[0, 3]; Range:max number of re-encode times.*/
	unsigned char b_qp_map_en; /* RW; Range:[0, 1]; enable qpmap.*/
} venc_param_h264_cbr_s;

/* The param of H264e vbr*/
typedef struct _venc_param_h264_vbr_s {
	int s32_change_pos;
	// RW; Range:[50, 100]; Indicates the ratio of the current bit rate to the maximum
	// bit rate when the QP value starts to be adjusted
	unsigned int u32_min_iprop; /* RW; Range:[1, 100] ; the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* RW; Range:(u32_min_iprop, 100] ; the max ratio of i frame and p frame */
	int s32_max_re_encode_times; /* RW; Range:[0, 3]; max number of re-encode times */
	unsigned char b_qp_map_en;

	unsigned int u32_max_qp; /* RW; Range:(u32_min_qp, 51]; the max P B qp */
	unsigned int u32_min_qp; /* RW; Range:[0, 51]; the min P B qp */
	unsigned int u32_max_iqp; /* RW; Range:(u32_min_iqp, 51]; the max I qp */
	unsigned int u32_min_iqp; /* RW; Range:[0, 51]; the min I qp */
} venc_param_h264_vbr_s;

/* The param of H264e avbr*/
typedef struct _venc_param_h264_avbr_s {
	int s32_change_pos;
	// RW; Range:[50, 100]; Indicates the ratio of the current bit rate to the maximum
	// bit rate when the QP value starts to be adjusted
	unsigned int u32_min_iprop; /* RW; Range:[1, 100] ; the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* RW; Range:(u32_min_iprop, 100] ; the max ratio of i frame and p frame */
	int s32_max_re_encode_times; /* RW; Range:[0, 3]; max number of re-encode times */
	unsigned char b_qp_map_en;

	int s32_min_still_percent; /* RW; Range:[5, 100]; the min percent of target bitrate for still scene */
	/* RW; Range:[u32_min_iqp, u32_max_iqp]; the max QP value of I frame for still scene*/
	unsigned int u32_max_still_qp;
	unsigned int u32_min_still_psnr; /* RW; reserved,Invalid member currently */

	unsigned int u32_max_qp; /* RW; Range:(u32_min_qp, 51]; the max P B qp */
	unsigned int u32_min_qp; /* RW; Range:[0, 51]; the min P B qp */
	unsigned int u32_max_iqp; /* RW; Range:(u32_min_iqp, 51]; the max I qp */
	unsigned int u32_min_iqp; /* RW; Range:[0, 51]; the min I qp */
	unsigned int u32_min_qp_delta;
	// Difference between FrameLevelMinQp & u32_min_qp, FrameLevelMinQp = u32_min_qp(or u32_min_iqp) + MinQpDelta

	unsigned int u32_motion_sensitivity; /* RW; Range:[0, 100]; Motion Sensitivity */
	int	s32_avbr_frm_lost_open; /* RW; Range:[0, 1]; Open Frame Lost */
	int s32_avbr_frm_gap; /* RW; Range:[0, 100]; Maximim Gap of Frame Lost */
	int s32_avbr_pure_still_thr;
} venc_param_h264_avbr_s;

typedef struct _venc_param_h264_qvbr_s {
	unsigned int u32_min_iprop; /* the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* the max ratio of i frame and p frame */
	int s32_max_re_encode_times; /* max number of re-encode times [0, 3]*/
	unsigned char b_qp_map_en;

	unsigned int u32_max_qp; /* the max P B qp */
	unsigned int u32_min_qp; /* the min P B qp */
	unsigned int u32_max_iqp; /* the max I qp */
	unsigned int u32_min_iqp; /* the min I qp */

	int s32_bit_percent_ul; /*Indicate the ratio of bitrate  upper limit*/
	int s32_bit_percent_ll; /*Indicate the ratio of bitrate  lower limit*/
	int s32_psnr_fluctuate_ul; /*Reduce the target bitrate when the value of psnr approch the upper limit*/
	int s32_psnr_fluctuate_ll; /*Increase the target bitrate when the value of psnr approch the lower limit */
} venc_param_h264_qvbr_s;

/* The param of H264e ubr */
typedef struct _venc_param_h264_ubr_s {
	unsigned int u32_min_iprop; /* RW; Range:[1, 100]; the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* RW; Range:(u32_min_iprop, 100]; the max ratio of i frame and p frame */
	unsigned int u32_max_qp; /* RW; Range:(u32_min_qp, 51];the max QP value */
	unsigned int u32_min_qp; /* RW; Range:[0, 51]; the min QP value */
	unsigned int u32_max_iqp; /* RW; Range:(u32_min_iqp, 51]; max qp for i frame */
	unsigned int u32_min_iqp; /* RW; Range:[0, 51]; min qp for i frame */
	int s32_max_re_encode_times; /* RW; Range:[0, 3]; Range:max number of re-encode times.*/
	unsigned char b_qp_map_en; /* RW; Range:[0, 1]; enable qpmap.*/
} venc_param_h264_ubr_s;

/* The param of mjpege cbr*/
typedef struct _venc_param_mjpeg_cbr_s {
	unsigned int u32_max_qfactor; /* RW; Range:[MinQfactor, 99]; the max Qfactor value*/
	unsigned int u32_min_qfactor; /* RW; Range:[1, 99]; the min Qfactor value */
} venc_param_mjpeg_cbr_s;

/* The param of mjpege vbr*/
typedef struct _venc_param_mjpeg_vbr_s {
	int s32_change_pos;
	// RW; Range:[50, 100]; Indicates the ratio of the current bit rate to the maximum
	// bit rate when the Qfactor value starts to be adjusted
	unsigned int u32_max_qfactor; /* RW; Range:[MinQfactor, 99]; max image quailty allowed */
	unsigned int u32_min_qfactor; /* RW; Range:[1, 99]; min image quality allowed */
} venc_param_mjpeg_vbr_s;

/* The param of h265e cbr*/
typedef struct _venc_param_h265_cbr_s {
	unsigned int u32_min_iprop; /* RW; Range: [1, 100]; the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* RW; Range: (u32_min_iprop, 100] ;the max ratio of i frame and p frame */
	unsigned int u32_max_qp; /* RW; Range:(u32_min_qp, 51];the max QP value */
	unsigned int u32_min_qp; /* RW; Range:[0, 51];the min QP value */
	unsigned int u32_max_iqp; /* RW; Range:(u32_min_iqp, 51];max qp for i frame */
	unsigned int u32_min_iqp; /* RW; Range:[0, 51];min qp for i frame */
	int s32_max_re_encode_times; /* RW; Range:[0, 3]; Range:max number of re-encode times.*/
	unsigned char b_qp_map_en; /* RW; Range:[0, 1]; enable qpmap.*/
	venc_rc_qpmap_mode_e en_qp_map_mode; /* RW; Qpmap Mode*/
} venc_param_h265_cbr_s;

/* The param of h265e vbr*/
typedef struct _venc_param_h265_vbr_s {
	int s32_change_pos;
	// RW; Range:[50, 100];Indicates the ratio of the current
	// bit rate to the maximum bit rate when the QP value starts to be adjusted
	unsigned int u32_min_iprop; /* RW; [1, 100]the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* RW; (u32_min_iprop, 100]the max ratio of i frame and p frame */
	int s32_max_re_encode_times; /* RW; Range:[0, 3]; Range:max number of re-encode times.*/

	unsigned int u32_max_qp; /* RW; Range:(u32_min_qp, 51]; the max P B qp */
	unsigned int u32_min_qp; /* RW; Range:[0, 51]; the min P B qp */
	unsigned int u32_max_iqp; /* RW; Range:(u32_min_iqp, 51]; the max I qp */
	unsigned int u32_min_iqp; /* RW; Range:[0, 51]; the min I qp */

	unsigned char b_qp_map_en; /* RW; Range:[0, 1]; enable qpmap.*/
	venc_rc_qpmap_mode_e en_qp_map_mode; /* RW; Qpmap Mode*/
} venc_param_h265_vbr_s;

/* The param of h265e vbr*/
typedef struct _venc_param_h265_avbr_s {
	int s32_change_pos;
	// RW; Range:[50, 100];Indicates the ratio of the current
	// bit rate to the maximum bit rate when the QP value starts to be adjusted
	unsigned int u32_min_iprop; /* RW; [1, 100]the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* RW; (u32_min_iprop, 100]the max ratio of i frame and p frame */
	int s32_max_re_encode_times; /* RW; Range:[0, 3]; Range:max number of re-encode times.*/

	int s32_min_still_percent; /* RW; Range:[5, 100]; the min percent of target bitrate for still scene */
	/* RW; Range:[u32_min_iqp, u32_max_iqp]; the max QP value of I frame for still scene*/
	unsigned int u32_max_still_qp;
	unsigned int u32_min_still_psnr; /* RW; reserved */

	unsigned int u32_max_qp; /* RW; Range:(u32_min_qp, 51];the max P B qp */
	unsigned int u32_min_qp; /* RW; Range:[0, 51];the min P B qp */
	unsigned int u32_max_iqp; /* RW; Range:(u32_min_iqp, 51];the max I qp */
	unsigned int u32_min_iqp; /* RW; Range:[0, 51];the min I qp */
	unsigned int u32_min_qp_delta;
	// Difference between FrameLevelMinQp & u32_min_qp, FrameLevelMinQp = u32_min_qp(or u32_min_iqp) + MinQpDelta

	unsigned int u32_motion_sensitivity; /* RW; Range:[0, 100]; Motion Sensitivity */
	int	s32_avbr_frm_lost_open; /* RW; Range:[0, 1]; Open Frame Lost */
	int s32_avbr_frm_gap; /* RW; Range:[0, 100]; Maximim Gap of Frame Lost */
	int s32_avbr_pure_still_thr;
	unsigned char b_qp_map_en; /* RW; Range:[0, 1]; enable qpmap.*/
	venc_rc_qpmap_mode_e en_qp_map_mode; /* RW; Qpmap Mode*/
} venc_param_h265_avbr_s;

typedef struct _venc_param_h265_qvbr_s {
	unsigned int u32_min_iprop; /* the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* the max ratio of i frame and p frame */
	int s32_max_re_encode_times; /* max number of re-encode times [0, 3]*/

	unsigned char b_qp_map_en;
	venc_rc_qpmap_mode_e en_qp_map_mode;

	unsigned int u32_max_qp; /* the max P B qp */
	unsigned int u32_min_qp; /* the min P B qp */
	unsigned int u32_max_iqp; /* the max I qp */
	unsigned int u32_min_iqp; /* the min I qp */

	int s32_bit_percent_ul; /* Indicate the ratio of bitrate  upper limit*/
	int s32_bit_percent_ll; /* Indicate the ratio of bitrate  lower limit*/
	int s32_psnr_fluctuate_ul; /* Reduce the target bitrate when the value of psnr approch the upper limit */
	int s32_psnr_fluctuate_ll; /* Increase the target bitrate when the value of psnr approch the lower limit */
} venc_param_h265_qvbr_s;

/* The param of h265e ubr*/
typedef struct _venc_param_h265_ubr_s {
	unsigned int u32_min_iprop; /* RW; Range: [1, 100]; the min ratio of i frame and p frame */
	unsigned int u32_max_iprop; /* RW; Range: (u32_min_iprop, 100]; the max ratio of i frame and p frame */
	unsigned int u32_max_qp; /* RW; Range:(u32_min_qp, 51];the max QP value */
	unsigned int u32_min_qp; /* RW; Range:[0, 51];the min QP value */
	unsigned int u32_max_iqp; /* RW; Range:(u32_min_iqp, 51];max qp for i frame */
	unsigned int u32_min_iqp; /* RW; Range:[0, 51];min qp for i frame */
	int s32_max_re_encode_times; /* RW; Range:[0, 3]; Range:max number of re-encode times.*/
	unsigned char b_qp_map_en; /* RW; Range:[0, 1]; enable qpmap.*/
	venc_rc_qpmap_mode_e en_qp_map_mode; /* RW; Qpmap Mode*/
} venc_param_h265_ubr_s;

/* The param of rc*/
typedef struct _venc_rc_param_s {
	unsigned int u32_thrd_i[RC_TEXTURE_THR_SIZE]; // RW; Range:[0, 255]; Mad threshold for
	// controlling the macroblock-level bit rate of I frames
	unsigned int u32_thrd_p[RC_TEXTURE_THR_SIZE]; // RW; Range:[0, 255]; Mad threshold for
	// controlling the macroblock-level bit rate of P frames
	unsigned int u32_thrd_b[RC_TEXTURE_THR_SIZE]; // RW; Range:[0, 255]; Mad threshold for
	// controlling the macroblock-level bit rate of B frames
	/*RW; Range:[0, 16]; The direction for controlling the macroblock-level bit rate */
	unsigned int u32_direction_thrd;
	unsigned int u32_row_qp_delta;
	// RW; Range:[0, 10];the start QP value of each macroblock row relative to the start QP value
	int s32_first_frame_start_qp; /* RW; Range:[-1, 51];Start QP value of the first frame*/
	int s32_initial_delay;	// RW; Range:[10, 3000]; Rate control initial delay (ms).
	unsigned int u32_thrd_lv; /*RW; Range:[0, 4]; Mad threshold for controlling the macroblock-level bit rate */
	unsigned char b_bg_enhance_en; /* RW; Range:[0, 1];  Enable background enhancement */
	int s32_bg_delta_qp; /* RW; Range:[-51, 51]; Backgournd Qp Delta */
	union {
		venc_param_h264_cbr_s st_param_h264_cbr;
		venc_param_h264_vbr_s st_param_h264_vbr;
		venc_param_h264_avbr_s st_param_h264_avbr;
		venc_param_h264_qvbr_s st_param_h264_qvbr;
		venc_param_h264_ubr_s st_param_h264_ubr;
		venc_param_h265_cbr_s st_param_h265_cbr;
		venc_param_h265_vbr_s st_param_h265_vbr;
		venc_param_h265_avbr_s st_param_h265_avbr;
		venc_param_h265_qvbr_s st_param_h265_qvbr;
		venc_param_h265_ubr_s st_param_h265_ubr;
		venc_param_mjpeg_cbr_s st_param_mjpeg_cbr;
		venc_param_mjpeg_vbr_s st_param_mjpeg_vbr;
	};
} venc_rc_param_s;

/* the frame lost mode*/
typedef enum _venc_framelost_mode_e {
	FRMLOST_NORMAL = 0, /*normal mode*/
	FRMLOST_PSKIP, /*pskip*/
	FRMLOST_BUTT,
} venc_framelost_mode_e;

/* The param of the frame lost mode*/
typedef struct _venc_framelost_s {
	unsigned char b_frm_lost_open; // RW; Range:[0,1];Indicates whether to discard frames
	// to ensure stable bit rate when the instant bit rate is exceeded
	unsigned int u32_frm_lost_bps_thr; /* RW; Range:[64k, 163840k];the instant bit rate threshold */
	venc_framelost_mode_e frm_lost_mode_en; /* frame lost strategy*/
	unsigned int u32_enc_frm_gaps; /* RW; Range:[0,65535]; the gap of frame lost*/
} venc_framelost_s;

/* the rc priority*/
typedef enum _venc_rc_priority_e {
	VENC_RC_PRIORITY_BITRATE_FIRST = 1, /* bitrate first */
	VENC_RC_PRIORITY_FRAMEBITS_FIRST, /* framebits first*/
	VENC_RC_PRIORITY_BUTT,
} venc_rc_priority_e;

/* the config of the superframe */
typedef struct _venc_superframe_cfg_s {
	venc_superfrm_mode_e super_frm_mode_en;
	/* RW; Indicates the mode of processing the super frame */
	unsigned int u32_super_ifrm_bits_thr; // RW; Range:[0, 33554432];Indicate the threshold
	// of the super I frame for enabling the super frame processing mode
	unsigned int u32_super_pfrm_bits_thr; // RW; Range:[0, 33554432];Indicate the threshold
	// of the super P frame for enabling the super frame processing mode
	unsigned int u32_super_bfrm_bits_thr; // RW; Range:[0, 33554432];Indicate the threshold
	// of the super B frame for enabling the super frame processing mode
	venc_rc_priority_e en_rc_priority; /* RW; Rc Priority */
} venc_superframe_cfg_s;

#ifdef __cplusplus
#if __cplusplus
}
#endif
#endif /* __cplusplus */

#endif /* __COMM_RC_H__ */

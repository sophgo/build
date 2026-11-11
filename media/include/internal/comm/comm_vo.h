/*
 * Copyright (C) Cvitek Co., Ltd. 2019-2020. All rights reserved.
 *
 * File Name: include/comm_vo.h
 * Description:
 *   The common data type defination for VO module.
 */

#ifndef __COMM_VO_H__
#define __COMM_VO_H__

#include "common.h"
#include "comm_video.h"

#ifdef __cplusplus
#if __cplusplus
extern "C" {
#endif
#endif /* End of #ifdef __cplusplus */

#define VO_GAMMA_NODENUM 65
#define MAX_VO_PINS 32
#define MAX_MCU_INSTR 256

/* VO video output interface type */
typedef enum {
	VO_INTF_BT656 = (0x01L << 7),
	VO_INTF_BT1120 = (0x01L << 8),
	VO_INTF_PARALLEL_RGB = (0x01L << 9),
	VO_INTF_SERIAL_RGB = (0x01L << 10),
	VO_INTF_I80 = (0x01L << 11),
	VO_INTF_HW_MCU = (0x01L << 12),
	VO_INTF_MIPI = (0x01L << 13),
	VO_INTF_LVDS = (0x01L << 14),
	VO_INTF_BUTT
} vo_intf_type_e;

/* VO video output sync type */
typedef enum {
	VO_OUTPUT_PAL = 0, /* PAL standard*/
	VO_OUTPUT_NTSC, /* NTSC standard */
	VO_OUTPUT_1080P24, /* 1920 x 1080 at 24 Hz. */
	VO_OUTPUT_1080P25, /* 1920 x 1080 at 25 Hz. */
	VO_OUTPUT_1080P30, /* 1920 x 1080 at 30 Hz. */
	VO_OUTPUT_720P50, /* 1280 x  720 at 50 Hz. */
	VO_OUTPUT_720P60, /* 1280 x  720 at 60 Hz. */
	VO_OUTPUT_1080P50, /* 1920 x 1080 at 50 Hz. */
	VO_OUTPUT_1080P60, /* 1920 x 1080 at 60 Hz. */
	VO_OUTPUT_576P50, /* 720  x  576 at 50 Hz. */
	VO_OUTPUT_480P60, /* 720  x  480 at 60 Hz. */
	VO_OUTPUT_800x600_60, /* VESA 800 x 600 at 60 Hz (non-interlaced) */
	VO_OUTPUT_1024x768_60, /* VESA 1024 x 768 at 60 Hz (non-interlaced) */
	VO_OUTPUT_1280x1024_60, /* VESA 1280 x 1024 at 60 Hz (non-interlaced) */
	VO_OUTPUT_1366x768_60, /* VESA 1366 x 768 at 60 Hz (non-interlaced) */
	VO_OUTPUT_1440x900_60, /* VESA 1440 x 900 at 60 Hz (non-interlaced) CVT Compliant */
	VO_OUTPUT_1280x800_60, /* 1280*800@60Hz VGA@60Hz*/
	VO_OUTPUT_1600x1200_60, /* VESA 1600 x 1200 at 60 Hz (non-interlaced) */
	VO_OUTPUT_1680x1050_60, /* VESA 1680 x 1050 at 60 Hz (non-interlaced) */
	VO_OUTPUT_1920x1200_60, /* VESA 1920 x 1600 at 60 Hz (non-interlaced) CVT (Reduced Blanking)*/
	VO_OUTPUT_640x480_60, /* VESA 640 x 480 at 60 Hz (non-interlaced) CVT */
	VO_OUTPUT_720x1280_60, /* For MIPI DSI Tx 720 x1280 at 60 Hz */
	VO_OUTPUT_1080x1920_60, /* For MIPI DSI Tx 1080x1920 at 60 Hz */
	VO_OUTPUT_480x800_60, /* For MIPI DSI Tx 480x800 at 60 Hz */
	VO_OUTPUT_440x1920_60, /* For MIPI DSI Tx 440x1920 at 60 Hz */
	VO_OUTPUT_480x640_60, /* For MIPI DSI Tx 480x640 at 60 Hz */
	VO_OUTPUT_1440P60, /* 2560 x 1440 at 60 Hz. */
	VO_OUTPUT_2160P24, /* 3840 x 2160 at 24 Hz. */
	VO_OUTPUT_2160P25, /* 3840 x 2160 at 25 Hz. */
	VO_OUTPUT_2160P30, /* 3840 x 2160 at 30 Hz. */
	VO_OUTPUT_2160P50, /* 3840 x 2160 at 50 Hz. */
	VO_OUTPUT_2160P60, /* 3840 x 2160 at 60 Hz. */
	VO_OUTPUT_4096x2160P24, /* 4096 x 2160 at 24 Hz. */
	VO_OUTPUT_4096x2160P25, /* 4096 x 2160 at 25 Hz. */
	VO_OUTPUT_4096x2160P30, /* 4096 x 2160 at 30 Hz. */
	VO_OUTPUT_4096x2160P50, /* 4096 x 2160 at 50 Hz. */
	VO_OUTPUT_4096x2160P60, /* 4096 x 2160 at 60 Hz. */
	VO_OUTPUT_USER, /* User timing. */
	VO_OUTPUT_BUTT
} vo_intf_sync_e;

/*
 * synm: sync mode(0:timing,as BT.656; 1:signal,as LCD)
 * iop: interlaced or progressive display(0:i; 1:p)
 * frame_rate: frame-rate
 * vact: vertical active area
 * vbb: vertical back blank porch
 * vfb: vertical front blank porch
 * hact: horizontal active area
 * hbb: horizontal back blank porch
 * hfb: horizontal front blank porch
 * hpw: horizontal pulse width
 * vpw: vertical pulse width
 * idv: inverse data valid of output
 * ihs: inverse horizontal synch signal
 * ivs: inverse vertical synch signal
 */
typedef struct {
	bool synm;
	bool iop;

	unsigned short frame_rate;

	unsigned short vact;
	unsigned short vbb;
	unsigned short vfb;

	unsigned short hact;
	unsigned short hbb;
	unsigned short hfb;

	unsigned short hpw;
	unsigned short vpw;

	bool idv;
	bool ihs;
	bool ivs;
} vo_sync_info_s;

typedef enum {
	VO_MUX_BT_VS = 0,
	VO_MUX_BT_HS,
	VO_MUX_BT_HDE,
	VO_MUX_BT_DATA0,
	VO_MUX_BT_DATA1,
	VO_MUX_BT_DATA2,
	VO_MUX_BT_DATA3,
	VO_MUX_BT_DATA4,
	VO_MUX_BT_DATA5,
	VO_MUX_BT_DATA6,
	VO_MUX_BT_DATA7,
	VO_MUX_BT_DATA8,
	VO_MUX_BT_DATA9,
	VO_MUX_BT_DATA10,
	VO_MUX_BT_DATA11,
	VO_MUX_BT_DATA12,
	VO_MUX_BT_DATA13,
	VO_MUX_BT_DATA14,
	VO_MUX_BT_DATA15,
	VO_MUX_TG_HS_TILE = 30,
	VO_MUX_TG_VS_TILE,
	VO_MUX_BT_CLK,
	VO_BT_MUX_MAX,
} vo_mac_bt_mux_e;

typedef enum {
	VO_MUX_MCU_CS = 0,
	VO_MUX_MCU_RS,
	VO_MUX_MCU_WR,
	VO_MUX_MCU_RD,
	VO_MUX_MCU_DATA0,
	VO_MUX_MCU_DATA1,
	VO_MUX_MCU_DATA2,
	VO_MUX_MCU_DATA3,
	VO_MUX_MCU_DATA4,
	VO_MUX_MCU_DATA5,
	VO_MUX_MCU_DATA6,
	VO_MUX_MCU_DATA7,
	VO_MUX_MAX,
} vo_mac_i80_mux_e;

typedef enum {
	VO_CLK0 = 0,
	VO_CLK1,
	VO_D0,
	VO_D1,
	VO_D2,
	VO_D3,
	VO_D4,
	VO_D5,
	VO_D6,
	VO_D7,
	VO_D8,
	VO_D9,
	VO_D10,
	VO_D11,
	VO_D12,
	VO_D13,
	VO_D14,
	VO_D15,
	VO_D16,
	VO_D17,
	VO_D18,
	VO_D19,
	VO_D20,
	VO_D21,
	VO_D22,
	VO_D23,
	VO_D24,
	VO_D25,
	VO_D26,
	VO_D27,
	VO_D28,
	VO_D29,
	VO_D30,
	VO_D31,
	VO_D32,
	VO_D33,
	VO_D34,
	VO_D35,
	VO_D36,
	VO_D37,
	VO_D_MAX,
} vo_sel;

typedef enum {
	VO_VIVO_D0 = VO_D13,
	VO_VIVO_D1 = VO_D14,
	VO_VIVO_D2 = VO_D15,
	VO_VIVO_D3 = VO_D16,
	VO_VIVO_D4 = VO_D17,
	VO_VIVO_D5 = VO_D18,
	VO_VIVO_D6 = VO_D19,
	VO_VIVO_D7 = VO_D20,
	VO_VIVO_D8 = VO_D21,
	VO_VIVO_D9 = VO_D22,
	VO_VIVO_D10 = VO_D23,
	VO_VIVO_CLK = VO_CLK1,
	VO_MIPI_TXM4 = VO_D24,
	VO_MIPI_TXP4 = VO_D25,
	VO_MIPI_TXM3 = VO_D26,
	VO_MIPI_TXP3 = VO_D27,
	VO_MIPI_TXM2 = VO_D0,
	VO_MIPI_TXP2 = VO_CLK0,
	VO_MIPI_TXM1 = VO_D2,
	VO_MIPI_TXP1 = VO_D1,
	VO_MIPI_TXM0 = VO_D4,
	VO_MIPI_TXP0 = VO_D3,
	VO_MIPI_RXN5 = VO_D12,
	VO_MIPI_RXP5 = VO_D11,
	VO_MIPI_RXN2 = VO_D10,
	VO_MIPI_RXP2 = VO_D9,
	VO_MIPI_RXN1 = VO_D8,
	VO_MIPI_RXP1 = VO_D7,
	VO_MIPI_RXN0 = VO_D6,
	VO_MIPI_RXP0 = VO_D5,
	VO_JTAG_CPU_TMS = VO_D28,
	VO_JTAG_CPU_TCK = VO_D29,
	VO_JTAG_CPU_TRST = VO_D30,
	VO_AUX0 = VO_D31,
	VO_SD1_D3 = VO_D32,
	VO_SD1_D2 = VO_D33,
	VO_SD1_D1 = VO_D34,
	VO_SD1_D0 = VO_D35,
	VO_SD1_CMD = VO_D36,
	VO_SD1_CLK = VO_D37,
	VO_PAD_MAX = VO_D_MAX,
} vo_mac_d_sel_e;

typedef struct {
	vo_mac_d_sel_e sel;
	unsigned int mux;
} vo_d_remap_s;

typedef enum {
	VO_BT_MODE_656 = 0,
	VO_BT_MODE_1120,
	VO_BT_MODE_601,
	VO_BT_MODE_MAX,
} vo_bt_mode_e;

typedef enum {
	VO_BT_DATA_SEQ0 = 0,
	VO_BT_DATA_SEQ1,
	VO_BT_DATA_SEQ2,
	VO_BT_DATA_SEQ3,
} vo_bt_data_seq_e;

typedef struct {
	unsigned char pin_num;
	bool bt_clk_inv;
	bool bt_vs_inv;
	bool bt_hs_inv;
	vo_bt_data_seq_e data_seq;
	vo_d_remap_s d_pins[MAX_VO_PINS];
} vo_bt_attr_s;

/* Define I80's cmd
 *
 * delay: ms to delay after instr
 * data_type: Data(1)/Command(0)
 * data: data to send
 */
typedef struct {
	unsigned char delay;
	unsigned char data_type;
	unsigned char data;
} vo_i80_instr_s;

/* Define PINMUX
 *
 * pin_num: Number of pins
 * d_pins: Pin mapping
 */
typedef struct {
	unsigned char pin_num;
	vo_d_remap_s d_pins[MAX_VO_PINS];
} vo_pinmux_s;

typedef enum {
	VO_MCU_MODE_RGB565 = 0,
	VO_MCU_MODE_RGB888,
	VO_MCU_MODE_MAX,
} vo_mcu_mode;

/* Define MCU Initialization
 *
 * instr_num: Initialization sequence num
 * instr_cmd: Initialization sequence
 */
typedef struct {
	unsigned char instr_num;
	vo_i80_instr_s instr_cmd[MAX_MCU_INSTR];
} vo_mcu_instr_s;

/* Define HW_MCU's config
 *
 * mode: fmt mode
 * pins: pin mapping
 * lcd_power_gpio_num: power gpio num
 * lcd_power_avtive: polarity
 * backlight_gpio_num: backlight gpio num
 * backlight_avtive: polarity
 * reset_gpio_num: reset gpio num
 * reset_avtive: polarity
 * instrs: Initialization sequence
 */
typedef struct {
	vo_mcu_mode mode;
	vo_pinmux_s pins;
	vo_mcu_instr_s instrs;
} vo_hw_mcu_cfg_s;

/*
 * bgcolor: Background color of a device, in RGB format.
 * intf_type: Type of a VO interface.
 * intf_sync: Type of a VO interface timing.
 * sync_info: Information about VO interface timings if customed type.
 */
typedef struct {
	unsigned int bgcolor;
	vo_intf_type_e intf_type;
	vo_intf_sync_e intf_sync;
	vo_sync_info_s sync_info;
	union {
		vo_hw_mcu_cfg_s stmcucfg;
	};
} vo_pub_attr_s;

typedef enum {
	VO_LVDS_MODE_JEIDA = 0,
	VO_LVDS_MODE_VESA,
	VO_LVDS_MODE_MAX,
} vo_lvds_mode_e;

typedef enum {
	VO_LVDS_OUT_6BIT = 0,
	VO_LVDS_OUT_8BIT,
	VO_LVDS_OUT_10BIT,
	VO_LVDS_OUT_MAX,
} vo_lvds_out_bit_e;

typedef enum {
	VO_LVDS_LANE_CLK = 0,
	VO_LVDS_LANE_0,
	VO_LVDS_LANE_1,
	VO_LVDS_LANE_2,
	VO_LVDS_LANE_3,
	VO_LVDS_LANE_MAX,
} vo_lvds_lane_e;

/* Define LVDS's config
 *
 * lvds_vesa_mode: true for VESA mode; false for JEIDA mode
 * out_bits: 6/8/10 bit
 * chn_num: output channel num
 * data_big_endian: true for big endian; false for little endian
 * lane_id: lane mapping, -1 no used
 * lane_pn_swap: lane pn-swap if true
 */
typedef struct {
	vo_lvds_mode_e lvds_vesa_mode;
	vo_lvds_out_bit_e out_bits;
	unsigned char chn_num;
	bool data_big_endian;
	vo_lvds_lane_e lane_id[VO_LVDS_LANE_MAX];
	bool lane_pn_swap[VO_LVDS_LANE_MAX];
} vo_lvds_attr_s;

/*
 * disp_rect: Display resolution
 * img_size: Original ImageSize.
 *              Only useful if vo support scaling, otherwise, it should be the same width disp_rect.
 * frame_rate: frame rate.
 * pixformat: Pixel format of the video layer
 * depth: Depth of layer done queue.
 */
typedef struct {
	rect_s disp_rect;
	size_s img_size;
	unsigned int frame_rate;
	pixel_format_e pixformat;
} vo_video_layer_attr_s;

typedef enum {
	VO_CSC_MATRIX_IDENTITY = 0,

	VO_CSC_MATRIX_601_LIMIT_YUV2RGB,
	VO_CSC_MATRIX_601_FULL_YUV2RGB,

	VO_CSC_MATRIX_709_LIMIT_YUV2RGB,
	VO_CSC_MATRIX_709_FULL_YUV2RGB,

	VO_CSC_MATRIX_601_LIMIT_RGB2YUV,
	VO_CSC_MATRIX_601_FULL_RGB2YUV,

	VO_CSC_MATRIX_709_LIMIT_RGB2YUV,
	VO_CSC_MATRIX_709_FULL_RGB2YUV,

	VO_CSC_MATRIX_BUTT
} vo_csc_matrix_e;

/*
 * csc_matrix: CSC matrix
 */
typedef struct {
	vo_csc_matrix_e csc_matrix;
} vo_csc_s;

/*
 * priority: Video out overlay priority.
 * rect: Rectangle of video output channel.
 * depth: Depth of video output channel done queue.
 */
typedef struct {
	unsigned int priority;
	rect_s rect;
} vo_chn_attr_s;

/*
 * chn_buf_used: Channel buffer that been occupied.
 */
typedef struct {
	unsigned int chn_buf_used;
} vo_query_status_s;

typedef struct {
	vo_dev dev;
	bool enable;
	bool osd_apply;
	unsigned int value[VO_GAMMA_NODENUM];
} vo_gamma_info_s;

typedef struct {
	vo_gamma_info_s gamma_info;
	unsigned int guard_magic;
} vo_bin_info_s;

typedef enum {
	VO_PAT_OFF = 0,
	VO_PAT_SNOW,
	VO_PAT_AUTO,
	VO_PAT_RED,
	VO_PAT_GREEN,
	VO_PAT_BLUE,
	VO_PAT_COLORBAR,
	VO_PAT_GRAY_GRAD_H,
	VO_PAT_GRAY_GRAD_V,
	VO_PAT_BLACK,
	VO_PAT_MAX,
} vo_pattern_mode_e;

#ifdef __cplusplus
#if __cplusplus
}
#endif
#endif /* End of #ifdef __cplusplus */

#endif /* End of #ifndef __COMM_VO_H__ */

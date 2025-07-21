#ifndef _COMM_GFBG_H_
#define _COMM_GFBG_H_

#include <linux/fb.h>
#include <linux/ioctl.h>

#ifdef __cplusplus
#if __cplusplus
extern "C"{
#endif
#endif /* __cplusplus */

#define IOC_TYPE_GFBG       'G'

#define DRV_GFBG_IOCTL_CMD_NUM_MIN 10
#define DRV_GFBG_IOCTL_CMD_NUM_MAX 100

/* To get the origin of an overlay layer on the screen */
#define FBIOGET_SCREEN_ORIGIN_GFBG	_IOR(IOC_TYPE_GFBG, 10, fb_point)
/* To set the origin of an overlay layer on the screen */
#define FBIOPUT_SCREEN_ORIGIN_GFBG	_IOW(IOC_TYPE_GFBG, 11, fb_point)
/* To obtain the display state of an overlay layer */
#define FBIOGET_SHOW_GFBG		_IOR(IOC_TYPE_GFBG, 12, bool)
/* To set the display state of an overlay layer */
#define FBIOPUT_SHOW_GFBG		_IOW(IOC_TYPE_GFBG, 13, bool)
/* get the screen output size */
#define FBIOGET_SCREEN_SIZE		_IOR(IOC_TYPE_GFBG, 14, fb_size)
/* set the screen output size */
#define FBIOPUT_SCREEN_SIZE		_IOW(IOC_TYPE_GFBG, 15, fb_size)
/* To wait for the vertical blanking region of an overlay layer */
#define FBIOGET_VER_BLANK_GFBG		_IO(IOC_TYPE_GFBG, 16)
/* To obtain the colorkey of an overlay layer */
#define FBIOGET_COLORKEY_GFBG		_IOR(IOC_TYPE_GFBG, 17, fb_colorkey)
/* To set the colorkey of an overlay layer */
#define FBIOPUT_COLORKEY_GFBG		_IOW(IOC_TYPE_GFBG, 18, fb_colorkey)
/* To get the layer information */
#define FBIOGET_LAYER_INFO		_IOR(IOC_TYPE_GFBG, 19, fb_layer_info)
/* To set the layer information */
#define FBIOPUT_LAYER_INFO		_IOW(IOC_TYPE_GFBG, 20, fb_layer_info)
/* To refresh the displayed contents in extended mode */
#define FBIO_REFRESH			_IOW(IOC_TYPE_GFBG, 21, fb_buf)
/* To get canvas buf */
#define FBIOGET_CANVAS_BUF		_IOR(IOC_TYPE_GFBG, 22, fb_buf)
/* To display multiple surfaces in turn and set the colorkey attributes */
#define FBIOFLIP_SURFACE		_IOW(IOC_TYPE_GFBG, 23, fb_surfaceex)
/* To set the compression function status of an overlay layer */
#define FBIOPUT_COMPRESSION_GFBG	_IOW(IOC_TYPE_GFBG, 24, bool)

typedef struct {
	u32 width;
	u32 height;
} fb_size;

typedef struct {
	bool enable;	/* colorkey enable flag */
	u32 value;		/* colorkey value */
} fb_colorkey;

typedef struct {
	int x;
	int y;
	int width;
	int height;
} fb_rect;

typedef struct {
	int x_pos;         /* <  horizontal position */
	int y_pos;         /* <  vertical position */
} fb_point;

typedef enum {
	FB_FORMAT_ARGB8888,	/* ARGB8888 */
	FB_FORMAT_ARGB4444,	/* ARGB4444 */
	FB_FORMAT_ARGB1555,	/* ARGB1555 */
	FB_FORMAT_LUT_256,	/* 256 LUT */
	FB_FORMAT_LUT_16,	/* 16 LUT */
	FB_FORMAT_BUTT
} fb_color_format;

/* refresh mode */
typedef enum {
	FB_LAYER_BUF_DOUBLE = 0x0,	/* 2 display buf in fb */
	FB_LAYER_BUF_ONE    = 0x1,	/* 1 display buf in fb */
	FB_LAYER_BUF_NONE   = 0x2,	/* no display buf in fb, the buf user refreshed will be directly set to VO */
	FB_LAYER_BUF_DOUBLE_IMMEDIATE = 0x3,	/* 2 display buf in fb, each refresh will be displayed */
	FB_LAYER_BUF_BUTT
} fb_layer_buf;

/* surface info */
typedef struct {
	u64 phys_addr;			/* start physical address */
	u32 width;			/* width pixels */
	u32 height;			/* height pixels */
	u32 pitch;			/* line pixels */
	fb_color_format format;		/* color format */
} fb_surface;

typedef struct {
	u64 phys_addr;
	fb_colorkey colorkey;
} fb_surfaceex;

/* refresh surface info */
typedef struct {
	fb_surface canvas;
	fb_rect update_rect;	/* refresh region */
} fb_buf;

/* layer info maskbit */
typedef enum {
	FB_LAYER_MASK_BUF_MODE = 0x1,			/* buf mode bitmask */
	FB_LAYER_MASK_POS = 0x4,			/* the position bitmask */
	FB_LAYER_MASK_CANVAS_SIZE = 0x8,		/* canvassize bitmask */
	FB_LAYER_MASK_DISPLAY_SIZE = 0x10,		/* displaysize bitmask */
	FB_LAYER_MASK_SCREEN_SIZE = 0x20,		/* screensize bitmask */
	FB_LAYER_MASK_BUTT
} fb_layer_info_maskbit;

/* layer info */
typedef struct {
	fb_layer_buf buf_mode;
	int x_pos;		/*  the x pos of origin point in screen */
	int y_pos;		/*  the y pos of origin point in screen */
	u32 canvas_width;	/*  the width of canvas buffer */
	u32 canvas_height;	/*  the height of canvas buffer */
	/* the width of display buf in fb.for 0 buf, there is no display buf in fb, so it's effectless */
	u32 display_width;
	u32 display_height;	/*  the height of display buf in fb. */
	u32 screen_width;	/*  the width of screen */
	u32 screen_height;	/*  the height of screen */
	u32 mask;		/*  param modify mask bit */
} fb_layer_info;

#ifdef __cplusplus
#if __cplusplus
}
#endif
#endif /* __cplusplus */


#endif /* _COMM_GFBG_H_ */

#ifndef __COMM_TDE_H__
#define __COMM_TDE_H__

#include "common.h"
#include "comm_video.h"

#define TDE_INVALID_HANDLE (-1)

typedef int tde_handle;


typedef struct _tde_surface_s {
	unsigned long long phy_addr;/* header address of a bitmap or the y component */
	unsigned int height;/* bitmap height */
	unsigned int width;/* bitmap width */
	unsigned int stride;/* stride of a bitmap */
	pixel_format_e color_fmt;
} tde_surface_s;

typedef enum _tde_rotate_angle_e {
	TDE_ROTATE_NONE = 0, /* no ratate */
	TDE_ROTATE_90, /* ratate 90 */
	TDE_ROTATE_270, /* ratate 270 */
	TDE_ROTATE_MAX
} tde_rotate_angle_e;

typedef struct _tde_line_s {
	int start_x;
	int start_y;
	int end_x;
	int end_y;
	unsigned int thick;
	unsigned int color;
} tde_line_s;

#endif

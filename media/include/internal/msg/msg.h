#ifndef __MSG_H__
#define __MSG_H__

/******************************************************************************
|----------------------------------------------------------------|
| |   MOD_ID	|	DEV_ID	|   CHN_ID	|	reserve	  |is blcok|
|----------------------------------------------------------------|
|<--8bits----><--8bits --><--8bits --><-----7bits----><---1bit--->|
******************************************************************************/

#define MODFD(MOD, DevID, ChnID) \
	((CVI_U32)(((MOD & 0xFF) << 24) | ((DevID & 0xFF) << 16) | ((ChnID & 0xFF) << 8)))

#define MODFD2(MOD, DevID, ChnID, isBlock) \
	((CVI_U32)(((MOD & 0xFF) << 24) | ((DevID & 0xFF) << 16) | ((ChnID & 0xFF) << 8) | (isBlock & 0x1)))

#define GET_MOD_ID(ModFd) \
	(((ModFd) >> 24) & 0xFF)

#define GET_DEV_ID(ModFd) \
	(((ModFd) >> 16) & 0xFF)

#define GET_CHN_ID(ModFd) \
	(((ModFd) >> 8) & 0xFF)

#define IS_BLOCK(ModFd) (ModFd & 0x1)

#define CVI_IPCMSG_MEDIA_PORT (1)
#define CVI_IPCMSG_SEND_SYNC_TIMEOUT (3000)

#define MSG_ACK  (0x11223344)


#endif

#ifndef __U_SYS_UAPI_H__
#define __U_SYS_UAPI_H__

#ifdef __cplusplus
	extern "C" {
#endif

#include "osal.h"
#ifndef __linux__
#include "osal_ioctl.h"
#endif


/* chip version list */
enum enum_chip_version {
	E_CHIPVERSION_U01 = 1,	//1
	E_CHIPVERSION_U02,	//2
};

/* chip power on reason list */
enum enum_chip_pwr_on_reason {
	E_CHIP_PWR_ON_COLDBOOT = 1,	//1
	E_CHIP_PWR_ON_WDT,	//2
	E_CHIP_PWR_ON_SUSPEND,	//3
	E_CHIP_PWR_ON_WARM_RST,	//4
};


#define SYS_IOC_MAGIC		'S'

#define SYS_IOC_SET_VIVPSSMODE			_IOW(SYS_IOC_MAGIC, 0x1, VI_VPSS_MODE_S)
#define SYS_IOC_GET_VIVPSSMODE			_IOR(SYS_IOC_MAGIC, 0x2, VI_VPSS_MODE_S)
#define SYS_IOC_READ_CHIP_ID			_IOR(SYS_IOC_MAGIC, 0x3, unsigned int)
#define SYS_IOC_READ_CHIP_VERSION		_IOR(SYS_IOC_MAGIC, 0x4, unsigned int)
#define SYS_IOC_READ_CHIP_PWR_ON_REASON	_IOR(SYS_IOC_MAGIC, 0x5, unsigned int)

#ifdef __cplusplus
	}
#endif

#endif /* __U_SYS_UAPI_H__ */

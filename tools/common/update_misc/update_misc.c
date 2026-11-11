#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>

#include <linux/reboot.h>
#include <sys/syscall.h>

#include "update_misc.h"

#define MAX_MISCDEV_LEN		32
#define MAX_PARAM_LEN		1024
#define MAX_PART_NAME_LEN	32
#define MAX_PART_TABLE_LEN	512

#define AVB_AB_MAX_PRIORITY 15

#define ARRAYSIZE(a) (sizeof(a) / sizeof((a)[0]))

enum device_type {
	DEVICE_UNKNOWN,
	DEVICE_MMC,
	DEVICE_NAND
};

struct partition_info {
	enum device_type device;
	int part_index;
};

enum rootfs_t {
	ROOTFS_NONE = 0,
	ROOTFS_A,
	ROOTFS_B,
	ROOTFS_R,
	ROOOTFS_NUM,
};

uint32_t crc32(unsigned char *buf, uint32_t size)
{
	uint32_t i, crc;

	crc = 0xFFFFFFFF;
	for (i = 0; i < size; i++)
		crc = crc32tab[(crc ^ buf[i]) & 0xff] ^ (crc >> 8);

	return crc^0xFFFFFFFF;
}

enum boot_system_type cvi_boot_system_detect(void)
{
	int fd = 0;
	int s32Ret = 0;
	void *cmdline_data;
	int len = 512 * sizeof(char);
	char *tmpbuf[len];

	fd = open("/proc/cmdline", O_RDWR);

	cmdline_data = malloc(len);
	s32Ret = read(fd, cmdline_data, len);

	if (s32Ret == 0) {
		printf("can not read data from cmdline\n");
		return BOOT_FROM_SYSTEM_UNKNOW;
	}

	memcpy(tmpbuf, cmdline_data, len);

	if (cmdline_data)
		free(cmdline_data);
	if (fd)
		close(fd);

	if (strstr((char *)tmpbuf, " _a"))
		return BOOT_FROM_SYSTEM_A;
	else if (strstr((char *)tmpbuf, " _b"))
		return BOOT_FROM_SYSTEM_B;
	else if (strstr((char *)tmpbuf, " _r"))
		return BOOT_FROM_SYSTEM_R;

	return BOOT_FROM_SYSTEM_UNKNOW;
}

static int extract_partition_name(const char *desc, char *name_buf, size_t buf_len)
{
	const char *start = strchr(desc, '(');
	const char *end = strchr(desc, ')');

	if (!start || !end || start >= end)
		return -1;

	size_t name_len = end - (start + 1);

	if (name_len >= buf_len)
		name_len = buf_len - 1;

	strncpy(name_buf, start + 1, name_len);
	name_buf[name_len] = '\0';

	return 0;
}

static int parse_mmc_partitions(const char *part_table, struct partition_info *result)
{
	char local_table[MAX_PART_TABLE_LEN];
	char *save_ptr = NULL;
	char *token = NULL;
	int index = 0;

	strncpy(local_table, part_table, sizeof(local_table) - 1);
	local_table[sizeof(local_table) - 1] = '\0';

	token = strtok_r(local_table, ",", &save_ptr);
	while (token != NULL) {
		index++;
		char part_name[MAX_PART_NAME_LEN];

		if (extract_partition_name(token, part_name, sizeof(part_name))) {
			token = strtok_r(NULL, ",", &save_ptr);
			continue;
		}

		if (strcmp(part_name, "MISC") == 0) {
			result->device = DEVICE_MMC;
			result->part_index = index;
			return 1;
		}
		token = strtok_r(NULL, ",", &save_ptr);
	}
	return 0;
}

static int parse_mtd_partitions(const char *part_table, struct partition_info *result)
{
	char local_table[MAX_PART_TABLE_LEN];
	char *save_ptr = NULL;
	char *token = NULL;
	int index = -1;

	strncpy(local_table, part_table, sizeof(local_table) - 1);
	local_table[sizeof(local_table) - 1] = '\0';

	token = strtok_r(local_table, ",", &save_ptr);
	while (token != NULL) {
		index++;
		char part_name[MAX_PART_NAME_LEN];

		if (extract_partition_name(token, part_name, sizeof(part_name))) {
			token = strtok_r(NULL, ",", &save_ptr);
			continue;
		}

		if (strcmp(part_name, "MISC") == 0) {
			result->device = DEVICE_NAND;
			result->part_index = index;
			return 1;
		}
		token = strtok_r(NULL, ",", &save_ptr);
	}
	return 0;
}

int find_misc_partition(const char *param_str, struct partition_info *result)
{
	const char *blkdevparts = strstr(param_str, "blkdevparts=");
	const char *mtdparts = strstr(param_str, "mtdparts=");

	if (blkdevparts) {
		const char *device_start = strstr(blkdevparts, "mmcblk");

		if (!device_start)
			return 0;

		const char *parts_start = strchr(device_start, ':');

		if (!parts_start)
			return 0;

		parts_start++;

		const char *parts_end = strchr(parts_start, ';');

		if (!parts_end)
			parts_end = param_str + strlen(param_str);

		char part_table[MAX_PART_TABLE_LEN];
		size_t len = parts_end - parts_start;

		if (len >= sizeof(part_table))
			len = sizeof(part_table) - 1;

		strncpy(part_table, parts_start, len);
		part_table[len] = '\0';

		return parse_mmc_partitions(part_table, result);
	}

	if (mtdparts) {
		const char *parts_start = strchr(mtdparts, ':');

		if (!parts_start)
			return 0;

		parts_start++;

		const char *parts_end = strchr(parts_start, ' ');

		if (!parts_end)
			parts_end = param_str + strlen(param_str);

		char part_table[MAX_PART_TABLE_LEN];
		size_t len = parts_end - parts_start;

		if (len >= sizeof(part_table))
			len = sizeof(part_table) - 1;

		strncpy(part_table, parts_start, len);
		part_table[len] = '\0';

		return parse_mtd_partitions(part_table, result);
	}

	return 0;
}

static int print_usage(int error_code)
{
	printf("\nUsage: update_misc [-b a|b] ");
	printf("  -s                        -- switch system to a|b|r\n");
	return error_code;
}

int main(int argc, char *argv[])
{
	int opt, i, n;
	enum rootfs_t rootfs = ROOTFS_NONE;
	char *rebootmode = NULL;

	int s32Ret = 0;
	int fd = 0;
	struct AvbABData ab_data;
	enum boot_system_type boot_type;

	char miscdev[MAX_MISCDEV_LEN] = { 0 };
	char cmdline[MAX_PARAM_LEN] = { 0 };
	struct partition_info info = { DEVICE_UNKNOWN, -1 };

	const char * const rootfs_str[] = {
		"none",
		"a",
		"b",
		"r",
	};

	while ((opt = getopt(argc, argv, "s:")) != EOF)
		switch (opt) {

		case 's':
			n = ARRAYSIZE(rootfs_str);
			for (i = 1; i < n; i++)
				if (!strcmp(optarg, rootfs_str[i]))	{
					rootfs = i;
					break;
				}
			break;

		case '?':
		case 'h':
		default:
			printf("Unkonw option --%c\n\n", opt);
			return print_usage(-1);
	}

	fd = open("/proc/cmdline", O_RDONLY);
	s32Ret = read(fd, cmdline, sizeof(cmdline));
	if (s32Ret == -1) {
		close(fd);
		printf("read fail with: %s\n", strerror(errno));
		return s32Ret;
	}
	close(fd);

	if (find_misc_partition(cmdline, &info)) {
		printf("device type: %s\n",
				(info.device == DEVICE_MMC) ? "MMC" :
				(info.device == DEVICE_NAND) ? "NAND" : "Unknown");
		printf("MISC partition index: %d\n\n", info.part_index);
	} else
		fprintf(stderr, "MISC partition not found\n\n");

	if (info.device == DEVICE_MMC)
		snprintf(miscdev, sizeof(miscdev), "/dev/mmcblk0p%d", info.part_index);
	else if (info.device == DEVICE_NAND)
		snprintf(miscdev, sizeof(miscdev), "/dev/mtd%d", info.part_index);
	else {
		fprintf(stderr, "unsupported flash\n\n");
		return -1;
	}

	fd = open(miscdev, O_RDWR);
	if (fd == -1) {
		printf("open MISC fail with: %s\n", strerror(errno));
		return -1;
	}

	s32Ret = read(fd, &ab_data, sizeof(struct AvbABData));
	if (s32Ret != sizeof(struct AvbABData)) {
		close(fd);
		printf("read fail with: %s\n", strerror(errno));
		return s32Ret;
	}

	if (memcmp(ab_data.magic, AVB_AB_MAGIC, AVB_AB_MAGIC_LEN) != 0) {
		close(fd);
		printf("AvbABData.magic error\n");
		return -1;
	}

	boot_type = cvi_boot_system_detect();

	if (rootfs != ROOTFS_NONE) {
		if (rootfs == ROOTFS_A) {
			rebootmode = "rootfsa";

			ab_data.slots[0].priority = AVB_AB_MAX_PRIORITY;
			ab_data.slots[1].priority = AVB_AB_MAX_PRIORITY - 1;

			if (boot_type == BOOT_FROM_SYSTEM_A)
				printf("warn: switch to system a in system a\n");
		} else if (rootfs == ROOTFS_B) {
			rebootmode = "rootfsb";

			ab_data.slots[0].priority = AVB_AB_MAX_PRIORITY - 1;
			ab_data.slots[1].priority = AVB_AB_MAX_PRIORITY;

			if (boot_type == BOOT_FROM_SYSTEM_B)
				printf("warn: switch to system b in system b\n");
		} else if (rootfs == ROOTFS_R) {
			rebootmode = "recovery";

			if (boot_type == BOOT_FROM_SYSTEM_R)
				printf("warn: switch to system r in system r\n");
		}
	} else {
		if (boot_type < BOOT_FROM_SYSTEM_R)
			ab_data.slots[boot_type].tries_remaining += 1;
	}

	printf("version_major=%u\n", ab_data.version_major);
	printf("version_minor=%u\n", ab_data.version_minor);
	printf("slots[0].priority=%u\n", ab_data.slots[0].priority);
	printf("slots[0].tries_remaining=%u\n", ab_data.slots[0].tries_remaining);
	printf("slots[0].successful_boot=%u\n", ab_data.slots[0].successful_boot);
	printf("slots[1].priority=%u\n", ab_data.slots[1].priority);
	printf("slots[1].tries_remaining=%u\n", ab_data.slots[1].tries_remaining);
	printf("slots[1].successful_boot=%u\n", ab_data.slots[1].successful_boot);
	printf("crc=%x\n", ab_data.crc32);

	ab_data.crc32 = crc32((unsigned char *)&ab_data, (sizeof(struct AvbABData) - sizeof(uint32_t)));
	printf("crc=%x\n", ab_data.crc32);

	lseek(fd, 0, SEEK_SET);
	s32Ret = write(fd, &ab_data, sizeof(struct AvbABData));
	if (s32Ret == -1)
		printf("write fail with: %s\n", strerror(errno));

	close(fd);

	if (rootfs != ROOTFS_NONE) {
		return syscall(__NR_reboot, LINUX_REBOOT_MAGIC1,
			LINUX_REBOOT_MAGIC2,
			LINUX_REBOOT_CMD_RESTART2, rebootmode);
	}

	return s32Ret;
}

#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>

#include "update_misc.h"

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

int main(int argc, char *argv[])
{
	(void)argc;
	(void)argv;
	int s32Ret = 0;
	int fd = 0;
	struct AvbABData ab_data;
	enum boot_system_type boot_type;

	fd = open("/dev/mmcblk0p5", O_RDWR);
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

	printf("version_major=%u\n", ab_data.version_major);
	printf("version_minor=%u\n", ab_data.version_minor);
	printf("slots[0].priority=%u\n", ab_data.slots[0].priority);
	printf("slots[0].tries_remaining=%u\n", ab_data.slots[0].tries_remaining);
	printf("slots[0].successful_boot=%u\n", ab_data.slots[0].successful_boot);
	printf("slots[1].priority=%u\n", ab_data.slots[1].priority);
	printf("slots[1].tries_remaining=%u\n", ab_data.slots[1].tries_remaining);
	printf("slots[1].successful_boot=%u\n", ab_data.slots[1].successful_boot);
	printf("crc=%x\n", ab_data.crc32);

	boot_type = cvi_boot_system_detect();
	if (boot_type <  BOOT_FROM_SYSTEM_R) {
		ab_data.slots[boot_type].tries_remaining += 1;
	}

	ab_data.crc32 = crc32((unsigned char *)&ab_data, (sizeof(struct AvbABData) - sizeof(uint32_t)));
	printf("crc=%x\n", ab_data.crc32);

	lseek(fd, 0, SEEK_SET);
	s32Ret = write(fd, &ab_data, sizeof(struct AvbABData));
	if (s32Ret == -1) {
		printf("write fail with: %s\n", strerror(errno));
	}

	close(fd);

	return s32Ret;
}

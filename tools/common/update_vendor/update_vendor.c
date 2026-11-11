#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/ioctl.h>

struct rk_vendor_req {
	uint32_t tag;
	uint16_t id;
	uint16_t len;
	uint8_t data[1024];
};

#define VENDOR_REQ_TAG		0x56524551
#define VENDOR_READ_IO		_IOW('v', 0x01, unsigned int)
#define VENDOR_WRITE_IO		_IOW('v', 0x02, unsigned int)

#define VENDOR_SN_ID		1 /* serialno */
#define VENDOR_WIFI_MAC_ID	2 /* wifi mac */
#define VENDOR_LAN_MAC_ID	3 /* lan mac */
#define VENDOR_BLUETOOTH_ID	4 /* bluetooth mac */
#define VENDOR_UPDATE_FLAG	14 /* for update flag */
#define VENDOR_MAX_ID		50 /* max id */

const char *VENDOR_DEV = "/dev/vendor_storage";

static int check_vendor_id(int id)
{
	if (id < VENDOR_SN_ID || id > VENDOR_MAX_ID) {
		printf("id error [%d] .\n", id);
		printf("1 SN\n");
		printf("2 WIFI MAC\n");
		printf("3 LAN MAC\n");
		printf("4 BLUETOOTH MAC\n");
		return -1;
	} else
		return 0;
}

static int mac_str_to_uint8(const char *mac_str, uint8_t mac[6])
{
	int values[6];

	if (!mac_str || !mac)
		return -1;

	if (sscanf(mac_str, "%x:%x:%x:%x:%x:%x",
			&values[0], &values[1], &values[2],
			&values[3], &values[4], &values[5]) != 6)
		return -1;

	for (int i = 0; i < 6; ++i) {
		if (values[i] < 0 || values[i] > 255)
			return -1;
		mac[i] = (uint8_t)values[i];
	}
	return 0;
}

int vendor_storage_read(int id, void *pbuf, int size)
{
	int fd = open(VENDOR_DEV, O_RDWR);
	int ret = 0;

	if (fd < 0) {
		printf("open %s failed\n", VENDOR_DEV);
		goto ERR_CLOSE;
	}

	struct rk_vendor_req *req = (struct rk_vendor_req *)malloc(sizeof(struct rk_vendor_req));

	if (req == NULL) {
		printf("malloc rk_vendor_req failed\n");
		goto ERR_CLOSE;
	}

	req->tag = VENDOR_REQ_TAG;
	req->id = id;
	req->len = size;
	memset(req->data, 0, sizeof(req->data));

	ret = ioctl(fd, VENDOR_READ_IO, req);
	if (ret < 0) {
		printf("read vendor failed, id = %d, ret = %d\n", id, ret);
		goto ERR_FREE;
	}

	memcpy(pbuf, req->data, req->len);
ERR_FREE:
	free(req);
ERR_CLOSE:
	close(fd);
	return 0;
}

int vendor_storage_write(int id, void *pbuf, int size)
{
	int fd = open(VENDOR_DEV, O_RDWR);
	int ret = 0;

	if (fd < 0) {
		printf("open %s failed\n", VENDOR_DEV);
		goto ERR_CLOSE;
	}

	struct rk_vendor_req *req = (struct rk_vendor_req *)malloc(sizeof(struct rk_vendor_req));

	if (req == NULL) {
		printf("malloc rk_vendor_req failed\n");
		goto ERR_CLOSE;
	}

	req->tag = VENDOR_REQ_TAG;
	req->id = id;
	req->len = size;
	memcpy(req->data, pbuf, size);

	ret = ioctl(fd, VENDOR_WRITE_IO, req);
	if (ret < 0) {
		printf("write vendor failed, id = %d, ret = %d\n", id, ret);
		goto ERR_FREE;
	}

ERR_FREE:
	free(req);
ERR_CLOSE:
	close(fd);
	return 0;
}

void print_help(char **argv)
{
	printf("usage: %s r <id>\n", argv[0]);
	printf("usage: %s w <id> <data>\n", argv[0]);
	printf("id:\n");
	printf("    1 SN\n");
	printf("    2 WIFI MAC\n");
	printf("    3 LAN MAC\n");
	printf("    4 BLUETOOTH MAC\n");
}

int main(int argc, char **argv)
{
	char info_str[1024] = {0};
	int id = 0;
	int ret = 0;
	uint8_t mac[6];

	if (argc < 2) {
		print_help(argv);
		return -1;
	}

	id = atoi(argv[2]);

	if (check_vendor_id(id)) {
		printf("id error [%d] .\n", id);
		print_help(argv);
		return -1;
	}

	if (argv[1][0] == 'r') {

		printf("read vendor %d\n", id);
		if (id == VENDOR_WIFI_MAC_ID)
			ret = vendor_storage_read(id, mac, 6);
		else
			ret = vendor_storage_read(id, info_str, 1024);

		if (ret < 0) {
			printf("read vendor failed, id = %d, ret = %d\n", id, ret);
			return -1;
		}

		if (id == VENDOR_WIFI_MAC_ID)
			printf("mac: %02x:%02x:%02x:%02x:%02x:%02x\n", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
		else
			printf("info_str: %s\n", info_str);

	} else if (argv[1][0] == 'w') {
		if (argc < 3) {
			print_help(argv);
			return -1;
		}

		printf("write vendor %d, %s\n", id, argv[3]);
		if (id == VENDOR_WIFI_MAC_ID) {
			if (mac_str_to_uint8(argv[3], mac)) {
				printf("mac format error\n");
				return -1;
			}
			ret = vendor_storage_write(id, mac, 6);
		} else
			ret = vendor_storage_write(id, argv[3], strlen(argv[3]));

		if (ret < 0) {
			printf("write vendor failed, id = %d, ret = %d\n", id, ret);
			return -1;
		}
	}
	return 0;
}

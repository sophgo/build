#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <crc16.h>

#define     ALIGN           (0x1000)    // chunk_crc_offset and chunk_crc_size align
#define     FILE_BUF_SIZE   (16*1024)
#define     CRC_TAG         (0x5a54)

char *in_file_path = NULL;
char *out_file_path = NULL;


struct head {
	uint32_t magic;
	uint32_t version;
	uint32_t file_sz;
    uint32_t file_crc_value;
    uint32_t chunk_crc_offset;
    uint32_t chunk_crc_size;
    uint32_t chunk_crc_value;
	uint32_t part_offset;
	uint32_t part_size;
    uint8_t reserve[128-36];
} header;


int32_t gen_image(const char *in_filename, const char *out_filename)
{
    int32_t ret = -1;
    uint32_t rdlen;
    uint32_t crc = 0;
    uint32_t crcbuf_size;
    uint8_t *crcbuf = NULL;

    if(!in_filename || !out_filename){
        printf("bad parameter\n");
        return ret;
    }
    if(access(in_filename, F_OK|R_OK)!=0){
        printf("file not exist or reading file has not permission\n");
        return ret;
    }

    FILE *infile = NULL;
    if((infile = fopen(in_filename, "r"))==NULL){
        printf("to do crc 32 check, open file error\n");
        return ret;
    }
    FILE *outfile = NULL;
    if((outfile = fopen(out_filename, "w"))==NULL){
        printf("open file error\n");
        return ret;
    }
    crcbuf_size = (FILE_BUF_SIZE > header.chunk_crc_size) ? FILE_BUF_SIZE : header.chunk_crc_size;
    crcbuf = malloc(crcbuf_size);
    if(!crcbuf){
        printf("malloc 0x%x byte error\n", crcbuf_size);
        goto exit;
    }

    // get file size
    if(fseek(infile, 0, SEEK_END) != 0){
		printf("fseek failed\n");
		goto exit;
	}
    header.file_sz = ftell(infile);
    if(header.chunk_crc_offset + header.chunk_crc_size > header.file_sz){
        printf("crc region illegal\n");
        goto exit; 
    }

    // get file crc
    if(fseek(infile, 0, SEEK_SET) != 0){
		printf("fseek failed\n");
		goto exit;
	}
    crc = 0;
    while((rdlen=fread(crcbuf, sizeof(uint8_t), crcbuf_size, infile))>0){
        crc = crc16_ccitt_with_tag(crcbuf, rdlen, CRC_TAG);
    }
    header.file_crc_value = crc;

    // get chunk crc
    if(fseek(infile, header.chunk_crc_offset, SEEK_SET) != 0){
		printf("fseek failed\n");
		goto exit;
	}
    if(fread(crcbuf, sizeof(uint8_t), header.chunk_crc_size, infile) != header.chunk_crc_size){
        printf("read file error\n");
        goto exit;
    }
    crc = 0;
    header.chunk_crc_value = crc16_ccitt_with_tag(crcbuf, header.chunk_crc_size, CRC_TAG);

    // write head
    fseek(outfile, 0, SEEK_SET);
    if(sizeof(header) != fwrite(&header, sizeof(uint8_t), sizeof(header), outfile)){
        printf("write head error\n");
        goto exit;
    }

    // write body 
    if(fseek(outfile, sizeof(header), SEEK_SET) != 0){
        printf("fseek failed\n");
		goto exit;
    }
    if(fseek(infile, 0, SEEK_SET) != 0){
		printf("fseek failed\n");
		goto exit;
	}
    while((rdlen=fread(crcbuf, sizeof(uint8_t), crcbuf_size, infile))>0){
        if(rdlen != fwrite(crcbuf, sizeof(uint8_t), rdlen, outfile)){
            printf("write file error\n");
            goto exit;
        }
    }

    ret=0;
exit:
    fclose(infile);
    fclose(outfile);
    free(crcbuf);
    return ret;
}

void print_head(void)
{
    printf("HEAD:\n"
            "   magic: 0x%x\n"
            "   version: 0x%x\n"
            "   file_sz: 0x%x\n"
            "   file_crc_value: 0x%x\n"
            "   chunk_crc_offset: 0x%x\n"
            "   chunk_crc_size: 0x%x\n"
            "   chunk_crc_value: 0x%x\n"
            "   part_offset: 0x%x\n"
            "   part_size: 0x%x\n",
            header.magic, header.version, header.file_sz, header.file_crc_value,
            header.chunk_crc_offset, header.chunk_crc_size, header.chunk_crc_value,
            header.part_offset, header.part_size);
}

int param_parse(int argc, char *argv[])
{
    char *ptr=NULL;
    if(argc != 9){
        return -1;
    }
    memset(&header, 0xff, sizeof(header));
    header.magic = strtoul(argv[1], &ptr, 16);
    header.version = strtoul(argv[2], &ptr, 16);
    header.chunk_crc_offset = strtoul(argv[3], &ptr, 16); 
    header.chunk_crc_size = strtoul(argv[4], &ptr, 16);
    header.part_offset = strtoul(argv[5], &ptr, 16); 
    header.part_size = strtoul(argv[6], &ptr, 16);
    in_file_path = argv[7];
    out_file_path = argv[8];
    
    if(header.chunk_crc_offset & (ALIGN-1)){
        printf("crc offset must be align 0x%x\n", ALIGN);
        return -1;
    }

    if((header.chunk_crc_size & (ALIGN-1)) || (header.chunk_crc_size == 0)){
        printf("crc size must be align 0x%x, and no equal 0\n", ALIGN);
        return -1;
    }

    return 0;
}

int main(int argc, char *argv[])
{
    int ret;

    ret = param_parse(argc, argv);
    if(ret){
        printf("param parse error\n");
        return -1;
    }
    gen_image(in_file_path, out_file_path);
    print_head();

    return 0;
}

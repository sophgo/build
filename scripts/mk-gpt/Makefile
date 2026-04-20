.PHONY: clean out

out:
	gcc mk_gpt.c crc.c -Werror -luuid -lxml2 -lm -I /usr/include/libxml2 -o ../mk_gpt
	gcc mk_sector_gpt.c crc.c -Werror -luuid -lxml2 -lm -I /usr/include/libxml2 -o ../mk_sector_gpt

clean:
	rm ../mk_gpt
	rm ../mk_sector_gpt

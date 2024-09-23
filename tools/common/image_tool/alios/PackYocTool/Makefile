CFLAGS += -static 

CFLAGS += -I./

src += PackYocTool.o
src += crc16.o

PackYocTool: $(src)
	gcc -o $@ $^ $(CFLAGS)
	chmod 777 $@


clean:
	# @rm -f  PackYocTool
	@rm -f *.o

SHELL = /bin/bash

ifeq ($(SDK_VER), 32bit)
  export CROSS_COMPILE = $(CROSS_COMPILE_32)
  OPT_LEVEL := -O3
else ifeq ($(SDK_VER), 64bit)
  export CROSS_COMPILE = $(CROSS_COMPILE_64)
  OPT_LEVEL := -O3
else ifeq ($(SDK_VER), uclibc)
  export CROSS_COMPILE = $(CROSS_COMPILE_UCLIBC)
  OPT_LEVEL := -Os
else ifeq ($(SDK_VER), glibc_riscv64)
  export CROSS_COMPILE = $(CROSS_COMPILE_GLIBC_RISCV64)
  OPT_LEVEL := -Os
  OPT_LEVEL += -mcpu=c906fdv -march=rv64imafdcv0p7xthead -mcmodel=medany -mabi=lp64d
else ifeq ($(SDK_VER), musl_riscv64)
  export CROSS_COMPILE = $(CROSS_COMPILE_MUSL_RISCV64)
  OPT_LEVEL := -Os
  OPT_LEVEL += -mcpu=c906fdv -march=rv64imafdcv0p7xthead -mcmodel=medany -mabi=lp64d
endif

## GCC COMPILER ##
CC = $(CROSS_COMPILE)gcc
CXX = $(CROSS_COMPILE)g++
AR = $(CROSS_COMPILE)ar
LD = $(CROSS_COMPILE)ld
NM = $(CROSS_COMPILE)nm
RANLIB = $(CROSS_COMPILE)ranlib
STRIP = $(CROSS_COMPILE)strip
OBJCOPY = $(CROSS_COMPILE)objcopy

WARNING_LEVEL=-Wall -Wextra -Werror

#Generate object files by CC
CFLAGS   = $(OPT_LEVEL) -std=gnu11 -g $(WARNING_LEVEL)
#Generate object files by CXX
CXXFLAGS = $(OPT_LEVEL) -std=gnu++11 -g $(WARNING_LEVEL)

SDIR = ./
SRCS = $(wildcard $(SDIR)/*.c)
OBJS = $(SRCS:.c=.o)
DEPS = $(SRCS:.c=.d)

TARGET = update_misc

.PHONY : clean all
all : $(TARGET)

$(COMMON_DIR)/%.o: $(COMMON_DIR)/%.c
	@$(CC) $(DEPFLAGS) $(CFLAGS) $(EXTRA_CFLAGS) -o $@ -c $<
	@echo [$(notdir $(CC))] $(notdir $@)

$(SDIR)/%.o: $(SDIR)/%.c
	@$(CC) $(DEPFLAGS) $(CFLAGS) $(EXTRA_CFLAGS) -o $@ -c $<
	@echo [$(notdir $(CC))] $(notdir $@)

$(TARGET) : $(COMM_OBJ) $(OBJS)
	@$(CXX) -o $@  $(OBJS) $(COMM_OBJS) $(ELFFLAGS) $(EXTRA_LDFLAGS)
	@echo -e $(BLUE)[LINK]$(END)[$(notdir $(CXX))] $(notdir $@)

clean:
	@rm -f $(OBJS) $(TARGET)

-include $(DEPS)

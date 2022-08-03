# ==========================================
#  Assignment2 Makefile
# ==========================================

#We try to detect the OS we are running on, and adjust commands as needed
C_COMPILER=gcc

ifdef CROSS_COMPILE 
COMPILER=$(CROSS_COMPILE)$(C_COMPILER)
else
COMPILER=$(C_COMPILER)
endif

CLEANUP = rm -f

CFLAGS += -Wall
CFLAGS += -Wextra

BUILD_ROOT=.

SRC_FILE=$(BUILD_ROOT)/writer.c
TGT_FILE=$(BUILD_ROOT)/writer

all: clean default

default: 
	$(COMPILER) $(CFLAGS) $(SRC_FILE) -o $(TGT_FILE)

clean:
	$(CLEANUP) $(TGT_FILE)

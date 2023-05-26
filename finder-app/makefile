# ==========================================
#  Assignment2 Makefile
# ==========================================

# Update makefile for buildroot cross compile
CLEANUP = rm -f

BUILD_ROOT=.

SRC_FILE=$(BUILD_ROOT)/writer.c
TGT_FILE=$(BUILD_ROOT)/writer

all: clean default

default: 
	$(CC) $(LDFLAGS) $(SRC_FILE) -o $(TGT_FILE)

clean:
	$(CLEANUP) $(TGT_FILE)

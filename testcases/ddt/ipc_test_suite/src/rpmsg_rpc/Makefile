# MakeFile function     :: MakeFile for compiling rpc_test

top_srcdir              ?= ../../../../..

include $(top_srcdir)/include/mk/env_pre.mk

INSTALL_DIR             := testcases/bin/ddt

FILTER_OUT_DIRS         :=

#List of source files- Update this on adding a new C file
SOURCES := \
        tests_rpc_stress.c

# We don't want to copy over the Makefile
UNWANTED_FILES          := Makefile \
                           rpmsg-rpc-stress.use \
                           ${SOURCES}

INSTALL_MODE            := 00755

CFLAGS          += -g -Wall -O1 -fomit-frame-pointer
LDFLAGS         += -g 
LDLIBS          += -lpthread
#INCLUDES        = -I $(KERNEL_USR_INC) #changing to kernel headers to workaround uapi header export bug
INCLUDES        = -I$(KERNEL_INC)/uapi -I$(KERNEL_INC)/include/uapi 

MAKE_TARGETS            := test_rpmsg_rpc

test_rpmsg_rpc:
	$(CC) -o test_rpmsg_rpc ${INCLUDES} ${SOURCES} ${CFLAGS} ${LDFLAGS} $(LDLIBS)

include $(top_srcdir)/include/mk/generic_leaf_target.mk

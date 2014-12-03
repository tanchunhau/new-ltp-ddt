# MakeFile function     :: MakeFile for compiling IPC kernel module

top_srcdir              ?= ../../../../../..

include $(top_srcdir)/include/mk/env_pre.mk

INSTALL_DIR             := testcases/bin/ddt

FILTER_OUT_DIRS         :=

# We don't want to copy over the Makefile
UNWANTED_FILES          := Makefile

INSTALL_MODE            := 00755

MAKE_TARGETS    :=

ifneq (,$(findstring $(PLATFORM),$(PLATFORMSwIPC)))
	MAKE_TARGETS    := $(wildcard ./*.ko)
endif

include $(top_srcdir)/include/mk/generic_leaf_target.mk

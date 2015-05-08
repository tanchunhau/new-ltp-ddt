# MakeFile function     :: MakeFile for compiling DMTIMER-TEST kernel module 

LDFLAGS         += -g -static
INCLUDES        = -I ../utils/user  -I $(KERNEL_DIR)/include  
EXTRA_CFLAGS	+= -I$(src)/arch/arm/plat-omap/include/plat

#List of source files for kernel module - Update this on adding a new C file
SOURCES_KERNEL := \
	testcases/dmtimer-test.o \

obj-m += dmtimer-test.o
dmtimer-test-objs := $(SOURCES_KERNEL)

MAKE_TARGETS		:= modules

modules:
	$(MAKE) -C $(KERNEL_DIR) ARCH=arm SUBDIRS=$(PWD) modules
	cp dmtimer-test.ko  ../../

clean:
	rm -f */*.o
	rm -f ../../*.ko
	rm -f  *.o
	rm -f  .*.cmd
	rm -rf  .tmp_versions/
	rm -f  *.order
	rm -f  *.c
	rm -f  *.symvers
	rm -f  ./testcases/*.o*
	rm -f  ./testcases/.*.cmd
	rm -f  ../../../utils/kernel/*.ko
	rm -f  ../../../utils/kernel/*.o
	rm -f  ../../../utils/kernel/*.mod.*
	rm -f  ../../../utils/kernel/.*.cmd
	rm -f  *.o
	rm -f *.*


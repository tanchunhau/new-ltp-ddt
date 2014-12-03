LDFLAGS         += -g -static
INCLUDES        = -I $(KERNEL_DIR)/include

obj-m += coproc_devfreq.o 

MAKE_TARGETS		:= modules

modules:
	$(MAKE) -C $(KERNEL_DIR) ARCH=arm SUBDIRS=$(PWD) modules
	cp coproc_devfreq.ko  ../../
	
clean:
	rm -f */*.o
	rm -f ../../*.ko
	rm -f  *.o
	rm -f  .*.cmd
	rm -rf  .tmp_versions/
	rm -f  *.order
	rm -f  *.symvers
	rm -f  ./testcases/*.o*
	rm -f  ./testcases/.*.cmd
	rm -f  ../../../utils/kernel/*.ko
	rm -f  ../../../utils/kernel/*.o
	rm -f  ../../../utils/kernel/*.mod.*
	rm -f  ../../../utils/kernel/.*.cmd
	rm -f  *.o
	rm -f *.ko
	rm -f *.mod.c


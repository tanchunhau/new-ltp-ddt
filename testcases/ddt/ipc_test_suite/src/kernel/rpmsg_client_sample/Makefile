
obj-m += rpmsg_client_sample.o

MAKE_TARGETS := modules

modules:
	$(MAKE) -C $(KERNEL_DIR) ARCH=arm SUBDIRS=$(PWD) modules

clean:
	$(RM) -r *.o *.ko *.mod.c .*.cmd .tmp_versions *.symvers modules.order


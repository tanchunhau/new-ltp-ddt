# MakeFile function     :: MakeFile for compiling IPC kernel module 


obj-m = iommu_test.o
iommu_test-objs = iommu.o

MAKE_TARGETS		:= modules

modules:
	make -C $(KERNEL_DIR) ARCH=arm SUBDIRS=$(PWD) modules
	cp *.ko  ../../

clean:
	$(RM) -r *.o *.ko *.mod.c .*.cmd .tmp_versions *.symvers modules.order

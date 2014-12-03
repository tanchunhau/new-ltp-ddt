# MakeFile function     :: MakeFile for compiling IPC kernel modules

MODULES_DIR = $(PWD)/modules

IPC_SUBDIRS = rpmsg_client_sample

modules:
	for dir in $(IPC_SUBDIRS); do \
		cd $$dir; $(MAKE) modules; cp *.ko $(MODULES_DIR); cd ..;\
	done
	
clean:
	for dir in $(IPC_SUBDIRS); do \
		cd $$dir; $(MAKE) clean; cd ..;\
	done

.PHONY: clean modules

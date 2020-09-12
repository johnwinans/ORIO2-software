SUBDIRS=tank dump


ALL_DIRS=$(SUBDIRS:%=all-%)
CLEAN_DIRS=$(SUBDIRS:%=clean-%)

.PHONY: all clean world $(CLEAN_DIRS) $(ALL_DIRS)

all:: $(ALL_DIRS)

clean:: $(CLEAN_DIRS)

world:: clean all

# for each dir, do a make all
$(ALL_DIRS):
	$(MAKE) -C $(@:all-%=%) all

# for each dir, do a make clean
$(CLEAN_DIRS):
	$(MAKE) -C $(@:clean-%=%) clean

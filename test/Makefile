### Setup

junk_file = REMOVE_ME
CLEANUP_FILES += $(junk_file)

ARCHIVE_PREFIX = /archive/prefix

SOURCE_ARCHIVE = source.tar

COMPILED_ARCHIVE = compiled.tar
compiled_file = COMPILED
COMPILE_COMMAND = touch $(compiled_file)


### Include

include ../build.mk


### Tests

.DEFAULT_GOAL = test

.PHONY: test
test:
	@echo Running test cases
	$(Q)$(MAKE) clean; \
	$(MAKE) test-clean-should-remove-cleanup-file; $(RECORD_TEST_STATUS) \
	$(MAKE) test-source-archive-should-contain-source-file; $(RECORD_TEST_STATUS) \
	$(MAKE) test-compiled-archive-should-contain-compiled-file; $(RECORD_TEST_STATUS) \
	$(RETURN_TEST_STATUS)


.PHONY: test-clean-should-remove-cleanup-file
test-clean-should-remove-cleanup-file:
	@echo $@
	$(Q)$(MAKE) clean && \
	touch $(junk_file) && \
	[ -f $(junk_file) ] && \
	$(MAKE) clean && \
	[ ! -f $(junk_file) ]


.PHONY: test-source-archive-should-contain-source-file
test-source-archive-should-contain-source-file:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) $(SOURCE_ARCHIVE) && \
	tar tf $(SOURCE_ARCHIVE) | grep ^archive/prefix/build.mk$$ >/dev/null


.PHONY: test-compiled-archive-should-contain-compiled-file
test-compiled-archive-should-contain-compiled-file:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) $(COMPILED_ARCHIVE) && \
	tar tf $(COMPILED_ARCHIVE) | grep ^archive/prefix/$(compiled_file)$$ >/dev/null

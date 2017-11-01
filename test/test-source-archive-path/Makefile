### Setup

ARCHIVE_PREFIX = /archive/prefix

SOURCE_ARCHIVE = source.tar
SOURCE_ARCHIVE_PATH = test


### Include

include ../../build.mk


### Tests

.PHONY: test-source-archive-should-be-limited-to-source-archive-path
test-source-archive-should-be-limited-to-source-archive-path:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) $(SOURCE_ARCHIVE) && \
	! tar tf $(SOURCE_ARCHIVE) | grep ^archive/prefix/build.mk$$ >/dev/null && \
	tar tf $(SOURCE_ARCHIVE) | grep ^archive/prefix/test/Makefile$$ >/dev/null && \
	! tar tf $(SOURCE_ARCHIVE) | grep ^archive/prefix/submodule/submodule-file$$ >/dev/null &&\
	tar tf $(SOURCE_ARCHIVE) | grep ^archive/prefix/test/submodule/submodule-file$$ >/dev/null



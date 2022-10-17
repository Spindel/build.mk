# Tests for build.mk

# Copyright (C) 2018 Modio AB

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


### Setup

junk_file = REMOVE_ME
CLEANUP_FILES += $(junk_file)

ARCHIVE_PREFIX = /archive/prefix

SOURCE_ARCHIVE = source.tar

COMPILED_ARCHIVE = compiled.tar
compiled_file = COMPILED
COMPILE_COMMAND = touch $(compiled_file)

ifeq ($(FEDORA_ROOT_RELEASE),)
  $(error You must set FEDORA_ROOT_RELEASE to reference a base-image)
endif
IMAGE_BUILD_FROM = registry.gitlab.com/modioab/base-image/fedora-$(FEDORA_ROOT_RELEASE)/python:latest
IMAGE_ARCHIVE = image.tar

ifneq ($(CI_REGISTRY_IMAGE),)
IMAGE_REPO = $(CI_REGISTRY_IMAGE)/test-container
endif

IMAGE_REPO ?= registry.gitlab.com/modioab/build.mk/test-container
repo_registry = $(firstword $(subst /, ,$(IMAGE_REPO)))
repo_path = $(subst $(repo_registry)/,,$(IMAGE_REPO))

### Include

include ../build.mk

ifneq ($(CI),)
_section_begin = printf '\e[0Ksection_start:'`date +%s`':%s\r\e[0K'
_section_end = printf '\e[0Ksection_end:'`date +%s`':%s\r\e[0K\n'
else
_section_begin = :
_section_end = :
endif

define _run_test =
$(_section_begin) $(1); $(MAKE) $(1); $(RECORD_TEST_STATUS) $(_section_end) $(1)
endef

### Tests

.DEFAULT_GOAL = test

MAKE += --no-print-directory

.PHONY: test
test:
	@echo Running test cases
	$(Q)$(MAKE) clean; \
	$(call _run_test,test-clean-should-remove-cleanup-file); \
	$(call _run_test,test-source-archive-should-contain-source-file); \
	$(call _run_test,test-source-archive-should-be-limited-to-source-archive-path); \
	$(call _run_test,test-compiled-archive-should-contain-compiled-file); \
	$(call _run_test,test-registry-should-be-correctly-set); \
	$(call _run_test,test-image-should-be-runnable); \
	$(call _run_test,test-image-without-test-should-be-testable); \
	$(call _run_test,test-image-with-working-test-should-succeed); \
	$(call _run_test,test-image-with-failing-test-should-fail); \
	$(call _run_test,test-image-no-pull-should-fail-properly); \
	$(call _run_test,test-image-should-be-republishable); \
	$(call _run_test,test-image-should-be-re-loadable); \
	$(call _run_test,test-build-volume-works); \
	$(call _run_test,test-build-args-works); \
	$(MAKE) clean; \
	$(RETURN_TEST_STATUS)


.PHONY: test-publish
test-publish:
	@echo Running test cases
	$(Q)$(MAKE) clean; \
	$(call _run_test,test-image-should-be-publishable); \
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
	tar tf $(SOURCE_ARCHIVE) | grep ^archive/prefix/build.mk$$ >/dev/null && \
	tar tf $(SOURCE_ARCHIVE) | grep ^archive/prefix/submodule/submodule-file$$ >/dev/null &&\
	tar tf $(SOURCE_ARCHIVE) | grep ^archive/prefix/test/submodule/submodule-file$$ >/dev/null



.PHONY: test-source-archive-should-be-limited-to-source-archive-path
test-source-archive-should-be-limited-to-source-archive-path:
	$(Q)$(MAKE) -C test-source-archive-path $@


.PHONY: test-compiled-archive-should-contain-compiled-file
test-compiled-archive-should-contain-compiled-file:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) $(COMPILED_ARCHIVE) && \
	tar tf $(COMPILED_ARCHIVE) | grep ^archive/prefix/$(compiled_file)$$ >/dev/null


.PHONY: test-registry-should-be-correctly-set echo_registry echo_repo
echo_registry:
	@echo "$(IMAGE_REGISTRY)"
echo_repo:
	@echo "$(_image_repo)"
test-registry-should-be-correctly-set:
	@echo $@
	$(Q)[ "$$($(MAKE) echo_registry CI_REGISTRY=)" == $(repo_registry) ]
	$(Q)[ "$$($(MAKE) echo_registry CI_REGISTRY=foo)" == foo ]
	$(Q)[ "$$($(MAKE) echo_registry CI_REGISTRY=foo IMAGE_REGISTRY=bar)" == bar ]
	$(Q)[ "$$($(MAKE) echo_repo CI_REGISTRY=)" == $(repo_registry)/$(repo_path) ]
	$(Q)[ "$$($(MAKE) echo_repo CI_REGISTRY=foo)" == foo/$(repo_path) ]
	$(Q)[ "$$($(MAKE) echo_repo CI_REGISTRY=foo IMAGE_REGISTRY=bar)" == bar/$(repo_path) ]
	$(Q)[ "$$($(MAKE) echo_repo CI_REGISTRY= IMAGE_REPO=/$(repo_path))" == localhost/$(repo_path) ]


.PHONY: test-image-should-be-runnable
test-image-should-be-runnable:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) $(IMAGE_ARCHIVE) && \
	$(MAKE) load
	$(MAKE) run-image
	$(MAKE) remove-local-image


.PHONY: test-image-without-test-should-be-testable
test-image-without-test-should-be-testable:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) $(IMAGE_ARCHIVE) && \
	$(MAKE) load
	$(MAKE) test-image
	$(MAKE) remove-local-image


.PHONY: test-image-with-working-test-should-succeed
test-image-with-working-test-should-succeed:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) $(IMAGE_ARCHIVE) && \
	$(MAKE) load
	$(MAKE) test-image IMAGE_TEST_CMD=/bin/true
	$(MAKE) remove-local-image


.PHONY: test-image-with-failing-test-should-fail
test-image-with-failing-test-should-fail:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) $(IMAGE_ARCHIVE) && \
	$(MAKE) load
	( ! $(MAKE) test-image IMAGE_TEST_CMD=/bin/false ) && :
	$(MAKE) remove-local-image


.PHONY: test-image-should-be-publishable
test-image-should-be-publishable:
	@echo $@
	$(Q)$(MAKE) clean
	$(Q)$(MAKE) build-publish


.PHONY: test-image-no-pull-should-fail-properly
test-image-no-pull-should-fail-properly:
	@echo $@
	$(Q)$(MAKE) clean
	( ! $(MAKE) PODMAN_PULL=--pull-never IMAGE_DOCKERFILE=Dockerfile.nofrom build ) && :
	$(MAKE) clean


.PHONY: test-image-should-be-re-loadable
test-image-should-be-re-loadable:
	@echo $@
	$(Q)$(MAKE) clean
	$(Q)$(MAKE) temp-publish
	$(Q)$(MAKE) test-image IMAGE_TEST_CMD=/bin/true
	$(Q)$(MAKE) clean
	$(MAKE) temp-pull
	$(Q)$(MAKE) test-image IMAGE_TEST_CMD=/bin/true
	$(Q)$(MAKE) remove-local-image


.PHONY: test-image-should-be-republishable
test-image-should-be-republishable:
	@echo $@
	$(Q)$(MAKE) clean
	$(Q)$(MAKE) temp-publish
	# Important to get rid of any tarballs
	$(Q)$(MAKE) clean
	$(Q)$(MAKE) temp-pull
	$(Q)$(MAKE) publish


.PHONY: test-build-volume-works
test-build-volume-works:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) IMAGE_BUILD_VOLUME=$(shell pwd) IMAGE_DOCKERFILE=Dockerfile.volume $(IMAGE_ARCHIVE) && \
	$(MAKE) load
	$(MAKE) run-image
	$(MAKE) remove-local-image


.PHONY: test-build-args-works
test-build-args-works:
	@echo $@
	$(Q)$(MAKE) clean && \
	$(MAKE) IMAGE_BUILD_ARGS="--build-arg=FLUMMOXED=scratch" IMAGE_DOCKERFILE=Dockerfile.args $(IMAGE_ARCHIVE) && \
	$(MAKE) load
	$(MAKE) run-image
	$(MAKE) remove-local-image

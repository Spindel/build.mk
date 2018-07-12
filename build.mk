## By setting certain variables before including build.mk in your
## makefile you can set up some commonly used make rules for building
## docker images.

## Variables with uppercase names are used as the public interface
## for build.mk.
##
## Variables with lowercase names are considered private to the
## including makefile.
##
## Variables having names starting with underscore are considered
## private to build.mk.


## The fallback default goal does nothing. Set the variable
## .DEFAULT_GOAL to change the default goal for your makefile, or
## specify a rule before including build.mk if that is appropriate.

default:


# Set V=1 to echo the make recipes. Recipes are always echoed for CI
# builds.

ifeq ($(CI),)
ifneq ($(V),1)
Q = @
endif
endif

# Some environments, like CI, don't declare a TERM variable, thus we
# guess.

TERM ?= dumb

# $(call _cmd,example) expands to the contents of _cmd_example
# variable. It should contain a series of commands suitable for a make
# recipe. Each command in the variable should be preceded with $(Q).
#
# If there is a _log_cmd_example variable, it will be expanded into a
# printf-command that precedes the commands from the _cmd_example
# variable. This printf will produce output even if the commands of
# the recipe aren't echoed.
#
# The "define" command may be used to assign multiple-line values to
# variables:
#
# define _cmd_example
# $(Q)rot13 < $< > $@
# endef
# _log_cmd_example = ROT13 $@

_tput = $(shell command -v tput)
ifneq ($(_tput),)
_log_before = if test -t 1; then $(_tput) -T $(TERM) setaf 14; fi
_log_after = if test -t 1; then $(_tput) -T $(TERM) sgr0; fi
else
_log_before = :
_log_after = :
endif

define _cmd
@$(if $(_log_cmd_$(1)), $(_log_before);printf '  %-9s %s\n' $(_log_cmd_$(1));$(_log_after);)
$(_cmd_$(1))
endef


## Add your built files to the CLEANUP_FILES variable to have them
## cleaned up by the clean goal.

define _cmd_clean
$(Q)rm -rf $(CLEANUP_FILES)
endef
_log_cmd_clean = CLEAN

.PHONY: clean
clean:
	$(call _cmd,clean)


## Set the ARCHIVE_PREFIX variable to specify the path prefix used for
## all created tar archives.

# Set a default so that using COMPILED_ARCHIVE works correctly without
# specifying an ARCHIVE_PREFIX
ARCHIVE_PREFIX ?= ./

# Remove leading and add one trailing slash
_archive_prefix := $(patsubst %/,%,$(patsubst /%,%,$(ARCHIVE_PREFIX)))/

# Check if we have a git binary. The _git variable should only be used
# when _git is known to be non-empty. If git is required when it is
# not available, an error should be raised.
GIT ?= git
_git = $(shell command -v $(GIT))


######################################################################
### Git source archive
######################################################################

## Set the SOURCE_ARCHIVE variable to a file name to create a rule
## which will create a git archive with that name for the head
## revision. The archive will also include submodules.
##
## The SOURCE_ARCHIVE_PATH variable can be used to specify what is to
## be included in the source archive. The path is relative to the root
## of the git working copy. The default includes everything.
##
## The ARCHIVE_PREFIX variable will specify the prefix path for the
## archive.

ifneq ($(SOURCE_ARCHIVE),)

CLEANUP_FILES += $(SOURCE_ARCHIVE)

SOURCE_ARCHIVE_PATH ?= .

ifeq ($(_git),)
$(SOURCE_ARCHIVE):
	$(error Git does not appear to be installed)
else
# The git ref file indicating the age of HEAD
GIT_HEAD_REF := $(shell $(_git) rev-parse --symbolic-full-name HEAD)
GIT_TOP_DIR := $(shell $(_git) rev-parse --show-toplevel)
GIT_HEAD_REF_FILE := $(shell $(_git) rev-parse --git-path $(GIT_HEAD_REF))

# Handle that older git versions output git-path results relative to
# the git top dir instead of relative to cwd
GIT_HEAD_REF_FILE := $(shell if [ -f $(GIT_HEAD_REF_FILE) ]; then \
                               echo $(GIT_HEAD_REF_FILE); \
                             else \
                               echo $(GIT_TOP_DIR)/$(GIT_HEAD_REF_FILE); \
                             fi)

define _cmd_source_archive
$(Q)tmpdir=$$(mktemp -d submodules.XXXXX) && \
trap "rm -rf $$tmpdir" EXIT && \
(cd "$(GIT_TOP_DIR)" && \
  $(_git) archive \
    -o "$(CURDIR)/$@" \
    --prefix="$(_archive_prefix)" \
    HEAD $(SOURCE_ARCHIVE_PATH) && \
  $(_git) submodule sync && \
  $(_git) submodule update --init && \
  $(_git) submodule --quiet foreach 'echo $$path' | while read path; do \
    match=$$(find $(SOURCE_ARCHIVE_PATH) -samefile $$path 2>/dev/null); \
    if [ -n "$$match" ]; then \
      (cd "$$path" && \
      $(_git) archive \
	-o "$(CURDIR)/$$tmpdir/submodule.tar" \
	--prefix="$(_archive_prefix)$$path/" \
	HEAD . && \
      tar --concatenate -f "$(CURDIR)/$@" "$(CURDIR)/$$tmpdir/submodule.tar"); \
    fi \
  done)
endef
_log_cmd_source_archive = SOURCE $@

$(SOURCE_ARCHIVE): $(GIT_HEAD_REF_FILE)
	$(call _cmd,source_archive)

endif # ifeq ($(_git),)
endif # ifneq ($(SOURCE_ARCHIVE),)


######################################################################
### Node packages
######################################################################

## Use the variable $(NODE_MODULES) as a prerequisite to ensure node
## modules are installed for a make rule. Node modules will be
## installed with yarn if it is available, otherwise with npm.
##
## Set the variable PACKAGE_JSON, if the package.json file is not in
## the top-level directory.

NODE = node
PACKAGE_JSON ?= package.json
NODE_MODULES ?= $(dir $(PACKAGE_JSON))node_modules/.mark

$(NODE_MODULES): $(PACKAGE_JSON)
	$(Q)(cd $(dir $<) && \
	if command -v yarn >/dev/null; then \
	  yarn; \
	elif command -v npm >/dev/null; then \
	  npm install; \
	else \
	  echo >&2 "Neither yarn nor npm is available"; \
	  exit 1; \
	fi; \
	) && touch $@



######################################################################
### Compiled archive from source archive
######################################################################

## Set the COMPILED_ARCHIVE variable to a file name to create a rule
## which will run the shell command specified by COMPILE_COMMAND in a
## temporary directory where the SOURCE_ARCHIVE has been unpacked. The
## directory will be packed again into COMPILED_ARCHIVE.
##
## The ARCHIVE_PREFIX variable will specify the prefix path for the
## archive.

ifneq ($(COMPILED_ARCHIVE),)

CLEANUP_FILES += $(COMPILED_ARCHIVE)

define _cmd_compile_archive
$(Q)tmpdir=$$(mktemp -d compilation.XXXXX) && \
trap "rm -rf $$tmpdir" EXIT && \
(tar -C $$tmpdir -xf $(SOURCE_ARCHIVE) && \
  (cd $$tmpdir/$(_archive_prefix) && $(COMPILE_COMMAND)) && \
  tar -C $$tmpdir -cf $(COMPILED_ARCHIVE) $(_archive_prefix))
endef
_log_cmd_compile_archive = COMPILE $(COMPILED_ARCHIVE)

$(COMPILED_ARCHIVE): $(SOURCE_ARCHIVE)
	$(call _cmd,compile_archive)

endif


######################################################################
### Docker image
######################################################################

## Set the IMAGE_ARCHIVE variable to a file name to create a rule
## which will build a docker image, and written to IMAGE_ARCHIVE with
## docker save.
##
## The IMAGE_REPO variable and optionally the IMAGE_TAG_PREFIX
## variable should be set to specify how the image should be tagged.
## GitLab CI variables also affect the tag.
##
## Set IMAGE_DOCKERFILE to specify a non-default dockerfile path. The
## default is Dockerfile in the current directory.
##
## If the docker image uses any built file, these should be added to
## the IMAGE_FILES variable.
##
## The build and save goals both create $(IMAGE_ARCHIVE).
##
## The load goal loads $(IMAGE_ARCHIVE) into the docker daemon. The
## target is used for local testing of containers.
##
## The publish goal expects the $(IMAGE_ARCHIVE) to exist and will
## load it into the daemon. It will re-tag it to the final tag and
## push the image.
##
## The build-publish goal will completely bypass $(IMAGE_ARCHIVE) and
## build and publish without hitting the filesystem.


ifneq ($(IMAGE_REPO),)

.PHONY: build save load publish build-publish

IMAGE_DOCKERFILE ?= Dockerfile
IMAGE_ARCHIVE ?= dummy.tar

CLEANUP_FILES += $(IMAGE_ARCHIVE)

ifeq ($(_git),)
build-publish $(IMAGE_ARCHIVE) build save publish:
	$(error Git does not appear to be installed, images cannot be tagged)
else

# The branch or tag name for which project is built
CI_COMMIT_REF_NAME ?= $(shell $(_git) rev-parse --abbrev-ref HEAD)
CI_COMMIT_REF_NAME := $(subst /,_,$(CI_COMMIT_REF_NAME))
CI_COMMIT_REF_NAME := $(subst \#,_,$(CI_COMMIT_REF_NAME))

# The commit revision for which project is built
CI_COMMIT_SHA ?= $(shell git rev-parse HEAD)

# The unique id of the current pipeline that GitLab CI uses internally
CI_PIPELINE_ID ?= no-pipeline

# The unique id of runner being used
_host := $(shell uname -a)

# Build timestamp
_date := $(shell date +%FT%H:%M%z)

# URL
CI_PROJECT_URL ?= http://localhost.localdomain/

ifneq ($(IMAGE_TAG_PREFIX),)
_image_tag_prefix := $(patsubst %-,%,$(IMAGE_TAG_PREFIX))-
endif

IMAGE_TAG_SUFFIX ?= $(CI_COMMIT_REF_NAME)

# Unique for this build
IMAGE_LOCAL_TAG = $(IMAGE_REPO):$(_image_tag_prefix)$(CI_PIPELINE_ID)

# Final tag
IMAGE_TAG = $(IMAGE_REPO):$(_image_tag_prefix)$(IMAGE_TAG_SUFFIX)

define _cmd_image =
@$(if $(_log_cmd_image_$(1)), $(_log_before);printf '  %-9s %s\n' $(_log_cmd_image_$(1));$(_log_after);)
$(Q)if command -v buildah >/dev/null && command -v podman >/dev/null; then \
  $(_cmd_image_buildah_$(1)); \
elif command -v docker >/dev/null; then \
  $(_cmd_image_docker_$(1)); \
else \
  echo >&2 "Neither buildah/podman nor docker is available"; \
  exit 1; \
fi
endef

_buildah = buildah

define _cmd_image_buildah_build =
  $(_buildah) bud --pull-always \
    --file=$< \
    --build-arg=BRANCH="$(CI_COMMIT_REF_NAME)" \
    --build-arg=COMMIT="$(CI_COMMIT_SHA)" \
    --build-arg=URL="$(CI_PROJECT_URL)" \
    --build-arg=DATE="$(_date)" \
    --build-arg=HOST="$(_host)" \
    --tag=$(IMAGE_LOCAL_TAG) \
    .
endef
define _cmd_image_docker_build =
  docker build --pull --no-cache \
    --file=$< \
    --build-arg=BRANCH="$(CI_COMMIT_REF_NAME)" \
    --build-arg=COMMIT="$(CI_COMMIT_SHA)" \
    --build-arg=URL="$(CI_PROJECT_URL)" \
    --build-arg=DATE="$(_date)" \
    --build-arg=HOST="$(_host)" \
    --tag=$(IMAGE_LOCAL_TAG) \
    .
endef
_log_cmd_image_build = BUILD $(IMAGE_LOCAL_TAG)

define _cmd_image_buildah_publish =
  $(_buildah) push $(IMAGE_LOCAL_TAG) docker://$(IMAGE_TAG); \
  $(_buildah) rmi $(IMAGE_LOCAL_TAG)
endef
define _cmd_image_docker_publish =
  docker tag $(IMAGE_LOCAL_TAG) $(IMAGE_TAG); \
  docker rmi $(IMAGE_LOCAL_TAG); \
  docker push $(IMAGE_TAG); \
  docker rmi $(IMAGE_TAG)
endef
_log_cmd_image_publish = PUBLISH $(IMAGE_TAG)

define _cmd_image_buildah_save =
  $(_buildah) push $(IMAGE_LOCAL_TAG) docker-archive:$(IMAGE_ARCHIVE):$(IMAGE_LOCAL_TAG); \
  $(_buildah) rmi $(IMAGE_LOCAL_TAG)
endef
define _cmd_image_docker_save
  docker save $(IMAGE_LOCAL_TAG) > $(IMAGE_ARCHIVE); \
  docker rmi $(IMAGE_LOCAL_TAG)
endef
_log_cmd_image_publish = SAVE $(IMAGE_ARCHIVE)

build-publish: $(IMAGE_DOCKERFILE) $(IMAGE_FILES)
	$(call _cmd_image,build)
	$(call _cmd_image,publish)

$(IMAGE_ARCHIVE): $(IMAGE_DOCKERFILE) $(IMAGE_FILES)
	$(call _cmd_image,build)
	$(call _cmd_image,save)

build save: $(IMAGE_ARCHIVE)

publish:
	$(call _cmd_image,load)
	$(call _cmd_image,publish)

endif # ifeq($(_git),)

define _cmd_image_buildah_load =
  podman load < $(IMAGE_ARCHIVE)
endef
define _cmd_image_docker_load =
  docker load < $(IMAGE_ARCHIVE)
endef
_log_cmd_image_load = LOAD $(IMAGE_ARCHIVE)

load:
	$(call _cmd_image,load)

endif # ifneq ($(IMAGE_REPO),)


######################################################################
### Test sequence helpers
######################################################################

## To run a series of tests where any may fail without stopping the
## make recipe, use $(RECORD_TEST_STATUS) after each command, and end
## the rule with $(RETURN_TEST_STATUS)

RECORD_TEST_STATUS = let "_result=_result|$$?";
RETURN_TEST_STATUS = ! let _result;


######################################################################
### Fedora root archive
######################################################################

## Set the FEDORA_ROOT_ARCHIVE variable to a file name to create a
## rule which will build a tar archive of a small Fedora root file
## system. The archive will be suitable for adding to a scratch
## container image.
##
## The FEDORA_ROOT_RELEASE variable specifies the Fedora release to
## use.
##
## The FEDORA_ROOT_PACKAGES variable should be set to a list of
## packages to be installed in the file system.
##
## The file system is built using dnf install --installroot, so the
## rule needs to be run with root privileges to work.

ifneq ($(FEDORA_ROOT_ARCHIVE),)

CLEANUP_FILES += $(FEDORA_ROOT_ARCHIVE)

FEDORA_ROOT_RELEASE ?= 28

define _cmd_fedora_root
$(Q)tmpdir=$$(mktemp -d fedora_root.XXXXX) && \
trap "rm -rf $$tmpdir" EXIT && \
dnf install \
  --installroot $(CURDIR)/$$tmpdir \
  --releasever $(FEDORA_ROOT_RELEASE) \
  --disablerepo "*" \
  --enablerepo "fedora" \
  --enablerepo "updates" \
  $(FEDORA_ROOT_PACKAGES) \
  glibc-minimal-langpack \
  --setopt install_weak_deps=false \
  --assumeyes && \
rm -rf \
  $$tmpdir/var/cache \
  $$tmpdir/var/log/dnf* && \
tar -C $$tmpdir -cf $(CURDIR)/$@ .
endef
_log_cmd_fedora_root = DNF $@

$(FEDORA_ROOT_ARCHIVE):
	$(call _cmd,fedora_root)

endif

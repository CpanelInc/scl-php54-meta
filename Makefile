#-------------------------------------------------------------------------------------
#
# Start Configuration
#
#-------------------------------------------------------------------------------------

# the upstream project
OBS_PROJECT := EA4

# the package name in OBS
OBS_PACKAGE := php54-php-meta

#-------------------------------------------------------------------------------------
#
# End Configuration
#
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
#
# TODO
#
#-------------------------------------------------------------------------------------
# - Cleaning the OBS target when files are removed from git
# - Add a obs_dependencies target to rebuild the package and all of it's dependencies
# - Create a devel RPM that contains all of these Makefile stubs.  This way it's
#   in one place, instead of being copied everywhere.
#
#

#-------------------
# Variables
#-------------------

ERRMSG := "Please read, https://cpanel.wiki/display/AL/Setting+up+yourself+for+using+OBS"
OBS_USERNAME := $(shell grep -A5 '[build.dev.cpanel.net]' ~/.oscrc | awk -F= '/user=/ {print $$2}')
# NOTE: OBS only like ascii alpha-numeric characters
GIT_BRANCH := $(shell git branch | awk '/^*/ { print $$2 }' | tr -c [A-Za-z0-9] _)
BUILD_TARGET := home:$(OBS_USERNAME):$(OBS_PROJECT):$(GIT_BRANCH)
OBS_WORKDIR := $(BUILD_TARGET)/$(OBS_PACKAGE)

.PHONY: all local obs check build-clean build-init

#-----------------------
# Primary make targets
#-----------------------

all: local

# Builds the RPM on your local machine using the OBS infrstructure.
# This is useful to test before submitting to OBS.
local: check
	make build-init
	cd OBS/$(OBS_WORKDIR) && osc build --noverify --disable-debuginfo
	make build-clean

# Commits local file changes to OBS, and ensures a build is performed.
obs: check
	make build-init
	cd OBS/$(OBS_WORKDIR) && osc add `osc status | awk '/^M|\?/ {print $$2}' | tr "\n" " "` 2> /dev/null || exit 0
	cd OBS/$(OBS_WORKDIR) && osc delete `osc status | awk '/^!/ {print $$2}' | tr "\n" " "` 2> /dev/null || exit 0
	cd OBS/$(OBS_WORKDIR) && osc ci -m "Makefile check-in - $(shell date)"
	make build-clean

# Debug target: Prints out variables to ensure they're correct
vars: check
	@echo "OBS_USERNAME: $(OBS_USERNAME)"
	@echo "GIT_BRANCH: $(GIT_BRANCH)"
	@echo "BUILD_TARGET: $(BUILD_TARGET)"
	@echo "OBS_WORKDIR: $(OBS_WORKDIR)"
	@echo "OBS_PROJECT: $(OBS_PROJECT)"
	@echo "OBS_PACKAGE: $(OBS_PACKAGE)"

#-----------------------
# Helper make targets
#-----------------------

build-init: build-clean
	mkdir OBS
	osc branch $(OBS_PROJECT) $(OBS_PACKAGE) $(BUILD_TARGET) $(OBS_PACKAGE) 2>/dev/null || exit 0
	cd OBS && osc co $(BUILD_TARGET)
	mv OBS/$(OBS_WORKDIR)/.osc OBS/.osc.proj.$$ && rm -rf OBS/$(OBS_WORKDIR)/* && cp --remove-destination -pr SOURCES/* SPECS/* OBS/$(OBS_WORKDIR) && mv OBS/.osc.proj.$$ OBS/$(OBS_WORKDIR)/.osc

build-clean:
	rm -rf OBS

check:
	@[ -e ~/.oscrc ] || make errmsg
	@[ -x /usr/bin/osc ] || make errmsg
	@[ -x /usr/bin/build ] || make errmsg
	@[ -d .git ] || ERRMSG="This isn't a git repository." make -e errmsg

errmsg:
	@echo -e "\nERROR: You haven't set up OBS correctly on your machine.\n $(ERRMSG)\n"
	@exit 1

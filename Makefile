SHELL := /bin/bash

SRC := src

# Read default configuration
include config.default
export $(shell sed 's/=.*//' config.default)

# Read custom configuration if exist
ifneq (,$(wildcard config.custom))
include config.custom
export $(shell sed 's/=.*//' config.custom)
endif

# Parent image
ifeq ($(strip $(IMAGE_FROM)),)
IMAGE_FROM=$(BASE_NAMESPACE)/$(BASE_IMAGE):$(BASE_TAG)
export IMAGE_FROM
endif

BUILD_IMAGE_NAMESPACE ?= gcr.io
BUILD_IMAGE_PROJECT ?= planet-4-151612
BUILD_IMAGE_NAME ?= circleci-base

BUILD_IMAGE ?= $(BUILD_IMAGE_NAMESPACE)/$(BUILD_IMAGE_PROJECT)/$(BUILD_IMAGE_NAME)

# ---

SED_MATCH ?= [^a-zA-Z0-9._-]

ifneq ($(strip $(CIRCLECI)),)
# Configure build variables based on CircleCI environment vars
BUILD_NUM = build-$(CIRCLE_BUILD_NUM)
BUILD_BRANCH ?= $(shell sed 's/$(SED_MATCH)/-/g' <<< "$(CIRCLE_BRANCH)")
BUILD_TAG ?= $(shell sed 's/$(SED_MATCH)/-/g' <<< "$(CIRCLE_TAG)")
else
# Not in CircleCI environment, try to set sane defaults
BUILD_NUM = build-$(shell uname -n | tr '[:upper:]' '[:lower:]' | sed 's/$(SED_MATCH)/-/g')
BUILD_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD | sed 's/$(SED_MATCH)/-/g')
BUILD_TAG ?= $(shell git tag -l --points-at HEAD | tail -n1 | sed 's/$(SED_MATCH)/-/g')
endif

# If BUILD_TAG is blank there's no tag on this commit
ifeq ($(strip $(BUILD_TAG)),)
# Default to branch name
BUILD_TAG := $(BUILD_BRANCH)
else
# Consider this the new :latest image
# FIXME: implement build tests before tagging with :latest
PUSH_LATEST := true
endif

export BUILD_IMAGE
export BUILD_IMAGE_NAME
export BUILD_IMAGE_PROJECT
export BUILD_IMAGE_NAMESPACE

export BUILD_NUM
export BUILD_BRANCH
export BUILD_TAG

# ============================================================================

.DEFAULT_GOAL := build

.PHONY: all clean lint lint-sh lint-yaml lint-docker src pull build test

all: clean pull build test

clean:
		@rm -f README.md $(SRC)/circleci-base/Dockerfile
		@$(MAKE) -C test clean

lint: lint-yaml lint-sh lint-docker

lint-yaml:
		yamllint -d "{extends: default, rules: {line-length: {max: 80, level: warning}}}" .circleci/config.yml

lint-sh:
		find . -type f -name '*.sh' | xargs shellcheck -x

lint-docker: $(SRC)/$(IMAGE)/Dockerfile
		find . -type f -name 'Dockerfile' | xargs hadolint

pull:
		docker pull $(IMAGE_FROM)

src: $(SRC)/$(IMAGE)/%
$(SRC)/$(IMAGE)/%:
		./bin/build.sh -t

build: lint
		./bin/build.sh -b

test:
		@$(MAKE) -j1 -C $@ clean
		@$(MAKE) -k -C $@
		$(MAKE) -C $@ status

push: push-tag push-latest

push-tag:
		docker push $(BUILD_IMAGE):$(BUILD_TAG)
		docker push $(BUILD_IMAGE):$(BUILD_NUM)

push-latest:
		@if [[ "$(PUSH_LATEST)" = "true" ]]; then { \
			docker tag $(BUILD_IMAGE):$(BUILD_NUM) $(BUILD_IMAGE):latest; \
			docker push $(BUILD_IMAGE):latest; \
		}	else { \
			echo "Not tagged.. skipping latest"; \
		} fi

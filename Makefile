SHELL := /bin/bash

IMAGE := circleci-base
# ---

# Read default configuration
include config.default
export $(shell sed 's/=.*//' config.default)

# Read custom configuration if exist
ifneq (,$(wildcard config.custom))
include config.custom
export $(shell sed 's/=.*//' config.custom)
endif

# ---

# Parent image
ifeq ($(strip $(IMAGE_FROM)),)
IMAGE_FROM := $(BASE_NAMESPACE)/$(BASE_IMAGE):$(BASE_TAG)
endif

BUILD_IMAGE_NAMESPACE ?= gcr.io
BUILD_IMAGE_PROJECT ?= greenpeaceinternational
BUILD_IMAGE_NAME ?= circleci-base

# Image to build
BUILD_IMAGE ?= $(BUILD_IMAGE_PROJECT)/$(BUILD_IMAGE_NAME)

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

export IMAGE_FROM

export BUILD_IMAGE
export BUILD_IMAGE_NAME
export BUILD_IMAGE_PROJECT
export BUILD_IMAGE_NAMESPACE

export BUILD_NUM
export BUILD_BRANCH
export BUILD_TAG

# ---

# Check necessary commands exist

DOCKER := $(shell command -v docker 2> /dev/null)
SHELLCHECK := $(shell command -v shellcheck 2> /dev/null)
YAMLLINT := $(shell command -v yamllint 2> /dev/null)

# ---

SRC := src

# ============================================================================

.DEFAULT_GOAL := all

.PHONY: all init clean lint lint-sh lint-yaml lint-docker src pull build test

all: clean pull build test

init: .git/hooks/pre-commit
	git update-index --assume-unchanged README.md
	git update-index --assume-unchanged $(SRC)/$(IMAGE)/Dockerfile

.git/hooks/pre-commit:
	@chmod 755 .githooks/*
	@find .git/hooks -type l -exec rm {} \;
	@find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;

clean:
		@rm -f README.md $(SRC)/circleci-base/Dockerfile
		@$(MAKE) -C test clean

lint: init lint-yaml lint-sh lint-docker

lint-yaml:
ifndef YAMLLINT
	$(error "yamllint is not installed: https://github.com/adrienverge/yamllint")
endif
		@$(YAMLLINT) -d "{extends: default, rules: {line-length: disable}}" .circleci/config.yml

lint-sh:
ifndef SHELLCHECK
	$(error "shellcheck is not installed: https://github.com/koalaman/shellcheck")
endif
		@find . -type f -name '*.sh' | xargs $(SHELLCHECK) -x
		@find src/circleci-base/bin/* -type f | xargs $(SHELLCHECK) -x

lint-docker: $(SRC)/$(IMAGE)/Dockerfile
ifndef DOCKER
	$(error "docker is not installed: https://docs.docker.com/install/")
endif
		@docker run --rm -i hadolint/hadolint < $(SRC)/$(IMAGE)/Dockerfile

pull:
		docker pull $(IMAGE_FROM)

src: $(SRC)/$(IMAGE)/Dockerfile README.md
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

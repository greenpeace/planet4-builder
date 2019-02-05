SHELL := /bin/bash

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

export BUILD_NUM
export BUILD_BRANCH
export BUILD_TAG

# ============================================================================

.DEFAULT_GOAL := build

.PHONY: clean lint lint-sh lint-yaml lint-docker rewrite template pull build

clean:


template: rewrite
rewrite:
		./bin/build.sh -t

lint: lint-yaml lint-sh lint-docker

lint-yaml:
		yamllint -d "{extends: default, rules: {line-length: {max: 80, level: warning}}}" .circleci/config.yml

lint-sh:
		find . -type f -name '*.sh' | xargs shellcheck -x

lint-docker: rewrite
		find . -type f -name 'Dockerfile' | xargs hadolint

pull:
		docker pull $(IMAGE_FROM)

build: lint
		./bin/build.sh -b

push: push-tag push-latest

push-tag:
		docker push gcr.io/planet-4-151612/circleci-base:$(BUILD_TAG)
		docker push gcr.io/planet-4-151612/circleci-base:$(BUILD_NUM)

push-latest:
		@if [[ "$(PUSH_LATEST)" = "true" ]]; then { \
			docker tag gcr.io/planet-4-151612/circleci-base:$(BUILD_NUM) gcr.io/planet-4-151612/circleci-base:latest; \
			docker push gcr.io/planet-4-151612/circleci-base:latest; \
		}	else { \
			echo "Not tagged.. skipping latest"; \
		} fi

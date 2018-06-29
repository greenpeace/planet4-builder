SHELL := /bin/bash

# Version of gcr.io/planet-4-151612/circleci-base to use
BASE_IMAGE_VERSION ?= latest

BUILD_NAMESPACE ?= gcr.io
GOOGLE_PROJECT_ID ?= planet-4-151612

MAINTAINER_NAME ?= Raymond Walker
MAINTAINER_EMAIL ?= raymond.walker@greenpeace.org

ifeq ($(CIRCLECI),true)
# Configure build variables based on CircleCI environment vars
BUILD_NUM = build-$(CIRCLE_BUILD_NUM)
BRANCH_NAME ?= $(shell sed 's/[$(SED_MATCH)]/-/g' <<< "$(CIRCLE_BRANCH)")
BUILD_TAG ?= $(shell sed 's/[^a-zA-Z0-9._-]/-/g' <<< "$(CIRCLE_TAG)")
else
# Not in CircleCI environment, try to set sane defaults
BUILD_NUM = build-local
BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9._-]/-/g')
BUILD_TAG ?= $(shell git tag -l --points-at HEAD | tail -n1 | sed 's/[^a-zA-Z0-9._-]/-/g')
endif

# If BUILD_TAG is still not set, default to
ifeq ($(BUILD_TAG),)
BUILD_TAG := $(BRANCH_NAME)
endif

REVISION_TAG = $(shell git rev-parse --short HEAD)

ALL: build

build:
	docker build \
		--tag=$(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/p4-builder:$(BUILD_TAG) \
		--tag=$(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/p4-builder:$(BUILD_NUM) \
		--tag=$(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/p4-builder:$(REVISION_TAG) \
		src

push: push-tag push-latest

push-tag:
	docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/p4-builder:$(BUILD_TAG)
	docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/p4-builder:$(BUILD_NUM)

push-latest:
	docker tag $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/p4-builder:$(REVISION_TAG) $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/p4-builder:latest
	docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/p4-builder:latest

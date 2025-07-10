SHELL := /bin/bash

# ---

# Read default configuration
include config.default
export $(shell sed 's/=.*//' config.default)

# ---

# Image to build
BUILD_IMAGE ?= $(BUILD_NAMESPACE)/$(IMAGE_NAME)
export BUILD_IMAGE

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

REVISION_TAG = $(shell git rev-parse --short HEAD)

export BUILD_NUM
export BUILD_BRANCH
export BUILD_TAG

# ---

# Check necessary commands exist

DOCKER := $(shell command -v docker 2> /dev/null)
SHELLCHECK := $(shell command -v shellcheck 2> /dev/null)
SHFMT := $(shell command -v shfmt 2> /dev/null)
YAMLLINT := $(shell command -v yamllint 2> /dev/null)
FLAKE8 := $(shell command -v flake8 2> /dev/null)

# ---

SRC := src

# ============================================================================

.DEFAULT_GOAL := all

.PHONY: all init lint lint-sh lint-yaml lint-py lint-docker Dockerfile prepare build test

all: init prepare lint build test

init:
	@chmod 755 .githooks/*
	@find .git/hooks -type l -exec rm {} \;
	@find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;

format: format-sh

format-sh:
ifndef SHFMT
		$(error "shfmt is not installed: https://github.com/mvdan/sh")
endif
	@shfmt -i 2 -ci -w .

lint: init lint-yaml lint-sh lint-py lint-docker

lint-yaml:
ifndef YAMLLINT
	$(error "yamllint is not installed: https://github.com/adrienverge/yamllint")
endif
	@$(YAMLLINT) -d "{extends: default, rules: {line-length: disable}}" .circleci/config.yml

lint-sh:
ifndef SHELLCHECK
		$(error "shellcheck is not installed: https://github.com/koalaman/shellcheck")
endif
ifndef SHFMT
		$(error "shfmt is not installed: https://github.com/mvdan/sh")
endif
	@shfmt -f . | xargs shellcheck -x
	@shfmt -i 2 -ci -d .

lint-py:
ifndef FLAKE8
	$(error "flake8 is not installed: https://pypi.org/project/flake8/")
endif
	@flake8

lint-docker: $(SRC)/Dockerfile
ifndef DOCKER
	$(error "docker is not installed: https://docs.docker.com/install/")
endif
	@docker run --rm -i hadolint/hadolint < $(SRC)/Dockerfile

prepare: Dockerfile

Dockerfile:
	envsubst '$${BASE_NAMESPACE},$${BASE_IMAGE},$${BASE_TAG},$${CIRCLECI_USER}, \
		$${YAMLLINT_VERSION},$${YQ_VERSION},$${BATS_VERSION},$${JUNIT_MERGE_VERSION}, \
		$${FLAKE8_VERSION},$${OAUTHLIB_VERSION},$${GITPYTHON_VERSION},$${SENDGRID_VERSION}, \
		$${SEMVER_VERSION},$${PYCIRCLECI_VERSION},$${PYGITHUB_VERSION},$${TAP_XUNIT_VERSION}, \
		$${HADOLINT_VERSION},$${SHELLCHECK_VERSION},$${HELM2_VERSION},$${HELM3_VERSION}, \
		$${TRIVY_VERSION},$${SHFMT_VERSION},$${GOOGLE_SDK_VERSION},$${NODE_VERSION}$${JIRA_VERSION}' \
		< Dockerfile.in > src/Dockerfile

build:
ifndef DOCKER
$(error "docker is not installed: https://docs.docker.com/install/")
endif
	docker build \
		--tag=$(BUILD_IMAGE):$(BUILD_TAG) \
		--tag=$(BUILD_IMAGE):$(BUILD_NUM) \
		--tag=$(BUILD_IMAGE):$(REVISION_TAG) \
		src/ ; \

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

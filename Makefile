SHELL := /bin/bash

# Version of gcr.io/planet-4-151612/circleci-base to use
BASE_IMAGE_VERSION ?= develop
export BASE_IMAGE_VERSION

BUILD_NAMESPACE ?= greenpeaceinternational
GOOGLE_PROJECT_ID ?= planet-4-151612

MAINTAINER_NAME ?= Raymond Walker
MAINTAINER_EMAIL ?= raymond.walker@greenpeace.org

# ============================================================================

SED_MATCH ?= [^a-zA-Z0-9._-]

ifeq ($(CIRCLECI),true)
# Configure build variables based on CircleCI environment vars
BUILD_NUM = $(CIRCLE_BUILD_NUM)
BRANCH_NAME ?= $(shell sed 's/$(SED_MATCH)/-/g' <<< "$(CIRCLE_BRANCH)")
BUILD_TAG ?= $(shell sed 's/$(SED_MATCH)/-/g' <<< "$(CIRCLE_TAG)")
else
# Not in CircleCI environment, try to set sane defaults
BUILD_NUM = local
BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD | sed 's/$(SED_MATCH)/-/g')
BUILD_TAG ?= $(shell git tag -l --points-at HEAD | tail -n1 | sed 's/$(SED_MATCH)/-/g')
endif

# If BUILD_TAG is blank there's no tag on this commit
ifeq ($(strip $(BUILD_TAG)),)
# Default to branch name
BUILD_TAG := $(BRANCH_NAME)
else
# Consider this the new :latest image
# FIXME: implement build tests before tagging with :latest
PUSH_LATEST := true
endif

REVISION_TAG = $(shell git rev-parse --short HEAD)

export BUILD_NUM
export BUILD_TAG

# ============================================================================

# Check necessary commands exist

CIRCLECI := $(shell command -v circleci 2> /dev/null)
DOCKER := $(shell command -v docker 2> /dev/null)
COMPOSER := $(shell command -v composer 2> /dev/null)
JQ := $(shell command -v jq 2> /dev/null)
SHELLCHECK := $(shell command -v shellcheck 2> /dev/null)
YAMLLINT := $(shell command -v yamllint 2> /dev/null)

# ============================================================================

ALL: clean build push

init: .git/hooks/pre-commit
	git update-index --assume-unchanged src/Dockerfile

.git/hooks/pre-commit:
	@chmod 755 .githooks/*
	@find .git/hooks -type l -exec rm {} \;
	@find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;

clean:
	rm -f src/Dockerfile

lint: init lint-sh lint-yaml lint-json lint-composer lint-docker lint-ci

lint-sh:
ifndef SHELLCHECK
$(error "shellcheck is not installed: https://github.com/koalaman/shellcheck")
endif
	@find . -type f -name '*.sh' | xargs shellcheck

lint-yaml:
ifndef YAMLLINT
$(error "yamllint is not installed: https://github.com/adrienverge/yamllint")
endif
	@find . -type f -name '*.yml' | xargs yamllint

lint-json:
ifndef JQ
$(error "jq is not installed: https://stedolan.github.io/jq/download/")
endif
	@find . -type f -name '*.json' | xargs jq type | grep -q '"object"'

lint-composer:
ifndef COMPOSER
$(error "composer is not installed: https://getcomposer.org/doc/00-intro.md#installation-linux-unix-macos")
endif
	@find . -type f -name 'composer*.json' | xargs composer validate >/dev/null

lint-docker: src/Dockerfile
ifndef DOCKER
$(error "docker is not installed: https://docs.docker.com/install/")
endif
	@docker run --rm -i hadolint/hadolint < src/Dockerfile >/dev/null

lint-ci:
ifndef CIRCLECI
$(error "circleci is not installed: https://circleci.com/docs/2.0/local-cli/#installation")
endif
	@circleci config validate >/dev/null

pull:
	docker pull $(BUILD_NAMESPACE)/circleci-base:$(BASE_IMAGE_VERSION)

src/Dockerfile:
	envsubst < src/templates/Dockerfile.in > $@

build:
	$(MAKE) -j lint pull
	docker build \
		--tag=$(BUILD_NAMESPACE)/p4-builder:$(BUILD_TAG) \
		--tag=$(BUILD_NAMESPACE)/p4-builder:build-$(BUILD_NUM) \
		--tag=$(BUILD_NAMESPACE)/p4-builder:$(REVISION_TAG) \
		src

push: push-tag push-latest

push-tag:
	docker push $(BUILD_NAMESPACE)/p4-builder:$(BUILD_TAG)
	docker push $(BUILD_NAMESPACE)/p4-builder:build-$(BUILD_NUM)

push-latest:
	if [[ "$(PUSH_LATEST)" = "true" ]]; then { \
		docker tag $(BUILD_NAMESPACE)/p4-builder:$(REVISION_TAG) $(BUILD_NAMESPACE)/p4-builder:latest; \
		docker push $(BUILD_NAMESPACE)/p4-builder:latest; \
	}	else { \
		echo "Not tagged.. skipping latest"; \
	} fi

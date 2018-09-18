SHELL := /bin/bash

BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

.DEFAULT_GOAL := all

.PHONY: all build pull

all: test build pull

test:
		yamllint -d "{extends: default, rules: {line-length: {max: 80, level: warning}}}"  .circleci/config.yml
		yamllint cloudbuild.yaml
		find . -type f -name '*.sh' | xargs shellcheck -x

build:
		./bin/build.sh -r

pull:
		docker pull gcr.io/planet-4-151612/circleci-base:$(BRANCH)

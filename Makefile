SHELL := /bin/bash

BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

.DEFAULT_GOAL := all

.PHONY: all lint lint-sh lint-yaml lint-docker build pull

all: lint build pull

rewrite:
		./bin/build.sh

lint: lint-yaml lint-sh lint-docker

lint-yaml:
		yamllint -d "{extends: default, rules: {line-length: {max: 80, level: warning}}}" .circleci/config.yml
		yamllint cloudbuild.yaml

lint-sh:
		find . -type f -name '*.sh' | xargs shellcheck -x

lint-docker: rewrite
		find . -type f -name 'Dockerfile' | xargs hadolint

build: lint
		./bin/build.sh -r

pull:
		docker pull gcr.io/planet-4-151612/circleci-base:$(BRANCH)

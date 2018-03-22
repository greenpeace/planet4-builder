SHELL := /bin/bash

BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

.DEFAULT_GOAL := all

all: build pull
.PHONY: build pull

build:
		./bin/build.sh -r

pull:
		docker pull gcr.io/planet-4-151612/circleci-base:$(BRANCH)

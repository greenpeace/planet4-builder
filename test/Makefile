SHELL := /bin/bash

# File suffixes
BATS := bats
TAP := tap
XML := xml
OUT := out

# Output directory
LOGS := logs

# Used in .env.bash
export LOGS
export OUT

# BATS test files
TEST_FILES := $(wildcard *.$(BATS))

# TAP output
TAP_FILES := $(patsubst %.$(BATS), $(LOGS)/%.$(TAP), $(TEST_FILES))

# XUNIT output
XML_DIRS := $(patsubst %.$(BATS), $(LOGS)/%/, $(TEST_FILES))
XML_FILES := $(patsubst %.$(BATS), $(LOGS)/%/results.$(XML), $(TEST_FILES))

# Uncomment to enable automatic parralelisation of N available cores

# NPROCS = $(shell grep -c 'processor' /proc/cpuinfo 2>/dev/null)
# ifeq ($(strip $(NPROCS)),)
# NPROCS = $(shell sysctl hw.ncpu  | grep -o '[0-9]\+')
# endif
#
# MAKEFLAGS += -j$(NPROCS)

.PHONY: all clean tap xml

all: clean $(LOGS) $(XML_DIRS) $(TAP_FILES) $(XML_FILES) status

clean:
ifndef LOGS
$(error LOGS is not set. Cowardly refusing to rm -fr an empty string)
endif
		@rm -fr $(LOGS)/

status:
		@! ag 'not ok' $(LOGS)/
		@echo 'ok'

tap: $(LOGS)/%.$(TAP)

xml: $(LOGS)/%/results.$(XML)

$(LOGS):
		mkdir -p $(XML_DIRS)

$(LOGS)/%.$(TAP): %.$(BATS)
		-@OUT=$(OUT) bats --tap $^ | tee $@

$(LOGS)/%/results.$(XML): $(LOGS)/%.$(TAP)
		@tap-xunit --package="circleci.base.$(shell echo $@ | cut -d/ -f2 | cut -d. -f1 )" < $^ > $@

BATS := bats
TAP := tap
XML := xml

LOGS := logs

TEST_FILES := $(wildcard *.$(BATS))
TAP_FILES := $(patsubst %.$(BATS), $(LOGS)/%.$(TAP), $(TEST_FILES))
XML_FILES := $(patsubst %.$(BATS), $(LOGS)/%.$(XML), $(TEST_FILES))

# NPROCS = $(shell grep -c 'processor' /proc/cpuinfo 2>/dev/null)
# ifeq ($(strip $(NPROCS)),)
# NPROCS = $(shell sysctl hw.ncpu  | grep -o '[0-9]\+')
# endif
#
# MAKEFLAGS += -j$(NPROCS)

.PHONY: all clean

all: $(LOGS) $(TAP_FILES) $(XML_FILES)

clean:
		@rm -f $(LOGS)/*.$(TAP) $(LOGS)/*.$(XML)

status:
		@! ag 'not ok' $(LOGS)/
		@echo 'ok'

$(LOGS):
		mkdir -p $(LOGS)

$(LOGS)/%.$(TAP): %.$(BATS)
		-@bats --tap $^ | tee $@

$(LOGS)/%.$(XML): $(LOGS)/%.$(TAP)
		@tap-xunit --package="circleci.base.$(shell echo $@ | cut -d/ -f2 | cut -d. -f1 )" < $^ > $@

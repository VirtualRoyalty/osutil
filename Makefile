export ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

export PACKAGE_BASE := github.com/VirtualRoyalty/osutil
export UNIT_TEST_TIMEOUT := 480

ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:) # turn arguments into do-nothing targets
export ARGS

ifdef ARGS
	HAS_ARGS := "1"
	PACKAGE := $(ARGS)
else
	HAS_ARGS :=
	PACKAGE := $(PACKAGE_BASE)/...
endif

ifdef NO_UNIT_TEST_CACHE
	export NO_UNIT_TEST_CACHE=-count=1
else
	export NO_UNIT_TEST_CACHE=
endif

.DEFAULT_GOAL := help

clean: # Clean up artifacts of the development environment to allow for untainted builds, installations and updates.
	go clean -i $(PACKAGE)
	go clean -i -race $(PACKAGE)
.PHONY: clean

editor: # Open our default IDE with the project's configuration.
	@# WORKAROUND VS.code does not call Delve with absolute paths to files which it needs to set breakpoints. Until either Delve or VS.code have a fix we need to disable "-trimpath" which converts absolute to relative paths of Go builds which is a requirement for reproducible builds.
	GOFLAGS="$(GOFLAGS) -trimpath=false" $(ROOT_DIR)/scripts/editor.sh
.PHONY: editor

help: # Show this help message.
	@grep -E '^[a-zA-Z-][a-zA-Z0-9.-]*?:.*?# (.+)' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help

install:
	go install -v $(PACKAGE)
.PHONY: install

install-all: install install-tools-linting install-tools-testing
.PHONY: install-all

lint:
	go tool github.com/kisielk/errcheck ./...
	go vet ./...
.PHONY: lint

test: # [<Go package] - # Test everything, or only the specified package.
	go tool gotest.tools/gotestsum --format standard-verbose --hide-summary skipped -- $(NO_UNIT_TEST_CACHE) -race -test.timeout $(UNIT_TEST_TIMEOUT)s -test.run='$(word 2,$(ARGS))' -v $(if $(ARGS), $(word 1,$(ARGS)), $(PACKAGE))
.PHONY: test

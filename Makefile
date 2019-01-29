SHELL=/bin/bash

all: rcm

######################################################################
### compiling

# for mounting permissions in docker-compose
export UID = $(shell id -u)
export GID = $(shell id -g)

COMPILE_FLAGS=
BUILD_TARGET=

ON_DOCKER=docker-compose run --rm crystal

.PHONY: build
build:
	@$(ON_DOCKER) shards build $(COMPILE_FLAGS) --link-flags "-static" $(BUILD_TARGET) $(O)

.PHONY: rcm
rcm: BUILD_TARGET=--release rcm
rcm: build

.PHONY: rcm-dev
rcm-dev: BUILD_TARGET=rcm-dev
rcm-dev: build

######################################################################
### testing

.PHONY: ci
ci: rcm spec

.PHONY : spec
spec:
	@$(ON_DOCKER) crystal spec $(COMPILE_FLAGS) -v --fail-fast

######################################################################
### github releasing

.PHONY: github-release
github-release: check-statically-linked
	@github-release
	@./bin/github-release

.PHONY: check-statically-linked
check-statically-linked:
	@if file bin/rcm | grep statically > /dev/null; then \
	  : ;\
	else \
	  echo "not statically linked" >&2; exit 1; \
	fi

######################################################################
### versioning

VERSION=
CURRENT_VERSION=$(shell git tag -l | sort -V | tail -1 | sed -e 's/^v//')
GUESSED_VERSION=$(shell git tag -l | sort -V | tail -1 | awk 'BEGIN { FS="." } { $$3++; } { printf "%d.%d.%d", $$1, $$2, $$3 }')

.PHONY : version
version:
	@if [ "$(VERSION)" = "" ]; then \
	  echo "ERROR: specify VERSION as bellow. (current: $(CURRENT_VERSION))";\
	  echo "  make version VERSION=$(GUESSED_VERSION)";\
	else \
	  sed -i -e 's/^version: .*/version: $(VERSION)/' shard.yml ;\
	  sed -i -e 's/^    version: [0-9]\+\.[0-9]\+\.[0-9]\+/    version: $(VERSION)/' README.md ;\
	  echo git commit -a -m "'$(COMMIT_MESSAGE)'" ;\
	  git commit -a -m 'version: $(VERSION)' ;\
	  git tag "v$(VERSION)" ;\
	fi

.PHONY : bump
bump:
	make version VERSION=$(GUESSED_VERSION) -s


SHELL = /bin/bash
LINK_FLAGS = --link-flags "-static" -D without_openssl
SRCS = ${wildcard src/bin/*.cr}
PROGS = $(SRCS:src/bin/%.cr=%)
CRYSTAL ?= crystal

VERSION=
CURRENT_VERSION=$(shell git tag -l | sort -V | tail -1)
GUESSED_VERSION=$(shell git tag -l | sort -V | tail -1 | awk 'BEGIN { FS="." } { $$3++; } { printf "%d.%d.%d", $$1, $$2, $$3 }')

.PHONY : all static compile spec test
.PHONY : ${PROGS}

all: static

test: spec compile static examples

ci: spec compile examples

static: ${PROGS}

rcm: src/bin/rcm.cr
	$(CRYSTAL) build --release $^ -o bin/$@ ${LINK_FLAGS}

spec:
	$(CRYSTAL) spec -v

compile:
	@for x in src/bin/*.cr ; do\
	  $(CRYSTAL) build "$$x" -o /dev/null ;\
	done

.PHONY : examples
examples:
	@for x in examples/*.cr ; do\
	  $(CRYSTAL) build "$$x" -o /dev/null ;\
	done

.PHONY : release
release: bin/rcm
	@github-release
	@./bin/release

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

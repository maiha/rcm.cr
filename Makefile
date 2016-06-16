SHELL = /bin/bash
LINK_FLAGS = --link-flags "-static"
SRCS = ${wildcard src/bin/*.cr}
PROGS = $(SRCS:src/bin/%.cr=%)

.PHONY : all build clean bin
.PHONY : ${PROGS}

all: build

build: bin ${PROGS}

bin:
	@mkdir -p bin

rcm: src/bin/rcm.cr
	crystal build --release $^ -o bin/$@ ${LINK_FLAGS}

spec:
	crystal spec -v

test-compile-bin:
	@for x in src/bin/*.cr ; do\
	  crystal build "$$x" -o /dev/null ;\
	done

clean:
	@rm -rf bin tmp

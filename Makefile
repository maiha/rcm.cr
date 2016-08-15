SHELL = /bin/bash
LINK_FLAGS = --link-flags "-static" -D without_openssl
SRCS = ${wildcard src/bin/*.cr}
PROGS = $(SRCS:src/bin/%.cr=%)

.PHONY : all static compile spec clean bin
.PHONY : ${PROGS}

all: static

static: bin ${PROGS}

bin:
	@mkdir -p bin

rcm: src/bin/rcm.cr
	crystal build --release $^ -o bin/$@ ${LINK_FLAGS}

spec:
	crystal spec -v

compile:
	@for x in src/bin/*.cr ; do\
	  crystal build "$$x" -o /dev/null ;\
	done

clean:
	@rm -rf bin

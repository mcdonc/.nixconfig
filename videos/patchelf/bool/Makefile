ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

bool:
	g++ -lboolector -I/usr/local/include/boolector bool.cc -o bool

install:
	install -d $(PREFIX)
	install -m 755 bool $(PREFIX)

all: bool

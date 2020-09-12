CXXFLAGS+=-Wall -Werror
CXXFLAGS+=-g

OBJ=\
	dump.o\
	spi.o

all: dump

dump: $(OBJ)
	$(LINK.cc) -o $@ $^ $(LDLIBS)

clean:
	rm -f $(OBJ) dump

world: clean all

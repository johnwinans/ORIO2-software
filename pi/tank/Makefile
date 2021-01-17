CXXFLAGS+=-Wall -Werror
CXXFLAGS+=-g
LDLIBS+=-lz

OBJ=\
	tank.o\
	spi.o\
	Joystick.o

.PHONY: all
all: tank

tank: $(OBJ)
	$(LINK.cc) -o $@ $^ $(LDLIBS)

.PHONY: clean
clean:
	rm -f $(OBJ) tank 
	rm -rf dox

.PHONY: dox
dox:
	doxygen

.PHONY: world
world: clean all

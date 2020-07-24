CXXFLAGS+=-Wall -Werror
CXXFLAGS+=-g
LDLIBS+=-lz

OBJ=\
	tank.o\
	spi.o\
	Joystick.o

all: tank

tank: $(OBJ)
	$(LINK.cc) -o $@ $^ $(LDLIBS)

clean:
	rm -f $(OBJ) tank

world: clean all

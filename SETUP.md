

# Install prerequisites

    sudo apt-get install build-essential clang bison flex libreadline-dev \
                    gawk tcl-dev libffi-dev git mercurial graphviz   \
                    xdot pkg-config python python3 libftdi-dev



# Download the tools

    git clone https://github.com/cliffordwolf/icestorm.git
    git clone https://github.com/cseed/arachne-pnr.git
    git clone https://github.com/cliffordwolf/yosys.git


# Build and install everything (this will litter /usr/local)

    PROCS=3

    cd icestorm
    make -j$PROCS
    sudo make install
    cd ..

    cd arachne-pnr
    make -j$PROCS
    sudo make install
    cd ..

    cd yosys
    make -j$PROCS
    sudo make install
    cd ..

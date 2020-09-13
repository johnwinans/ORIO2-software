#    Copyright (C) 2020  John Winans
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
#    USA


# Project setup
PROJ      = orio2
BUILD     = ./build

# for 1K devices
#DEVICE    = 1k
#FOOTPRINT = tq144
#PINS=pinmap-icestick.pcf

# for 4K devices
DEVICE    = 8k
FOOTPRINT = tq144:4k
PINS=pinmap-2057.pcf

FILES=\
	SPI_slave.v\
	SPI_master.v\
	top.v\
	pwm.v\
	quadin.v\
	pll_25_40.v\
	mcp3004_controller.v\
	mcp3004.v\
	signal_sync.v

.PHONY: all clean burn

all:
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	yosys -p "synth_ice40 -top top -blif $(BUILD)/$(PROJ).blif" $(FILES)
	# Place and route using arachne
	arachne-pnr -d $(DEVICE) -P $(FOOTPRINT) -o $(BUILD)/$(PROJ).asc -p $(PINS) $(BUILD)/$(PROJ).blif
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

timings:
	icetime -tmd hx$(DEVICE)  $(BUILD)/$(PROJ).asc

burn:
	iceprog $(BUILD)/$(PROJ).bin


VSPI_master:
	verilator -Wall --cc -CFLAGS "-g" --trace SPI_master.v --exe sim_SPI_master.cpp
	cd obj_dir
	make -j -C obj_dir -f VSPI_master.mk VSPI_master

Vmcp3004:
	verilator -Wall --cc -CFLAGS "-g" --trace mcp3004.v --exe sim_mcp3004.cpp
	cd obj_dir
	make -j -C obj_dir -f Vmcp3004.mk Vmcp3004
	

clean:
	rm -rf build obj_dir

world: clean all

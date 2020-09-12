#!/bin/bash

#    A script to configure Lattice iCE40 FPGA by SPI from Raspberry Pi
#
#    Copyright (C) 2015 Jan Marjanovic <jan@marjanovic.pro>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# 2020-09-12 - Hacked by John Winans



# To program an FPGA:
#
# sudo ./prog.sh ~/blinky.bin


# The 2060-ORIO2 is connected to the PI like this:
#
# Signal		PI pin		PI function
# CRESET*		15			GPIO22
# CDONE			16			GPIO23
# FPGA_SS		18			GPIO24	(special case for booting)
# FPGA_SDI		19			SPI_MOSI 
# FPGA_SDO		21			SPI_MISO
# FPGA_SCK		23			SPI_SCK
# FPGA_CE0		24			SPI_CE0 (special case not used for booting)

RESET=22
SSEL=24




######################################
echo ""
if [ $# -ne 1 ]; then
    echo "Usage: $0 FPGA-bin-file "
    exit 1
fi

if [ $EUID -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

######################################

if [ ! -d /sys/class/gpio/gpio${SSEL} ]; then
    echo "GPIO ${SSEL} not exported, trying to export..."
    echo ${SSEL} > /sys/class/gpio/export
    if [ ! -d /sys/class/gpio/gpio${SSEL} ]; then
	echo "ERROR: directory /sys/class/gpio/gpio${SSEL} does not exist"
	exit 1
    fi
else
    echo "OK: GPIO ${SSEL} exported"
fi

if [ ! -d /sys/class/gpio/gpio${RESET} ]; then
    echo "GPIO ${RESET} not exported, trying to export..."
    echo ${RESET} > /sys/class/gpio/export
    if [ ! -d /sys/class/gpio/gpio${RESET} ]; then
    echo "ERROR: directory /sys/class/gpio/gpio${RESET} does not exist"
    exit 1
    fi
else
    echo "OK: GPIO ${RESET} exported"
fi

######################################

echo ""
if [ -e /dev/spidev0.0 ]; then
    echo "OK: SPI driver loaded"
else
    echo "spidev does not exist"
    
    lsmod | grep spi_bcm2708 >& /dev/null

    if [ $? -ne 0 ]; then
	echo "SPI driver not loaded, try to load it..."
	modprobe spi_bcm2708

	if [ $? -eq 0 ]; then
	    echo "OK: SPI driver loaded"
	else
	    echo "Could not load SPI driver"
	    exit 1
	fi  
    fi
fi

######################################

#./downloader < $1
#exit 0

# set the SSEL to low before we reset the FPGA
echo ""
echo "Changing direction to out"
echo out > /sys/class/gpio/gpio${SSEL}/direction
cat /sys/class/gpio/gpio${SSEL}/direction

echo "Setting output to low (should be 0)"
echo 0 > /sys/class/gpio/gpio${SSEL}/value
cat /sys/class/gpio/gpio${SSEL}/value

######################################

echo ""
echo "Changing direction to out"
echo out > /sys/class/gpio/gpio${RESET}/direction
cat /sys/class/gpio/gpio${RESET}/direction

echo "Resetting the FPGA (should be 0)"
echo 0 > /sys/class/gpio/gpio${RESET}/value
cat /sys/class/gpio/gpio${RESET}/value
sleep 1
echo "Releasing the reset... (should be 1)"
echo 1 > /sys/class/gpio/gpio${RESET}/value
cat /sys/class/gpio/gpio${RESET}/value
sleep 1

######################################

echo "Continuing with configuration procedure"
dd if=$1 of=/dev/spidev0.0
echo -e "\x0\x0\x0\x0\x0\x0\x0" > /dev/spidev0.0

echo "Setting output to high (should be 1)"
echo 1 > /sys/class/gpio/gpio${SSEL}/value
cat /sys/class/gpio/gpio${SSEL}/value

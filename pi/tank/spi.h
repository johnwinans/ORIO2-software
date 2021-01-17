//****************************************************************************
//
//    ORIO2 Software: https://github.com/johnwinans/ORIO2-software
//
//    Copyright (C) 2020  John Winans
//
//    This library is free software; you can redistribute it and/or
//    modify it under the terms of the GNU Lesser General Public
//    License as published by the Free Software Foundation; either
//    version 2.1 of the License, or (at your option) any later version.
//
//    This library is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//    Lesser General Public License for more details.
//
//    You should have received a copy of the GNU Lesser General Public
//    License along with this library; if not, write to the Free Software
//    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
//    USA
//
//****************************************************************************

#ifndef spi_H
#define spi_H

#include <stdint.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <getopt.h>
#include <string.h>
#include <sys/time.h>

#include <linux/types.h>
#include <linux/spi/spidev.h>

#include <string>

class spi
{
public:
	/**
	* Open the given SPI device.
	* @param devname The name of the SPI port to open.
	***************************************************************************/
	spi(const char *devname = "/dev/spidev0.0");

	/**
	* Close the SPI device.
	***************************************************************************/
	~spi();

	/**
	* @param tx The byte buffer to write to the SPI port
	* @param rx The byte bufer that is read from the SPI port
	* @param len The number of bytes to send and receive (tx len bytes & rx len bytes)
	* @return the value from the low-level ioctl(fd, SPI_IOC_MESSAGE(), ...) call
	***************************************************************************/
	int transfer(void *tx, void*rx, uint32_t len);

	/**
	* Print a report of the SPI device and its status.
	***************************************************************************/
	void dump();

private:

	uint8_t mode = { 0 };			///< Default SPI mode = 0
	uint8_t bits = { 8 };			///< Default SPI word size = 8 bits
	uint32_t speed = { 4000000 };	///< Default SPI speed = 4mhz
	uint16_t delay = { 0 };			///< How long to delay after the last bit transfer to deselect
	int fd = { -1 };				///< The file descriptor of the opened SPI device
	std::string spidev;				///< A saved copy of the opened device name
};

#endif

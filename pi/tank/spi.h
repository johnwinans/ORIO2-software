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
	***************************************************************************/
	spi(const char *devname);

	/**
	***************************************************************************/
	~spi();

	/**
	***************************************************************************/
	int transfer(void *tx, void*rx, size_t len);

	/**
	***************************************************************************/
	void dump();

private:

	uint8_t mode = { 0 };
	uint8_t bits = { 8 };
	uint32_t speed = { 4000000 };
	uint16_t delay = { 0 };
	int fd = { -1 };
	std::string spidev;
};

#endif

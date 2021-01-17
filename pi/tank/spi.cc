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

#include "spi.h"

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

#include <sys/ioctl.h>

//***************************************************************************
spi::spi(const char *spidev)
{
	this->spidev = spidev;
	if ((fd = open(spidev, O_RDWR)) < 0)
	{
		fprintf(stderr, "Can't open '%s': ", spidev);
		return;
	}

	ioctl(fd, SPI_IOC_WR_MODE, &mode);
	ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits);
	ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
}

//***************************************************************************
spi::~spi()
{
	if (fd != -1)
		close(fd);
}

//***************************************************************************
void spi::dump()
{
	if (fd == -1)
	{
		printf("spidev: %s\n", spidev.c_str());
		printf("ERROR: Device not open\n");
	}
	else
	{
		uint8_t m;
		uint8_t b;
		uint32_t s;

		ioctl(fd, SPI_IOC_RD_MODE, &m);
		ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &b);
		ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &s);

		printf("spidev: %s\n", spidev.c_str());
		printf("  mode: %d\n", m);
		printf("  bits: %d\n", b);
		printf(" speed: %d\n", s);
	}
}

//***************************************************************************
int spi::transfer(
	void *txBuf,
	void *rxBuf,
	size_t len
	)
{
    struct spi_ioc_transfer tr = {
        .tx_buf = (uint64_t)txBuf,
        .rx_buf = (uint64_t)rxBuf,
        .len = len,
        .speed_hz = speed,
        .delay_usecs = delay,
        .bits_per_word = bits
    };

    return ioctl(fd, SPI_IOC_MESSAGE(1), &tr);
}

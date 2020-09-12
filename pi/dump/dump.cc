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

#define DEBUG_PRINT

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
#include <linux/joystick.h>

/**
* Print a message and exit.
*************************************************************************/
static void die(const char *s)
{
	perror(s);
	exit(1);
}

/**
*************************************************************************/
void hexDump(const void *a, unsigned long len, uint32_t addr)
{
	const unsigned char *p = (const unsigned char*)a;
	int first = 1;
	if (addr%16 != 0)
	{
		first = 0;
		printf("%8x:    ", addr);
		int i = addr%16;
		while(--i)
			printf("   ");
	}
	while(len)
	{
		if (addr%16 == 0)
		{
			if (!first)
				printf("\r\n");
			printf("%8x: ", addr);
		}
		printf("%s%02x", (addr%16 == 8)?"-":" ", *p);
		++p;
		++addr;
		--len;
		first = 0;
	}
	printf("\r\n");
}

/**
***************************************************************************/
static void transfer(
	spi *ps,
	double left, 
	double right, 
	uint8_t rsl,
	uint8_t leds
	)
{
#define LEN (4+10*4+2+8*2+1)

    uint8_t tx[LEN];
    uint8_t rx[LEN];

	// clamp the speed values
	if (left > 1.0)
		left = 1.0;
	if (right > 1.0)
		right = 1.0;
	if (left < -1.0)
		left = -1.0;
	if (right < -1.0)
		right = -1.0;

	// zero out the message body
    memset(tx, 0, sizeof(tx));

    // want 1msec - 2msec
    // 65536 ticks = 10msec (@100HZ)
    // 6554 = 1msec
    // 13108 = 2msec

    // 65536 ticks = 16.666msec (@60HZ)
    // 3932 = 1msec
    // 7864 = 2msec

#define PWM_MIN	(3932)
#define PWM_MAX	(7864)

	uint16_t val = 0;

	double scale = (PWM_MAX-PWM_MIN)/2.0;
	double d;

	d = (scale+1.0) * left + PWM_MIN;		// scale & align to target positive range
	printf("left: %f\n", d);
	val = d;
	tx[0] = val >> 8;
	tx[1] = val & 0x0ff;

	d = (scale+1.0) * right + PWM_MIN;		// scale & align to target positive range
	printf("right: %f\n", d);
	val = d;
	tx[2] = val >> 8;
	tx[3] = val & 0x0ff;

    tx[35] = rsl?1:0;   // lsb = RSL light

	tx[33] = leds;


    printf("==========================================================================\n");
    printf("TX:\n");
    hexDump(&tx, sizeof(tx), 0);

	if (ps->transfer(tx, rx, LEN) < 1)
        die("can't send spi message");

    printf("RX:\n");
    hexDump(&rx, sizeof(rx), 0);
}

/**
****************************************************************************/
int main(int argc, char *argv[])
{
	const char *spidev = "/dev/spidev0.0";
	spi s(spidev);

	uint8_t ctr = 0;
	float speed = 0.0;
	float delta = .01;	// how fast to ramp the speed up/down
	float dir = 1;

	while(1)
    {
		printf("Speed: %f\n", speed);
		transfer(&s, speed, -speed, ctr&0x20, ctr);

		if (speed >= 1.0)
			dir = -1;
		else if (speed <= 0.0)
			dir = 1;

		speed += delta*dir;
		++ctr;

		usleep(10000);	// for a 100HZ(ish) poll rate
		//usleep(100000);	// for a 10HZ(ish) poll rate
    }

    return 0;
}

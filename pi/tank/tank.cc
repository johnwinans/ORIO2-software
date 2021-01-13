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

#include "Joystick.h"
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
	int rsl,
	int air,
	int led0,
	int led1,
	int led2,
	int led3,
	int led4,
	int led5,
	int led6,
	int led7
	)
{
#define LEN (4+10*4+2+8*2+1)

    uint8_t tx[LEN];
    uint8_t rx[LEN];

	// zero out the message body
    memset(tx, 0, sizeof(tx));

    // want 1msec - 2msec
    // 65536 ticks = 10msec (@100HZ)
    // 6554 = 1msec
    // 13108 = 2msec

    // 65536 ticks = 16.666msec (@60HZ)
    // 3932 = 1msec
    // 7864 = 2msec

	// Due to clock divisor rounding on the FPGA
	// 65536 ticks = 
	// 4167 - 1msec
	// 2083 - 2msec

//#define PWM_MIN	(3932)
//#define PWM_MAX	(7864)

#define PWM_MIN	(4000)
#define PWM_MAX	(7000)

	uint16_t val = 0;

	double scale = (PWM_MAX-PWM_MIN)/2.0;
	//double scale = (PWM_MAX-PWM_MIN);
	double d;

#if 0
	// deadband
	if (left > -.01 && left < .01)
		left = 0.0;
	if (right > -.01 && right < .01)
		right = 0.0;
#endif

	d = scale * (left+1.0) + PWM_MIN;		// scale & align to target positive range
	printf("left: %f => %f\n", left, d);
	val = d;
	tx[0] = val >> 8;
	tx[1] = val & 0x0ff;

	d = scale * (right+1.0) + PWM_MIN;		// scale & align to target positive range
	printf("right: %f => %f\n", right, d);
	val = d;
	tx[2] = val >> 8;
	tx[3] = val & 0x0ff;

#if 1
	// just set all the rest of the PWMs to the right joystick value
	for (int i=2; i<16; ++i)
	{
		tx[i*2] = val >> 8;
		tx[i*2+1] = val & 0x0ff;
	}
#endif


	// digital out (make same as LEDs for debugging)
	tx[32] = (led0<<0)|(led1<<1)|(led2<<2)|(led3<<3)|(led4<<4)|(led5<<5)|(led6<<6)|(led7<<7);

	// LEDs
	tx[33] = (led0<<0)|(led1<<1)|(led2<<2)|(led3<<3)|(led4<<4)|(led5<<5)|(led6<<6)|(led7<<7);

	// solenoids (make same as LEDs for debugging)
	tx[34] = (led0<<0)|(led1<<1)|(led2<<2)|(led3<<3)|(led4<<4)|(led5<<5)|(led6<<6)|(led7<<7);

    tx[35] = rsl?1:0;		// lsb = RSL light
    tx[35] |= air?2:0;		// air compressor


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
    const char *jsdev = "/dev/input/js0";
	const char *spidev = "/dev/spidev0.0";

	Joystick js(jsdev);
	spi s(spidev);
	
	while(1)
    {
		js.poll();

		struct timeval tv;
		gettimeofday(&tv, NULL);

		int rsl = (tv.tv_usec / (1000000/8)) % 2;
		//int rsl = tv.tv_sec % 2;
		int air = tv.tv_sec % 20;

		transfer(&s, js.getRawAxis(1), js.getRawAxis(4), rsl, air,
			js.getRawButton(0), 
			js.getRawButton(1), 
			js.getRawButton(2), 
			js.getRawButton(3), 
			js.getRawButton(4), 
			js.getRawButton(5), 
			js.getRawButton(6), 
			js.getRawButton(7)
			);

		usleep(10000);	// for a 100HZ(ish) poll rate
    }

    return 0;
}

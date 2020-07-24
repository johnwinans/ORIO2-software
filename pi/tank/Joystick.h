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

#ifndef Joystick_H
#define Joystick_H

// FYI - The Linux joystick API is documented here:
//
// https://www.kernel.org/doc/Documentation/input/joystick-api.txt

#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/joystick.h>

/**
* @bug Deal with the case where a joystick is unplugged and then reconnected.
******************************************************************************/
class Joystick
{
public:
	Joystick(const char *devname);
	~Joystick();

	int poll();
	double getRawAxis(int axis);
	bool getRawButton(int button);

	int getAxisCount() const { return buttonCount; }
	int getButtonCount() const { return buttonCount; }

private:
	int fd = {-1};

	uint16_t axisCount = { 0 };
	double *axes = { 0 };

	uint16_t buttonCount = { 0 };
	uint8_t *buttons = { 0 };
};

#endif

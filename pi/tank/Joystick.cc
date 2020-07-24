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

// FYI - The Linux joystick API is documented here:
//
// https://www.kernel.org/doc/Documentation/input/joystick-api.txt

#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

#include <linux/joystick.h>

Joystick::Joystick(const char *devname)
{
   	fd = open(devname, O_RDONLY|O_NONBLOCK);

	uint8_t i;
	if (ioctl(fd, JSIOCGAXES, &i) != -1)
	{
		axisCount = i;

		axes = new double[axisCount];
		for (int j=0; j<axisCount; ++j)
			axes[j] = 0;
	}
	if (ioctl(fd, JSIOCGBUTTONS, &i) != -1)
	{
		buttonCount = i;

		buttons = new uint8_t[buttonCount];
		for (int j=0; j<buttonCount; ++j)
			buttons[j] = 0;
	}

   	printf("axis count=%d\n", getAxisCount());
   	printf("button count=%d\n", getButtonCount());
}

Joystick::~Joystick()
{
	if (fd != -1)
		close(fd);
	delete[] axes;
	delete[] buttons;
}

int Joystick::poll()
{
	struct js_event event;

	while(read(fd, &event, sizeof(event)) == sizeof(event))
	{
		if (event.type & JS_EVENT_BUTTON)
		{
			if (event.number < buttonCount)
				buttons[event.number] = event.value;
#ifdef DEBUG_PRINT
			printf("Button %d is %d (%d)\n", event.number, event.value, buttons[event.number]);
#endif
		}
		else if (event.type & JS_EVENT_AXIS)
		{
			if (event.number < axisCount)
				axes[event.number] = (double)event.value/32768.0;
#ifdef DEBUG_PRINT
			printf("Axis %d at %d (%f)\n", event.number, event.value, axes[event.number]);
#endif
		}
	}
	return 0;
}

double Joystick::getRawAxis(int axis)
{
	if (axis < axisCount)
		return axes[axis];
	else
		return 0.0;
}

bool Joystick::getRawButton(int button) 
{
	if (button < buttonCount)
		return buttons[button];
	else
		return false;
}

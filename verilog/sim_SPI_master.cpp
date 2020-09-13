//**************************************************************************
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
//**************************************************************************


#include <unistd.h>
#include <getopt.h>

#include <verilated.h>          // Defines common routines
#include <verilated_vcd_c.h>
#include <iostream>             // Need std::cout
#include <iomanip>
#include <string>
#include <ctype.h>
#include <iostream>
#include <fstream>

#include "VSPI_master.h"

using namespace std;

static VSPI_master *ptop;                      // Instantiation of module

static vluint64_t main_time = 0;       // Current simulation time
static VerilatedVcdC* tfp = 0;

#define PERIOD  (5)

/**
* Called by $time in Verilog
****************************************************************************/
double sc_time_stamp ()
{
    return main_time;       // converts to double, to match
                            // what SystemC does
}

/**
****************************************************************************/
static void tick(int count)
{
    for (;count > 0; --count)
    {
        //if (tfp)
            //tfp->dump(main_time); // dump traces (inputs stable before outputs change)
        ptop->eval();            // Evaluate model
        main_time++;            // Time passes...
        if (tfp)
            tfp->dump(main_time);   // inputs and outputs all updated at same time
    }
}

/**
****************************************************************************/
static void run(uint64_t limit)
{
    uint64_t count = 0;

    while(count < limit)
    {
        ptop->clk = 1;
        tick(PERIOD);
        ptop->clk = 0;
        tick(PERIOD);

        ++count;
    }
}

/**
****************************************************************************/
static void reset()
{
    ptop->clk = 0;
    ptop->reset = 0;
	run(10);
    ptop->reset = 1;
	run(10);
    ptop->reset = 0;
	run(10);
}

/**
* sim ucfile [memfile]
****************************************************************************/
int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);
    ptop = new VSPI_master;             // Create instance

    int verbose = 0;

    int opt;
    while ((opt = getopt(argc, argv, "tv:")) != -1)
    {
        switch (opt)
        {
        case 'v':
            verbose=atoi(optarg);
            break;
        case 't':
            // init trace dump
            Verilated::traceEverOn(true);
            tfp = new VerilatedVcdC;
            ptop->trace(tfp, 99);
            tfp->open("wave.vcd");
            break;
        }
    }

    // start things going
    reset();

    run(100);
#if 0
	input wire	reset,
	input wire	clk,					
	output wire	sck, 
	output wire	ssel,
	output wire	mosi,
	input wire	miso,
	output wire busy,						// true when the SPI is busy (only set tx_data_tick when low)

	output wire rx_data_tick,				// one clock-wide high indicates transfer complete & rx_data valid
	output wire [BIT_WIDTH-1:0] rx_data,	// this will remain stable from rx_data_tick until tx_data_tick
											// rx_data will be garbage during a transfer

	input wire tx_data_tick,				// one clock-wide high indicates request to start a transfer using tx_data
	input wire [BIT_WIDTH-1:0] tx_data		// must be stable on posedge clk & may change after tx_data_tick period
#endif

	ptop->miso = 1;
	ptop->tx_data_tick = 1;
	run(1);
	ptop->tx_data_tick = 0;
    run(2000);
	ptop->miso = 0;
	ptop->tx_data_tick = 1;
	run(1);
	ptop->tx_data_tick = 0;
    run(2000);

#if 0
	ptop->tx_data = 0;
#endif



    if (tfp)
        tfp->close();

    ptop->final();               // Done simulating

    if (tfp)
        delete tfp;

    delete ptop;

	return 0;
}

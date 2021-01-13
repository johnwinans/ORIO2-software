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


module mcp3004
	#(
		parameter SCK_PERIOD=100				// sck divisor: sck = (clk/SCK_PERIOD) (minimum = 2)
	)
	(
	input wire	reset,
	input wire	clk,
	output wire	sck, 
	output wire	ssel,
	output wire	mosi,
	input wire	miso,

	output wire rx_data_tick,					// one clock-wide high indicates transfer complete & rx_data valid
	output wire [MCP3004_BIT_WIDTH-1:0] rx_data	// this will remain stable from rx_data_tick until tx_data_tick
												// rx_data will be garbage during a transfer
	);

	localparam MCP3004_BIT_WIDTH = 8*16;		// module message size (8 uint16_t values)
	localparam SPI_BIT_WIDTH = 24;				// SPI buffer size

	wire spi_tx_data_tick;
	wire [SPI_BIT_WIDTH-1:0] spi_tx_data;
	wire spi_rx_data_tick;
	wire [SPI_BIT_WIDTH-1:0] spi_rx_data;
	wire spi_busy;

	SPI_master #(
		.SCK_PERIOD(SCK_PERIOD),
		.BIT_WIDTH(SPI_BIT_WIDTH)				// why can I not use mcp3004_controller_unit.SPI_BIT_WIDTH here???
	) SPI_master_unit(
		.clk(clk),
		.reset(reset),
		.sck(sck),
		.ssel(ssel),
		.mosi(mosi),
		.miso(miso),
		.busy(spi_busy),
		.rx_data_tick(spi_rx_data_tick),
		.rx_data(spi_rx_data),
		.tx_data_tick(spi_tx_data_tick),
		.tx_data(spi_tx_data)
	);

	mcp3004_controller mcp3004_controller_unit (
		.clk(clk),
		.reset(reset),
		.spi_busy(spi_busy),
		.spi_rx_data_tick(spi_rx_data_tick),
		.spi_rx_data(spi_rx_data),
		.spi_tx_data_tick(spi_tx_data_tick),
		.spi_tx_data(spi_tx_data),
		.rx_data_tick(rx_data_tick),
		.rx_data(rx_data)
	);

endmodule

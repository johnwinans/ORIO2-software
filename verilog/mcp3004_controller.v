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

module mcp3004_controller (
	input wire	reset,
	input wire	clk,					

	input wire spi_busy,

	input wire spi_rx_data_tick,				// SPI transfer complete

	/* verilator lint_save */
	/* verilator lint_off UNUSED */
	input wire [SPI_BIT_WIDTH-1:0] spi_rx_data,
	/* verilator lint_restore */

	output wire spi_tx_data_tick,				// SPI transfer begin
	output wire [SPI_BIT_WIDTH-1:0] spi_tx_data,

	output wire rx_data_tick,					// module data update notification
	output wire [MCP3004_BIT_WIDTH-1:0] rx_data
	);


	localparam MCP3004_BIT_WIDTH = 8*16;	// mcp3004 module message size (8 uint16_t values)
	localparam SPI_BIT_WIDTH = 24;			// SPI buffer size


	reg spi_tx_data_tick_reg = 0, spi_tx_data_tick_next;
	assign spi_tx_data_tick = spi_tx_data_tick_reg;

	reg [SPI_BIT_WIDTH-1:0] spi_tx_data_reg = 0, spi_tx_data_next;
	assign spi_tx_data = spi_tx_data_reg;


	reg rx_data_tick_reg = 0, rx_data_tick_next;
	assign rx_data_tick = rx_data_tick_reg;

	reg [MCP3004_BIT_WIDTH-1:0] rx_data_reg = 0, rx_data_next;
	assign rx_data = rx_data_reg;

	reg [2:0] adc_channel_reg = 0, adc_channel_next;


	localparam STATE_WAIT_SPI_BUSY = 0;
	localparam STATE_START = 1;
	localparam STATE_WAIT_SPI_RX_DATA_TICK = 2;
	localparam NUM_STATES = 4;
	reg [$clog2(NUM_STATES)-1:0] state_reg = STATE_WAIT_SPI_BUSY, state_next;


	always @(posedge clk)
	begin
		if (reset)
		begin
			spi_tx_data_tick_reg <= 0;
			spi_tx_data_reg <= 0;
			rx_data_tick_reg <= 0;
			rx_data_reg <= 0;
			state_reg <= STATE_WAIT_SPI_BUSY;
			adc_channel_reg <= 0;
		end
		else
		begin
			spi_tx_data_tick_reg <= spi_tx_data_tick_next;
			spi_tx_data_reg <= spi_tx_data_next;
			rx_data_tick_reg <= rx_data_tick_next;
			rx_data_reg <= rx_data_next;
			state_reg <= state_next;
			adc_channel_reg <= adc_channel_next;
		end
	end


	always @(*)
	begin
		spi_tx_data_tick_next = 1'b0;
		spi_tx_data_next = spi_tx_data_reg;
		rx_data_tick_next = 1'b0;
		rx_data_next = rx_data_reg;
		state_next = state_reg;
		adc_channel_next = adc_channel_reg;

		case (state_reg)
		STATE_WAIT_SPI_BUSY:
			begin
				if(spi_busy==0)
					state_next = STATE_START;
			end

		STATE_START:
			begin
				spi_tx_data_next = {8'b01, 1'b1, adc_channel_reg, 4'b0, 8'b0};
				adc_channel_next = adc_channel_reg+1;
				spi_tx_data_tick_next = 1'b1;
				state_next = STATE_WAIT_SPI_RX_DATA_TICK;
			end

		STATE_WAIT_SPI_RX_DATA_TICK:
			begin
				if (spi_rx_data_tick==1'b1)
				begin
					state_next = STATE_WAIT_SPI_BUSY;
					rx_data_next = {rx_data_reg[MCP3004_BIT_WIDTH-17:0], 6'b0, spi_rx_data[9:0]};
					if (adc_channel_reg==0)
						rx_data_tick_next = 1'b1;
				end
			end

		endcase
	end


endmodule

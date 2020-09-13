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


module SPI_master
	#(
		parameter BIT_WIDTH=(8),					// SPI message size in bits
		parameter SCK_PERIOD=(100),					// sck divisor: sck = (clk/SCK_PERIOD) (minimum = 2)
		parameter SSEL_SETUP_PERIOD=(SCK_PERIOD*2),	// number of clk periods after SSEL before SCK rising edge (minimum = 1)
		parameter SSEL_HOLD_PERIOD=(SCK_PERIOD*2),	// number of clk periods after SSEL before SCK rising edge (minimum = 1)
		parameter XACT_HOLD_PERIOD=(SCK_PERIOD*2)	// number of clk periods between SSEL rise and SSEL low (minimum = 1)
	)
	(
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
	);

	localparam SH_REG_MAX		= (SSEL_SETUP_PERIOD>SSEL_HOLD_PERIOD?SSEL_SETUP_PERIOD:SSEL_HOLD_PERIOD) > XACT_HOLD_PERIOD ? (SSEL_SETUP_PERIOD>SSEL_HOLD_PERIOD?SSEL_SETUP_PERIOD:SSEL_HOLD_PERIOD) : XACT_HOLD_PERIOD;
	localparam STATE_IDLE		= 0;
	localparam STATE_SSEL_SETUP	= 1;
	localparam STATE_XFER		= 2;
	localparam STATE_SSEL_HOLD	= 3;
	localparam STATE_XACT_HOLD	= 4;
	localparam NUM_STATES		= 5;

	reg [$clog2(BIT_WIDTH):0] bitcnt_reg, bitcnt_next;		// counts the SPI message length
	reg [$clog2(SCK_PERIOD)-1:0] sck_div_reg, sck_div_next;		// clock divider for SCK
	reg [$clog2(NUM_STATES)-1:0] state_reg, state_next;
	reg [$clog2(SH_REG_MAX)-1:0] sh_reg, sh_next;

	reg [BIT_WIDTH-1:0] rx_data_reg, rx_data_next;				// data read from slave
	reg [BIT_WIDTH-1:0] tx_data_reg, tx_data_next;				// data written to slave
	reg rx_data_tick_reg, rx_data_tick_next;
	reg sck_reg, sck_next;
	reg ssel_reg, ssel_next;					// Note this is positive logic within this module

	assign sck = sck_reg;
	assign ssel = ssel_reg;
	assign mosi = tx_data_reg[BIT_WIDTH-1];
	assign rx_data_tick = rx_data_tick_reg;
	assign rx_data = rx_data_reg;
	assign busy = (state_reg!=STATE_IDLE) ? 1'b1 : 1'b0;

	// Note: We don't need to synchronize MISO since it must be sync with SCK by definition
	wire miso_s = miso;

	always @(posedge clk)
	begin
		if (reset)
		begin
			bitcnt_reg <= 0;
			sck_div_reg <= 0;
			state_reg <= STATE_IDLE;
			sh_reg <= 0;

			// rx_data_reg <= 0;		// XXX no need to clear this on reset
			// tx_data_reg <= 0;		// XXX no need to clear this on reset
			rx_data_tick_reg <= 0;
			sck_reg <= 0;
			ssel_reg <= 1;
		end
		else
		begin
			bitcnt_reg <= bitcnt_next;
			sck_div_reg <= sck_div_next;
			state_reg <= state_next;
			sh_reg <= sh_next;

			rx_data_reg <= rx_data_next;
			tx_data_reg <= tx_data_next;
			rx_data_tick_reg <= rx_data_tick_next;
			sck_reg <= sck_next;
			ssel_reg <= ssel_next;
		end
	end



	always @(*)
	begin

		bitcnt_next = bitcnt_reg;
		sck_div_next = sck_div_reg;
		state_next = state_reg;
		sh_next = sh_reg;
		rx_data_next = rx_data_reg;
		tx_data_next = tx_data_reg;
		rx_data_tick_next = rx_data_tick_reg;
		sck_next = sck_reg;
		ssel_next = ssel_reg;

		case (state_reg)
		STATE_IDLE:
			begin
				if (tx_data_tick!=0)
				begin
					tx_data_next = tx_data;	// take a snapshot of the transmit data buffer
					state_next = STATE_SSEL_SETUP;
					sh_next = SSEL_SETUP_PERIOD-1;
					ssel_next = 1'b0;
					bitcnt_next = BIT_WIDTH;

					//sck_next = 0;			// this should never be necessary 
					// Note: mosi is always set to the tx buffer MSb
				end
			end

		STATE_SSEL_SETUP:
			begin
				if (sh_reg!=0)
					sh_next = sh_reg-1;
				else
				begin
					state_next = STATE_XFER;
					sck_div_next = SCK_PERIOD/2;
				end
			end

		STATE_XFER:
			begin
				if (sck_div_reg!=0)
					sck_div_next = sck_div_reg-1;
				else
				begin
					sck_div_next = SCK_PERIOD/2;

					if (sck_reg == 1'b0)
					begin
						// rising edge of SCK = capture the miso bit
						sck_next = 1'b1;
						rx_data_next = {rx_data_reg[BIT_WIDTH-2:0], miso_s};
						bitcnt_next = bitcnt_reg-1;
					end
					else
					begin
						// falling edge of SCK = send the next mosi bit
						sck_next = 1'b0;
						tx_data_next = {tx_data_next[BIT_WIDTH-2:0], 1'b0};		// shift the buffer to tx the next bit

						if (bitcnt_reg == 0)
						begin
							rx_data_tick_next = 1'b1;
							state_next = STATE_SSEL_HOLD;
							sh_next = SSEL_HOLD_PERIOD-1;
						end
					end 
				end
			end

		STATE_SSEL_HOLD:
			begin
				rx_data_tick_next = 1'b0;
				if (sh_reg!=0)
					sh_next = sh_reg-1;
				else
				begin
					ssel_next = 1'b1;
					state_next = STATE_XACT_HOLD;
					sh_next = XACT_HOLD_PERIOD-1;
				end
			end

		STATE_XACT_HOLD:
			begin
				if (sh_reg!=0)
					sh_next = sh_reg-1;
				else
					state_next = STATE_IDLE;
			end
		endcase

	end

endmodule

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


/*
* SPI message format:
*
* TX buffer:					RX buffer:
*  0 uint32_t time
*  4 uint32_t quad_ctr0			 0 uint16_t pwm0
*  8 uint32_t quad_ctr1			 2 uint16_t pwm1
* 12 uint32_t quad_ctr2			 4 uint16_t pwm2
* 16 uint32_t quad_ctr3			 6 uint16_t pwm3
* 20 uint32_t quad_ctr4			 8 uint16_t pwm4
* 24 uint32_t quad_ctr5			10 uint16_t pwm5
* 28 uint32_t quad_ctr6			12 uint16_t pwm6
* 32 uint32_t quad_ctr7			14 uint16_t pwm7
* 36 uint32_t quad_ctr8			16 uint16_t pwm8
* 40 uint32_t quad_ctr9			18 uint16_t pwm9
*                               20 uint16_t pwm10
*                               22 uint16_t pwm11
*                               24 uint16_t pwm12
*                               26 uint16_t pwm13
*                               28 uint16_t pwm14
*                               30 uint16_t pwm15

* 44 uint16_t din				32 uint8_t dout
*								33 uint8_t leds
* 46 uint16_t adc0				34 uint8_t sol
* 48 uint16_t adc1				35 uint8_t rsl
* 50 uint16_t adc2
* 52 uint16_t adc3
* 54 uint16_t adc4
* 56 uint16_t adc5
* 58 uint16_t adc6
* 60 uint16_t adc7
*
* 62 uint8_t sw
*/

module top(
    input wire			clk25,			// 25 MHZ
    input wire [1:0]	pb,		// active low reset

    output wire			rsl,
    output wire[7:0]	led,
    output wire[7:0]	sol,
    input wire[7:0]		sw,

    // PI SPI-slave interface
    output wire			spi_miso,	// we send MSB first
    input wire			spi_ss,		// active-low select
    input wire			spi_mosi,
    input wire			spi_sck,	// sample falling, change rising

	// ADC SPI-master interface
	input wire			spi1_miso,
	output wire			spi1_mosi,
	output wire			spi1_sck,
	output wire			spi1_ss,

	input wire [1:0]	fpga_nc,
	input wire [15:0]	fpga_io,

	input wire [9:0]	quad_a,
	input wire [9:0]	quad_b,
	output wire [15:0]	pwm,

	input wire [7:0]	din,
	output wire [7:0]	dout

    );

	wire [1:0] fpga_nc_pu;
	wire [15:0] fpga_io_pu;

    genvar i;

    generate
        for (i = 0; i < 2; i = i + 1) begin: genpwm
			SB_IO #(
				.PIN_TYPE(6'b0000_01),	// output = 0, input = 1
				.PULLUP(1'b1)			// enable the pullup = 1
			) fpga_nc_pullup (
				.PACKAGE_PIN(fpga_nc[i]),	// the physical pin number with the pullup on it
				.D_IN_0(fpga_nc_pu[i])		// an internal wire for this pin
			);
        end
    endgenerate

    generate
        for (i = 0; i < 16; i = i + 1) begin: genpwm
			SB_IO #(
				.PIN_TYPE(6'b0000_01),	// output = 0, input = 1
				.PULLUP(1'b1)			// enable the pullup = 1
			) fpga_io_pullup (
				.PACKAGE_PIN(fpga_io[i]),	// the physical pin number with the pullup on it
				.D_IN_0(fpga_io_pu[i])		// an internal wire for this pin
			);
        end
    endgenerate





	localparam SPI_MSG_WIDTH = (4+10*4+2+8*2+1)*8;		// this is the TX message length (it is longer)

	wire rstp;			// reset with a pullup
	wire rst = ~rstp;	// make rst an active high signal

	wire userp;			// user with a pullup
	wire user = ~userp;	// make user an active high signal

	// pullup resistors on the push button inputs
	SB_IO #(
		.PIN_TYPE(6'b0000_01),	// output = 0, input = 1
		.PULLUP(1'b1)			// enable the pullup = 1
	) reset_button(
		.PACKAGE_PIN(pb[0]),	// the physical pin number with the pullup on it
		.D_IN_0(rstp)			// an internal wire for this pin
	);
	SB_IO #(
		.PIN_TYPE(6'b0000_01),	// output = 0, input = 1
		.PULLUP(1'b1)			// enable the pullup = 1
	) user_button(
		.PACKAGE_PIN(pb[1]),	// the physical pin number with the pullup on it
		.D_IN_0(userp)			// an internal wire for this pin
	);

	assign dout = pi_rx_data_reg[SPI_MSG_WIDTH-(8*32)-1:SPI_MSG_WIDTH-(8*33)];
	assign led = pi_rx_data_reg[SPI_MSG_WIDTH-(8*33)-1:SPI_MSG_WIDTH-(8*34)];
	assign sol = pi_rx_data_reg[SPI_MSG_WIDTH-(8*34)-1:SPI_MSG_WIDTH-(8*35)];
	assign rsl = pi_rx_data_reg[SPI_MSG_WIDTH-(8*35)-8];								// LSb of the rsl byte

	// Establish the main system clock
	wire clk;
/*
	localparam CLOCK_HZ = 100000000;
	pll_25_100 upll(.clock_in(clk25), .global_clock(clk));
*/

	localparam CLOCK_HZ = 39844444;
	pll_25_40 upll(.clock_in(clk25), .global_clock(clk));
/*
	localparam CLOCK_HZ = 25000000;
	assign clk = clk25;
*/

	wire spi_miso_lz;		// internal low-Z output signal
	// MISO should be high-z when not selected
	assign spi_miso = spi_miso_lz; //(spi_ss==0) ? spi_miso_lz : 1'bz;

	// A 1mhz timer for the uptime in the SPI response messages
	reg [31:0] time_reg;
	reg [7:0] mod_reg;

	wire pi_rx_data_tick;
	wire [SPI_MSG_WIDTH-1:0] pi_rx_data;
	reg [SPI_MSG_WIDTH-1:0] pi_rx_data_reg;
	wire [31:0] quad_ctr [9:0];

	wire [8*2*8-1:0] adc_rx_data;
	reg [8*2*8-1:0] adc_rx_data_reg, adc_rx_data_next;

	wire adc_rx_data_tick;

	always @(posedge clk)
	begin
		if (rst)
		begin
			mod_reg <= 0;
			time_reg <= 0;
			pi_rx_data_reg <= 0;
			adc_rx_data_reg <= 0;
		end else begin
			if (mod_reg == 100)
			begin
				mod_reg <=0;
				time_reg <= time_reg + 1;
			end
			else
				mod_reg <= mod_reg + 1;

			if (pi_rx_data_tick)
				pi_rx_data_reg <= pi_rx_data;

			adc_rx_data_reg <= adc_rx_data_next;
		end
	end

	always @(*)
	begin
		adc_rx_data_next = adc_rx_data_tick ? adc_rx_data : adc_rx_data_reg;
	end


// XXX this needs a tx_buffer to snapshot the tx_data on the falling edge of SSEL  

	wire [6:0] din_nc;
	//assign din_nc = 0;
	assign din_nc = {&{fpga_io_pu, fpga_nc_pu}, 6'b0};	// XXX just to use the fpga IO pins to prevent the elimination of the pullups

	SPI_slave #( .BIT_WIDTH(SPI_MSG_WIDTH) ) spi(
    	.reset(rst), 
    	.clk(clk), 
    	.sck(spi_sck), 
    	.ssel(spi_ss), 
    	.mosi(spi_mosi), 
    	.miso(spi_miso_lz), 
    	.rx_data_tick(pi_rx_data_tick), 
    	.rx_data(pi_rx_data),
    	.tx_data({time_reg, quad_ctr[0], quad_ctr[1], quad_ctr[2], quad_ctr[3], quad_ctr[4], quad_ctr[5], quad_ctr[6], quad_ctr[7], quad_ctr[8], quad_ctr[9], user, din_nc, din, adc_rx_data_reg, sw_pu})	// XXX user, din not sync
    );

	
	// generate the reference clock for the quadrature sampler
	//wire qclk = time_reg[0];	// 500khz
	//wire qclk = time_reg[1];	// 250khz
	//wire qclk = time_reg[2];	// 125khz
	//wire qclk = time_reg[3];	// 62.5khz
	//wire qclk = time_reg[4];	// 31.25khz
	//assign refclk = qclk;


	// pullup resistors on the switch inputs
	wire [7:0] sw_pu;
/* This does not work (generates warnings about reducing the width to 1)
	SB_IO #(
		.PIN_TYPE(6'b0000_01),	// output = 0, input = 1
		.PULLUP(1'b1)			// enable the pullup = 1
	) sw_unit (
		.PACKAGE_PIN(sw),	// the physical pin number with the pullup on it
		.D_IN_0(sw_pu)		// an internal wire for this pin
	);
*/
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_sw
			SB_IO #(
				.PIN_TYPE(6'b0000_01),	// output = 0, input = 1
				.PULLUP(1'b1)			// enable the pullup = 1
			) sw_unit (
				.PACKAGE_PIN(sw[i]),	// the physical pin number with the pullup on it
				.D_IN_0(sw_pu[i])		// an internal wire for this pin
			);
        end
    endgenerate

    generate
        for (i = 0; i < 16; i = i + 1) begin: gen_pwm
            pwm #(
				.CLK_FREQ(CLOCK_HZ) 
			)
			unit (
                .clk(clk),
                .rst(rst),
                .duty(pi_rx_data_reg[SPI_MSG_WIDTH-(i*16)-1:SPI_MSG_WIDTH-((i+1)*16)]),
                .out(pwm[i])
            );
        end
    endgenerate


    generate
        for (i = 0; i < 10; i = i + 1) begin: gen_quad
			quadin quad9 (
    			.clk(clk),
    			.reset(rst),

    			.a(quad_a[i]),
    			.b(quad_b[i]),
/*
    			.a(quad_a[0]),.b(quad_b[0]),		// XXX test all on the same input
*/

    			.count(quad_ctr[i])
    			);
        end
    endgenerate

	mcp3004 #(
		.SCK_PERIOD(CLOCK_HZ/1000000),	// want to run at 1MHz
	)
	mcp3004_unit
	(
		.clk(clk),
		.reset(rst),
		.sck(spi1_sck),
		.ssel(spi1_ss),
		.mosi(spi1_mosi),
		.miso(spi1_miso),
		.rx_data_tick(adc_rx_data_tick),
		.rx_data(adc_rx_data)
	);


endmodule

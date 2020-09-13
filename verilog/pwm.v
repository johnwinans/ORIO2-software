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


module pwm
	#(
		parameter CLK_FREQ=(25000000),	// frequency of clk
		parameter CLK_TICKS=(65536),	// total clock ticks per pwm period
		localparam PWM_FREQ=(60)		// the PWM period is 60HZ
	)
	(
    input clk,							// system clock running at CLK_FREQ HZ
    input rst,							// active high reset
	input [$clog2(CLK_TICKS)-1:0] duty,	// number of ticks of high time
	output out							// pwm modulated output
    );

	localparam CLK_DIV=CLK_FREQ/(PWM_FREQ*CLK_TICKS);

	//reg out_reg;
	//reg out_next;
	//assign out = out_reg;
	assign out = (duty > ctr_reg) ? 1 : 0;

	reg [$clog2(CLK_DIV)-1:0] clk_div_reg, clk_div_next;
	reg [$clog2(CLK_TICKS)-1:0] ctr_reg, ctr_next;

	always @(posedge clk)
	begin
		if (rst)
		begin
			ctr_reg <= 0;
			//out_reg <= 0;
			clk_div_reg <= 0;
		end
		else
		begin
			ctr_reg <= ctr_next;
			//out_reg <= out_next;
			clk_div_reg <= clk_div_next;
		end
	end

	always @(*)
	begin
		clk_div_next = (clk_div_reg<CLK_DIV) ? clk_div_reg+1 : 0;

		if (clk_div_reg == 0)
			ctr_next = (ctr_reg < CLK_TICKS) ? (ctr_reg + 1) : 0;
		else
			ctr_next = ctr_reg;

		//out_next = (duty > ctr_reg) ? 1 : 0;
	end

endmodule

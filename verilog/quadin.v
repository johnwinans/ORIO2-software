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


module quadin(
	input			clk,		// system clock
	input 			reset,		// set count to 0
	input			a,			// quadrature phase a
	input			b,			// quadrature phase b
	output [31:0]	count		// signed position value
    );

	reg [31:0]	count_reg, count_next;
	reg [1:0]	state_reg, state_next;
	wire [1:0] qin;
	
	assign count = count_reg;

	signal_sync  #(.WIDTH(2)) sync (.clkB(clk), .inA({a,b}), .outB(qin));

	always @(posedge clk)
	begin
		if (reset)
		begin
			count_reg <= 0;
			state_reg <= qin;
		end
		else
		begin
			count_reg <= count_next;
			state_reg <= state_next;
		end
	end

	always @(*)
	begin
		count_next = count_reg;
		state_next = qin;

		case ({state_reg,qin})
		4'b0001: count_next = count_reg+1;
		4'b0010: count_next = count_reg-1;
		4'b0100: count_next = count_reg-1;
		4'b0111: count_next = count_reg+1;
		4'b1011: count_next = count_reg-1;
		4'b1000: count_next = count_reg+1;
		4'b1101: count_next = count_reg-1;
		4'b1110: count_next = count_reg+1;
		endcase
	end

endmodule


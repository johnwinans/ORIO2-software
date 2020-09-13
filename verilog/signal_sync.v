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

// Synchronize a single bit signal level across two clock domains

module signal_sync #(
		parameter WIDTH = 1
	) (
		input wire [WIDTH-1:0]	inA,	// signal A in clock domain A
    	input wire				clkB,	// clock for domain B
		output wire [WIDTH-1:0]	outB	// inA synchronized to clkB
	);

	reg [WIDTH-1:0] ff1_reg;
	reg [WIDTH-1:0] ff2_reg;

	always @(posedge clkB) 
	begin
		ff1_reg <= inA;
		ff2_reg <= ff1_reg;
	end

	assign outB = ff2_reg;

endmodule


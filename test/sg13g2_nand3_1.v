`timescale 1ns/10ps
`celldefine
module sg13g2_nand3_1 (Y, A, B, C);
	output Y;
	input A, B, C;
	wire int_fwire_0;
	and (int_fwire_0, A, B, C);
	not (Y, int_fwire_0);
endmodule
`endcelldefine

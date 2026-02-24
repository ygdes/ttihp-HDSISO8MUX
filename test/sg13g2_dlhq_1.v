`ifdef _udp_def_ihp_latch_
`else
`define _udp_def_ihp_latch_
primitive ihp_latch (q, v, clk, d);
	output q;
	reg q;
	input v, clk, d;
	table
		* ? ? : ? : x;
		? 1 0 : ? : 0;
		? 1 1 : ? : 1;
		? x 0 : 0 : -;
		? x 1 : 1 : -;
		? 0 ? : ? : -;
	endtable
endprimitive
`endif

// type: DLHQ
`timescale 1ns/10ps
`celldefine
module sg13g2_dlhq_1 (Q, D, GATE);
	output Q;
	input D, GATE;
	reg notifier;

	// Function
	wire int_fwire_IQ;

	ihp_latch (int_fwire_IQ, notifier, GATE, D);
	buf (Q, int_fwire_IQ);

endmodule
`endcelldefine

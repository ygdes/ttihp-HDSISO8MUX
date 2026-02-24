/*
 * src/SISO_latch.v (c) 2026 Yann Guidon / whygee@f-cpu.org
 * SPDX-License-Identifier: Apache-2.0
 * Check the /doc and the diagrams at
 *   https://github.com/ygdes/ttihp-HDSISO8/tree/main/docs
 *
 * This is one of the 3 versions :
 *  - siso_slice4_dl_neg (this one) is the ol'good version
 *      using standard latches. Reliable but bulky.
 *  - siso_slice4_mx_neg does the same but smaller and
 *      with less constrained timing.
 *  - siso_slice4_mx_pos is siso_slice4_dl_neg but with internally
 *       inverted control signal, for bubble pushing.
 *
 * 4 versions are provided:
 *  - siso_slice4_dl_neg         stores 4 bits in parallel, driver by one inv_4.
 *  - siso_tranche4x4_dl_neg     stores 16 bits (12 effective).
 *  - siso_tranche4x4x4_dl_pos   stores 64 bits, control pulse polarity is back to positive.
 *  - siso_tranche4x4x4x4_dl_pos stores 256 bits, polarity preserved by double inversion.
 *
 * To shift the 4 data bits from siso_in to siso_out, provide 4 sequential,
 * non-overlapping positive pulses on latch[3:0], starting from bit 0 to bit 3.
 * It takes 4 pulses for a new data nibble to appear at the output.
 */

//.................................................................................

`ifdef  ygdef_Inverters_x4
`else
`define ygdef_Inverters_x4

// Just a 4-bit interter-buffer to keep the code size down.
// area : 4 × 10.9 = 43.6
module Inverters_x4 (
    input  wire [3:0] A,
    output wire [3:0] Y);

  (* keep *) sg13g2_inv_4  Amp0(.Y(Y[0]), .A(A[0]));
  (* keep *) sg13g2_inv_4  Amp1(.Y(Y[1]), .A(A[1]));
  (* keep *) sg13g2_inv_4  Amp2(.Y(Y[2]), .A(A[2]));
  (* keep *) sg13g2_inv_4  Amp3(.Y(Y[3]), .A(A[3]));
endmodule

`endif

//.................................................................................

// sg13g2_dlhq_1 area = 30.8
// sg13g2_inv_4  area = 10.9
// Total : 134.1
module siso_slice4_dl_neg (      // Pulse low to latch
    input  wire [3:0] siso_in,   // 4 staggered data inputs
    output wire [3:0] siso_out,  // 4 staggered data outputs
    input  wire       latch      // pass/keep signal
);

  wire latch_n;
  (* keep *) sg13g2_inv_4 Amp(.Y(latch_n), .A(latch));
  (* keep *) sg13g2_dlhq_1 l0(.Q(siso_out[0]), .D(siso_in[0]), .GATE(latch_n));
  (* keep *) sg13g2_dlhq_1 l1(.Q(siso_out[1]), .D(siso_in[1]), .GATE(latch_n));
  (* keep *) sg13g2_dlhq_1 l2(.Q(siso_out[2]), .D(siso_in[2]), .GATE(latch_n));
  (* keep *) sg13g2_dlhq_1 l3(.Q(siso_out[3]), .D(siso_in[3]), .GATE(latch_n));
endmodule

//.................................................................................

// area: 4 × 134.1 = 536.4
// 16 latches hold 12 bits
module siso_tranche4x4_dl_neg (  // Pulse low to latch
    input  wire [3:0] siso_in,   // 4 staggered data inputs
    output wire [3:0] siso_out,  // 4 staggered data outputs
    input  wire [3:0] latch      // pass/keep signals
);

  wire [3:0] t1, t2, t3;
  siso_slice4_dl_neg slice0(.siso_in(siso_in), .siso_out(t1),       .latch(latch[3]));
  siso_slice4_dl_neg slice1(.siso_in(t1),      .siso_out(t2),       .latch(latch[2])); // p in reverse order
  siso_slice4_dl_neg slice2(.siso_in(t2),      .siso_out(t3),       .latch(latch[1]));
  siso_slice4_dl_neg slice3(.siso_in(t3),      .siso_out(siso_out), .latch(latch[0]));
endmodule

//.................................................................................

// area: 4×(536.4 + 10.9) = 2189.2
// 64 latches hold 48 bits
module siso_tranche4x4x4_dl_pos ( // Pulse high to latch
    input  wire [3:0] siso_in,    // 4 staggered data inputs
    output wire [3:0] siso_out,   // 4 staggered data outputs
    input  wire [3:0] latch       // pass/keep signals
);

  wire [3:0] t1, t2, t3, p;
  Inverters_x4 Amp(.Y(p), .A(latch));
  siso_tranche4x4_dl_neg tranche0(.siso_in(siso_in), .siso_out(t1),       .latch(p));
  siso_tranche4x4_dl_neg tranche1(.siso_in(t1),      .siso_out(t2),       .latch(p));
  siso_tranche4x4_dl_neg tranche2(.siso_in(t2),      .siso_out(t3),       .latch(p));
  siso_tranche4x4_dl_neg tranche3(.siso_in(t3),      .siso_out(siso_out), .latch(p));
endmodule

//.................................................................................

// area: 5×43.6 + 4×2189.2 = 8974.8
// 256 latches hold 192 bits
module siso_tranche4x4x4x4_dl_pos ( // Pulse high to latch
    input  wire [3:0] siso_in,      // 4 staggered data inputs
    output wire [3:0] siso_out,     // 4 staggered data outputs
    input  wire [3:0] latch         // pass/keep signals
);

  wire [3:0] t1, t2, t3, q, p0, p1, p2, p3;
  // Double inversion, but last stage is per-tranche for better distance/reach
  Inverters_x4  Amp0(.Y(q ), .A(latch));
  Inverters_x4  Amp1(.Y(p0), .A(q));
  Inverters_x4  Amp2(.Y(p1), .A(q));
  Inverters_x4  Amp3(.Y(p2), .A(q));
  Inverters_x4  Amp4(.Y(p3), .A(q));

  siso_tranche4x4x4_dl_pos tranche0(.siso_in(siso_in), .siso_out(t1),       .latch(p0));
  siso_tranche4x4x4_dl_pos tranche1(.siso_in(t1),      .siso_out(t2),       .latch(p1));
  siso_tranche4x4x4_dl_pos tranche2(.siso_in(t2),      .siso_out(t3),       .latch(p2));
  siso_tranche4x4x4_dl_pos tranche3(.siso_in(t3),      .siso_out(siso_out), .latch(p3));
endmodule


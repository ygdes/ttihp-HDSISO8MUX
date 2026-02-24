/*
 * Copyright (c) 2026 Yann Guidon / whygee@f-cpu.org
 * SPDX-License-Identifier: Apache-2.0
 * Check the /doc and the diagrams at
 *   https://github.com/ygdes/ttihp-HDSISO8/tree/main/docs
 */

`default_nettype none

module tt_um_ygdes_hdsiso8_mux2 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

////////////////////////////// Plumbing //////////////////////////////

  // IO config & misc.
  assign uio_oe  = 8'b11111111; // port uio goes all out


  // General/housekeeping signals
  wire CLK_SEL, EXT_CLK, EXT_RST;
  assign CLK_SEL   = ui_in[0];
  assign EXT_CLK   = ui_in[1];
  assign EXT_RST   = ui_in[2];
//assign           = ui_in[4]; // unused

  wire CLK_OUT, CLK_OUTn;
  assign uo_out[1] = CLK_OUTn;


  // SISO
  wire D_OUT, D_IN;
  assign D_IN      = ui_in[3];
  assign uo_out[0] = D_OUT;

  // Johnson counter
  wire [3:0] Johnson4;
  assign uo_out[2] = Johnson4[0];
  assign uo_out[3] = Johnson4[1];
  assign uo_out[4] = Johnson4[2];
  assign uo_out[5] = Johnson4[3];


  // LFSR
  wire SHOW_LFSR, LFSR_EN, DIN_SEL;
  assign SHOW_LFSR = ui_in[5];
  assign LFSR_EN   = ui_in[6];
  assign DIN_SEL   = ui_in[7];

  wire LFSR_PERIOD, LFSR_BIT;
  assign uo_out[6] = LFSR_PERIOD;
  assign uo_out[7] = LFSR_BIT;


  // multiplexed output
  // assign uio_out = SHOW_LFSR ? LFSR_state8 : Decoded8 ;
  wire SHOW_LFSR_n1, SHOW_LFSR_n2;
  (* keep *) sg13g2_inv_4 negShow1(.Y(SHOW_LFSR_n1), .A(SHOW_LFSR));
  (* keep *) sg13g2_inv_4 negShow2(.Y(SHOW_LFSR_n2), .A(SHOW_LFSR));
  wire [7:0] LFSR_state8, Decoded8;
  (* keep *) sg13g2_mux2_2 mux_uio0(.A0(LFSR_state8[0]), .A1(Decoded8[0]), .S(SHOW_LFSR_n1), .X(uio_out[0]));
  (* keep *) sg13g2_mux2_2 mux_uio1(.A0(LFSR_state8[1]), .A1(Decoded8[1]), .S(SHOW_LFSR_n1), .X(uio_out[1]));
  (* keep *) sg13g2_mux2_2 mux_uio2(.A0(LFSR_state8[2]), .A1(Decoded8[2]), .S(SHOW_LFSR_n1), .X(uio_out[2]));
  (* keep *) sg13g2_mux2_2 mux_uio3(.A0(LFSR_state8[3]), .A1(Decoded8[3]), .S(SHOW_LFSR_n1), .X(uio_out[3]));
  (* keep *) sg13g2_mux2_2 mux_uio4(.A0(LFSR_state8[4]), .A1(Decoded8[4]), .S(SHOW_LFSR_n2), .X(uio_out[4]));
  (* keep *) sg13g2_mux2_2 mux_uio5(.A0(LFSR_state8[5]), .A1(Decoded8[5]), .S(SHOW_LFSR_n2), .X(uio_out[5]));
  (* keep *) sg13g2_mux2_2 mux_uio6(.A0(LFSR_state8[6]), .A1(Decoded8[6]), .S(SHOW_LFSR_n2), .X(uio_out[6]));
  (* keep *) sg13g2_mux2_2 mux_uio7(.A0(LFSR_state8[7]), .A1(Decoded8[7]), .S(SHOW_LFSR_n2), .X(uio_out[7]));


////////////////////////////// custom soup //////////////////////////////

  // select the clock
  // CLK_OUT = clk if CLK_SEL=0, else EXT_CLK
  // assign CLK_OUT = CLK_SEL ? EXT_CLK : clk;
  (* keep *) sg13g2_mux2_2 mux_clk(.A0(clk), .A1(EXT_CLK), .S(CLK_SEL), .X(CLK_OUT));
  // ring oscillator anyone ?
  (* keep *) sg13g2_inv_4 negClkOut(.Y(CLK_OUTn), .A(CLK_OUT));

  wire INT_RESET;
  // Combined and resynch'ed Reset
  (* keep *) sg13g2_dfrbpq_2 DFF_reset(.Q(INT_RESET), .D(EXT_RST), .RESET_B(rst_n), .CLK(CLK_OUT));


  // Select + resynch D_in
  wire SISO_in;
  //      SISO_in <= DIN_SEL ? LFSR_BIT : D_IN;
  (* keep *) sg13g2_sdfrbpq_1 sync_Din(.Q(SISO_in), .D(D_IN),
                         .SCD(LFSR_BIT), .SCE(DIN_SEL), .RESET_B(INT_RESET), .CLK(CLK_OUT));

////////////////////////////// sub-modules //////////////////////////////

  LFSR8 lfsr(
    .CLK(CLK_OUT),
    .RESET(INT_RESET),
    .LFSR_EN(LFSR_EN),
    .LFSR_PERIOD(LFSR_PERIOD),
    .LFSR_BIT(LFSR_BIT),
    .LFSR_STATE(LFSR_state8));  // the LFSR state is directly routed to the byte output, will be muxed later.

  Johnson8 J8(
    .CLK(CLK_OUT),
    .RESET(INT_RESET),
    .DFF4(Johnson4),
    .Decoded8(Decoded8));


// JUST A TEST FOR NOW  !!!! The MUX/DEMUX IS STILL MISSING SO IT'S F/8

  // looping the SISO on itself to get 8× downsampling because no demux yet

  // First, sample the data at the right moment
  wire back;
    (* keep *) sg13g2_sdfrbpq_1 sync8(.Q(back), .D(back),
       .SCD(SISO_in), .SCE(Decoded8[5]), .RESET_B(INT_RESET), .CLK(CLK_OUT));

  wire [3:0] siso_in4, siso_out4, latch4, latch4neg,
          chain4_a, chain4_b, chain4_c, chain4_d, chain4_e ;    // l'originalité des noms de variables......
  assign siso_in4[0] = back;
  assign siso_in4[1] = siso_out4[0];
  assign siso_in4[2] = siso_out4[1];  // au diable la syntaxe,
  assign siso_in4[3] = siso_out4[2];  // mate le formatage
  assign D_OUT       = siso_out4[3];
  assign latch4 = {
    Decoded8[0], // the first latch's data is locked during the transition from [0] to [1]
    Decoded8[2],
    Decoded8[4], // Input is sampled by sync8 at [5] so setup&hold should be comfortable.
    Decoded8[6]
  };
  Inverters_x4 BoostLatch(.Y(latch4neg), .A(latch4));

// goal=512 bits, actual storage is × 4/3 = 682
// 2×( 256+64+16 ) = 672 bits, close enough.

  siso_tranche4x4x4x4_mx_pos siso256_1(
    .siso_in(siso_in4),
    .siso_out(chain4_a),
    .latch(latch4));

  siso_tranche4x4x4x4_mx_pos siso256_2(
    .siso_in(chain4_a),
    .siso_out(chain4_b),
    .latch(latch4));

  siso_tranche4x4x4_mx_pos siso64_1(
    .siso_in(chain4_b),
    .siso_out(chain4_c),
    .latch(latch4));

  siso_tranche4x4x4_mx_pos siso64_2(
    .siso_in(chain4_c),
    .siso_out(chain4_d),
    .latch(latch4));

  siso_tranche4x4_mx_neg siso16_1(
    .siso_in(chain4_d),
    .siso_out(chain4_e),
    .latch(latch4neg));  // NEG here

  siso_tranche4x4_mx_neg siso16_2(
    .siso_in(chain4_e),
    .siso_out(siso_out4),
    .latch(latch4neg));  // NEG here too


////////////////////////////// All the dummies go here //////////////////////////////

  // List all unused inputs to prevent warnings
  wire _unused = &{
    ena,       // They said not to bother, then ... why provide it ?
    uio_in,
    ui_in[4],
    1'b0};

endmodule

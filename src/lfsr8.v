// lfsr8.v
// © 2026 Yann Guidon / whygee@f-cpu.org

// Just a 8-bit LFSR for Tiny Tapeout targetting the iHP CMOS PDK
// LFSR shifts "right" (down to LSB) with poly 0x95
// Check the "map" image in /doc

module LFSR8(
  input wire CLK,
  input wire RESET,
  input wire LFSR_EN,

  output wire LFSR_PERIOD,
  output wire LFSR_BIT,
  output [7:0] LFSR_STATE);

  wire dum1, dum2; // some unused DFF outputs
  wire _unused = &{dum1, dum2, 1'b0};

  wire feedback;
  // pulling LFSR_EN low stalls the LFSR even if the clock runs. Toggle RESET to restart
  (* keep *) sg13g2_and2_2 stall(.X(feedback), .A(LFSR_STATE[0]), .B(LFSR_EN));

  assign LFSR_BIT = LFSR_STATE[0];

  // The poly XORs
  wire x1, x2, x3; 
  (* keep *) sg13g2_xor2_1 x_a(.X(x1), .A(feedback), .B(LFSR_STATE[5]));
  (* keep *) sg13g2_xor2_1 x_b(.X(x2), .A(feedback), .B(LFSR_STATE[3]));
  (* keep *) sg13g2_xor2_1 x_c(.X(x3), .A(feedback), .B(LFSR_STATE[1]));

  // The actual shit register, that supports "reset to 00000110"
  (* keep *) sg13g2_dfrbpq_2 lfsr7(            .Q(LFSR_STATE[7]), .D(feedback),      .RESET_B(RESET), .CLK(CLK));
  (* keep *) sg13g2_dfrbpq_2 lfsr6(            .Q(LFSR_STATE[6]), .D(LFSR_STATE[7]), .RESET_B(RESET), .CLK(CLK));
  (* keep *) sg13g2_dfrbpq_2 lfsr5(            .Q(LFSR_STATE[5]), .D(LFSR_STATE[6]), .RESET_B(RESET), .CLK(CLK));
  (* keep *) sg13g2_dfrbpq_2 lfsr4(            .Q(LFSR_STATE[4]), .D(x1),            .RESET_B(RESET), .CLK(CLK));
  (* keep *) sg13g2_dfrbpq_2 lfsr3(            .Q(LFSR_STATE[3]), .D(LFSR_STATE[4]), .RESET_B(RESET), .CLK(CLK));
  (* keep *) sg13g2_dfrbp_2  lfsr2(.Q(dum1), .Q_N(LFSR_STATE[2]), .D(x2),            .RESET_B(RESET), .CLK(CLK));
  (* keep *) sg13g2_dfrbp_2  lfsr1(.Q(dum2), .Q_N(LFSR_STATE[1]), .D(LFSR_STATE[2]), .RESET_B(RESET), .CLK(CLK));
  (* keep *) sg13g2_dfrbpq_2 lfsr0(            .Q(LFSR_STATE[0]), .D(x3),            .RESET_B(RESET), .CLK(CLK));

  // assign LFSR_PERIOD = &{LFSR_STATE};
  wire and8_1, and8_2;
  (* keep *) sg13g2_and4_2 period4_1(.X(and8_1), .A(LFSR_STATE[0]), .B(LFSR_STATE[1]), .C(LFSR_STATE[2]), .D(LFSR_STATE[3]));
  (* keep *) sg13g2_and4_2 period4_2(.X(and8_2), .A(LFSR_STATE[4]), .B(LFSR_STATE[5]), .C(LFSR_STATE[6]), .D(LFSR_STATE[7]));
  (* keep *) sg13g2_and2_2 period8(.X(LFSR_PERIOD), .A(and8_1), .B(and8_2));

endmodule

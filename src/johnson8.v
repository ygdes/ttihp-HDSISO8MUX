
/* johnson8.v  by whygee@f-cpu.org
  8-step sequencer using an inverted ring counter,
  aka Johnson counter. 4 DFF, 8 AND (NAND+INV4).
  using raw cells from iHP CMOS PDK
*/

module Johnson8(
  input  wire CLK,
  input  wire RESET,
  output wire [3:0] DFF4,
  output wire [7:0] Decoded8);

  // Boost Reset
  wire rst, rst1, rst2, rst3;
  (* keep *) sg13g2_inv_4 boost0(.Y(rst),  .A(RESET));
  (* keep *) sg13g2_inv_4 boost1(.Y(rst1), .A(rst));
  (* keep *) sg13g2_inv_4 boost2(.Y(rst2), .A(rst));
  (* keep *) sg13g2_inv_4 boost3(.Y(rst3), .A(rst));

  // The ring counter
  wire [3:0] J4P, J4N;
  (* keep *) sg13g2_dfrbp_2  DFF_J1(.Q(J4P[0]), .Q_N(J4N[0]), .D(J4N[3]), .RESET_B(rst1), .CLK(CLK));
  (* keep *) sg13g2_dfrbp_2  DFF_J2(.Q(J4P[1]), .Q_N(J4N[1]), .D(J4P[0]), .RESET_B(rst1), .CLK(CLK));
  (* keep *) sg13g2_dfrbp_2  DFF_J3(.Q(J4P[2]), .Q_N(J4N[2]), .D(J4P[1]), .RESET_B(rst1), .CLK(CLK));
  (* keep *) sg13g2_dfrbp_2  DFF_J4(.Q(J4P[3]), .Q_N(J4N[3]), .D(J4P[2]), .RESET_B(rst1), .CLK(CLK));
  assign DFF4 = J4P;

  // The decoder
  wire [7:0] DecN;
  (* keep *) sg13g2_nand3_1 dec0(.Y(DecN[0]), .A(J4N[3]), .B(J4N[0]), .C(rst2));
  (* keep *) sg13g2_nand3_1 dec1(.Y(DecN[1]), .A(J4P[0]), .B(J4N[1]), .C(rst2));
  (* keep *) sg13g2_nand3_1 dec2(.Y(DecN[2]), .A(J4P[1]), .B(J4N[2]), .C(rst2));
  (* keep *) sg13g2_nand3_1 dec3(.Y(DecN[3]), .A(J4P[2]), .B(J4N[3]), .C(rst2));
  (* keep *) sg13g2_nand3_1 dec4(.Y(DecN[4]), .A(J4P[3]), .B(J4P[0]), .C(rst3));
  (* keep *) sg13g2_nand3_1 dec5(.Y(DecN[5]), .A(J4N[0]), .B(J4P[1]), .C(rst3));
  (* keep *) sg13g2_nand3_1 dec6(.Y(DecN[6]), .A(J4N[1]), .B(J4P[2]), .C(rst3));
  (* keep *) sg13g2_nand3_1 dec7(.Y(DecN[7]), .A(J4N[2]), .B(J4P[3]), .C(rst3));

  (* keep *) sg13g2_inv_4 boosta(.Y(Decoded8[0]), .A(DecN[0]));
  (* keep *) sg13g2_inv_4 boostb(.Y(Decoded8[1]), .A(DecN[1]));
  (* keep *) sg13g2_inv_4 boostc(.Y(Decoded8[2]), .A(DecN[2]));
  (* keep *) sg13g2_inv_4 boostd(.Y(Decoded8[3]), .A(DecN[3]));
  (* keep *) sg13g2_inv_4 booste(.Y(Decoded8[4]), .A(DecN[4]));
  (* keep *) sg13g2_inv_4 boostf(.Y(Decoded8[5]), .A(DecN[5]));
  (* keep *) sg13g2_inv_4 boostg(.Y(Decoded8[6]), .A(DecN[6]));
  (* keep *) sg13g2_inv_4 boosth(.Y(Decoded8[7]), .A(DecN[7]));

endmodule

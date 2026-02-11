`timescale 1ns / 1ps

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits internally would generate a carry-out (independent of cin)
 * @param pout whether these 4 bits internally would propagate an incoming carry from cin
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);

   // Group propagate: all bits propagate
   assign pout = &pin;

   // Group generate (independent of cin):
   // gout = g3 | p3 g2 | p3 p2 g1 | p3 p2 p1 g0
   assign gout = gin[3]
              | (pin[3] & gin[2])
              | (pin[3] & pin[2] & gin[1])
              | (pin[3] & pin[2] & pin[1] & gin[0]);

   // Internal carries (carry into bit1/2/3), using c0=cin
   // c1 = g0 | p0 c0
   assign cout[0] = gin[0] | (pin[0] & cin);

   // c2 = g1 | p1 g0 | p1 p0 c0
   assign cout[1] = gin[1]
                  | (pin[1] & gin[0])
                  | (pin[1] & pin[0] & cin);

   // c3 = g2 | p2 g1 | p2 p1 g0 | p2 p1 p0 c0
   assign cout[2] = gin[2]
                  | (pin[2] & gin[1])
                  | (pin[2] & pin[1] & gin[0])
                  | (pin[2] & pin[1] & pin[0] & cin);

endmodule

/** Same as gp4 but for an 8-bit window instead */
module gp8(input wire [7:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [6:0] cout);

   // Build gp8 from two gp4 blocks (low nibble and high nibble)
   wire gout_lo, pout_lo;
   wire [2:0] cout_lo;   // c1..c3 within low nibble
   wire gout_hi, pout_hi;
   wire [2:0] cout_hi;   // carries into bits 5..7 (relative to 8-bit window)
   wire c4;              // carry into bit4

   gp4 u_lo(
      .gin (gin[3:0]),
      .pin (pin[3:0]),
      .cin (cin),
      .gout(gout_lo),
      .pout(pout_lo),
      .cout(cout_lo)
   );

   // carry into bit4: c4 = Glo | Plo*cin
   assign c4 = gout_lo | (pout_lo & cin);

   gp4 u_hi(
      .gin (gin[7:4]),
      .pin (pin[7:4]),
      .cin (c4),
      .gout(gout_hi),
      .pout(pout_hi),
      .cout(cout_hi)
   );

   // Group propagate/generate for 8-bit window (independent of cin)
   assign pout = pout_hi & pout_lo;
   assign gout = gout_hi | (pout_hi & gout_lo);

   // Internal carries (carry into bits 1..7)
   // cout[0]=c1, cout[1]=c2, cout[2]=c3, cout[3]=c4, cout[4]=c5, cout[5]=c6, cout[6]=c7
   assign cout[2:0] = cout_lo;   // c1..c3
   assign cout[3]   = c4;        // c4
   assign cout[6:4] = cout_hi;   // c5..c7

endmodule

module CarryLookaheadAdder
  (input wire [31:0]  a, b,
   input wire         cin,
   output wire [31:0] sum);

   // Bit-level generate/propagate
   wire [31:0] g, p;

   genvar i;
   generate
      for (i = 0; i < 32; i++) begin : GEN_GP1
         gp1 u_gp1(.a(a[i]), .b(b[i]), .g(g[i]), .p(p[i]));
      end
   endgenerate

   // Four 8-bit groups
   wire [3:0] G8, P8;
   wire [6:0] c8_0, c8_1, c8_2, c8_3; // carries into bits 1..7 of each 8-bit group

   // Group carry-ins for each 8-bit block: c8_in[0]=cin, others from gp4 over groups
   wire [3:0] c8_in;
   wire [2:0] c8_grp_cout; // carries into group1..group3
   wire gout32, pout32;

   assign c8_in[0] = cin;

   // gp8 instances (LSB group is [7:0])
   gp8 u_gp8_0(.gin(g[7:0]),   .pin(p[7:0]),   .cin(c8_in[0]), .gout(G8[0]), .pout(P8[0]), .cout(c8_0));
   gp8 u_gp8_1(.gin(g[15:8]),  .pin(p[15:8]),  .cin(c8_in[1]), .gout(G8[1]), .pout(P8[1]), .cout(c8_1));
   gp8 u_gp8_2(.gin(g[23:16]), .pin(p[23:16]), .cin(c8_in[2]), .gout(G8[2]), .pout(P8[2]), .cout(c8_2));
   gp8 u_gp8_3(.gin(g[31:24]), .pin(p[31:24]), .cin(c8_in[3]), .gout(G8[3]), .pout(P8[3]), .cout(c8_3));

   // Top layer: compute carries into 8-bit groups 1..3 using gp4 over group G/P
   gp4 u_gp4_groups(
      .gin (G8),
      .pin (P8),
      .cin (cin),
      .gout(gout32),
      .pout(pout32),
      .cout(c8_grp_cout)
   );

   assign c8_in[1] = c8_grp_cout[0]; // carry into bit8
   assign c8_in[2] = c8_grp_cout[1]; // carry into bit16
   assign c8_in[3] = c8_grp_cout[2]; // carry into bit24

   // Build per-bit carry-in vector c[31:0] (carry into each bit)
   wire [31:0] c;

   assign c[0]     = cin;
   assign c[7:1]   = c8_0;        // carries into bits 1..7
   assign c[8]     = c8_in[1];
   assign c[15:9]  = c8_1;        // carries into bits 9..15
   assign c[16]    = c8_in[2];
   assign c[23:17] = c8_2;        // carries into bits 17..23
   assign c[24]    = c8_in[3];
   assign c[31:25] = c8_3;        // carries into bits 25..31

   // Sum = a XOR b XOR carry_in
   assign sum = (a ^ b) ^ c;

endmodule


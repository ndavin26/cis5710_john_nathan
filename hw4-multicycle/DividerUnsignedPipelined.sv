`timescale 1ns / 1ns

// quotient = dividend / divisor

// Create 32 instances of the DividerOneIter module to compute the 32 bit division
module DividerUnsignedPipelined (
    input wire clk, rst, stall,
    input  wire  [31:0] i_dividend,
    input  wire  [31:0] i_divisor,
    output logic [31:0] o_remainder,
    output logic [31:0] o_quotient
);

    genvar i;

    // We need 8 stages of registers to hold the in-flight data
    // Index 0 will hold the result of the first 4-bit iteration
    logic [31:0] reg_dividend [6:0];
    logic [31:0] reg_remainder [6:0];
    logic [31:0] reg_quotient [6:0];
    logic [31:0] reg_divisor [6:0];

    generate
        for (i = 0; i < 8; i++) begin : gen_divider_stages
            // Intermediate wires for the output of the combinational StageDivider
            wire [31:0] out_div, out_rem, out_quo, out_dvr;
            
            // Inputs for this stage
            wire [31:0] stage_in_div = (i == 0) ? i_dividend : reg_dividend[i-1];
            wire [31:0] stage_in_rem = (i == 0) ? 32'h0      : reg_remainder[i-1];
            wire [31:0] stage_in_quo = (i == 0) ? 32'h0      : reg_quotient[i-1];
            wire [31:0] stage_in_dvr = (i == 0) ? i_divisor   : reg_divisor[i-1];

            StageDivider SD (
                .i_dividend(stage_in_div),
                .i_divisor(stage_in_dvr),
                .i_remainder(stage_in_rem),
                .i_quotient(stage_in_quo),
                .o_dividend(out_div),
                .o_remainder(out_rem),
                .o_quotient(out_quo),
                .o_divisor(out_dvr)
            );

            if (i<7) begin : gen_registers
            always_ff @(posedge clk) begin
                
                if (rst) begin
                    reg_dividend[i] <= 32'h0;
                    reg_remainder[i] <= 32'h0;
                    reg_quotient[i] <= 32'h0;
                    reg_divisor[i] <= 32'h0;
                end
                else begin
                    reg_dividend[i]  <= out_div;
                    reg_remainder[i] <= out_rem;
                    reg_quotient[i]  <= out_quo;
                    reg_divisor[i]   <= out_dvr;
                end
            end
            end

            if (i==7) begin : gen_output_logic
                assign o_quotient = out_quo;
                assign o_remainder = out_rem; 
            end
        end
    endgenerate

endmodule

module StageDivider(
    input wire [31:0] i_dividend,
    input wire [31:0] i_divisor,
    input wire [31:0] i_remainder,
    input wire [31:0] i_quotient,
    output wire [31:0] o_dividend,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient,
    output wire [31:0] o_divisor
);
    genvar i;

    logic [31:0] stage_dividend [4:0];
    logic [31:0] stage_remainder [4:0];
    logic [31:0] stage_quotient [4:0];

    assign stage_dividend[0] = i_dividend;
    assign stage_remainder[0] = i_remainder;
    assign stage_quotient[0] = i_quotient;

    assign o_dividend = stage_dividend[4];
    assign o_remainder = stage_remainder[4];
    assign o_quotient = stage_quotient[4];
    assign o_divisor = i_divisor;

    generate
        for (i=0; i<4; i++) begin : gen_dividers
            DividerOneIter DOI(
                .i_dividend(stage_dividend[i]),
                .i_divisor(i_divisor),
                .i_remainder(stage_remainder[i]),
                .i_quotient(stage_quotient[i]),
                .o_dividend(stage_dividend[i+1]),
                .o_remainder(stage_remainder[i+1]),
                .o_quotient(stage_quotient[i+1])
            );
        end

    endgenerate
endmodule


module DividerOneIter (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    input  wire [31:0] i_remainder,
    input  wire [31:0] i_quotient,
    output wire [31:0] o_dividend,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);
  /*
    for (int i = 0; i < 32; i++) {
        remainder = (remainder << 1) | ((dividend >> 31) & 0x1);
        if (remainder < divisor) {
            quotient = (quotient << 1);
        } else {
            quotient = (quotient << 1) | 0x1;
            remainder = remainder - divisor;
        }
        dividend = dividend << 1;
    }
    */

    // TODO: your code here

    // Construct a temporary remainder wire
    wire [31:0] remainder_temp;

    // Shifts the remainder left and concantenates the MSB of the dividend to the end
    assign remainder_temp = {i_remainder[30:0], i_dividend[31]};  

    // Shift the quotient to the left by one bit. If the remainder is smaller than the divisor, make the new LSB a 0
    // If not, make the new LSB a 1
    assign o_quotient = (remainder_temp < i_divisor) ? {i_quotient[30:0], 1'b0} : {i_quotient[30:0], 1'b1};

    // If the remainder is smaller than the divisor, keep the remainder the same. If not, subtract the divisor from the remainder
    assign o_remainder = (remainder_temp < i_divisor) ? remainder_temp : (remainder_temp - i_divisor);

    // Shift the dividend to the left by 1
    assign o_dividend = {i_dividend[30:0], 1'b0};
    
endmodule

/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ns

// quotient = dividend / divisor

// Create 32 instances of the DividerOneIter module to compute the 32 bit division
module DividerUnsigned (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);

    // TODO: your code here

    // Create the looping variable
    genvar i;

    // Create intermediary variables to hold the values between stages
    logic [31:0] stage_dividend [32:0];
    logic [31:0] stage_remainder [32:0];
    logic [31:0] stage_quotient [32:0];

    // Set the input values for the first stage
    assign stage_remainder[0] = 32'h0;
    assign stage_quotient[0] = 32'h0;
    assign stage_dividend[0] = i_dividend;

    // Set the output values for the final stage
    assign o_remainder = stage_remainder[32];
    assign o_quotient = stage_quotient[32];  

    // Create each instance through the use of a generate block and for loop
    generate
        for (i=0; i<32; i++) begin : gen_dividers

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

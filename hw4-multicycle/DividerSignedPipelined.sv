`timescale 1ns / 1ns

`define REG_SIZE 31:0
`define INSN_SIZE 31:0
`define OPCODE_SIZE 6:0

`include "../hw3-singlecycle/cycle_status.sv"
`include "PipelineStageStructs.sv"
`include "FunctionCalls.sv"  // Includes twos_comp32 function

// Creates an 8 stage pipelined divider. Each stage performs 4 iterations of the non-restoring division algorithm
// Registers hold intermediate values and final results are output to a memory stage struct

module DividerSignedPipelined (
    input wire clk, rst, stall,
    input stage_execute_t i_x_state,
    output stage_memory_t o_m_state
);

    genvar i;

    stage_divider_t divider_state [8:0];  // Only 6:0 used, staves off warnings for now


    logic div_div_by_zero, div_overflow;
    logic div_a_neg, div_b_neg;
    logic [`REG_SIZE] div_a_abs, div_b_abs, dividend_input, divisor_input;
    

    // First stage of the pipeline takes inputs from execute stage struct
    always_comb begin
        divider_state[0].pc = i_x_state.pc;
        divider_state[0].insn = i_x_state.insn;
        divider_state[0].cycle_status = i_x_state.cycle_status;
        divider_state[0].rs2 = i_x_state.rs2;
        divider_state[0].rd = i_x_state.rd;
        divider_state[0].reg_write = i_x_state.reg_write;
        divider_state[0].is_ecall = i_x_state.is_ecall;
        divider_state[0].funct3 = i_x_state.funct3;
        divider_state[0].funct7 = i_x_state.funct7;
        divider_state[0].opcode = i_x_state.opcode;
        divider_state[0].rs2_val = i_x_state.rs2_val;
        divider_state[0].is_div = i_x_state.is_div;

        divider_state[0].dividend_input = 32'b0;
        divider_state[0].divisor_input = 32'b0;

        divider_state[0].is_signed = (i_x_state.funct7 == 7'b0000001) && (i_x_state.funct3[0] == 1'b0);
        divider_state[0].is_rem = (i_x_state.funct7 == 7'b0000001) && ((i_x_state.funct3 == 3'b110) || (i_x_state.funct3 == 3'b111));

        divider_state[0].div_by_zero = i_x_state.rs2_val == 32'b0;
        divider_state[0].overflow = divider_state[0].is_signed && (i_x_state.rs1_val == 32'h8000_0000) && (i_x_state.rs2_val == 32'hFFFF_FFFF);

        div_a_neg = i_x_state.rs1_val[31];
        div_b_neg = i_x_state.rs2_val[31];

        div_a_abs = div_a_neg ? twos_comp32(i_x_state.rs1_val) : i_x_state.rs1_val;
        div_b_abs = div_b_neg ? twos_comp32(i_x_state.rs2_val) : i_x_state.rs2_val;

        if (!divider_state[0].is_signed) begin
            dividend_input = i_x_state.rs1_val;
            divisor_input = i_x_state.rs2_val;
        end else begin
            dividend_input = div_a_abs;
            divisor_input = div_b_abs;
        end 

        divider_state[0].negate_quotient = divider_state[0].is_signed && (div_a_neg ^ div_b_neg);
        divider_state[0].negate_remainder = divider_state[0].is_signed && div_a_neg;

        divider_state[0].dividend = 32'h0;
        divider_state[0].remainder = 32'h0;

        divider_state[0].dividend_input = dividend_input;
        divider_state[0].divisor_input = divisor_input;
    end

    // First divider stage is purely combinational and takes inputs directly from execute stage struct
    StageDivider SD (
        .i_dividend(dividend_input),
        .i_divisor(divisor_input),
        .i_remainder(32'h0),
        .i_quotient(32'h0),
        .o_dividend(divider_state[0].dividend),
        .o_remainder(divider_state[0].remainder),
        .o_quotient(divider_state[0].quotient),
        .o_divisor(divider_state[0].divisor)
    );



    // Create 8 stages
    generate
        for (i = 1; i < 8; i++) begin : gen_divider_stages
            // Intermediate wires for the output of the combinational StageDivider
            wire [`REG_SIZE] out_div, out_rem, out_quo, out_dvr;
            
            // Inputs for this stage. Set to module inputs for first stage and to previous stage's registers for subsequent stages
            // wire [`REG_SIZE] in_div = divider_state[i-1].dividend;
            // wire [`REG_SIZE] in_rem = divider_state[i-1].remainder;
            // wire [`REG_SIZE] in_quo = divider_state[i-1].quotient;
            // wire [`REG_SIZE] in_dvr = divider_state[i-1].divisor;

            // Instantiates the combinational, 4 iteration divider stage
            StageDivider SD (
                .i_dividend(divider_state[i-1].dividend),
                .i_divisor(divider_state[i-1].divisor),
                .i_remainder(divider_state[i-1].remainder),
                .i_quotient(divider_state[i-1].quotient),
                .o_dividend(out_div),
                .o_remainder(out_rem),
                .o_quotient(out_quo),
                .o_divisor(out_dvr)
            );

            // Updates the values in registers on clock edge
            always_ff @(posedge clk) begin
                
                if (rst) begin
                    divider_state[i].pc <= 32'h0;
                    divider_state[i].insn <= 32'h0;
                    divider_state[i].cycle_status <= CYCLE_RESET;
                    divider_state[i].rd <= 5'h0;
                    divider_state[i].rs2 <= 5'h0;
                    divider_state[i].reg_write <= 1'b0;
                    divider_state[i].is_ecall <= 1'b0;
                    divider_state[i].funct3 <= 3'b0;
                    divider_state[i].funct7 <= 7'b0;
                    divider_state[i].opcode <= 7'b0;
                    divider_state[i].rs2_val <= 32'h0;
                    divider_state[i].is_div <= 1'b0;
                    divider_state[i].dividend <= 32'h0;
                    divider_state[i].remainder <= 32'h0;
                    divider_state[i].quotient <= 32'h0;
                    divider_state[i].divisor <= 32'h0;
                    divider_state[i].is_signed <= 1'b0;
                    divider_state[i].negate_quotient <= 1'b0;
                    divider_state[i].negate_remainder <= 1'b0;
                    divider_state[i].is_rem <= 1'b0;
                    divider_state[i].div_by_zero <= 1'b0;
                    divider_state[i].overflow <= 1'b0;
                    divider_state[i].dividend_input <= 32'h0;
                    divider_state[i].divisor_input <= 32'h0;
                end
                else if (!stall)begin
                    //if (i < 7) begin
                        divider_state[i].pc <= divider_state[i-1].pc;
                        divider_state[i].insn <= divider_state[i-1].insn;
                        divider_state[i].cycle_status <= divider_state[i-1].cycle_status;
                        divider_state[i].rs2 <= divider_state[i-1].rs2;
                        divider_state[i].rd <= divider_state[i-1].rd;
                        divider_state[i].reg_write <= divider_state[i-1].reg_write;
                        divider_state[i].is_ecall <= divider_state[i-1].is_ecall;
                        divider_state[i].funct3 <= divider_state[i-1].funct3;
                        divider_state[i].funct7 <= divider_state[i-1].funct7;
                        divider_state[i].opcode <= divider_state[i-1].opcode;
                        divider_state[i].rs2_val <= divider_state[i-1].rs2_val;
                        divider_state[i].is_div <= divider_state[i-1].is_div;
                        divider_state[i].is_signed <= divider_state[i-1].is_signed;
                        divider_state[i].negate_quotient <= divider_state[i-1].negate_quotient;
                        divider_state[i].negate_remainder <= divider_state[i-1].negate_remainder;
                        divider_state[i].is_rem <= divider_state[i-1].is_rem;
                        divider_state[i].div_by_zero <= divider_state[i-1].div_by_zero;
                        divider_state[i].overflow <= divider_state[i-1].overflow;
                        divider_state[i].dividend_input <= divider_state[i-1].dividend_input;
                        divider_state[i].divisor_input <= divider_state[i-1].divisor_input;
                        divider_state[i].dividend <= out_div;
                        divider_state[i].remainder <= out_rem;
                        divider_state[i].quotient <= out_quo;
                        divider_state[i].divisor <= out_dvr;
                    //end 
                    // if (i == 7) begin
                    //     o_m_state.pc <= divider_state[i-1].pc;
                    //     o_m_state.insn <= divider_state[i-1].insn;
                    //     o_m_state.cycle_status <= divider_state[i-1].cycle_status;
                    //     o_m_state.rs2 <= divider_state[i-1].rs2;
                    //     o_m_state.rd <= divider_state[i-1].rd;
                    //     o_m_state.reg_write <= divider_state[i-1].reg_write;
                    //     o_m_state.is_ecall <= divider_state[i-1].is_ecall;
                    //     o_m_state.funct3 <= divider_state[i-1].funct3;
                    //     o_m_state.funct7 <= divider_state[i-1].funct7;
                    //     o_m_state.opcode <= divider_state[i-1].opcode;
                    //     o_m_state.rs2_val <= divider_state[i-1].rs2_val;
                    //     o_m_state.is_div <= divider_state[i-1].is_div;

                    //     divider_state[i].is_rem <= divider_state[i-1].is_rem;
                    //     divider_state[i].is_signed <= divider_state[i-1].is_signed;
                    //     divider_state[i].negate_quotient <= divider_state[i-1].negate_quotient;
                    //     divider_state[i].negate_remainder <= divider_state[i-1].negate_remainder;
                    //     divider_state[i].div_by_zero <= divider_state[i-1].div_by_zero;
                        
                    //     //o_m_state.rd_value <= divider_state[i-1].quotient;

                    //     o_m_state.rd_value <= out_quo;

                    //     // Output is either quotient or remainder based on input control signal
                    //     // Negated if signed and negate control signals are set
                    //     /*if (divider_state[i-1].div_by_zero) begin
                    //         o_m_state.rd_value <= 32'h0; // Could be set to anything since div by zero should be treated as a nop, but set to 0 for consistency
                    //     end else if (divider_state[i-1].overflow) begin
                    //         o_m_state.rd_value <= (divider_state[i-1].is_rem) ? divider_state[i-1].divisor_input : divider_state[i-1].dividend_input; // On overflow, remainder is set to dividend and quotient is set to divisor
                    //     end else begin
                    //         case (divider_state[i-1].is_signed)
                    //             1'b0: begin
                    //                 o_m_state.rd_value <= (divider_state[i-1].is_rem) ? out_rem : out_quo;
                    //             end
                    //             1'b1: begin
                    //                 o_m_state.rd_value <= (divider_state[i-1].is_rem) ? ((divider_state[i-1].negate_remainder) ? twos_comp32(out_rem) : out_rem) : 
                    //                 ((divider_state[i-1].negate_quotient) ? twos_comp32(out_quo) : out_quo);
                    //             end
                    //             default: o_m_state.rd_value <= 32'd0;
                    //         endcase
                    //     end*/
                    // end
                end
            end

            // always_comb begin
            //     o_m_state.pc = divider_state[7].pc;
            //     o_m_state.insn = divider_state[7].insn;
            //     o_m_state.cycle_status = divider_state[7].cycle_status;
            //     o_m_state.rs2 = divider_state[7].rs2;
            //     o_m_state.rd = divider_state[7].rd;
            //     o_m_state.reg_write = divider_state[7].reg_write;
            //     o_m_state.is_ecall = divider_state[7].is_ecall;
            //     o_m_state.funct3 = divider_state[7].funct3;
            //     o_m_state.funct7 = divider_state[7].funct7;
            //     o_m_state.opcode = divider_state[7].opcode;
            //     o_m_state.rs2_val = divider_state[7].rs2_val;
            //     o_m_state.is_div = divider_state[7].is_div;
            //     o_m_state.rd_value = divider_state[7].quotient;
            // end
               
        end
    endgenerate

    // After endgenerate:
always_comb begin
        o_m_state.pc           = divider_state[7].pc;
        o_m_state.insn         = divider_state[7].insn;
        o_m_state.cycle_status = divider_state[7].cycle_status;
        o_m_state.rs2          = divider_state[7].rs2;
        o_m_state.rd           = divider_state[7].rd;
        o_m_state.reg_write    = divider_state[7].reg_write;
        o_m_state.is_ecall     = divider_state[7].is_ecall;
        o_m_state.funct3       = divider_state[7].funct3;
        o_m_state.funct7       = divider_state[7].funct7;
        o_m_state.opcode       = divider_state[7].opcode;
        o_m_state.rs2_val      = divider_state[7].rs2_val;
        o_m_state.is_div       = divider_state[7].is_div;

        o_m_state.rd_value = gen_divider_stages[7].out_quo;

        // if (divider_state[7].div_by_zero) begin
        //     o_m_state.rd_value <= (divider_state[7].is_rem) ? divider_state[7].dividend_input : 32'hFFFF_FFFF;
        // end else if (divider_state[7].overflow) begin
        //     o_m_state.rd_value <= (divider_state[7].is_rem) ? 32'h0 : 32'h8000_0000;
        // end else if (divider_state[7].is_signed) begin
        //     o_m_state.rd_value <= (divider_state[7].is_rem)
        //         ? (divider_state[7].negate_remainder ? twos_comp32(divider_state[7].remainder) : divider_state[7].remainder)
        //         : (divider_state[7].negate_quotient  ? twos_comp32(divider_state[7].quotient)  : divider_state[7].quotient);
        // end else begin
        //     o_m_state.rd_value <= (divider_state[7].is_rem) ? divider_state[7].remainder : divider_state[7].quotient;
        // end
    
end

endmodule


// Creates a 4 stage combinational divider
module StageDivider(
    input wire [`REG_SIZE] i_dividend,
    input wire [`REG_SIZE] i_divisor,
    input wire [`REG_SIZE] i_remainder,
    input wire [`REG_SIZE] i_quotient,
    output wire [`REG_SIZE] o_dividend,
    output wire [`REG_SIZE] o_remainder,
    output wire [`REG_SIZE] o_quotient,
    output wire [`REG_SIZE] o_divisor
);
    genvar i;

    logic [`REG_SIZE] stage_dividend [4:0];
    logic [`REG_SIZE] stage_remainder [4:0];
    logic [`REG_SIZE] stage_quotient [4:0];

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

// Single stage combinational divider
module DividerOneIter (
    input  wire [`REG_SIZE] i_dividend,
    input  wire [`REG_SIZE] i_divisor,
    input  wire [`REG_SIZE] i_remainder,
    input  wire [`REG_SIZE] i_quotient,
    output wire [`REG_SIZE] o_dividend,
    output wire [`REG_SIZE] o_remainder,
    output wire [`REG_SIZE] o_quotient
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
    wire [`REG_SIZE] remainder_temp;

    // Shifts the remainder left and concantenates the MSB of the dividend to the end
    assign remainder_temp = {i_remainder[30:0], i_dividend[31]};  

    // Shift the quotient to the left by one bit. If the remainder is smaller than the divisor, make the new LSB a 0
    // If not, make the new LSB a 1
    assign o_quotient = (remainder_temp >= i_divisor) ? {i_quotient[30:0], 1'b1} : {i_quotient[30:0], 1'b0};

    // If the remainder is smaller than the divisor, keep the remainder the same. If not, subtract the divisor from the remainder
    assign o_remainder = (remainder_temp >= i_divisor) ? (remainder_temp - i_divisor) : remainder_temp;

    // Shift the dividend to the left by 1
    assign o_dividend = {i_dividend[30:0], 1'b0};
    
endmodule

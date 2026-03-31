`timescale 1ns / 1ns

`define REG_SIZE 31:0
`define INSN_SIZE 31:0
`define OPCODE_SIZE 6:0

`include "../hw3-singlecycle/cycle_status.sv"
`include "PipelineStageStructs.sv"
`include "FunctionCalls.sv"  // Includes twos_comp32 function


// quotient = dividend / divisor

// Creates an 8 stage pipelined divider. Each stage performs 4 iterations of the non-restoring division algorithm
// Registers hold intermediate values and final results are output to a memory stage struct
module DividerSignedPipelined (
    input wire clk, rst, stall,
    input wire [`REG_SIZE] i_dividend,
    input wire [`REG_SIZE] i_divisor,
    input wire is_remainder,
    input stage_execute_t i_x_state,
    input wire is_signed,
    input wire negate_quotient,
    input wire negate_remainder,
    output logic [`REG_SIZE] o_remainder,
    output logic [`REG_SIZE] o_quotient,
    output stage_execute_t o_m_state
);

    genvar i;

    // Intermediate registers for each pipeline stage
    logic [`REG_SIZE] reg_dividend [6:0];
    logic [`REG_SIZE] reg_remainder [6:0];
    logic [`REG_SIZE] reg_quotient [6:0];
    logic [`REG_SIZE] reg_divisor [6:0];
    logic reg_is_signed [6:0];
    logic reg_negate_quotient [6:0];
    logic reg_negate_remainder [6:0];
    logic reg_is_remainder [6:0];

    stage_execute_t reg_state [6:0];

    // Create 8 stages
    generate
        for (i = 0; i < 8; i++) begin : gen_divider_stages
            // Intermediate wires for the output of the combinational StageDivider
            wire [`REG_SIZE] out_div, out_rem, out_quo, out_dvr;
            
            // Inputs for this stage. Set to module inputs for first stage and to previous stage's registers for subsequent stages
            wire [`REG_SIZE] stage_in_div = (i == 0) ? i_dividend : reg_dividend[i-1];
            wire [`REG_SIZE] stage_in_rem = (i == 0) ? 32'h0      : reg_remainder[i-1];
            wire [`REG_SIZE] stage_in_quo = (i == 0) ? 32'h0      : reg_quotient[i-1];
            wire [`REG_SIZE] stage_in_dvr = (i == 0) ? i_divisor   : reg_divisor[i-1];
            wire stage_in_is_signed = (i == 0) ? is_signed : reg_is_signed[i-1];
            wire stage_in_negate_quotient = (i == 0) ? negate_quotient : reg_negate_quotient[i-1];
            wire stage_in_negate_remainder = (i == 0) ? negate_remainder : reg_negate_remainder[i-1];
            wire stage_in_is_remainder = (i == 0) ? is_remainder : reg_is_remainder[i-1];

            stage_execute_t stage_in_state = (i == 0) ? i_x_state : reg_state[i-1];

            // Instantiates the combinational, 4 iteration divider stage
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

            // Updates the values in registers on clock edge
            if (i<7) begin : gen_registers
            always_ff @(posedge clk) begin
                
                if (rst) begin
                    reg_dividend[i] <= 32'h0;
                    reg_remainder[i] <= 32'h0;
                    reg_quotient[i] <= 32'h0;
                    reg_divisor[i] <= 32'h0;
                    reg_is_signed[i] <= 1'b0;
                    reg_negate_quotient[i] <= 1'b0;
                    reg_negate_remainder[i] <= 1'b0;
                    reg_is_remainder[i] <= 1'b0;
                    reg_state[i] <= '0;
                end
                else if (!stall)begin
                    reg_dividend[i]  <= out_div;
                    reg_remainder[i] <= out_rem;
                    reg_quotient[i]  <= out_quo;
                    reg_divisor[i]   <= out_dvr;
                    reg_is_signed[i] <= stage_in_is_signed;
                    reg_negate_quotient[i] <= stage_in_negate_quotient;
                    reg_negate_remainder[i] <= stage_in_negate_remainder;
                    reg_is_remainder[i] <= stage_in_is_remainder;
                    reg_state[i] <= stage_in_state;
                end
            end
            end

            // Outputs final results to memory struct at end of pipeline
            if (i==7) begin : gen_output_logic
                always_comb begin
                    o_m_state.pc = stage_in_state.pc;
                    o_m_state.insn = stage_in_state.insn;
                    o_m_state.cycle_status = stage_in_state.cycle_status;
                    o_m_state.rs2 = stage_in_state.rs2;
                    o_m_state.rd = stage_in_state.rd;
                    o_m_state.reg_write = stage_in_state.reg_write;
                    o_m_state.is_ecall = stage_in_state.is_ecall;
                    o_m_state.funct3 = stage_in_state.funct3;
                    o_m_state.funct7 = stage_in_state.funct7;
                    o_m_state.opcode = stage_in_state.opcode;
                    o_m_state.rs2_val = stage_in_state.rs2_val;
                    // Output is either quotient or remainder based on input control signal
                    // Negated if signed and negate control signals are set
                    case (stage_in_is_signed)
                        1'b0: begin
                            o_m_state.rd_value = (reg_is_remainder[6]) ? out_rem : out_quo;
                        end
                        1'b1: begin
                            o_m_state.rd_value = (reg_is_remainder[6]) ? ((stage_in_negate_remainder) ? twos_comp32(out_rem) : out_rem) : 
                            ((stage_in_negate_quotient) ? twos_comp32(out_quo) : out_quo);
                        end
                        default: 
                    endcase
                end
            end
        end
    endgenerate

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
    assign o_quotient = (remainder_temp < i_divisor) ? {i_quotient[30:0], 1'b0} : {i_quotient[30:0], 1'b1};

    // If the remainder is smaller than the divisor, keep the remainder the same. If not, subtract the divisor from the remainder
    assign o_remainder = (remainder_temp < i_divisor) ? remainder_temp : (remainder_temp - i_divisor);

    // Shift the dividend to the left by 1
    assign o_dividend = {i_dividend[30:0], 1'b0};
    
endmodule

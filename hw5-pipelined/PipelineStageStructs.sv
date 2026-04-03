`timescale 1ns / 1ns

`define REG_SIZE 31:0
`define INSN_SIZE 31:0
`define OPCODE_SIZE 6:0

`ifndef PIPELINE_STAGE_STRUCTS_SV
`define PIPELINE_STAGE_STRUCTS_SV

`include "../hw3-singlecycle/cycle_status.sv"
`include "FunctionCalls.sv"

typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e cycle_status;
} stage_decode_t;

typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e cycle_status;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic [`REG_SIZE] rs1_val;
  logic [`REG_SIZE] rs2_val;
  logic [`REG_SIZE] imm_i_sext;
  logic [`REG_SIZE] imm_b_sext;
  logic [`REG_SIZE] imm_s_sext;
  logic [`REG_SIZE] imm_u;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [`OPCODE_SIZE] opcode;
  logic reg_write;
  logic is_branch;
  logic is_ecall;
  logic is_load;
  logic is_div;
} stage_execute_t;

typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e cycle_status;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic reg_write;
  logic [`OPCODE_SIZE] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [`REG_SIZE] rs2_val;
  logic [`REG_SIZE] rd_value;
  logic is_ecall;
  logic is_div;
} stage_memory_t;

typedef stage_memory_t stage_writeback_t;

typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e cycle_status;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic reg_write;
  logic [`OPCODE_SIZE] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [`REG_SIZE] rs2_val;
  logic [`REG_SIZE] rd_value;
  logic is_ecall;
  logic is_div;
  logic [`REG_SIZE] dividend;
  logic [`REG_SIZE] divisor;
  logic [`REG_SIZE] quotient;
  logic [`REG_SIZE] remainder;
  logic [`REG_SIZE] dividend_input;
  logic [`REG_SIZE] divisor_input;
  logic is_signed;
  logic is_rem;
  logic overflow;
  logic negate_quotient;
  logic negate_remainder;
} stage_divider_t;

`endif // PIPELINE_STAGE_STRUCTS_SV

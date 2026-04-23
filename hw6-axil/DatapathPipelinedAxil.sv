`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31:0

// insns are 32 bits in RV32IM
`define INSN_SIZE 31:0

// RV opcodes are 7 bits
`define OPCODE_SIZE 6:0

`define ADDR_WIDTH 32
`define DATA_WIDTH 32

`ifndef DIVIDER_STAGES
`define DIVIDER_STAGES 8
`endif

`ifndef SYNTHESIS
  `include "../hw3-singlecycle/RvDisassembler.sv"
`endif
`include "../hw2b-cla/CarryLookaheadAdder.sv"
`include "../hw3-singlecycle/cycle_status.sv"
`include "../hw4-multicycle/DividerUnsignedPipelined.sv"
`include "EasyAxilMemory.sv"

module Disasm #(
    PREFIX = "D"
) (
    input wire [31:0] insn,
    output wire [(8*32)-1:0] disasm
);
`ifndef RISCV_FORMAL
`ifndef SYNTHESIS
  // this code is only for simulation, not synthesis
  string disasm_string;
  always_comb begin
    disasm_string = rv_disasm(insn);
  end
  // HACK: get disasm_string to appear in GtkWave, which can apparently show only wire/logic. Also,
  // string needs to be reversed to render correctly.
  genvar i;
  for (i = 3; i < 32; i = i + 1) begin : gen_disasm
    assign disasm[((i+1-3)*8)-1-:8] = disasm_string[31-i];
  end
  assign disasm[255-:8] = PREFIX;
  assign disasm[247-:8] = ":";
  assign disasm[239-:8] = " ";
`endif
`endif
endmodule

module RegFile (
    input logic [4:0] rd,
    input logic [`REG_SIZE] rd_data,
    input logic [4:0] rs1,


    output logic [`REG_SIZE] rs1_data,
    input logic [4:0] rs2,
    output logic [`REG_SIZE] rs2_data,

    input logic clk,
    input logic we,
    input logic rst
);
  localparam int NumRegs = 32;
  logic [`REG_SIZE] regs[NumRegs];

  always_comb begin
    if (rs1 == 5'd0) begin
      rs1_data = 32'd0;

    end else if (we && (rd != 5'd0) && (rd == rs1)) begin
      rs1_data = rd_data;
    end else begin
      rs1_data = regs[rs1];

    end

    if (rs2 == 5'd0) begin
      rs2_data = 32'd0;
    end else if (we && (rd != 5'd0) && (rd == rs2)) begin
      rs2_data = rd_data;
    end else begin
      rs2_data = regs[rs2];
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int j = 0; j < NumRegs; j++) begin


        regs[j] <= 32'd0;
      end
    end else if (we && (rd != 5'd0)) begin
      regs[rd] <= rd_data;
    end
  end
endmodule

typedef struct packed {
  logic [`REG_SIZE] pc;
  cycle_status_e cycle_status;
} stage_go_t;


////////////
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

////
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
////////////

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

module DatapathPipelinedAxil (
    input wire clk,
    input wire rst,

    ///interface to insn memory/cache
    axil_if.manager imem,
    ////// interface to data memory/cache
    axil_if.manager dmem,

    output logic halt,

    ///// 
    output logic [`REG_SIZE] trace_completed_pc,

    /// 
    output logic [`INSN_SIZE] trace_completed_insn,
    ////// 
    output cycle_status_e trace_completed_cycle_status
);

  localparam bit [`OPCODE_SIZE] OpcodeBranch = 7'b11_000_11;
  localparam bit [`OPCODE_SIZE] OpcodeRegImm = 7'b00_100_11;
  localparam bit [`OPCODE_SIZE] OpcodeRegReg = 7'b01_100_11;


  localparam bit [`OPCODE_SIZE] OpcodeEnviron = 7'b11_100_11;
  localparam bit [`OPCODE_SIZE] OpcodeAuipc  = 7'b00_101_11;

  localparam bit [`OPCODE_SIZE] OpcodeLui    = 7'b01_101_11;

  localparam bit [`OPCODE_SIZE] OpcodeJal    = 7'b11_011_11;
  localparam bit [`OPCODE_SIZE] OpcodeJalr   = 7'b11_001_11;
  localparam bit [`OPCODE_SIZE] OpcodeLoad   = 7'b00_000_11;
  localparam bit [`OPCODE_SIZE] OpcodeStore  = 7'b01_000_11;

  function automatic stage_decode_t make_decode_bubble(input cycle_status_e st);
    stage_decode_t tmp;
    begin
      tmp = '0;
      tmp.cycle_status = st;
      return tmp;
    end
  endfunction



//19 April
  function automatic stage_execute_t make_execute_bubble(input cycle_status_e st);
    stage_execute_t tmp;
    begin
      tmp = '0;
      tmp.cycle_status = st;
      return tmp;
    end
  endfunction

  function automatic stage_memory_t make_memory_bubble(input cycle_status_e st);
    stage_memory_t tmp;
    begin
      tmp = '0;
      tmp.cycle_status = st;
      return tmp;
    end
  endfunction


  logic [`REG_SIZE] cycles_current;
  always_ff @(posedge clk) begin
    if (rst) begin
      cycles_current <= 32'd0;
    end else begin
      cycles_current <= cycles_current + 32'd1;
    end
  end


  // FETCH


  logic [`REG_SIZE] f_pc_current;


  //G

  stage_go_t g_state;
  logic g_valid;

  //DECODE 


  stage_decode_t decode_state;

  wire [255:0] d_disasm;
  Disasm #(
      .PREFIX("D")
  ) disasm_1decode (
      .insn  (decode_state.insn),
      .disasm(d_disasm)
  );

  wire [6:0] d_funct7 = decode_state.insn[31:25];
  wire [4:0] d_rs2 = decode_state.insn[24:20];
  wire [4:0] d_rs1 = decode_state.insn[19:15];
  wire [2:0] d_funct3 = decode_state.insn[14:12];
  wire [4:0] d_rd = decode_state.insn[11:7];
  wire [`OPCODE_SIZE] d_opcode = decode_state.insn[6:0];

  wire [11:0] d_imm_i = decode_state.insn[31:20];
  wire [12:0] d_imm_b = {decode_state.insn[31], decode_state.insn[7], decode_state.insn[30:25], decode_state.insn[11:8], 1'b0};
  wire [11:0] d_imm_s = {decode_state.insn[31:25], decode_state.insn[11:7]};
  wire [19:0] d_imm_u_raw = decode_state.insn[31:12];

  wire [`REG_SIZE] d_imm_i_sext = {{20{d_imm_i[11]}}, d_imm_i};
  wire [`REG_SIZE] d_imm_b_sext = {{19{d_imm_b[12]}}, d_imm_b};
  wire [`REG_SIZE] d_imm_s_sext = {{20{d_imm_s[11]}}, d_imm_s};
  wire [`REG_SIZE] d_imm_u = {d_imm_u_raw, 12'b0};

  logic [4:0] rf_rd;
  logic [`REG_SIZE] rf_rd_data;
  logic rf_we;
  wire [`REG_SIZE] rf_rs1_data;
  wire [`REG_SIZE] rf_rs2_data;


  RegFile rf (
      .rd(rf_rd),
      .rd_data(rf_rd_data),
      .rs1(d_rs1),
      .rs1_data(rf_rs1_data),
      .rs2(d_rs2),
      .rs2_data(rf_rs2_data),
      .clk(clk),
      .we(rf_we),
      .rst(rst)
  );


  wire d_is_lui    = (d_opcode == OpcodeLui);
  wire d_is_auipc  = (d_opcode == OpcodeAuipc);
  wire d_is_regimm = (d_opcode == OpcodeRegImm);
  wire d_is_regreg = (d_opcode == OpcodeRegReg);
  wire d_is_branch = (d_opcode == OpcodeBranch);
  wire d_is_jal    = (d_opcode == OpcodeJal);
  wire d_is_jalr   = (d_opcode == OpcodeJalr);
  wire d_is_ecall  = (d_opcode == OpcodeEnviron) && (decode_state.insn[31:7] == 25'd0);
  wire d_is_load   = (d_opcode == OpcodeLoad);
  wire d_is_store  = (d_opcode == OpcodeStore);
  wire d_is_div    = (d_opcode == OpcodeRegReg) && (d_funct7 == 7'b0000001)
                  && ((d_funct3 == 3'b100) || (d_funct3 == 3'b101)
                   || (d_funct3 == 3'b110) || (d_funct3 == 3'b111));

  wire d_reg_write = d_is_lui || d_is_auipc || d_is_regimm || d_is_regreg || d_is_load || d_is_jal || d_is_jalr;





  // EXECUTE


  stage_execute_t x_state;

  wire [255:0] x_disasm;
  Disasm #(
      .PREFIX("X")
  ) disasm_2execute (
      .insn  (x_state.insn),
      .disasm(x_disasm)
  );

  logic [`REG_SIZE] x_alu_result;
  logic x_branch_taken;
  logic [`REG_SIZE] x_branch_target;
  logic [`REG_SIZE] x_src1;
  logic [`REG_SIZE] x_src2;
  wire [`REG_SIZE] x_imm_j_sext = {{11{x_state.insn[31]}}, x_state.insn[31], x_state.insn[19:12], x_state.insn[20], x_state.insn[30:21], 1'b0};
  wire d_is_load_stall;

  stage_memory_t div_out_m_state;
  logic dependent_on_active_div;
  logic [4:0] active_div_rd [6:0];
  logic branch_refill_pending;
  stage_execute_t div_issue_state;

  always_comb begin
    div_issue_state = x_state;
    div_issue_state.is_div = divide_issue;
  end

  DividerUnsignedPipelined u_div (
      .clk(clk),
      .rst(rst),
      .stall(d_is_load_stall),
      .i_x_state(div_issue_state),
      .i_src1(x_src1),
      .i_src2(x_src2),
      .o_m_state(div_out_m_state)
  );

  // Multiplier
  logic signed [63:0] mult_a_s;
  logic signed [63:0] mult_b_s;
  logic [63:0] mult_a_u;
  logic [63:0] mult_b_u;
  logic signed [63:0] mult_prod_ss;
  logic signed [63:0] mult_prod_su;
  logic [63:0] mult_prod_uu;

  always_comb begin
    mult_a_s = {{32{x_src1[31]}}, x_src1};
    mult_b_s = {{32{x_src2[31]}}, x_src2};
    mult_a_u = {{32{1'b0}}, x_src1};
    mult_b_u = {{32{1'b0}}, x_src2};

    mult_prod_ss = mult_a_s * mult_b_s;
    mult_prod_su = mult_a_s * mult_b_u;
    mult_prod_uu = mult_a_u * mult_b_u;
  end

  always_comb begin
    x_alu_result = 32'd0;
    x_branch_taken = 1'b0;
    x_branch_target = x_state.pc + x_state.imm_b_sext;

    case (x_state.opcode)
      OpcodeLui: begin
        x_alu_result = x_state.imm_u;
      end
      OpcodeAuipc: begin
        x_alu_result = x_state.pc + x_state.imm_u;
      end
      OpcodeRegImm: begin
        case (x_state.funct3)
          3'b000: x_alu_result = x_src1 + x_state.imm_i_sext;
          3'b010: x_alu_result = ($signed(x_src1) < $signed(x_state.imm_i_sext)) ? 32'd1 : 32'd0;
          3'b011: x_alu_result = (x_src1 < x_state.imm_i_sext) ? 32'd1 : 32'd0;
          3'b100: x_alu_result = x_src1 ^ x_state.imm_i_sext;
          3'b110: x_alu_result = x_src1 | x_state.imm_i_sext;
          3'b111: x_alu_result = x_src1 & x_state.imm_i_sext;
          3'b001: x_alu_result = x_src1 << x_state.insn[24:20];
          3'b101: begin
            if (x_state.funct7 == 7'b0100000) begin
              x_alu_result = $signed(x_src1) >>> x_state.insn[24:20];
            end else begin
              x_alu_result = x_src1 >> x_state.insn[24:20];
            end
          end
          default: x_alu_result = 32'd0;
        endcase
      end
      OpcodeRegReg: begin
        case (x_state.funct3)
          3'b000: begin
            case (x_state.funct7)
              7'b0000000: x_alu_result = x_src1 + x_src2;
              7'b0100000: x_alu_result = x_src1 - x_src2;
              7'b0000001: x_alu_result = mult_prod_uu[31:0];
              default: x_alu_result = 32'd0;
            endcase
          end
          3'b001: begin
            case (x_state.funct7)
              7'b0000000: x_alu_result = x_src1 << x_src2[4:0];
              7'b0000001: x_alu_result = mult_prod_ss[63:32];
              default: x_alu_result = 32'd0;
            endcase
          end
          3'b010: begin
            case (x_state.funct7)
              7'b0000000: x_alu_result = ($signed(x_src1) < $signed(x_src2)) ? 32'd1 : 32'd0;
              7'b0000001: x_alu_result = mult_prod_su[63:32];
              default: x_alu_result = 32'd0;
            endcase
          end
          3'b011: begin
            case (x_state.funct7)
              7'b0000000: x_alu_result = (x_src1 < x_src2) ? 32'd1 : 32'd0;
              7'b0000001: x_alu_result = mult_prod_uu[63:32];
              default: x_alu_result = 32'd0;
            endcase
          end
          3'b100: begin
            if (x_state.funct7 == 7'b0000000) begin
              x_alu_result = x_src1 ^ x_src2;
            end else begin
              x_alu_result = 32'd0;
            end
          end
          3'b101: begin
            case (x_state.funct7)
              7'b0000000: x_alu_result = x_src1 >> x_src2[4:0];
              7'b0100000: x_alu_result = $signed(x_src1) >>> x_src2[4:0];
              default: x_alu_result = 32'd0;
            endcase
          end
          3'b110: begin
            if (x_state.funct7 == 7'b0000000) begin
              x_alu_result = x_src1 | x_src2;
            end else begin
              x_alu_result = 32'd0;
            end
          end
          3'b111: begin
            if (x_state.funct7 == 7'b0000000) begin
              x_alu_result = x_src1 & x_src2;
            end else begin
              x_alu_result = 32'd0;
            end
          end
          default: x_alu_result = 32'd0;
        endcase
      end
      OpcodeBranch: begin
        case (x_state.funct3)
          3'b000: x_branch_taken = (x_src1 == x_src2);
          3'b001: x_branch_taken = (x_src1 != x_src2);
          3'b100: x_branch_taken = ($signed(x_src1) <  $signed(x_src2));
          3'b101: x_branch_taken = ($signed(x_src1) >= $signed(x_src2));
          3'b110: x_branch_taken = (x_src1 <  x_src2);
          3'b111: x_branch_taken = (x_src1 >= x_src2);
          default: x_branch_taken = 1'b0;
        endcase
      end
      OpcodeJal: begin
        x_alu_result = x_state.pc + 32'd4;
        x_branch_taken = 1'b1;
        x_branch_target = x_state.pc + x_imm_j_sext;
      end
      OpcodeJalr: begin
        x_alu_result = x_state.pc + 32'd4;
        x_branch_taken = 1'b1;
        x_branch_target = (x_src1 + x_state.imm_i_sext) & 32'hffff_fffe;
      end
      OpcodeLoad: begin
        x_alu_result = x_src1 + x_state.imm_i_sext;
      end
      OpcodeStore: begin
        x_alu_result = x_src1 + x_state.imm_s_sext;
      end
      default: begin
        x_alu_result = 32'd0;
      end
    endcase

    if (x_state.cycle_status != CYCLE_NO_STALL) begin
      x_branch_taken = 1'b0;
    end
  end


  //MEMORY


  stage_memory_t m_state;

  wire [255:0] m_disasm;
  Disasm #(
      .PREFIX("M")
  ) disasm_3memory (
      .insn  (m_state.insn),
      .disasm(m_disasm)
  );

  logic [`REG_SIZE] m_result_to_wb;

  always_comb begin
    m_result_to_wb = m_state.rd_value;

    case (m_state.opcode)
      OpcodeLoad: begin
        case (m_state.funct3)
          3'b000: begin
            case (m_state.rd_value[1:0])
              2'b00: m_result_to_wb = {{24{dmem.RDATA[7]}}, dmem.RDATA[7:0]};
              2'b01: m_result_to_wb = {{24{dmem.RDATA[15]}}, dmem.RDATA[15:8]};
              2'b10: m_result_to_wb = {{24{dmem.RDATA[23]}}, dmem.RDATA[23:16]};
              2'b11: m_result_to_wb = {{24{dmem.RDATA[31]}}, dmem.RDATA[31:24]};
              default: m_result_to_wb = 32'd0;
            endcase
          end
          3'b100: begin
            case (m_state.rd_value[1:0])
              2'b00: m_result_to_wb = {24'd0, dmem.RDATA[7:0]};
              2'b01: m_result_to_wb = {24'd0, dmem.RDATA[15:8]};
              2'b10: m_result_to_wb = {24'd0, dmem.RDATA[23:16]};
              2'b11: m_result_to_wb = {24'd0, dmem.RDATA[31:24]};
              default: m_result_to_wb = 32'd0;
            endcase
          end
          3'b001: begin
            case (m_state.rd_value[1])
              1'b0: m_result_to_wb = {{16{dmem.RDATA[15]}}, dmem.RDATA[15:0]};
              1'b1: m_result_to_wb = {{16{dmem.RDATA[31]}}, dmem.RDATA[31:16]};
              default: m_result_to_wb = 32'd0;
            endcase
          end
          3'b101: begin
            case (m_state.rd_value[1])
              1'b0: m_result_to_wb = {16'd0, dmem.RDATA[15:0]};
              1'b1: m_result_to_wb = {16'd0, dmem.RDATA[31:16]};
              default: m_result_to_wb = 32'd0;
            endcase
          end
          3'b010: m_result_to_wb = dmem.RDATA;
          default: m_result_to_wb = 32'd0;
        endcase
      end
      default: begin
      end
    endcase
  end


  // WRITEBACK




  stage_writeback_t w_state;

  wire [255:0] w_disasm;
  Disasm #(
      .PREFIX("W")
  ) disasm_4writeback (
      .insn  (w_state.insn),
      .disasm(w_disasm)
  );

  cycle_status_e trace_status_out;

  always_comb begin
    trace_status_out = w_state.cycle_status;


    if (trace_status_out != CYCLE_NO_STALL) begin
      if ((m_state.cycle_status == CYCLE_TAKEN_BRANCH) ||
          (x_state.cycle_status == CYCLE_TAKEN_BRANCH) ||
          (decode_state.cycle_status == CYCLE_TAKEN_BRANCH) ||
          (g_state.cycle_status == CYCLE_TAKEN_BRANCH) ||
          branch_refill_pending) begin
        trace_status_out = CYCLE_TAKEN_BRANCH;
      end else if ((m_state.cycle_status == CYCLE_IMEM_WAIT) ||
                   (x_state.cycle_status == CYCLE_IMEM_WAIT) ||
                   (decode_state.cycle_status == CYCLE_IMEM_WAIT)) begin
        trace_status_out = CYCLE_IMEM_WAIT;
      end
    end

    trace_completed_cycle_status = trace_status_out;
    trace_completed_pc = (trace_status_out == CYCLE_NO_STALL) ? w_state.pc : 32'd0;
    trace_completed_insn = (trace_status_out == CYCLE_NO_STALL) ? w_state.insn : 32'd0;
    halt = (trace_status_out == CYCLE_NO_STALL) && w_state.is_ecall;

    rf_rd = w_state.rd;
    rf_rd_data = w_state.rd_value;
    rf_we = w_state.reg_write;
  end

  // FORWARDING and HAZARDS


  logic [`REG_SIZE] x_rs1_committed;
  logic [`REG_SIZE] x_rs2_committed;

  always_comb begin
    x_rs1_committed = (x_state.rs1 == 5'd0) ? 32'd0 : rf.regs[x_state.rs1];
    x_rs2_committed = (x_state.rs2 == 5'd0) ? 32'd0 : rf.regs[x_state.rs2];

    // start from the most up-to-date committed register-file contents rather than
    //the values captured when the instruction first left Decode.

    x_src1 = x_rs1_committed;
    if ((x_state.rs1 != 5'd0) && m_state.reg_write && (m_state.rd == x_state.rs1) && (m_state.opcode != OpcodeLoad)) begin
      x_src1 = m_state.rd_value;
    end else if ((x_state.rs1 != 5'd0) && w_state.reg_write && (w_state.rd == x_state.rs1)) begin
      x_src1 = w_state.rd_value;
    end

    x_src2 = x_rs2_committed;
    if ((x_state.rs2 != 5'd0) && m_state.reg_write && (m_state.rd == x_state.rs2) && (m_state.opcode != OpcodeLoad)) begin
      x_src2 = m_state.rd_value;
    end else if ((x_state.rs2 != 5'd0) && w_state.reg_write && (w_state.rd == x_state.rs2)) begin
      x_src2 = w_state.rd_value;
    end
  end

  wire d_uses_rs2 = d_is_regreg || d_is_branch || d_is_store;
  assign d_is_load_stall = x_state.is_load && (x_state.rd != 5'd0)
                      && ((x_state.rd == d_rs1) || (d_uses_rs2 && (x_state.rd == d_rs2)));

  wire divide = x_state.is_div;

  logic [6:0] div_stage_busy;
  wire divide_issue = x_state.is_div && !dependent_on_active_div;
  wire divider_active = (div_stage_busy != 7'b0) || divide_issue;

  always_comb begin
    dependent_on_active_div = 1'b0;
    for (int i = 0; i < 7; i++) begin
      if (div_stage_busy[i]
          && (active_div_rd[i] != 5'd0)
          && (((active_div_rd[i] == x_state.rs1) && (x_state.rs1 != 5'd0))
           || ((active_div_rd[i] == x_state.rs2) && (x_state.rs2 != 5'd0)))) begin
        dependent_on_active_div = 1'b1;
      end
    end
  end

  wire div_stall = (divider_active && !x_state.is_div) || (dependent_on_active_div && x_state.is_div);
  wire frontend_hold = d_is_load_stall || div_stall;
  wire mem_stall = (dependent_on_active_div && x_state.is_div) || (divider_active && !div_stage_busy[6]);

  
  // AXI-LITE IMEM I/F


  wire imem_resp_fire = g_valid && imem.RVALID && imem.RREADY;
  wire imem_issue_ok = (!g_valid) || imem_resp_fire;
  wire imem_req_fire = imem.ARVALID && imem.ARREADY;

  always_comb begin
    //    Read-only port
    imem.AWADDR  = 32'd0;
    imem.AWVALID = 1'b0;
    imem.AWPROT  = 3'b000;
    imem.WDATA   = 32'd0;
    imem.WSTRB   = 4'b0000;
    imem.WVALID  = 1'b0;
    imem.BREADY  = 1'b1;

    imem.ARADDR  = f_pc_current;
    imem.ARPROT  = 3'b000;
    imem.ARVALID = 1'b0;
    imem.RREADY  = 1'b0;

    if (!rst) begin
      if (x_branch_taken) begin
        // can consume and discard the wrong-path response in G but dont issue a new wrong-path request from F.
        imem.RREADY  = 1'b1;
        imem.ARVALID = 1'b0;
      end else if (frontend_hold) begin
        //  F/G/D together
        imem.RREADY  = 1'b0;
        imem.ARVALID = 1'b0;
      end else begin
        imem.RREADY  = 1'b1;
        imem.ARVALID = imem_issue_ok;
      end
    end
  end







  // AXI-LITE DMEM I/F


  logic [31:0] dmem_store_data;
  logic [3:0]  dmem_store_strb;

  always_comb begin
    dmem_store_data = 32'd0;
    dmem_store_strb = 4'b0000;

    if ((x_state.cycle_status == CYCLE_NO_STALL) && (x_state.opcode == OpcodeStore)) begin
      case (x_state.funct3)
        3'b000: begin
          dmem_store_data = {4{x_src2[7:0]}};
          case (x_alu_result[1:0])
            2'b00: dmem_store_strb = 4'b0001;
            2'b01: dmem_store_strb = 4'b0010;
            2'b10: dmem_store_strb = 4'b0100;
            2'b11: dmem_store_strb = 4'b1000;
            default: dmem_store_strb = 4'b0000;
          endcase
        end
        3'b001: begin
          dmem_store_data = {2{x_src2[15:0]}};
          case (x_alu_result[1])
            1'b0: dmem_store_strb = 4'b0011;
            1'b1: dmem_store_strb = 4'b1100;
            default: dmem_store_strb = 4'b0000;
          endcase
        end
        3'b010: begin
          dmem_store_data = x_src2;
          dmem_store_strb = 4'b1111;
        end
        default: begin
          dmem_store_data = 32'd0;
          dmem_store_strb = 4'b0000;
        end
      endcase
    end
  end

  always_comb begin
    dmem.ARADDR  = {x_alu_result[31:2], 2'b00};
    dmem.ARVALID = (x_state.cycle_status == CYCLE_NO_STALL) && (x_state.opcode == OpcodeLoad);
    dmem.ARPROT  = 3'b000;
    dmem.RREADY  = 1'b1;

    dmem.AWADDR  = {x_alu_result[31:2], 2'b00};
    dmem.AWVALID = (x_state.cycle_status == CYCLE_NO_STALL) && (x_state.opcode == OpcodeStore);
    dmem.AWPROT  = 3'b000;

    dmem.WDATA   = dmem_store_data;
    dmem.WSTRB   = dmem_store_strb;
    dmem.WVALID  = (x_state.cycle_status == CYCLE_NO_STALL) && (x_state.opcode == OpcodeStore);

    dmem.BREADY  = 1'b1;
  end




  //PIPELINE REGISTERS 


  always_ff @(posedge clk) begin
    if (rst) begin
      f_pc_current <= 32'd0;
      g_state <= '{pc: 32'd0, cycle_status: CYCLE_RESET};
      g_valid <= 1'b0;
      decode_state <= make_decode_bubble(CYCLE_RESET);
      x_state <= make_execute_bubble(CYCLE_RESET);

      m_state <= make_memory_bubble(CYCLE_RESET);
      w_state <= make_memory_bubble(CYCLE_RESET);
      div_stage_busy <= 7'b0;
      active_div_rd[0] <= 5'd0;
      active_div_rd[1] <= 5'd0;

      active_div_rd[2] <= 5'd0;
      active_div_rd[3] <= 5'd0;
      active_div_rd[4] <= 5'd0;
      active_div_rd[5] <= 5'd0;
      active_div_rd[6] <= 5'd0;
      branch_refill_pending <= 1'b0;
    end else begin
      // Writeback always advances.
      w_state <= '{
        pc: m_state.pc,
        insn: m_state.insn,
        cycle_status: m_state.cycle_status,
        rs2: m_state.rs2,

        rd: m_state.rd,
        reg_write: m_state.reg_write,
        opcode: m_state.opcode,
        funct3: m_state.funct3,
        funct7: m_state.funct7,

        rs2_val: m_state.rs2_val,
        rd_value: m_result_to_wb,
        is_ecall: m_state.is_ecall,
        is_div: m_state.is_div
      };

      div_stage_busy <= {div_stage_busy[5:0], divide_issue};
      active_div_rd[6] <= active_div_rd[5];
      active_div_rd[5] <= active_div_rd[4];
      active_div_rd[4] <= active_div_rd[3];

//21/4
      active_div_rd[3] <= active_div_rd[2];
      active_div_rd[2] <= active_div_rd[1];
      active_div_rd[1] <= active_div_rd[0];
      active_div_rd[0] <= divide_issue ? x_state.rd : 5'd0;

      if (x_branch_taken) begin
        branch_refill_pending <= 1'b1;
      end else if (branch_refill_pending && imem_resp_fire) begin

        branch_refill_pending <= 1'b0;
      end

      if (div_out_m_state.is_div) begin
        m_state <= div_out_m_state;
      end else if (!mem_stall) begin
        m_state <= '{
          pc: x_state.pc,
          insn: x_state.insn,
          cycle_status: x_state.cycle_status,
          rs2: x_state.rs2,
          rd: x_state.rd,
          reg_write: x_state.reg_write,
          opcode: x_state.opcode,
          funct3: x_state.funct3,
          funct7: x_state.funct7,
          rs2_val: x_src2,
          rd_value: x_alu_result,
          is_ecall: x_state.is_ecall,
          is_div: x_state.is_div
        };
      end else begin
        m_state <= make_memory_bubble(CYCLE_DIV);
      end

      if (x_branch_taken) begin
        // Flush wrong-path F/G/D, already prevented a new wrong-path AR request.
        f_pc_current <= x_branch_target;
        g_state <= '{pc: 32'd0, cycle_status: CYCLE_TAKEN_BRANCH};
        g_valid <= 1'b0;
        decode_state <= make_decode_bubble(CYCLE_TAKEN_BRANCH);
        x_state <= make_execute_bubble(CYCLE_TAKEN_BRANCH);
      end else if (d_is_load_stall) begin
        // hold F/G/D. Insert a bubble into X
        f_pc_current <= f_pc_current;
        g_state <= g_state;
        g_valid <= g_valid;
        decode_state <= decode_state;
        x_state <= make_execute_bubble(CYCLE_LOAD2USE);
      end else if (div_stall) begin
        // hold the front-end and keep the divide in X
        // ;latch the currently-forwarded operands so transient WX/MX bypassed values
        
        f_pc_current <= f_pc_current;
        g_state <= g_state;
        g_valid <= g_valid;
        decode_state <= decode_state;
        x_state <= '{
          pc: x_state.pc,
          insn: x_state.insn,
          cycle_status: x_state.cycle_status,
          rs1: x_state.rs1,
          rs2: x_state.rs2,
          rd: x_state.rd,
          rs1_val: x_src1,
          rs2_val: x_src2,
          imm_i_sext: x_state.imm_i_sext,
          imm_b_sext: x_state.imm_b_sext,
          imm_s_sext: x_state.imm_s_sext,
          imm_u: x_state.imm_u,
          funct3: x_state.funct3,
          funct7: x_state.funct7,
          opcode: x_state.opcode,
          reg_write: x_state.reg_write,
          is_branch: x_state.is_branch,
          is_ecall: x_state.is_ecall,
          is_load: x_state.is_load,
          is_div: x_state.is_div
        };
      end else begin
        // Front-end
        if (imem_req_fire) begin
          g_state <= '{pc: f_pc_current, cycle_status: CYCLE_NO_STALL};
          g_valid <= 1'b1;
          f_pc_current <= f_pc_current + 32'd4;

        end else if (imem_resp_fire) begin

          g_state <= '{pc: 32'd0, cycle_status: CYCLE_RESET};
          g_valid <= 1'b0;
          f_pc_current <= f_pc_current;

        end else begin
          g_state <= g_state;
          g_valid <= g_valid;

          f_pc_current <= f_pc_current;
        end


        if (imem_resp_fire) begin
          decode_state <= '{
            pc: g_state.pc,
            insn: imem.RDATA,
            cycle_status: CYCLE_NO_STALL
          };
        end else if (branch_refill_pending || (g_state.cycle_status == CYCLE_TAKEN_BRANCH)) begin
          decode_state <= make_decode_bubble(CYCLE_TAKEN_BRANCH);
        end else if (g_valid || imem_req_fire) begin
          decode_state <= make_decode_bubble(CYCLE_IMEM_WAIT);
        end else begin
          decode_state <= make_decode_bubble(CYCLE_RESET);
        end

        x_state <= '{
          pc: decode_state.pc,
          insn: decode_state.insn,
          cycle_status: decode_state.cycle_status,
          rs1: d_rs1,
          rs2: d_rs2,
          rd: d_rd,
          rs1_val: rf_rs1_data,
          rs2_val: rf_rs2_data,

          imm_i_sext: d_imm_i_sext,
          imm_b_sext: d_imm_b_sext,
          imm_s_sext: d_imm_s_sext,
          imm_u: d_imm_u,
          funct3: d_funct3,
          funct7: d_funct7,
          opcode: d_opcode,
          reg_write: d_reg_write,
          is_branch: d_is_branch,
          is_ecall: d_is_ecall,
          is_load: d_is_load,
          is_div: d_is_div
        };
      end
    end
  end

endmodule // DatapathPipelinedAxil

/* This design has just one clock for both processor and memory. */
module Processor (
    input  wire  clk,
    input  wire  rst,
    output logic halt,
    output wire [`REG_SIZE] trace_completed_pc,
    output wire [`INSN_SIZE] trace_completed_insn,
    output cycle_status_e trace_completed_cycle_status
);

  // This wire is set by cocotb to the name of the currently-running test, to make it easier
  // to see what is going on in the waveforms.
  wire [(8*32)-1:0] test_case;

  axil_if axil_mem_ro ();
  axil_if axil_mem_rw ();

  EasyAxilMemory #(
      .OPT_SKIDBUFFER(1),
      .OPT_LOWPOWER(0),
      .NUM_WORDS(8192)
  ) memory (
      .ACLK(clk),
      .ARESETn(~rst),
      .port_ro(axil_mem_ro.subord),
      .port_rw(axil_mem_rw.subord)
  );

  DatapathPipelinedAxil datapath (
      .clk(clk),
      .rst(rst),
      .imem(axil_mem_ro.manager),
      .dmem(axil_mem_rw.manager),
      .halt(halt),
      .trace_completed_pc(trace_completed_pc),
      .trace_completed_insn(trace_completed_insn),
      .trace_completed_cycle_status(trace_completed_cycle_status)
  );

endmodule

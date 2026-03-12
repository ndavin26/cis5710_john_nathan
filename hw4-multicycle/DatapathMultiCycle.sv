`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31:0

// insns are 32 bits in RV32IM
`define INSN_SIZE 31:0

// RV opcodes are 7 bits
`define OPCODE_SIZE 6:0

`include "../hw2b-cla/CarryLookaheadAdder.sv"
`include "../hw3-singlecycle/cycle_status.sv"
`include "../hw4-multicycle/DividerUnsignedPipelined.sv"


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

  // async reads
  assign rs1_data = regs[rs1];
  assign rs2_data = regs[rs2];

  // sync writes
  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < NumRegs; i++) begin
        regs[i] <= 0;
      end
    end else if (we) begin
      if (rd != 5'd0) begin
        regs[rd] <= rd_data;
      end
    end
  end
endmodule

module DatapathSingleCycle (
    input wire                clk,
    input wire                rst,
    output logic              halt,
    output logic [`REG_SIZE]  pc_to_imem,
    input wire [`INSN_SIZE]   insn_from_imem,
    // addr_to_dmem is used for both loads and stores
    output logic [`REG_SIZE]  addr_to_dmem,
    input logic [`REG_SIZE]   load_data_from_dmem,
    output logic [`REG_SIZE]  store_data_to_dmem,
    output logic [3:0]        store_we_to_dmem,

    // the PC of the insn executing in the current cycle
    output logic [`REG_SIZE]  trace_completed_pc,
    // the machine code of the insn executing in the current cycle
    output logic [`INSN_SIZE] trace_completed_insn,
    // the cycle status of the current cycle: should always be CYCLE_NO_STALL
    output cycle_status_e     trace_completed_cycle_status
);

  // ---------------- Instruction fields ----------------
  wire [6:0] insn_funct7;
  wire [4:0] insn_rs2;
  wire [4:0] insn_rs1;
  wire [2:0] insn_funct3;
  wire [4:0] insn_rd;
  wire [`OPCODE_SIZE] insn_opcode;

  assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn_from_imem;

  // immediates
  wire [11:0] imm_i = insn_from_imem[31:20];
  wire [ 4:0] imm_shamt = insn_from_imem[24:20];

  wire [11:0] imm_s = {insn_from_imem[31:25], insn_from_imem[11:7]};
  wire [12:0] imm_b = {insn_from_imem[31], insn_from_imem[7], insn_from_imem[30:25], insn_from_imem[11:8], 1'b0};
  wire [19:0] imm_u = insn_from_imem[31:12];
  wire [20:0] imm_j = {insn_from_imem[31], insn_from_imem[19:12], insn_from_imem[20], insn_from_imem[30:21], 1'b0};

  wire [`REG_SIZE] imm_i_sext = {{20{imm_i[11]}}, imm_i};
  wire [`REG_SIZE] imm_s_sext = {{20{imm_s[11]}}, imm_s};
  wire [`REG_SIZE] imm_b_sext = {{19{imm_b[12]}}, imm_b};
  wire [`REG_SIZE] imm_j_sext = {{11{imm_j[20]}}, imm_j};

  // opcodes
  localparam bit [`OPCODE_SIZE] OpLoad    = 7'b00_000_11;
  localparam bit [`OPCODE_SIZE] OpStore   = 7'b01_000_11;
  localparam bit [`OPCODE_SIZE] OpBranch  = 7'b11_000_11;
  localparam bit [`OPCODE_SIZE] OpJalr    = 7'b11_001_11;
  localparam bit [`OPCODE_SIZE] OpMiscMem = 7'b00_011_11;
  localparam bit [`OPCODE_SIZE] OpJal     = 7'b11_011_11;
  localparam bit [`OPCODE_SIZE] OpRegImm  = 7'b00_100_11;
  localparam bit [`OPCODE_SIZE] OpRegReg  = 7'b01_100_11;
  localparam bit [`OPCODE_SIZE] OpEnviron = 7'b11_100_11;
  localparam bit [`OPCODE_SIZE] OpAuipc   = 7'b00_101_11;
  localparam bit [`OPCODE_SIZE] OpLui     = 7'b01_101_11;

  // instruction decodes
  wire insn_lui   = (insn_opcode == OpLui);
  wire insn_auipc = (insn_opcode == OpAuipc);
  wire insn_jal   = (insn_opcode == OpJal);
  wire insn_jalr  = (insn_opcode == OpJalr);

  wire insn_beq  = (insn_opcode == OpBranch) && (insn_funct3 == 3'b000);
  wire insn_bne  = (insn_opcode == OpBranch) && (insn_funct3 == 3'b001);
  wire insn_blt  = (insn_opcode == OpBranch) && (insn_funct3 == 3'b100);
  wire insn_bge  = (insn_opcode == OpBranch) && (insn_funct3 == 3'b101);
  wire insn_bltu = (insn_opcode == OpBranch) && (insn_funct3 == 3'b110);
  wire insn_bgeu = (insn_opcode == OpBranch) && (insn_funct3 == 3'b111);

  wire insn_lb  = (insn_opcode == OpLoad) && (insn_funct3 == 3'b000);
  wire insn_lh  = (insn_opcode == OpLoad) && (insn_funct3 == 3'b001);
  wire insn_lw  = (insn_opcode == OpLoad) && (insn_funct3 == 3'b010);
  wire insn_lbu = (insn_opcode == OpLoad) && (insn_funct3 == 3'b100);
  wire insn_lhu = (insn_opcode == OpLoad) && (insn_funct3 == 3'b101);

  wire insn_sb = (insn_opcode == OpStore) && (insn_funct3 == 3'b000);
  wire insn_sh = (insn_opcode == OpStore) && (insn_funct3 == 3'b001);
  wire insn_sw = (insn_opcode == OpStore) && (insn_funct3 == 3'b010);

  wire insn_addi  = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b000);
  wire insn_slti  = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b010);
  wire insn_sltiu = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b011);
  wire insn_xori  = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b100);
  wire insn_ori   = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b110);
  wire insn_andi  = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b111);

  wire insn_slli = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b001) && (insn_funct7 == 7'd0);
  wire insn_srli = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b101) && (insn_funct7 == 7'd0);
  wire insn_srai = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b101) && (insn_funct7 == 7'b0100000);

  wire insn_add  = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b000) && (insn_funct7 == 7'd0);
  wire insn_sub  = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b000) && (insn_funct7 == 7'b0100000);
  wire insn_sll  = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b001) && (insn_funct7 == 7'd0);
  wire insn_slt  = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b010) && (insn_funct7 == 7'd0);
  wire insn_sltu = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b011) && (insn_funct7 == 7'd0);
  wire insn_xor  = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b100) && (insn_funct7 == 7'd0);
  wire insn_srl  = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b101) && (insn_funct7 == 7'd0);
  wire insn_sra  = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b101) && (insn_funct7 == 7'b0100000);
  wire insn_or   = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b110) && (insn_funct7 == 7'd0);
  wire insn_and  = (insn_opcode == OpRegReg) && (insn_funct3 == 3'b111) && (insn_funct7 == 7'd0);

  // RV32M: funct7==1
  wire insn_mul    = (insn_opcode == OpRegReg) && (insn_funct7 == 7'd1) && (insn_funct3 == 3'b000);
  wire insn_mulh   = (insn_opcode == OpRegReg) && (insn_funct7 == 7'd1) && (insn_funct3 == 3'b001);
  wire insn_mulhsu = (insn_opcode == OpRegReg) && (insn_funct7 == 7'd1) && (insn_funct3 == 3'b010);
  wire insn_mulhu  = (insn_opcode == OpRegReg) && (insn_funct7 == 7'd1) && (insn_funct3 == 3'b011);
  wire insn_div    = (insn_opcode == OpRegReg) && (insn_funct7 == 7'd1) && (insn_funct3 == 3'b100);
  wire insn_divu   = (insn_opcode == OpRegReg) && (insn_funct7 == 7'd1) && (insn_funct3 == 3'b101);
  wire insn_rem    = (insn_opcode == OpRegReg) && (insn_funct7 == 7'd1) && (insn_funct3 == 3'b110);
  wire insn_remu   = (insn_opcode == OpRegReg) && (insn_funct7 == 7'd1) && (insn_funct3 == 3'b111);

  wire insn_ecall = (insn_opcode == OpEnviron) && (insn_from_imem[31:7] == 25'd0);

  // disassembler (simulation only)
  `ifndef SYNTHESIS
    `include "../hw3-singlecycle/RvDisassembler.sv"
    string disasm_string;
    always_comb begin
      disasm_string = rv_disasm(insn_from_imem);
    end
    wire [(8*32)-1:0] disasm_wire;
    genvar di;
    for (di = 0; di < 32; di = di + 1) begin : gen_disasm
      assign disasm_wire[(((di+1))*8)-1:((di)*8)] = disasm_string[31-di];
    end
  `endif

  // ---------------- PC ----------------
  logic [`REG_SIZE] pcNext, pcCurrent;
  always @(posedge clk) begin
    if (rst) pcCurrent <= 32'd0;
    else     pcCurrent <= pcNext;
  end
  assign pc_to_imem = pcCurrent;

  logic [3:0] div_stall_count;

  // counters (debug)
  logic [`REG_SIZE] cycles_current, num_insns_current;
  always @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
      num_insns_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
      num_insns_current <= num_insns_current + 1;
    end
  end

  // ---------------- Register file ----------------
  wire [`REG_SIZE] rs1_data;
  wire [`REG_SIZE] rs2_data;
  logic [`REG_SIZE] rd_data;

  wire [4:0] rs1 = insn_rs1;
  wire [4:0] rs2 = insn_rs2;
  logic [4:0] rd;
  logic we;

  RegFile rf (
    .rd(rd), .rd_data(rd_data),
    .rs1(rs1), .rs1_data(rs1_data),
    .rs2(rs2), .rs2_data(rs2_data),
    .clk(clk), .we(we), .rst(rst)
  );

  logic illegal_insn;

  // ---------------- CLA (HW2B) ----------------
  logic [`REG_SIZE] cla_in1, cla_in2, cla_sum;
  logic cla_cin;
  CarryLookaheadAdder ALU_adder(.a(cla_in1), .b(cla_in2), .cin(cla_cin), .sum(cla_sum));


  function automatic logic [31:0] twos_comp32(input logic [31:0] x);
    twos_comp32 = (~x) + 32'd1;
  endfunction



  // ---------------- Divider (HW2A) ----------------
  logic [31:0] div_in_dividend, div_in_divisor;
  wire  [31:0] div_out_quotient, div_out_remainder;
  wire stall_active;
  
  DividerUnsignedPipelined u_div(
    .i_dividend(div_in_dividend), .i_divisor(div_in_divisor),
    .o_quotient(div_out_quotient), .o_remainder(div_out_remainder),
    .clk(clk), .rst(rst), .stall(stall_active)
  );

  logic div_use, div_signed, div_is_rem;
  logic div_div_by_zero, div_overflow;
  logic div_a_neg, div_b_neg;
  logic [31:0] div_a_abs, div_b_abs;
  logic [2:0] div_stage;

  // -------- Dedicated comb blocks (avoid Verilator UNOPTFLAT) --------

  // Drive CLA inputs in a separate block (does NOT read cla_sum)
  always_comb begin
    cla_in1 = 32'b0;
    cla_in2 = 32'b0;
    cla_cin = 1'b0;

    if (insn_addi) begin
      cla_in1 = rs1_data;
      cla_in2 = imm_i_sext;
      cla_cin = 1'b0;
    end else if (insn_add) begin
      cla_in1 = rs1_data;
      cla_in2 = rs2_data;
      cla_cin = 1'b0;
    
    // Use carry in bit and negation to eliminate need for an a separate adder in subtraction
    end else if (insn_sub) begin
      cla_in1 = rs1_data;
      cla_in2 = ~rs2_data;
      cla_cin = 1'b1;
    end
  end

  // Divider input prep in a separate block (does NOT read div_out_*)
  always_comb begin

      div_in_dividend = 32'b0;
      div_in_divisor  = 32'b0;

      div_use         = (insn_divu || insn_remu || insn_div || insn_rem);
      div_signed      = (insn_div  || insn_rem);
      div_is_rem      = (insn_remu || insn_rem);

      div_div_by_zero = div_use && (rs2_data == 32'b0);
      div_overflow    = div_signed && (rs1_data == 32'h8000_0000) && (rs2_data == 32'hFFFF_FFFF);

      div_a_neg = rs1_data[31];
      div_b_neg = rs2_data[31];

      div_a_abs = div_a_neg ? twos_comp32(rs1_data) : rs1_data;
      div_b_abs = div_b_neg ? twos_comp32(rs2_data) : rs2_data;

      if (insn_divu || insn_remu) begin
        div_in_dividend = rs1_data;
        div_in_divisor  = rs2_data;
      end else if (insn_div || insn_rem) begin
        div_in_dividend = div_a_abs;
        div_in_divisor  = div_b_abs;
      end

      
end

always_ff @(posedge clk) begin
        if (rst) begin
          div_stall_count <= 4'd0;
        end else if (div_use && div_stall_count < 4'd8) begin
        // Increment until we reach the 8th cycle of execution
          div_stall_count <= div_stall_count + 4'd1;
        end else if (div_stall_count == 4'd8) begin
        // Reset once the result is ready to be captured (9th cycle)
          div_stall_count <= 4'd0;
        end
end

assign stall_active = (div_use && div_stall_count < 4'd8);
  
  // ---------------- Main datapath comb ----------------
  always_comb begin
    illegal_insn = 1'b0;

    halt = 1'b0;
    we   = 1'b0;
    rd   = 5'd0;
    rd_data = 32'd0;

    if (stall_active) begin
        pcNext = pcCurrent; // Hold PC
    end else begin
        pcNext = pcCurrent + 32'd4; // Default increment
    end

    addr_to_dmem = 32'd0;
    store_data_to_dmem = 32'd0;
    store_we_to_dmem = 4'b0000;

    case (insn_opcode)
      OpLui: begin
        rd = insn_rd;
        we = 1'b1;
        rd_data = {imm_u, 12'b0};
      end

      OpAuipc: begin
        rd = insn_rd;
        we = 1'b1;
        rd_data = pcCurrent + {imm_u, 12'b0};
      end

      OpJal: begin
        rd = insn_rd;
        we = 1'b1;
        rd_data = pcCurrent + 32'd4;
        pcNext  = pcCurrent + imm_j_sext;
      end

      OpJalr: begin
        rd = insn_rd;
        we = 1'b1;
        rd_data = pcCurrent + 32'd4;
        pcNext = (rs1_data + imm_i_sext) & 32'hFFFF_FFFC;
      end

      OpLoad: begin
        logic [31:0] eff_addr;
        logic [1:0] off;
        logic [31:0] w;
        logic [7:0] b;
        logic [15:0] h;

        rd = insn_rd;
        we = 1'b1;

        eff_addr = rs1_data + imm_i_sext;
        off = eff_addr[1:0];
        addr_to_dmem = eff_addr & 32'hFFFF_FFFC;
        w = load_data_from_dmem;

        if (insn_lw) begin
          if (off != 2'b00) begin
            illegal_insn = 1'b1;
            we = 1'b0;
          end else begin
            rd_data = w;
          end
        end else if (insn_lb || insn_lbu) begin
          case (off)
            2'd0: b = w[7:0];
            2'd1: b = w[15:8];
            2'd2: b = w[23:16];
            default: b = w[31:24];
          endcase
          rd_data = insn_lb ? {{24{b[7]}}, b} : {24'b0, b};
        end else if (insn_lh || insn_lhu) begin
          if (off[0] != 1'b0) begin
            illegal_insn = 1'b1;
            we = 1'b0;
          end else begin
            h = off[1] ? w[31:16] : w[15:0];
            rd_data = insn_lh ? {{16{h[15]}}, h} : {16'b0, h};
          end
        end else begin
          illegal_insn = 1'b1;
          we = 1'b0;
        end
      end

      OpStore: begin
        logic [31:0] eff_addr;
        logic [1:0] off;

        eff_addr = rs1_data + imm_s_sext;
        off = eff_addr[1:0];
        addr_to_dmem = eff_addr & 32'hFFFF_FFFC;

        if (insn_sw) begin
          if (off != 2'b00) begin
            illegal_insn = 1'b1;
          end else begin
            store_we_to_dmem = 4'b1111;
            store_data_to_dmem = rs2_data;
          end
        end else if (insn_sb) begin
          store_we_to_dmem = (4'b0001 << off);
          store_data_to_dmem = ({24'b0, rs2_data[7:0]} << (off * 8));
        end else if (insn_sh) begin
          if (off[0] != 1'b0) begin
            illegal_insn = 1'b1;
          end else if (off[1] == 1'b0) begin
            store_we_to_dmem = 4'b0011;
            store_data_to_dmem = {16'b0, rs2_data[15:0]};
          end else begin
            store_we_to_dmem = 4'b1100;
            store_data_to_dmem = {rs2_data[15:0], 16'b0};
          end
        end else begin
          illegal_insn = 1'b1;
        end
      end

      OpMiscMem: begin
        // fence/fence.i: NOP
      end

      OpRegImm: begin
        rd = insn_rd;
        we = 1'b1;

        if (insn_addi) begin
          rd_data = cla_sum;
        end else if (insn_slti) begin
          rd_data = ($signed(rs1_data) < $signed(imm_i_sext)) ? 32'd1 : 32'd0;
        end else if (insn_sltiu) begin
          rd_data = (rs1_data < imm_i_sext) ? 32'd1 : 32'd0;
        end else if (insn_xori) begin
          rd_data = rs1_data ^ imm_i_sext;
        end else if (insn_ori) begin
          rd_data = rs1_data | imm_i_sext;
        end else if (insn_andi) begin
          rd_data = rs1_data & imm_i_sext;
        end else if (insn_slli) begin
          rd_data = rs1_data << imm_shamt;
        end else if (insn_srli) begin
          rd_data = rs1_data >> imm_shamt;
        end else if (insn_srai) begin
          rd_data = $signed(rs1_data) >>> imm_shamt;
        end else begin
          illegal_insn = 1'b1;
          we = 1'b0;
        end
      end

      OpRegReg: begin
        rd = insn_rd;
        
        if(stall_active) begin
          we = 1'b0;
        end else begin
          we = 1'b1;
        end

        if (insn_add || insn_sub) begin
          rd_data = cla_sum;
        end else if (insn_sll) begin
          rd_data = rs1_data << rs2_data[4:0];
        end else if (insn_slt) begin
          rd_data = ($signed(rs1_data) < $signed(rs2_data)) ? 32'd1 : 32'd0;
        end else if (insn_sltu) begin
          rd_data = (rs1_data < rs2_data) ? 32'd1 : 32'd0;
        end else if (insn_xor) begin
          rd_data = rs1_data ^ rs2_data;
        end else if (insn_srl) begin
          rd_data = rs1_data >> rs2_data[4:0];
        end else if (insn_sra) begin
          rd_data = $signed(rs1_data) >>> rs2_data[4:0];
        end else if (insn_or) begin
          rd_data = rs1_data | rs2_data;
        end else if (insn_and) begin
          rd_data = rs1_data & rs2_data;
        end else if (insn_mul || insn_mulh || insn_mulhsu || insn_mulhu) begin
          logic signed [63:0] a_s;
          logic signed [63:0] b_s;
          logic [63:0] a_u;
          logic [63:0] b_u;
          logic signed [63:0] prod_ss;
          logic signed [63:0] prod_su;
          logic [63:0] prod_uu;

          a_s = {{32{rs1_data[31]}}, rs1_data};
          b_s = {{32{rs2_data[31]}}, rs2_data};
          a_u = {32'b0, rs1_data};
          b_u = {32'b0, rs2_data};

          prod_ss = a_s * b_s;
          prod_su = a_s * $signed(b_u);
          prod_uu = a_u * b_u;

          if (insn_mul) begin
            rd_data = prod_ss[31:0];
          end else if (insn_mulh) begin
            rd_data = prod_ss[63:32];
          end else if (insn_mulhsu) begin
            rd_data = prod_su[63:32];
          end else begin
            rd_data = prod_uu[63:32];
          end
        end else if (insn_div || insn_divu || insn_rem || insn_remu) begin
          if (div_div_by_zero) begin
            if (insn_div || insn_divu) rd_data = 32'hFFFF_FFFF;
            else rd_data = rs1_data;
          end else if (div_overflow) begin
            if (insn_div) rd_data = 32'h8000_0000;
            else if (insn_rem) rd_data = 32'd0;
            else rd_data = div_is_rem ? 32'd0 : 32'h8000_0000;
          end else if (insn_divu || insn_remu) begin
            rd_data = (insn_divu) ? div_out_quotient : div_out_remainder;
          end else begin
            logic [31:0] q_abs, r_abs;
            logic [31:0] q_signed, r_signed;
            q_abs = div_out_quotient;
            r_abs = div_out_remainder;
            q_signed = (div_a_neg ^ div_b_neg) ? twos_comp32(q_abs) : q_abs;
            r_signed = div_a_neg ? twos_comp32(r_abs) : r_abs;
            rd_data = insn_div ? q_signed : r_signed;
          end
        end else begin
          illegal_insn = 1'b1;
          we = 1'b0;
        end
      end

      OpBranch: begin
        we = 1'b0;
        if (insn_beq) begin
          if (rs1_data == rs2_data) pcNext = pcCurrent + imm_b_sext;
        end else if (insn_bne) begin
          if (rs1_data != rs2_data) pcNext = pcCurrent + imm_b_sext;
        end else if (insn_blt) begin
          if ($signed(rs1_data) < $signed(rs2_data)) pcNext = pcCurrent + imm_b_sext;
        end else if (insn_bge) begin
          if ($signed(rs1_data) >= $signed(rs2_data)) pcNext = pcCurrent + imm_b_sext;
        end else if (insn_bltu) begin
          if (rs1_data < rs2_data) pcNext = pcCurrent + imm_b_sext;
        end else if (insn_bgeu) begin
          if (rs1_data >= rs2_data) pcNext = pcCurrent + imm_b_sext;
        end else begin
          illegal_insn = 1'b1;
        end
      end

      OpEnviron: begin
        if (insn_ecall) halt = 1'b1;
        else illegal_insn = 1'b1;
      end

      default: begin
        illegal_insn = 1'b1;
      end
    endcase
  end

  // trace signals
  assign trace_completed_pc = pcCurrent;
  assign trace_completed_insn = insn_from_imem;
  assign trace_completed_cycle_status = stall_active ? CYCLE_DIV : CYCLE_NO_STALL;

endmodule
module MemorySingleCycle #(
    parameter int NUM_WORDS = 512
) (
    // rst for both imem and dmem
    input wire rst,

    // clock for both imem and dmem. See RiscvProcessor for clock details.
    input wire clock_mem,

    // must always be aligned to a 4B boundary
    input wire [`REG_SIZE] pc_to_imem,

    // the value at memory location pc_to_imem
    output logic [`INSN_SIZE] insn_from_imem,

    // must always be aligned to a 4B boundary
    input wire [`REG_SIZE] addr_to_dmem,

    // the value at memory location addr_to_dmem
    output logic [`REG_SIZE] load_data_from_dmem,

    // the value to be written to addr_to_dmem, controlled by store_we_to_dmem
    input wire [`REG_SIZE] store_data_to_dmem,

    // Each bit determines whether to write the corresponding byte of store_data_to_dmem to memory location addr_to_dmem.
    // E.g., 4'b1111 will write 4 bytes. 4'b0001 will write only the least-significant byte.
    input wire [3:0] store_we_to_dmem
);

  // memory is arranged as an array of 4B words
  logic [`REG_SIZE] mem_array[NUM_WORDS];

`ifdef SYNTHESIS
  initial begin
    $readmemh("mem_initial_contents.hex", mem_array);
  end
`endif

  always_comb begin
    // memory addresses should always be 4B-aligned
    assert (pc_to_imem[1:0] == 2'b00);
    assert (addr_to_dmem[1:0] == 2'b00);
  end

  localparam int AddrMsb = $clog2(NUM_WORDS) + 1;
  localparam int AddrLsb = 2;

  always @(posedge clock_mem) begin
    if (rst) begin
    end else begin
      insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
    end
  end

  always @(negedge clock_mem) begin
    if (rst) begin
    end else begin
      if (store_we_to_dmem[0]) begin
        mem_array[addr_to_dmem[AddrMsb:AddrLsb]][7:0] <= store_data_to_dmem[7:0];
      end
      if (store_we_to_dmem[1]) begin
        mem_array[addr_to_dmem[AddrMsb:AddrLsb]][15:8] <= store_data_to_dmem[15:8];
      end
      if (store_we_to_dmem[2]) begin
        mem_array[addr_to_dmem[AddrMsb:AddrLsb]][23:16] <= store_data_to_dmem[23:16];
      end
      if (store_we_to_dmem[3]) begin
        mem_array[addr_to_dmem[AddrMsb:AddrLsb]][31:24] <= store_data_to_dmem[31:24];
      end
      // dmem is "read-first": read returns value before the write
      load_data_from_dmem <= mem_array[{addr_to_dmem[AddrMsb:AddrLsb]}];
    end
  end
endmodule

/*
This shows the relationship between clock_proc and clock_mem. The clock_mem is
phase-shifted 90° from clock_proc. You could think of one proc cycle being
broken down into 3 parts. During part 1 (which starts @posedge clock_proc)
the current PC is sent to the imem. In part 2 (starting @posedge clock_mem) we
read from imem. In part 3 (starting @negedge clock_mem) we read/write memory and
prepare register/PC updates, which occur at @posedge clock_proc.

        ____
 proc: |    |______
           ____
 mem:  ___|    |___
*/
module Processor (
    input wire               clock_proc,
    input wire               clock_mem,
    input wire               rst,
    output wire [`REG_SIZE]  trace_completed_pc,
    output wire [`INSN_SIZE] trace_completed_insn,
    output cycle_status_e    trace_completed_cycle_status, 
    output logic             halt
);

  wire [`REG_SIZE] pc_to_imem, mem_data_addr, mem_data_loaded_value, mem_data_to_write;
  wire [`INSN_SIZE] insn_from_imem;
  wire [3:0] mem_data_we;

  // This wire is set by cocotb to the name of the currently-running test, to make it easier
  // to see what is going on in the waveforms.
  wire [(8*32)-1:0] test_case;

  MemorySingleCycle #(
      .NUM_WORDS(8192)
  ) memory (
      .rst      (rst),
      .clock_mem (clock_mem),
      // imem is read-only
      .pc_to_imem(pc_to_imem),
      .insn_from_imem(insn_from_imem),
      // dmem is read-write
      .addr_to_dmem(mem_data_addr),
      .load_data_from_dmem(mem_data_loaded_value),
      .store_data_to_dmem (mem_data_to_write),
      .store_we_to_dmem  (mem_data_we)
  );

  DatapathSingleCycle datapath (
      .clk(clock_proc),
      .rst(rst),
      .pc_to_imem(pc_to_imem),
      .insn_from_imem(insn_from_imem),
      .addr_to_dmem(mem_data_addr),
      .store_data_to_dmem(mem_data_to_write),
      .store_we_to_dmem(mem_data_we),
      .load_data_from_dmem(mem_data_loaded_value),
      .trace_completed_pc(trace_completed_pc),
      .trace_completed_insn(trace_completed_insn),
      .trace_completed_cycle_status(trace_completed_cycle_status),
      .halt(halt)
  );

endmodule

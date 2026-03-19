`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31:0

// insns are 32 bits in RV32IM
`define INSN_SIZE 31:0

// RV opcodes are 7 bits
`define OPCODE_SIZE 6:0

`ifndef DIVIDER_STAGES
`define DIVIDER_STAGES 8
`endif

`ifndef SYNTHESIS
`include "../hw3-singlecycle/RvDisassembler.sv"
`endif
`include "../hw2b-cla/CarryLookaheadAdder.sv"
`include "../hw4-multicycle/DividerUnsignedPipelined.sv"
`include "../hw3-singlecycle/cycle_status.sv"

module Disasm #(
    byte PREFIX = "D"
) (
    input wire [31:0] insn,
    output wire [(8*32)-1:0] disasm
);
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

  // async reads with built-in WD bypass and x0 hardwired to zero
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

  // sync writes
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

/** state at the start of Decode stage */
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
  logic [`REG_SIZE] imm_u;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [`OPCODE_SIZE] opcode;
  logic reg_write;
  logic is_branch;
  logic is_ecall;
} stage_execute_t;

typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e cycle_status;
  logic [4:0] rd;
  logic reg_write;
  logic [`REG_SIZE] rd_value;
  logic is_ecall;
} stage_memory_t;

typedef stage_memory_t stage_writeback_t;

module DatapathPipelined (
    input wire clk,
    input wire rst,
    output logic [`REG_SIZE] pc_to_imem,
    input wire [`INSN_SIZE] insn_from_imem,
    // dmem is read/write
    output logic [`REG_SIZE] addr_to_dmem,
    input wire [`REG_SIZE] load_data_from_dmem,
    output logic [`REG_SIZE] store_data_to_dmem,
    output logic [3:0] store_we_to_dmem,

    output logic halt,

    // The PC of the insn currently in Writeback. 0 if not a valid insn.
    output logic [`REG_SIZE] trace_completed_pc,
    // The bits of the insn currently in Writeback. 0 if not a valid insn.
    output logic [`INSN_SIZE] trace_completed_insn,
    // The status of the insn (or stall) currently in Writeback. See the cycle_status.sv file for valid values.
    output cycle_status_e trace_completed_cycle_status
);

  // opcodes - see section 19 of RiscV spec
  localparam bit [`OPCODE_SIZE] OpcodeBranch = 7'b11_000_11;

  localparam bit [`OPCODE_SIZE] OpcodeRegImm = 7'b00_100_11;
  localparam bit [`OPCODE_SIZE] OpcodeRegReg = 7'b01_100_11;
  localparam bit [`OPCODE_SIZE] OpcodeEnviron = 7'b11_100_11;

  localparam bit [`OPCODE_SIZE] OpcodeAuipc = 7'b00_101_11;
  localparam bit [`OPCODE_SIZE] OpcodeLui = 7'b01_101_11;

  // cycle counter, not really part of any stage but useful for orienting within GtkWave
  // do not rename this as the testbench uses this value
  logic [`REG_SIZE] cycles_current;
  always_ff @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
    end
  end

  /***************/
  /* FETCH STAGE */
  /***************/

  logic [`REG_SIZE] f_pc_current;
  wire [`REG_SIZE] f_insn;
  cycle_status_e f_cycle_status;

  assign pc_to_imem = f_pc_current;
  assign f_insn = insn_from_imem;

  // Here's how to disassemble an insn into a string you can view in GtkWave.
  // Use PREFIX to provide a 1-character tag to identify which stage the insn comes from.
  wire [255:0] f_disasm;
  Disasm #(
      .PREFIX("F")
  ) disasm_0fetch (
      .insn  (f_insn),
      .disasm(f_disasm)
  );

  /****************/
  /* DECODE STAGE */
  /****************/

  stage_decode_t decode_state;

  wire [255:0] d_disasm;
  Disasm #(
      .PREFIX("D")
  ) disasm_1decode (
      .insn  (decode_state.insn),
      .disasm(d_disasm)
  );

  // Decode-stage field extraction
  wire [6:0] d_funct7 = decode_state.insn[31:25];
  wire [4:0] d_rs2 = decode_state.insn[24:20];
  wire [4:0] d_rs1 = decode_state.insn[19:15];
  wire [2:0] d_funct3 = decode_state.insn[14:12];
  wire [4:0] d_rd = decode_state.insn[11:7];
  wire [`OPCODE_SIZE] d_opcode = decode_state.insn[6:0];

  wire [11:0] d_imm_i = decode_state.insn[31:20];
  wire [12:0] d_imm_b = {decode_state.insn[31], decode_state.insn[7], decode_state.insn[30:25], decode_state.insn[11:8], 1'b0};
  wire [19:0] d_imm_u_raw = decode_state.insn[31:12];

  wire [`REG_SIZE] d_imm_i_sext = {{20{d_imm_i[11]}}, d_imm_i};
  wire [`REG_SIZE] d_imm_b_sext = {{19{d_imm_b[12]}}, d_imm_b};
  wire [`REG_SIZE] d_imm_u = {d_imm_u_raw, 12'b0};

  // Register file reads happen in Decode. Testbench requires the instance name `rf`.
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

  wire d_is_lui   = (d_opcode == OpcodeLui);
  wire d_is_auipc = (d_opcode == OpcodeAuipc);

  wire d_is_regimm = (d_opcode == OpcodeRegImm);
  wire d_is_regreg = (d_opcode == OpcodeRegReg);

  wire d_is_branch = (d_opcode == OpcodeBranch);
  wire d_is_ecall = (d_opcode == OpcodeEnviron) && (decode_state.insn[31:7] == 25'd0);

  wire d_reg_write = d_is_lui || d_is_auipc || d_is_regimm || d_is_regreg;

  /*****************/
  /* EXECUTE STAGE */
  /*****************/

  stage_execute_t x_state;

  wire [255:0] x_disasm;
  Disasm #(
      .PREFIX("X")
  ) disasm_2execute (
      .insn  (x_state.insn),
      .disasm(x_disasm)
  );

  /****************/
  /* MEMORY STAGE */
  /****************/

  stage_memory_t m_state;

  wire [255:0] m_disasm;
  Disasm #(
      .PREFIX("M")
  ) disasm_3memory (
      .insn  (m_state.insn),
      .disasm(m_disasm)
  );

  /*******************/
  /* WRITEBACK STAGE */
  /*******************/

  stage_writeback_t w_state;

  wire [255:0] w_disasm;
  Disasm #(
      .PREFIX("W")
  ) disasm_4writeback (
      .insn  (w_state.insn),
      .disasm(w_disasm)
  );

  // Execute-stage forwarding (MX and WX bypasses)
  logic [`REG_SIZE] x_src1;
  logic [`REG_SIZE] x_src2;
  always_comb begin
    x_src1 = x_state.rs1_val;
    if ((x_state.rs1 != 5'd0) && m_state.reg_write && (m_state.rd == x_state.rs1)) begin

      x_src1 = m_state.rd_value;
    end else if ((x_state.rs1 != 5'd0) && w_state.reg_write && (w_state.rd == x_state.rs1)) begin
      x_src1 = w_state.rd_value;
    end


    x_src2 = x_state.rs2_val;
    if ((x_state.rs2 != 5'd0) && m_state.reg_write && (m_state.rd == x_state.rs2)) begin
      x_src2 = m_state.rd_value;
    end else if ((x_state.rs2 != 5'd0) && w_state.reg_write && (w_state.rd == x_state.rs2)) begin
      x_src2 = w_state.rd_value;
    end

  end

  logic [`REG_SIZE] x_alu_result;
  logic x_branch_taken;
  logic [`REG_SIZE] x_branch_target;

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
          3'b000: x_alu_result = x_src1 + x_state.imm_i_sext;                     // addi
          3'b010: x_alu_result = ($signed(x_src1) < $signed(x_state.imm_i_sext)) ? 32'd1 : 32'd0; // slti
          3'b011: x_alu_result = (x_src1 < x_state.imm_i_sext) ? 32'd1 : 32'd0;  // sltiu
          3'b100: x_alu_result = x_src1 ^ x_state.imm_i_sext;     // xori
          3'b110: x_alu_result = x_src1 | x_state.imm_i_sext;                                // ori
          3'b111: x_alu_result = x_src1 & x_state.imm_i_sext;              // andi
          3'b001: x_alu_result = x_src1 << x_state.insn[24:20];         // slli
          3'b101: begin
            if (x_state.funct7 == 7'b0100000) begin
              x_alu_result = $signed(x_src1) >>> x_state.insn[24:20];             // srai
            end else begin
              x_alu_result = x_src1 >> x_state.insn[24:20];                       // srli
            end
          end
          default: x_alu_result = 32'd0;
        endcase
      end

      OpcodeRegReg: begin
        case (x_state.funct3)
          3'b000: begin
            if (x_state.funct7 == 7'b0100000) begin
              x_alu_result = x_src1 - x_src2;                                      // sub
            end else begin
              x_alu_result = x_src1 + x_src2;                                      // add
            end
          end
          3'b001: x_alu_result = x_src1 << x_src2[4:0];                           // sll

          3'b010: x_alu_result = ($signed(x_src1) < $signed(x_src2)) ? 32'd1 : 32'd0; // slt
          3'b011: x_alu_result = (x_src1 < x_src2) ? 32'd1 : 32'd0;               // sltu
          3'b100: x_alu_result = x_src1 ^ x_src2;                                  // xor
          3'b101: begin
            if (x_state.funct7 == 7'b0100000) begin
              x_alu_result = $signed(x_src1) >>> x_src2[4:0];                      // sra
            end else begin
              x_alu_result = x_src1 >> x_src2[4:0];                                // srl
            end
          end
          3'b110: x_alu_result = x_src1 | x_src2;                                  // or
          3'b111: x_alu_result = x_src1 & x_src2;                                  // and
          default: x_alu_result = 32'd0;
        endcase
      end

      OpcodeBranch: begin
        case (x_state.funct3)
          3'b000: x_branch_taken = (x_src1 == x_src2);                 // beq
          3'b001: x_branch_taken = (x_src1 != x_src2);                 // bne
          3'b100: x_branch_taken = ($signed(x_src1) <  $signed(x_src2)); // blt
          3'b101: x_branch_taken = ($signed(x_src1) >= $signed(x_src2)); // bge
          3'b110: x_branch_taken = (x_src1 <  x_src2);                 // bltu
          3'b111: x_branch_taken = (x_src1 >= x_src2);                 // bgeu
          default: x_branch_taken = 1'b0;
        endcase
      end

      default: begin
        x_alu_result = 32'd0;
      end
    endcase

    if (x_state.cycle_status != CYCLE_NO_STALL) begin
      x_branch_taken = 1'b0;
    end
  end

  // dmem unused for Milestone 1
  always_comb begin
    addr_to_dmem = 32'd0;
    store_data_to_dmem = 32'd0;
    store_we_to_dmem = 4'b0000;
  end

  // WB outputs / side effects
  always_comb begin
    trace_completed_cycle_status = w_state.cycle_status;
    trace_completed_pc = (w_state.cycle_status == CYCLE_NO_STALL) ? w_state.pc : 32'd0;
    trace_completed_insn = (w_state.cycle_status == CYCLE_NO_STALL) ? w_state.insn : 32'd0;
    halt = (w_state.cycle_status == CYCLE_NO_STALL) && w_state.is_ecall;

    rf_rd = w_state.rd;
    rf_rd_data = w_state.rd_value;
    rf_we = (w_state.cycle_status == CYCLE_NO_STALL) && w_state.reg_write;
  end

  // Pipeline registers
  always_ff @(posedge clk) begin
    if (rst) begin
      f_pc_current <= 32'd0;
      f_cycle_status <= CYCLE_NO_STALL;

      decode_state <= '{pc: 32'd0, insn: 32'd0, cycle_status: CYCLE_RESET};
      x_state <= '{
        pc: 32'd0,
        insn: 32'd0,
        cycle_status: CYCLE_RESET,
        rs1: 5'd0,
        rs2: 5'd0,
        rd: 5'd0,
        rs1_val: 32'd0,
        rs2_val: 32'd0,
        imm_i_sext: 32'd0,
        imm_b_sext: 32'd0,
        imm_u: 32'd0,
        funct3: 3'd0,
        funct7: 7'd0,
        opcode: 7'd0,
        reg_write: 1'b0,
        is_branch: 1'b0,
        is_ecall: 1'b0
      };
      m_state <= '{
        pc: 32'd0,
        insn: 32'd0,
        cycle_status: CYCLE_RESET,
        rd: 5'd0,
        reg_write: 1'b0,
        rd_value: 32'd0,
        is_ecall: 1'b0
      };
      w_state <= '{
        pc: 32'd0,
        insn: 32'd0,
        cycle_status: CYCLE_RESET,
        rd: 5'd0,
        reg_write: 1'b0,
        rd_value: 32'd0,
        is_ecall: 1'b0
      };
    end else begin
      // older stages always advance
      w_state <= m_state;
      m_state <= '{
        pc: x_state.pc,
        insn: x_state.insn,
        cycle_status: x_state.cycle_status,
        rd: x_state.rd,
        reg_write: x_state.reg_write,
        rd_value: x_alu_result,
        is_ecall: x_state.is_ecall
      };

      if (x_branch_taken) begin
        // branch resolved in Execute; flush wrong-path insns in Fetch and Decode
        f_pc_current <= x_branch_target;
        f_cycle_status <= CYCLE_NO_STALL;

        decode_state <= '{
          pc: 32'd0,
          insn: 32'd0,
          cycle_status: CYCLE_TAKEN_BRANCH
        };

        x_state <= '{
          pc: 32'd0,
          insn: 32'd0,
          cycle_status: CYCLE_TAKEN_BRANCH,
          rs1: 5'd0,
          rs2: 5'd0,
          rd: 5'd0,
          rs1_val: 32'd0,
          rs2_val: 32'd0,
          imm_i_sext: 32'd0,
          imm_b_sext: 32'd0,
          imm_u: 32'd0,
          funct3: 3'd0,
          funct7: 7'd0,
          opcode: 7'd0,
          reg_write: 1'b0,
          is_branch: 1'b0,
          is_ecall: 1'b0
        };
      end else begin
        f_pc_current <= f_pc_current + 32'd4;
        f_cycle_status <= CYCLE_NO_STALL;

        decode_state <= '{
          pc: f_pc_current,
          insn: f_insn,
          cycle_status: f_cycle_status
        };

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
          imm_u: d_imm_u,
          funct3: d_funct3,
          funct7: d_funct7,
          opcode: d_opcode,
          reg_write: d_reg_write,
          is_branch: d_is_branch,
          is_ecall: d_is_ecall
        };
      end
    end
  end

endmodule

module MemorySingleCycle #(
    parameter int NUM_WORDS = 512
) (
    // rst for both imem and dmem
    input wire rst,

    // clock for both imem and dmem. The memory reads/writes on @(negedge clk)
    input wire clk,

    // must always be aligned to a 4B boundary
    input wire [`REG_SIZE] pc_to_imem,

    // the value at memory location pc_to_imem
    output logic [`REG_SIZE] insn_from_imem,

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

  always @(negedge clk) begin
    if (rst) begin
    end else begin
      insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
    end
  end

  always @(negedge clk) begin
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

/* This design has just one clock for both processor and memory. */
module Processor (
    input  wire  clk,
    input  wire  rst,
    output logic halt,
    output wire [`REG_SIZE] trace_completed_pc,
    output wire [`INSN_SIZE] trace_completed_insn,
    output cycle_status_e trace_completed_cycle_status
);


  wire [`INSN_SIZE] insn_from_imem;
  wire [`REG_SIZE] pc_to_imem, mem_data_addr, mem_data_loaded_value, mem_data_to_write;
  wire [3:0] mem_data_we;

  // This wire is set by cocotb to the name of the currently-running test, to make it easier
  // to see what is going on in the waveforms.
  wire [(8*32)-1:0] test_case;

  MemorySingleCycle #(
      .NUM_WORDS(8192)
  ) memory (
      .rst                (rst),
      .clk                (clk),
      // imem is read-only
      .pc_to_imem         (pc_to_imem),
      .insn_from_imem     (insn_from_imem),
      // dmem is read-write
      .addr_to_dmem       (mem_data_addr),
      .load_data_from_dmem(mem_data_loaded_value),
      .store_data_to_dmem (mem_data_to_write),
      .store_we_to_dmem   (mem_data_we)
  );

  DatapathPipelined datapath (
      .clk(clk),
      .rst(rst),
      .pc_to_imem(pc_to_imem),
      .insn_from_imem(insn_from_imem),
      .addr_to_dmem(mem_data_addr),
      .store_data_to_dmem(mem_data_to_write),
      .store_we_to_dmem(mem_data_we),
      .load_data_from_dmem(mem_data_loaded_value),
      .halt(halt),
      .trace_completed_pc(trace_completed_pc),
      .trace_completed_insn(trace_completed_insn),
      .trace_completed_cycle_status(trace_completed_cycle_status)
  );


endmodule

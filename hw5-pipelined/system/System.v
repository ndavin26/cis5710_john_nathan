module MyClockGen (
	input_clk_25MHz,
	clk_proc,
	locked
);
	input input_clk_25MHz;
	output wire clk_proc;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "20" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
		.PLLRST_ENA("DISABLED"),
		.INTFB_WAKE("DISABLED"),
		.STDBY_ENABLE("DISABLED"),
		.DPHASE_SOURCE("DISABLED"),
		.OUTDIVIDER_MUXA("DIVA"),
		.OUTDIVIDER_MUXB("DIVB"),
		.OUTDIVIDER_MUXC("DIVC"),
		.OUTDIVIDER_MUXD("DIVD"),
		.CLKI_DIV(5),
		.CLKOP_ENABLE("ENABLED"),
		.CLKOP_DIV(30),
		.CLKOP_CPHASE(15),
		.CLKOP_FPHASE(0),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(4)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_proc),
		.CLKFB(clkfb),
		.CLKINTFB(clkfb),
		.PHASESEL0(1'b0),
		.PHASESEL1(1'b0),
		.PHASEDIR(1'b1),
		.PHASESTEP(1'b1),
		.PHASELOADREG(1'b1),
		.PLLWAKESYNC(1'b0),
		.ENCLKOP(1'b0),
		.LOCK(locked)
	);
endmodule
module Disasm (
	insn,
	disasm
);
	parameter signed [7:0] PREFIX = "D";
	input wire [31:0] insn;
	output wire [255:0] disasm;
endmodule
module RegFile (
	rd,
	rd_data,
	rs1,
	rs1_data,
	rs2,
	rs2_data,
	clk,
	we,
	rst
);
	reg _sv2v_0;
	input wire [4:0] rd;
	input wire [31:0] rd_data;
	input wire [4:0] rs1;
	output reg [31:0] rs1_data;
	input wire [4:0] rs2;
	output reg [31:0] rs2_data;
	input wire clk;
	input wire we;
	input wire rst;
	localparam signed [31:0] NumRegs = 32;
	reg [31:0] regs [0:31];
	always @(*) begin
		if (_sv2v_0)
			;
		if (rs1 == 5'd0)
			rs1_data = 32'd0;
		else if ((we && (rd != 5'd0)) && (rd == rs1))
			rs1_data = rd_data;
		else
			rs1_data = regs[rs1];
		if (rs2 == 5'd0)
			rs2_data = 32'd0;
		else if ((we && (rd != 5'd0)) && (rd == rs2))
			rs2_data = rd_data;
		else
			rs2_data = regs[rs2];
	end
	always @(posedge clk)
		if (rst) begin : sv2v_autoblock_1
			reg signed [31:0] j;
			for (j = 0; j < NumRegs; j = j + 1)
				regs[j] <= 32'd0;
		end
		else if (we && (rd != 5'd0))
			regs[rd] <= rd_data;
	initial _sv2v_0 = 0;
endmodule
module DatapathPipelined (
	clk,
	rst,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem,
	halt,
	trace_writeback_pc,
	trace_writeback_insn,
	trace_writeback_cycle_status
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	output wire [31:0] pc_to_imem;
	input wire [31:0] insn_from_imem;
	output reg [31:0] addr_to_dmem;
	input wire [31:0] load_data_from_dmem;
	output reg [31:0] store_data_to_dmem;
	output reg [3:0] store_we_to_dmem;
	output reg halt;
	output reg [31:0] trace_writeback_pc;
	output reg [31:0] trace_writeback_insn;
	output reg [31:0] trace_writeback_cycle_status;
	localparam [6:0] OpcodeBranch = 7'b1100011;
	localparam [6:0] OpcodeRegImm = 7'b0010011;
	localparam [6:0] OpcodeRegReg = 7'b0110011;
	localparam [6:0] OpcodeEnviron = 7'b1110011;
	localparam [6:0] OpcodeAuipc = 7'b0010111;
	localparam [6:0] OpcodeLui = 7'b0110111;
	reg [31:0] cycles_current;
	always @(posedge clk)
		if (rst)
			cycles_current <= 0;
		else
			cycles_current <= cycles_current + 1;
	reg [31:0] f_pc_current;
	wire [31:0] f_insn;
	reg [31:0] f_cycle_status;
	assign pc_to_imem = f_pc_current;
	assign f_insn = insn_from_imem;
	wire [255:0] f_disasm;
	Disasm #(.PREFIX("F")) disasm_0fetch(
		.insn(f_insn),
		.disasm(f_disasm)
	);
	reg [95:0] decode_state;
	wire [255:0] d_disasm;
	Disasm #(.PREFIX("D")) disasm_1decode(
		.insn(decode_state[63-:32]),
		.disasm(d_disasm)
	);
	wire [6:0] d_funct7 = decode_state[63:57];
	wire [4:0] d_rs2 = decode_state[56:52];
	wire [4:0] d_rs1 = decode_state[51:47];
	wire [2:0] d_funct3 = decode_state[46:44];
	wire [4:0] d_rd = decode_state[43:39];
	wire [6:0] d_opcode = decode_state[38:32];
	wire [11:0] d_imm_i = decode_state[63:52];
	wire [12:0] d_imm_b = {decode_state[63], decode_state[39], decode_state[62:57], decode_state[43:40], 1'b0};
	wire [19:0] d_imm_u_raw = decode_state[63:44];
	wire [31:0] d_imm_i_sext = {{20 {d_imm_i[11]}}, d_imm_i};
	wire [31:0] d_imm_b_sext = {{19 {d_imm_b[12]}}, d_imm_b};
	wire [31:0] d_imm_u = {d_imm_u_raw, 12'b000000000000};
	reg [4:0] rf_rd;
	reg [31:0] rf_rd_data;
	reg rf_we;
	wire [31:0] rf_rs1_data;
	wire [31:0] rf_rs2_data;
	RegFile rf(
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
	wire d_is_lui = d_opcode == OpcodeLui;
	wire d_is_auipc = d_opcode == OpcodeAuipc;
	wire d_is_regimm = d_opcode == OpcodeRegImm;
	wire d_is_regreg = d_opcode == OpcodeRegReg;
	wire d_is_branch = d_opcode == OpcodeBranch;
	wire d_is_ecall = (d_opcode == OpcodeEnviron) && (decode_state[63:39] == 25'd0);
	wire d_reg_write = ((d_is_lui || d_is_auipc) || d_is_regimm) || d_is_regreg;
	reg [290:0] x_state;
	wire [255:0] x_disasm;
	Disasm #(.PREFIX("X")) disasm_2execute(
		.insn(x_state[258-:32]),
		.disasm(x_disasm)
	);
	reg [134:0] m_state;
	wire [255:0] m_disasm;
	Disasm #(.PREFIX("M")) disasm_3memory(
		.insn(m_state[102-:32]),
		.disasm(m_disasm)
	);
	reg [134:0] w_state;
	wire [255:0] w_disasm;
	Disasm #(.PREFIX("W")) disasm_4writeback(
		.insn(w_state[102-:32]),
		.disasm(w_disasm)
	);
	reg [31:0] x_src1;
	reg [31:0] x_src2;
	always @(*) begin
		if (_sv2v_0)
			;
		x_src1 = x_state[179-:32];
		if (((x_state[194-:5] != 5'd0) && m_state[33]) && (m_state[38-:5] == x_state[194-:5]))
			x_src1 = m_state[32-:32];
		else if (((x_state[194-:5] != 5'd0) && w_state[33]) && (w_state[38-:5] == x_state[194-:5]))
			x_src1 = w_state[32-:32];
		x_src2 = x_state[147-:32];
		if (((x_state[189-:5] != 5'd0) && m_state[33]) && (m_state[38-:5] == x_state[189-:5]))
			x_src2 = m_state[32-:32];
		else if (((x_state[189-:5] != 5'd0) && w_state[33]) && (w_state[38-:5] == x_state[189-:5]))
			x_src2 = w_state[32-:32];
	end
	reg [31:0] x_alu_result;
	reg x_branch_taken;
	reg [31:0] x_branch_target;
	always @(*) begin
		if (_sv2v_0)
			;
		x_alu_result = 32'd0;
		x_branch_taken = 1'b0;
		x_branch_target = x_state[290-:32] + x_state[83-:32];
		case (x_state[9-:7])
			OpcodeLui: x_alu_result = x_state[51-:32];
			OpcodeAuipc: x_alu_result = x_state[290-:32] + x_state[51-:32];
			OpcodeRegImm:
				case (x_state[19-:3])
					3'b000: x_alu_result = x_src1 + x_state[115-:32];
					3'b010: x_alu_result = ($signed(x_src1) < $signed(x_state[115-:32]) ? 32'd1 : 32'd0);
					3'b011: x_alu_result = (x_src1 < x_state[115-:32] ? 32'd1 : 32'd0);
					3'b100: x_alu_result = x_src1 ^ x_state[115-:32];
					3'b110: x_alu_result = x_src1 | x_state[115-:32];
					3'b111: x_alu_result = x_src1 & x_state[115-:32];
					3'b001: x_alu_result = x_src1 << x_state[251:247];
					3'b101:
						if (x_state[16-:7] == 7'b0100000)
							x_alu_result = $signed(x_src1) >>> x_state[251:247];
						else
							x_alu_result = x_src1 >> x_state[251:247];
					default: x_alu_result = 32'd0;
				endcase
			OpcodeRegReg:
				case (x_state[19-:3])
					3'b000:
						if (x_state[16-:7] == 7'b0100000)
							x_alu_result = x_src1 - x_src2;
						else
							x_alu_result = x_src1 + x_src2;
					3'b001: x_alu_result = x_src1 << x_src2[4:0];
					3'b010: x_alu_result = ($signed(x_src1) < $signed(x_src2) ? 32'd1 : 32'd0);
					3'b011: x_alu_result = (x_src1 < x_src2 ? 32'd1 : 32'd0);
					3'b100: x_alu_result = x_src1 ^ x_src2;
					3'b101:
						if (x_state[16-:7] == 7'b0100000)
							x_alu_result = $signed(x_src1) >>> x_src2[4:0];
						else
							x_alu_result = x_src1 >> x_src2[4:0];
					3'b110: x_alu_result = x_src1 | x_src2;
					3'b111: x_alu_result = x_src1 & x_src2;
					default: x_alu_result = 32'd0;
				endcase
			OpcodeBranch:
				case (x_state[19-:3])
					3'b000: x_branch_taken = x_src1 == x_src2;
					3'b001: x_branch_taken = x_src1 != x_src2;
					3'b100: x_branch_taken = $signed(x_src1) < $signed(x_src2);
					3'b101: x_branch_taken = $signed(x_src1) >= $signed(x_src2);
					3'b110: x_branch_taken = x_src1 < x_src2;
					3'b111: x_branch_taken = x_src1 >= x_src2;
					default: x_branch_taken = 1'b0;
				endcase
			default: x_alu_result = 32'd0;
		endcase
		if (x_state[226-:32] != 32'd1)
			x_branch_taken = 1'b0;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		addr_to_dmem = 32'd0;
		store_data_to_dmem = 32'd0;
		store_we_to_dmem = 4'b0000;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		trace_writeback_cycle_status = w_state[70-:32];
		trace_writeback_pc = (w_state[70-:32] == 32'd1 ? w_state[134-:32] : 32'd0);
		trace_writeback_insn = (w_state[70-:32] == 32'd1 ? w_state[102-:32] : 32'd0);
		halt = (w_state[70-:32] == 32'd1) && w_state[0];
		rf_rd = w_state[38-:5];
		rf_rd_data = w_state[32-:32];
		rf_we = (w_state[70-:32] == 32'd1) && w_state[33];
	end
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(posedge clk)
		if (rst) begin
			f_pc_current <= 32'd0;
			f_cycle_status <= 32'd1;
			decode_state <= 96'h000000000000000000000004;
			x_state <= 291'h20000000000000000000000000000000000000000000000000;
			m_state <= 135'h0000000000000000000000020000000000;
			w_state <= 135'h0000000000000000000000020000000000;
		end
		else begin
			w_state <= m_state;
			m_state <= {sv2v_cast_32(x_state[290-:32]), sv2v_cast_32(x_state[258-:32]), sv2v_cast_32(x_state[226-:32]), sv2v_cast_5(x_state[184-:5]), x_state[2], x_alu_result, x_state[0]};
			if (x_branch_taken) begin
				f_pc_current <= x_branch_target;
				f_cycle_status <= 32'd1;
				decode_state <= 96'h000000000000000000000008;
				x_state <= 291'h40000000000000000000000000000000000000000000000000;
			end
			else begin
				f_pc_current <= f_pc_current + 32'd4;
				f_cycle_status <= 32'd1;
				decode_state <= {f_pc_current, f_insn, f_cycle_status};
				x_state <= {sv2v_cast_32(decode_state[95-:32]), sv2v_cast_32(decode_state[63-:32]), sv2v_cast_32(decode_state[31-:32]), d_rs1, d_rs2, d_rd, rf_rs1_data, rf_rs2_data, d_imm_i_sext, d_imm_b_sext, d_imm_u, d_funct3, d_funct7, d_opcode, d_reg_write, d_is_branch, d_is_ecall};
			end
		end
	initial _sv2v_0 = 0;
endmodule
module MemorySingleCycle (
	rst,
	clk,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem
);
	reg _sv2v_0;
	parameter signed [31:0] NUM_WORDS = 512;
	input wire rst;
	input wire clk;
	input wire [31:0] pc_to_imem;
	output reg [31:0] insn_from_imem;
	input wire [31:0] addr_to_dmem;
	output reg [31:0] load_data_from_dmem;
	input wire [31:0] store_data_to_dmem;
	input wire [3:0] store_we_to_dmem;
	reg [31:0] mem_array [0:NUM_WORDS - 1];
	initial $readmemh("mem_initial_contents.hex", mem_array);
	always @(*)
		if (_sv2v_0)
			;
	localparam signed [31:0] AddrMsb = $clog2(NUM_WORDS) + 1;
	localparam signed [31:0] AddrLsb = 2;
	always @(negedge clk)
		if (rst)
			;
		else
			insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
	always @(negedge clk)
		if (rst)
			;
		else begin
			if (store_we_to_dmem[0])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][7:0] <= store_data_to_dmem[7:0];
			if (store_we_to_dmem[1])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][15:8] <= store_data_to_dmem[15:8];
			if (store_we_to_dmem[2])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][23:16] <= store_data_to_dmem[23:16];
			if (store_we_to_dmem[3])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][31:24] <= store_data_to_dmem[31:24];
			load_data_from_dmem <= mem_array[{addr_to_dmem[AddrMsb:AddrLsb]}];
		end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
`default_nettype none
module SystemResourceCheck (
	external_clk_25MHz,
	btn,
	led
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
	wire clk_proc;
	wire clk_locked;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_proc(clk_proc),
		.locked(clk_locked)
	);
	wire [31:0] pc_to_imem;
	wire [31:0] insn_from_imem;
	wire [31:0] mem_data_addr;
	wire [31:0] mem_data_loaded_value;
	wire [31:0] mem_data_to_write;
	wire [3:0] mem_data_we;
	wire [31:0] trace_writeback_pc;
	wire [31:0] trace_writeback_insn;
	wire [31:0] trace_writeback_cycle_status;
	MemorySingleCycle #(.NUM_WORDS(128)) memory(
		.rst(!clk_locked),
		.clk(clk_proc),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.load_data_from_dmem(mem_data_loaded_value),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we)
	);
	DatapathPipelined datapath(
		.clk(clk_proc),
		.rst(!clk_locked),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we),
		.load_data_from_dmem(mem_data_loaded_value),
		.halt(led[0]),
		.trace_writeback_pc(trace_writeback_pc),
		.trace_writeback_insn(trace_writeback_insn),
		.trace_writeback_cycle_status(trace_writeback_cycle_status)
	);
endmodule
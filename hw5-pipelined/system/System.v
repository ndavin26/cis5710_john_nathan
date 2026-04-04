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
module DividerSignedPipelined (
	clk,
	rst,
	stall,
	i_x_state,
	i_src1,
	i_src2,
	o_m_state
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	input wire stall;
	input wire [324:0] i_x_state;
	input wire [31:0] i_src1;
	input wire [31:0] i_src2;
	output reg [189:0] o_m_state;
	genvar _gv_i_2;
	reg [386:0] divider_state [8:0];
	wire div_div_by_zero;
	wire div_overflow;
	reg div_a_neg;
	reg div_b_neg;
	reg [31:0] div_a_abs;
	reg [31:0] div_b_abs;
	reg [31:0] dividend_input;
	reg [31:0] divisor_input;
	function automatic [31:0] twos_comp32;
		input reg [31:0] x;
		twos_comp32 = ~x + 32'd1;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		divider_state[0][386-:32] = i_x_state[324-:32];
		divider_state[0][354-:32] = i_x_state[292-:32];
		divider_state[0][322-:32] = 32'd1;
		divider_state[0][290-:5] = i_x_state[223-:5];
		divider_state[0][285-:5] = i_x_state[218-:5];
		divider_state[0][280] = i_x_state[4];
		divider_state[0][198] = i_x_state[2];
		divider_state[0][272-:3] = i_x_state[21-:3];
		divider_state[0][269-:7] = i_x_state[18-:7];
		divider_state[0][279-:7] = i_x_state[11-:7];
		divider_state[0][262-:32] = i_x_state[181-:32];
		divider_state[0][197] = i_x_state[0];
		divider_state[0][68-:32] = 32'b00000000000000000000000000000000;
		divider_state[0][36-:32] = 32'b00000000000000000000000000000000;
		divider_state[0][4] = (i_x_state[18-:7] == 7'b0000001) && (i_x_state[19] == 1'b0);
		divider_state[0][3] = (i_x_state[18-:7] == 7'b0000001) && ((i_x_state[21-:3] == 3'b110) || (i_x_state[21-:3] == 3'b111));
		divider_state[0][2] = (divider_state[0][4] && (i_src1 == 32'h80000000)) && (i_src2 == 32'hffffffff);
		div_a_neg = i_src1[31];
		div_b_neg = i_src2[31];
		div_a_abs = (div_a_neg ? twos_comp32(i_src1) : i_src1);
		div_b_abs = (div_b_neg ? twos_comp32(i_src2) : i_src2);
		if (!divider_state[0][4]) begin
			dividend_input = i_src1;
			divisor_input = i_src2;
		end
		else begin
			dividend_input = div_a_abs;
			divisor_input = div_b_abs;
		end
		divider_state[0][1] = divider_state[0][4] && (div_a_neg ^ div_b_neg);
		divider_state[0][0] = divider_state[0][4] && div_a_neg;
		divider_state[0][68-:32] = dividend_input;
		divider_state[0][36-:32] = divisor_input;
	end
	wire [32:1] sv2v_tmp_SD_o_dividend;
	always @(*) divider_state[0][196-:32] = sv2v_tmp_SD_o_dividend;
	wire [32:1] sv2v_tmp_SD_o_remainder;
	always @(*) divider_state[0][100-:32] = sv2v_tmp_SD_o_remainder;
	wire [32:1] sv2v_tmp_SD_o_quotient;
	always @(*) divider_state[0][132-:32] = sv2v_tmp_SD_o_quotient;
	wire [32:1] sv2v_tmp_SD_o_divisor;
	always @(*) divider_state[0][164-:32] = sv2v_tmp_SD_o_divisor;
	StageDivider SD(
		.i_dividend(dividend_input),
		.i_divisor(divisor_input),
		.i_remainder(32'h00000000),
		.i_quotient(32'h00000000),
		.o_dividend(sv2v_tmp_SD_o_dividend),
		.o_remainder(sv2v_tmp_SD_o_remainder),
		.o_quotient(sv2v_tmp_SD_o_quotient),
		.o_divisor(sv2v_tmp_SD_o_divisor)
	);
	generate
		for (_gv_i_2 = 1; _gv_i_2 < 8; _gv_i_2 = _gv_i_2 + 1) begin : gen_divider_stages
			localparam i = _gv_i_2;
			wire [31:0] out_div;
			wire [31:0] out_rem;
			wire [31:0] out_quo;
			wire [31:0] out_dvr;
			StageDivider SD(
				.i_dividend(divider_state[i - 1][196-:32]),
				.i_divisor(divider_state[i - 1][164-:32]),
				.i_remainder(divider_state[i - 1][100-:32]),
				.i_quotient(divider_state[i - 1][132-:32]),
				.o_dividend(out_div),
				.o_remainder(out_rem),
				.o_quotient(out_quo),
				.o_divisor(out_dvr)
			);
			always @(posedge clk)
				if (rst) begin
					divider_state[i][386-:32] <= 32'h00000000;
					divider_state[i][354-:32] <= 32'h00000000;
					divider_state[i][322-:32] <= 32'd4;
					divider_state[i][285-:5] <= 5'h00;
					divider_state[i][290-:5] <= 5'h00;
					divider_state[i][280] <= 1'b0;
					divider_state[i][198] <= 1'b0;
					divider_state[i][272-:3] <= 3'b000;
					divider_state[i][269-:7] <= 7'b0000000;
					divider_state[i][279-:7] <= 7'b0000000;
					divider_state[i][262-:32] <= 32'h00000000;
					divider_state[i][197] <= 1'b0;
					divider_state[i][196-:32] <= 32'h00000000;
					divider_state[i][100-:32] <= 32'h00000000;
					divider_state[i][132-:32] <= 32'h00000000;
					divider_state[i][164-:32] <= 32'h00000000;
					divider_state[i][4] <= 1'b0;
					divider_state[i][1] <= 1'b0;
					divider_state[i][0] <= 1'b0;
					divider_state[i][3] <= 1'b0;
					divider_state[i][2] <= 1'b0;
					divider_state[i][68-:32] <= 32'h00000000;
					divider_state[i][36-:32] <= 32'h00000000;
				end
				else if (!stall) begin
					divider_state[i][386-:32] <= divider_state[i - 1][386-:32];
					divider_state[i][354-:32] <= divider_state[i - 1][354-:32];
					divider_state[i][322-:32] <= 32'd1;
					divider_state[i][290-:5] <= divider_state[i - 1][290-:5];
					divider_state[i][285-:5] <= divider_state[i - 1][285-:5];
					divider_state[i][280] <= divider_state[i - 1][280];
					divider_state[i][198] <= divider_state[i - 1][198];
					divider_state[i][272-:3] <= divider_state[i - 1][272-:3];
					divider_state[i][269-:7] <= divider_state[i - 1][269-:7];
					divider_state[i][279-:7] <= divider_state[i - 1][279-:7];
					divider_state[i][262-:32] <= divider_state[i - 1][262-:32];
					divider_state[i][197] <= divider_state[i - 1][197];
					divider_state[i][4] <= divider_state[i - 1][4];
					divider_state[i][1] <= divider_state[i - 1][1];
					divider_state[i][0] <= divider_state[i - 1][0];
					divider_state[i][3] <= divider_state[i - 1][3];
					divider_state[i][2] <= divider_state[i - 1][2];
					divider_state[i][68-:32] <= divider_state[i - 1][68-:32];
					divider_state[i][36-:32] <= divider_state[i - 1][36-:32];
					divider_state[i][196-:32] <= out_div;
					divider_state[i][100-:32] <= out_rem;
					divider_state[i][132-:32] <= out_quo;
					divider_state[i][164-:32] <= out_dvr;
				end
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		o_m_state[189-:32] = divider_state[7][386-:32];
		o_m_state[157-:32] = divider_state[7][354-:32];
		o_m_state[125-:32] = divider_state[7][322-:32];
		o_m_state[93-:5] = divider_state[7][290-:5];
		o_m_state[88-:5] = divider_state[7][285-:5];
		o_m_state[83] = divider_state[7][280];
		o_m_state[1] = divider_state[7][198];
		o_m_state[75-:3] = divider_state[7][272-:3];
		o_m_state[72-:7] = divider_state[7][269-:7];
		o_m_state[82-:7] = divider_state[7][279-:7];
		o_m_state[65-:32] = divider_state[7][262-:32];
		o_m_state[0] = divider_state[7][197];
		if (divider_state[7][36-:32] != 0) begin
			if (divider_state[7][2])
				o_m_state[33-:32] = (divider_state[7][3] ? 32'h00000000 : 32'h80000000);
			else if (divider_state[7][4])
				o_m_state[33-:32] = (divider_state[7][3] ? (divider_state[7][0] ? twos_comp32(divider_state[7][100-:32]) : divider_state[7][100-:32]) : (divider_state[7][1] ? twos_comp32(divider_state[7][132-:32]) : divider_state[7][132-:32]));
			else
				o_m_state[33-:32] = (divider_state[7][3] ? divider_state[7][100-:32] : divider_state[7][132-:32]);
		end
		else
			o_m_state[33-:32] = (divider_state[7][3] ? divider_state[7][68-:32] : 32'hffffffff);
	end
	initial _sv2v_0 = 0;
endmodule
module StageDivider (
	i_dividend,
	i_divisor,
	i_remainder,
	i_quotient,
	o_dividend,
	o_remainder,
	o_quotient,
	o_divisor
);
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	input wire [31:0] i_remainder;
	input wire [31:0] i_quotient;
	output wire [31:0] o_dividend;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	output wire [31:0] o_divisor;
	genvar _gv_i_3;
	wire [31:0] stage_dividend [4:0];
	wire [31:0] stage_remainder [4:0];
	wire [31:0] stage_quotient [4:0];
	assign stage_dividend[0] = i_dividend;
	assign stage_remainder[0] = i_remainder;
	assign stage_quotient[0] = i_quotient;
	assign o_dividend = stage_dividend[4];
	assign o_remainder = stage_remainder[4];
	assign o_quotient = stage_quotient[4];
	assign o_divisor = i_divisor;
	generate
		for (_gv_i_3 = 0; _gv_i_3 < 4; _gv_i_3 = _gv_i_3 + 1) begin : gen_dividers
			localparam i = _gv_i_3;
			DividerOneIter DOI(
				.i_dividend(stage_dividend[i]),
				.i_divisor(i_divisor),
				.i_remainder(stage_remainder[i]),
				.i_quotient(stage_quotient[i]),
				.o_dividend(stage_dividend[i + 1]),
				.o_remainder(stage_remainder[i + 1]),
				.o_quotient(stage_quotient[i + 1])
			);
		end
	endgenerate
endmodule
module DividerOneIter (
	i_dividend,
	i_divisor,
	i_remainder,
	i_quotient,
	o_dividend,
	o_remainder,
	o_quotient
);
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	input wire [31:0] i_remainder;
	input wire [31:0] i_quotient;
	output wire [31:0] o_dividend;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	wire [31:0] remainder_temp;
	assign remainder_temp = {i_remainder[30:0], i_dividend[31]};
	assign o_quotient = (remainder_temp >= i_divisor ? {i_quotient[30:0], 1'b1} : {i_quotient[30:0], 1'b0});
	assign o_remainder = (remainder_temp >= i_divisor ? remainder_temp - i_divisor : remainder_temp);
	assign o_dividend = {i_dividend[30:0], 1'b0};
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
	trace_completed_pc,
	trace_completed_insn,
	trace_completed_cycle_status
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
	output reg [31:0] trace_completed_pc;
	output reg [31:0] trace_completed_insn;
	output reg [31:0] trace_completed_cycle_status;
	localparam [6:0] OpcodeBranch = 7'b1100011;
	localparam [6:0] OpcodeRegImm = 7'b0010011;
	localparam [6:0] OpcodeRegReg = 7'b0110011;
	localparam [6:0] OpcodeEnviron = 7'b1110011;
	localparam [6:0] OpcodeAuipc = 7'b0010111;
	localparam [6:0] OpcodeLui = 7'b0110111;
	localparam [6:0] OpcodeJal = 7'b1101111;
	localparam [6:0] OpcodeJalr = 7'b1100111;
	localparam [6:0] OpcodeLoad = 7'b0000011;
	localparam [6:0] OpcodeStore = 7'b0100011;
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
	wire [11:0] d_imm_s = {decode_state[63:57], decode_state[43:39]};
	wire [20:0] d_imm_j = {decode_state[63], decode_state[51:44], decode_state[52], decode_state[62:53], 1'b0};
	wire [19:0] d_imm_u_raw = decode_state[63:44];
	wire [31:0] d_imm_i_sext = {{20 {d_imm_i[11]}}, d_imm_i};
	wire [31:0] d_imm_b_sext = {{19 {d_imm_b[12]}}, d_imm_b};
	wire [31:0] d_imm_s_sext = {{20 {d_imm_s[11]}}, d_imm_s};
	wire [31:0] d_imm_j_sext = {{11 {d_imm_j[20]}}, d_imm_j};
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
	wire d_is_jal = d_opcode == OpcodeJal;
	wire d_is_jalr = d_opcode == OpcodeJalr;
	wire d_is_ecall = (d_opcode == OpcodeEnviron) && (decode_state[63:39] == 25'd0);
	wire d_is_load = d_opcode == OpcodeLoad;
	wire d_is_store = d_opcode == OpcodeStore;
	wire d_is_div = ((d_opcode == OpcodeRegReg) && (d_funct7 == 7'b0000001)) && ((((d_funct3 == 3'b100) || (d_funct3 == 3'b110)) || (d_funct3 == 3'b111)) || (d_funct3 == 3'b101));
	wire d_reg_write = ((((((d_is_lui || d_is_auipc) || d_is_regimm) || d_is_regreg) || d_is_load) || d_is_div) || d_is_jal) || d_is_jalr;
	reg [324:0] x_state;
	wire d_load_stall = ((x_state[1] && (x_state[218-:5] != 5'd0)) && ((x_state[218-:5] == d_rs1) || ((x_state[218-:5] == d_rs2) && (d_is_regreg || d_is_branch)))) && !((d_is_store && (x_state[218-:5] == d_rs2)) && (x_state[218-:5] != d_rs1));
	wire [189:0] div_out_m_state;
	wire [255:0] x_disasm;
	Disasm #(.PREFIX("X")) disasm_2execute(
		.insn(x_state[292-:32]),
		.disasm(x_disasm)
	);
	reg [31:0] x_alu_result;
	reg x_branch_taken;
	reg [31:0] x_branch_target;
	reg [31:0] x_src1;
	reg [31:0] x_src2;
	wire [31:0] x_imm_j_sext = {{11 {x_state[292]}}, x_state[292], x_state[280:273], x_state[281], x_state[291:282], 1'b0};
	DividerSignedPipelined u_div(
		.clk(clk),
		.rst(rst),
		.stall(d_load_stall),
		.i_x_state(x_state),
		.i_src1(x_src1),
		.i_src2(x_src2),
		.o_m_state(div_out_m_state)
	);
	reg signed [63:0] mult_a_s;
	reg signed [63:0] mult_b_s;
	reg [63:0] mult_a_u;
	reg [63:0] mult_b_u;
	reg signed [63:0] mult_prod_ss;
	reg signed [63:0] mult_prod_su;
	reg [63:0] mult_prod_uu;
	always @(*) begin
		if (_sv2v_0)
			;
		mult_a_s = {{32 {x_src1[31]}}, x_src1};
		mult_b_s = {{32 {x_src2[31]}}, x_src2};
		mult_a_u = {{32 {1'b0}}, x_src1};
		mult_b_u = {{32 {1'b0}}, x_src2};
		mult_prod_ss = mult_a_s * mult_b_s;
		mult_prod_su = mult_a_s * mult_b_u;
		mult_prod_uu = mult_a_u * mult_b_u;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		x_alu_result = 32'd0;
		x_branch_taken = 1'b0;
		x_branch_target = x_state[324-:32] + x_state[117-:32];
		case (x_state[11-:7])
			OpcodeLui: x_alu_result = x_state[53-:32];
			OpcodeAuipc: x_alu_result = x_state[324-:32] + x_state[53-:32];
			OpcodeRegImm:
				case (x_state[21-:3])
					3'b000: x_alu_result = x_src1 + x_state[149-:32];
					3'b010: x_alu_result = ($signed(x_src1) < $signed(x_state[149-:32]) ? 32'd1 : 32'd0);
					3'b011: x_alu_result = (x_src1 < x_state[149-:32] ? 32'd1 : 32'd0);
					3'b100: x_alu_result = x_src1 ^ x_state[149-:32];
					3'b110: x_alu_result = x_src1 | x_state[149-:32];
					3'b111: x_alu_result = x_src1 & x_state[149-:32];
					3'b001: x_alu_result = x_src1 << x_state[285:281];
					3'b101:
						if (x_state[18-:7] == 7'b0100000)
							x_alu_result = $signed(x_src1) >>> x_state[285:281];
						else
							x_alu_result = x_src1 >> x_state[285:281];
					default: x_alu_result = 32'd0;
				endcase
			OpcodeRegReg:
				case (x_state[21-:3])
					3'b000:
						case (x_state[18-:7])
							7'b0000000: x_alu_result = x_src1 + x_src2;
							7'b0100000: x_alu_result = x_src1 - x_src2;
							7'b0000001: x_alu_result = mult_prod_uu[31:0];
							default: x_alu_result = 32'd0;
						endcase
					3'b001:
						case (x_state[18-:7])
							7'b0000000: x_alu_result = x_src1 << x_src2[4:0];
							7'b0000001: x_alu_result = mult_prod_ss[63:32];
							default: x_alu_result = 32'd0;
						endcase
					3'b010:
						case (x_state[18-:7])
							7'b0000000: x_alu_result = ($signed(x_src1) < $signed(x_src2) ? 32'd1 : 32'd0);
							7'b0000001: x_alu_result = mult_prod_su[63:32];
							default: x_alu_result = 32'd0;
						endcase
					3'b011:
						case (x_state[18-:7])
							7'b0000000: x_alu_result = (x_src1 < x_src2 ? 32'd1 : 32'd0);
							7'b0000001: x_alu_result = mult_prod_uu[63:32];
							default: x_alu_result = 32'd0;
						endcase
					3'b100: x_alu_result = x_src1 ^ x_src2;
					3'b101:
						case (x_state[18-:7])
							7'b0000000: x_alu_result = x_src1 >> x_src2[4:0];
							7'b0100000: x_alu_result = $signed(x_src1) >>> x_src2[4:0];
							default: x_alu_result = 32'd0;
						endcase
					3'b110: x_alu_result = x_src1 | x_src2;
					3'b111: x_alu_result = x_src1 & x_src2;
					default: x_alu_result = 32'd0;
				endcase
			OpcodeBranch:
				case (x_state[21-:3])
					3'b000: x_branch_taken = x_src1 == x_src2;
					3'b001: x_branch_taken = x_src1 != x_src2;
					3'b100: x_branch_taken = $signed(x_src1) < $signed(x_src2);
					3'b101: x_branch_taken = $signed(x_src1) >= $signed(x_src2);
					3'b110: x_branch_taken = x_src1 < x_src2;
					3'b111: x_branch_taken = x_src1 >= x_src2;
					default: x_branch_taken = 1'b0;
				endcase
			OpcodeJal: begin
				x_alu_result = x_state[324-:32] + 32'd4;
				x_branch_taken = 1'b1;
				x_branch_target = x_state[324-:32] + x_imm_j_sext;
			end
			OpcodeJalr: begin
				x_alu_result = x_state[324-:32] + 32'd4;
				x_branch_taken = 1'b1;
				x_branch_target = (x_src1 + x_state[149-:32]) & 32'hfffffffe;
			end
			OpcodeLoad: x_alu_result = x_src1 + x_state[149-:32];
			OpcodeStore: x_alu_result = x_src1 + x_state[85-:32];
			default: x_alu_result = 32'd0;
		endcase
		if (x_state[260-:32] != 32'd1)
			x_branch_taken = 1'b0;
	end
	reg [189:0] m_state;
	wire [255:0] m_disasm;
	Disasm #(.PREFIX("M")) disasm_3memory(
		.insn(m_state[157-:32]),
		.disasm(m_disasm)
	);
	reg [31:0] m_result_to_wb;
	reg [31:0] m_src2;
	always @(*) begin
		if (_sv2v_0)
			;
		addr_to_dmem = 32'd0;
		store_data_to_dmem = 32'd0;
		store_we_to_dmem = 4'b0000;
		m_result_to_wb = m_state[33-:32];
		case (m_state[82-:7])
			OpcodeLoad: begin
				addr_to_dmem = {m_state[33:4], 2'b00};
				case (m_state[75-:3])
					3'b000:
						case (m_state[3:2])
							2'b00: m_result_to_wb = {{24 {load_data_from_dmem[7]}}, load_data_from_dmem[7:0]};
							2'b01: m_result_to_wb = {{24 {load_data_from_dmem[15]}}, load_data_from_dmem[15:8]};
							2'b10: m_result_to_wb = {{24 {load_data_from_dmem[23]}}, load_data_from_dmem[23:16]};
							2'b11: m_result_to_wb = {{24 {load_data_from_dmem[31]}}, load_data_from_dmem[31:24]};
							default: m_result_to_wb = 32'd0;
						endcase
					3'b100:
						case (m_state[3:2])
							2'b00: m_result_to_wb = {24'd0, load_data_from_dmem[7:0]};
							2'b01: m_result_to_wb = {24'd0, load_data_from_dmem[15:8]};
							2'b10: m_result_to_wb = {24'd0, load_data_from_dmem[23:16]};
							2'b11: m_result_to_wb = {24'd0, load_data_from_dmem[31:24]};
							default: m_result_to_wb = 32'd0;
						endcase
					3'b001:
						case (m_state[3])
							1'b0: m_result_to_wb = {{16 {load_data_from_dmem[15]}}, load_data_from_dmem[15:0]};
							1'b1: m_result_to_wb = {{16 {load_data_from_dmem[31]}}, load_data_from_dmem[31:16]};
							default: m_result_to_wb = 32'd0;
						endcase
					3'b101:
						case (m_state[3])
							1'b0: m_result_to_wb = {16'd0, load_data_from_dmem[15:0]};
							1'b1: m_result_to_wb = {16'd0, load_data_from_dmem[31:16]};
							default: m_result_to_wb = 32'd0;
						endcase
					3'b010: m_result_to_wb = load_data_from_dmem;
					default: m_result_to_wb = 32'd0;
				endcase
			end
			OpcodeStore: begin
				addr_to_dmem = {m_state[33:4], 2'b00};
				case (m_state[75-:3])
					3'b000: begin
						store_data_to_dmem = {4 {m_src2[7:0]}};
						case (m_state[3:2])
							2'b00: store_we_to_dmem = 4'b0001;
							2'b01: store_we_to_dmem = 4'b0010;
							2'b10: store_we_to_dmem = 4'b0100;
							2'b11: store_we_to_dmem = 4'b1000;
							default: store_we_to_dmem = 4'b0000;
						endcase
					end
					3'b001: begin
						store_data_to_dmem = {2 {m_src2[15:0]}};
						case (m_state[3])
							1'b0: store_we_to_dmem = 4'b0011;
							1'b1: store_we_to_dmem = 4'b1100;
							default: store_data_to_dmem = 32'd0;
						endcase
					end
					3'b010: begin
						store_we_to_dmem = 4'b1111;
						store_data_to_dmem = m_src2;
					end
					default: begin
						store_we_to_dmem = 4'b0000;
						store_data_to_dmem = 32'd0;
					end
				endcase
			end
			default:
				;
		endcase
	end
	reg [189:0] w_state;
	wire [255:0] w_disasm;
	Disasm #(.PREFIX("W")) disasm_4writeback(
		.insn(w_state[157-:32]),
		.disasm(w_disasm)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		trace_completed_cycle_status = w_state[125-:32];
		trace_completed_pc = (w_state[125-:32] == 32'd1 ? w_state[189-:32] : 32'd0);
		trace_completed_insn = (w_state[125-:32] == 32'd1 ? w_state[157-:32] : 32'd0);
		halt = (w_state[125-:32] == 32'd1) && w_state[1];
		rf_rd = w_state[88-:5];
		rf_rd_data = w_state[33-:32];
		rf_we = w_state[83];
	end
	always @(*) begin
		if (_sv2v_0)
			;
		x_src1 = x_state[213-:32];
		if (((x_state[228-:5] != 5'd0) && m_state[83]) && (m_state[88-:5] == x_state[228-:5]))
			x_src1 = m_state[33-:32];
		else if (((x_state[228-:5] != 5'd0) && w_state[83]) && (w_state[88-:5] == x_state[228-:5]))
			x_src1 = w_state[33-:32];
		x_src2 = x_state[181-:32];
		if (((x_state[223-:5] != 5'd0) && m_state[83]) && (m_state[88-:5] == x_state[223-:5]))
			x_src2 = m_state[33-:32];
		else if (((x_state[223-:5] != 5'd0) && w_state[83]) && (w_state[88-:5] == x_state[223-:5]))
			x_src2 = w_state[33-:32];
	end
	always @(*) begin
		if (_sv2v_0)
			;
		m_src2 = m_state[65-:32];
		if (((m_state[93-:5] != 5'd0) && w_state[83]) && (w_state[88-:5] == m_state[93-:5]))
			m_src2 = w_state[33-:32];
	end
	wire divide = x_state[0];
	reg [6:0] div_stage_busy;
	wire divider_active = (div_stage_busy != 0) || divide;
	wire next_is_div = d_is_div;
	reg dependent_on_active_div;
	wire div_stall = (divider_active && !x_state[0]) || (dependent_on_active_div && x_state[0]);
	wire global_stall = div_stall || d_load_stall;
	wire [4:0] active_div_rd [7:0];
	wire mem_stall = (dependent_on_active_div && x_state[0]) || (divider_active && !div_stage_busy[6]);
	always @(*) begin
		if (_sv2v_0)
			;
		dependent_on_active_div = 1'b0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 1; i < 8; i = i + 1)
				if (((u_div.divider_state[i].rd == x_state[228-:5]) || (u_div.divider_state[i].rd == x_state[223-:5])) && u_div.divider_state[i].is_div)
					dependent_on_active_div = 1'b1;
		end
	end
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	function automatic [6:0] sv2v_cast_7;
		input reg [6:0] inp;
		sv2v_cast_7 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	always @(posedge clk)
		if (rst) begin
			f_pc_current <= 32'd0;
			f_cycle_status <= 32'd4;
			decode_state <= 96'h000000000000000000000004;
			x_state <= 325'h8000000000000000000000000000000000000000000000000000000000;
			m_state <= 190'h000000000000000000000001000000000000000000000000;
			w_state <= 190'h000000000000000000000001000000000000000000000000;
			div_stage_busy <= 7'b0000000;
		end
		else begin
			w_state <= {sv2v_cast_32(m_state[189-:32]), sv2v_cast_32(m_state[157-:32]), sv2v_cast_32(m_state[125-:32]), sv2v_cast_5(m_state[93-:5]), sv2v_cast_5(m_state[88-:5]), m_state[83], sv2v_cast_7(m_state[82-:7]), sv2v_cast_3(m_state[75-:3]), sv2v_cast_7(m_state[72-:7]), sv2v_cast_32(m_state[65-:32]), m_result_to_wb, m_state[1], m_state[0]};
			div_stage_busy <= {div_stage_busy[5:0], divide};
			if (div_out_m_state[0])
				m_state <= div_out_m_state;
			else if (!mem_stall)
				m_state <= {sv2v_cast_32(x_state[324-:32]), sv2v_cast_32(x_state[292-:32]), sv2v_cast_32(x_state[260-:32]), sv2v_cast_5(x_state[223-:5]), sv2v_cast_5(x_state[218-:5]), x_state[4], sv2v_cast_7(x_state[11-:7]), sv2v_cast_3(x_state[21-:3]), sv2v_cast_7(x_state[18-:7]), x_src2, x_alu_result, x_state[2], x_state[0]};
			else
				m_state <= 190'h000000000000000000000000800000000000000000000000;
			if (x_branch_taken) begin
				f_pc_current <= x_branch_target;
				f_cycle_status <= 32'd1;
				decode_state <= 96'h000000000000000000000008;
				x_state <= 325'h10000000000000000000000000000000000000000000000000000000000;
			end
			else if (d_load_stall) begin
				f_pc_current <= f_pc_current;
				f_cycle_status <= 32'd1;
				decode_state <= {sv2v_cast_32(decode_state[95-:32]), sv2v_cast_32(decode_state[63-:32]), 32'd1};
				x_state <= 325'h20000000000000000000000000000000000000000000000000000000000;
			end
			else if (div_stall) begin
				f_pc_current <= f_pc_current;
				f_cycle_status <= 32'd1;
				decode_state <= {sv2v_cast_32(decode_state[95-:32]), sv2v_cast_32(decode_state[63-:32]), 32'd1};
				x_state <= {sv2v_cast_32(x_state[324-:32]), sv2v_cast_32(x_state[292-:32]), 32'd1, sv2v_cast_5(x_state[228-:5]), sv2v_cast_5(x_state[223-:5]), sv2v_cast_5(x_state[218-:5]), sv2v_cast_32(x_state[213-:32]), sv2v_cast_32(x_state[181-:32]), sv2v_cast_32(x_state[149-:32]), sv2v_cast_32(x_state[117-:32]), sv2v_cast_32(x_state[85-:32]), sv2v_cast_32(x_state[53-:32]), sv2v_cast_3(x_state[21-:3]), sv2v_cast_7(x_state[18-:7]), sv2v_cast_7(x_state[11-:7]), x_state[4], x_state[3], x_state[2], x_state[1], x_state[0]};
			end
			else begin
				f_pc_current <= f_pc_current + 32'd4;
				f_cycle_status <= 32'd1;
				decode_state <= {f_pc_current, f_insn, 32'd1};
				x_state <= {sv2v_cast_32(decode_state[95-:32]), sv2v_cast_32(decode_state[63-:32]), sv2v_cast_32(decode_state[31-:32]), d_rs1, d_rs2, d_rd, rf_rs1_data, rf_rs2_data, d_imm_i_sext, d_imm_b_sext, d_imm_s_sext, d_imm_u, d_funct3, d_funct7, d_opcode, d_reg_write, d_is_branch, d_is_ecall, d_is_load, d_is_div};
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
		.trace_completed_pc(trace_writeback_pc),
		.trace_completed_insn(trace_writeback_insn),
		.trace_completed_cycle_status(trace_writeback_cycle_status)
	);
endmodule
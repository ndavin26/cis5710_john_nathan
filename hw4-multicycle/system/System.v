module MyClockGen (
	input_clk_25MHz,
	clk_proc,
	clk_mem,
	locked
);
	input input_clk_25MHz;
	output wire clk_proc;
	output wire clk_mem;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "10" *) (* FREQUENCY_PIN_CLKOS = "10" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
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
		.CLKOP_DIV(60),
		.CLKOP_CPHASE(30),
		.CLKOP_FPHASE(0),
		.CLKOS_ENABLE("ENABLED"),
		.CLKOS_DIV(60),
		.CLKOS_CPHASE(45),
		.CLKOS_FPHASE(0),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(2)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_proc),
		.CLKOS(clk_mem),
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
module gp1 (
	a,
	b,
	g,
	p
);
	input wire a;
	input wire b;
	output wire g;
	output wire p;
	assign g = a & b;
	assign p = a | b;
endmodule
module gp4 (
	gin,
	pin,
	cin,
	gout,
	pout,
	cout
);
	input wire [3:0] gin;
	input wire [3:0] pin;
	input wire cin;
	output wire gout;
	output wire pout;
	output wire [2:0] cout;
	assign pout = &pin;
	assign gout = ((gin[3] | (pin[3] & gin[2])) | ((pin[3] & pin[2]) & gin[1])) | (((pin[3] & pin[2]) & pin[1]) & gin[0]);
	assign cout[0] = gin[0] | (pin[0] & cin);
	assign cout[1] = (gin[1] | (pin[1] & gin[0])) | ((pin[1] & pin[0]) & cin);
	assign cout[2] = ((gin[2] | (pin[2] & gin[1])) | ((pin[2] & pin[1]) & gin[0])) | (((pin[2] & pin[1]) & pin[0]) & cin);
endmodule
module gp8 (
	gin,
	pin,
	cin,
	gout,
	pout,
	cout
);
	input wire [7:0] gin;
	input wire [7:0] pin;
	input wire cin;
	output wire gout;
	output wire pout;
	output wire [6:0] cout;
	wire gout_lo;
	wire pout_lo;
	wire [2:0] cout_lo;
	wire gout_hi;
	wire pout_hi;
	wire [2:0] cout_hi;
	wire c4;
	gp4 u_lo(
		.gin(gin[3:0]),
		.pin(pin[3:0]),
		.cin(cin),
		.gout(gout_lo),
		.pout(pout_lo),
		.cout(cout_lo)
	);
	assign c4 = gout_lo | (pout_lo & cin);
	gp4 u_hi(
		.gin(gin[7:4]),
		.pin(pin[7:4]),
		.cin(c4),
		.gout(gout_hi),
		.pout(pout_hi),
		.cout(cout_hi)
	);
	assign pout = pout_hi & pout_lo;
	assign gout = gout_hi | (pout_hi & gout_lo);
	assign cout[2:0] = cout_lo;
	assign cout[3] = c4;
	assign cout[6:4] = cout_hi;
endmodule
module CarryLookaheadAdder (
	a,
	b,
	cin,
	sum
);
	input wire [31:0] a;
	input wire [31:0] b;
	input wire cin;
	output wire [31:0] sum;
	wire [31:0] g;
	wire [31:0] p;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 32; _gv_i_1 = _gv_i_1 + 1) begin : GEN_GP1
			localparam i = _gv_i_1;
			gp1 u_gp1(
				.a(a[i]),
				.b(b[i]),
				.g(g[i]),
				.p(p[i])
			);
		end
	endgenerate
	wire [3:0] G8;
	wire [3:0] P8;
	wire [6:0] c8_0;
	wire [6:0] c8_1;
	wire [6:0] c8_2;
	wire [6:0] c8_3;
	wire [3:0] c8_in;
	wire [2:0] c8_grp_cout;
	wire gout32;
	wire pout32;
	assign c8_in[0] = cin;
	gp8 u_gp8_0(
		.gin(g[7:0]),
		.pin(p[7:0]),
		.cin(c8_in[0]),
		.gout(G8[0]),
		.pout(P8[0]),
		.cout(c8_0)
	);
	gp8 u_gp8_1(
		.gin(g[15:8]),
		.pin(p[15:8]),
		.cin(c8_in[1]),
		.gout(G8[1]),
		.pout(P8[1]),
		.cout(c8_1)
	);
	gp8 u_gp8_2(
		.gin(g[23:16]),
		.pin(p[23:16]),
		.cin(c8_in[2]),
		.gout(G8[2]),
		.pout(P8[2]),
		.cout(c8_2)
	);
	gp8 u_gp8_3(
		.gin(g[31:24]),
		.pin(p[31:24]),
		.cin(c8_in[3]),
		.gout(G8[3]),
		.pout(P8[3]),
		.cout(c8_3)
	);
	gp4 u_gp4_groups(
		.gin(G8),
		.pin(P8),
		.cin(cin),
		.gout(gout32),
		.pout(pout32),
		.cout(c8_grp_cout)
	);
	assign c8_in[1] = c8_grp_cout[0];
	assign c8_in[2] = c8_grp_cout[1];
	assign c8_in[3] = c8_grp_cout[2];
	wire [31:0] c;
	assign c[0] = cin;
	assign c[7:1] = c8_0;
	assign c[8] = c8_in[1];
	assign c[15:9] = c8_1;
	assign c[16] = c8_in[2];
	assign c[23:17] = c8_2;
	assign c[24] = c8_in[3];
	assign c[31:25] = c8_3;
	assign sum = (a ^ b) ^ c;
endmodule
module DividerUnsignedPipelined (
	clk,
	rst,
	stall,
	i_dividend,
	i_divisor,
	o_remainder,
	o_quotient
);
	input wire clk;
	input wire rst;
	input wire stall;
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	genvar _gv_i_2;
	reg [31:0] reg_dividend [6:0];
	reg [31:0] reg_remainder [6:0];
	reg [31:0] reg_quotient [6:0];
	reg [31:0] reg_divisor [6:0];
	generate
		for (_gv_i_2 = 0; _gv_i_2 < 8; _gv_i_2 = _gv_i_2 + 1) begin : gen_divider_stages
			localparam i = _gv_i_2;
			wire [31:0] out_div;
			wire [31:0] out_rem;
			wire [31:0] out_quo;
			wire [31:0] out_dvr;
			wire [31:0] stage_in_div = (i == 0 ? i_dividend : reg_dividend[i - 1]);
			wire [31:0] stage_in_rem = (i == 0 ? 32'h00000000 : reg_remainder[i - 1]);
			wire [31:0] stage_in_quo = (i == 0 ? 32'h00000000 : reg_quotient[i - 1]);
			wire [31:0] stage_in_dvr = (i == 0 ? i_divisor : reg_divisor[i - 1]);
			StageDivider SD(
				.i_dividend(stage_in_div),
				.i_divisor(stage_in_dvr),
				.i_remainder(stage_in_rem),
				.i_quotient(stage_in_quo),
				.o_dividend(out_div),
				.o_remainder(out_rem),
				.o_quotient(out_quo),
				.o_divisor(out_dvr)
			);
			if (i < 7) begin : gen_registers
				always @(posedge clk)
					if (rst) begin
						reg_dividend[i] <= 32'h00000000;
						reg_remainder[i] <= 32'h00000000;
						reg_quotient[i] <= 32'h00000000;
						reg_divisor[i] <= 32'h00000000;
					end
					else begin
						reg_dividend[i] <= out_div;
						reg_remainder[i] <= out_rem;
						reg_quotient[i] <= out_quo;
						reg_divisor[i] <= out_dvr;
					end
			end
			if (i == 7) begin : gen_output_logic
				assign o_quotient = out_quo;
				assign o_remainder = out_rem;
			end
		end
	endgenerate
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
	assign o_quotient = (remainder_temp < i_divisor ? {i_quotient[30:0], 1'b0} : {i_quotient[30:0], 1'b1});
	assign o_remainder = (remainder_temp < i_divisor ? remainder_temp : remainder_temp - i_divisor);
	assign o_dividend = {i_dividend[30:0], 1'b0};
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
	input wire [4:0] rd;
	input wire [31:0] rd_data;
	input wire [4:0] rs1;
	output wire [31:0] rs1_data;
	input wire [4:0] rs2;
	output wire [31:0] rs2_data;
	input wire clk;
	input wire we;
	input wire rst;
	localparam signed [31:0] NumRegs = 32;
	reg [31:0] regs [0:31];
	assign rs1_data = regs[rs1];
	assign rs2_data = regs[rs2];
	always @(posedge clk)
		if (rst) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < NumRegs; i = i + 1)
				regs[i] <= 0;
		end
		else if (we) begin
			if (rd != 5'd0)
				regs[rd] <= rd_data;
		end
endmodule
module DatapathMultiCycle (
	clk,
	rst,
	halt,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem,
	trace_completed_pc,
	trace_completed_insn,
	trace_completed_cycle_status
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	output reg halt;
	output wire [31:0] pc_to_imem;
	input wire [31:0] insn_from_imem;
	output reg [31:0] addr_to_dmem;
	input wire [31:0] load_data_from_dmem;
	output reg [31:0] store_data_to_dmem;
	output reg [3:0] store_we_to_dmem;
	output wire [31:0] trace_completed_pc;
	output wire [31:0] trace_completed_insn;
	output wire [31:0] trace_completed_cycle_status;
	wire [6:0] insn_funct7;
	wire [4:0] insn_rs2;
	wire [4:0] insn_rs1;
	wire [2:0] insn_funct3;
	wire [4:0] insn_rd;
	wire [6:0] insn_opcode;
	assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn_from_imem;
	wire [11:0] imm_i = insn_from_imem[31:20];
	wire [4:0] imm_shamt = insn_from_imem[24:20];
	wire [11:0] imm_s = {insn_from_imem[31:25], insn_from_imem[11:7]};
	wire [12:0] imm_b = {insn_from_imem[31], insn_from_imem[7], insn_from_imem[30:25], insn_from_imem[11:8], 1'b0};
	wire [19:0] imm_u = insn_from_imem[31:12];
	wire [20:0] imm_j = {insn_from_imem[31], insn_from_imem[19:12], insn_from_imem[20], insn_from_imem[30:21], 1'b0};
	wire [31:0] imm_i_sext = {{20 {imm_i[11]}}, imm_i};
	wire [31:0] imm_s_sext = {{20 {imm_s[11]}}, imm_s};
	wire [31:0] imm_b_sext = {{19 {imm_b[12]}}, imm_b};
	wire [31:0] imm_j_sext = {{11 {imm_j[20]}}, imm_j};
	localparam [6:0] OpLoad = 7'b0000011;
	localparam [6:0] OpStore = 7'b0100011;
	localparam [6:0] OpBranch = 7'b1100011;
	localparam [6:0] OpJalr = 7'b1100111;
	localparam [6:0] OpMiscMem = 7'b0001111;
	localparam [6:0] OpJal = 7'b1101111;
	localparam [6:0] OpRegImm = 7'b0010011;
	localparam [6:0] OpRegReg = 7'b0110011;
	localparam [6:0] OpEnviron = 7'b1110011;
	localparam [6:0] OpAuipc = 7'b0010111;
	localparam [6:0] OpLui = 7'b0110111;
	wire insn_lui = insn_opcode == OpLui;
	wire insn_auipc = insn_opcode == OpAuipc;
	wire insn_jal = insn_opcode == OpJal;
	wire insn_jalr = insn_opcode == OpJalr;
	wire insn_beq = (insn_opcode == OpBranch) && (insn_funct3 == 3'b000);
	wire insn_bne = (insn_opcode == OpBranch) && (insn_funct3 == 3'b001);
	wire insn_blt = (insn_opcode == OpBranch) && (insn_funct3 == 3'b100);
	wire insn_bge = (insn_opcode == OpBranch) && (insn_funct3 == 3'b101);
	wire insn_bltu = (insn_opcode == OpBranch) && (insn_funct3 == 3'b110);
	wire insn_bgeu = (insn_opcode == OpBranch) && (insn_funct3 == 3'b111);
	wire insn_lb = (insn_opcode == OpLoad) && (insn_funct3 == 3'b000);
	wire insn_lh = (insn_opcode == OpLoad) && (insn_funct3 == 3'b001);
	wire insn_lw = (insn_opcode == OpLoad) && (insn_funct3 == 3'b010);
	wire insn_lbu = (insn_opcode == OpLoad) && (insn_funct3 == 3'b100);
	wire insn_lhu = (insn_opcode == OpLoad) && (insn_funct3 == 3'b101);
	wire insn_sb = (insn_opcode == OpStore) && (insn_funct3 == 3'b000);
	wire insn_sh = (insn_opcode == OpStore) && (insn_funct3 == 3'b001);
	wire insn_sw = (insn_opcode == OpStore) && (insn_funct3 == 3'b010);
	wire insn_addi = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b000);
	wire insn_slti = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b010);
	wire insn_sltiu = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b011);
	wire insn_xori = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b100);
	wire insn_ori = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b110);
	wire insn_andi = (insn_opcode == OpRegImm) && (insn_funct3 == 3'b111);
	wire insn_slli = ((insn_opcode == OpRegImm) && (insn_funct3 == 3'b001)) && (insn_funct7 == 7'd0);
	wire insn_srli = ((insn_opcode == OpRegImm) && (insn_funct3 == 3'b101)) && (insn_funct7 == 7'd0);
	wire insn_srai = ((insn_opcode == OpRegImm) && (insn_funct3 == 3'b101)) && (insn_funct7 == 7'b0100000);
	wire insn_add = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b000)) && (insn_funct7 == 7'd0);
	wire insn_sub = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b000)) && (insn_funct7 == 7'b0100000);
	wire insn_sll = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b001)) && (insn_funct7 == 7'd0);
	wire insn_slt = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b010)) && (insn_funct7 == 7'd0);
	wire insn_sltu = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b011)) && (insn_funct7 == 7'd0);
	wire insn_xor = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b100)) && (insn_funct7 == 7'd0);
	wire insn_srl = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b101)) && (insn_funct7 == 7'd0);
	wire insn_sra = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b101)) && (insn_funct7 == 7'b0100000);
	wire insn_or = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b110)) && (insn_funct7 == 7'd0);
	wire insn_and = ((insn_opcode == OpRegReg) && (insn_funct3 == 3'b111)) && (insn_funct7 == 7'd0);
	wire insn_mul = ((insn_opcode == OpRegReg) && (insn_funct7 == 7'd1)) && (insn_funct3 == 3'b000);
	wire insn_mulh = ((insn_opcode == OpRegReg) && (insn_funct7 == 7'd1)) && (insn_funct3 == 3'b001);
	wire insn_mulhsu = ((insn_opcode == OpRegReg) && (insn_funct7 == 7'd1)) && (insn_funct3 == 3'b010);
	wire insn_mulhu = ((insn_opcode == OpRegReg) && (insn_funct7 == 7'd1)) && (insn_funct3 == 3'b011);
	wire insn_div = ((insn_opcode == OpRegReg) && (insn_funct7 == 7'd1)) && (insn_funct3 == 3'b100);
	wire insn_divu = ((insn_opcode == OpRegReg) && (insn_funct7 == 7'd1)) && (insn_funct3 == 3'b101);
	wire insn_rem = ((insn_opcode == OpRegReg) && (insn_funct7 == 7'd1)) && (insn_funct3 == 3'b110);
	wire insn_remu = ((insn_opcode == OpRegReg) && (insn_funct7 == 7'd1)) && (insn_funct3 == 3'b111);
	wire insn_ecall = (insn_opcode == OpEnviron) && (insn_from_imem[31:7] == 25'd0);
	reg [31:0] pcNext;
	reg [31:0] pcCurrent;
	always @(posedge clk)
		if (rst)
			pcCurrent <= 32'd0;
		else
			pcCurrent <= pcNext;
	assign pc_to_imem = pcCurrent;
	reg [3:0] div_stall_count;
	reg [31:0] cycles_current;
	reg [31:0] num_insns_current;
	always @(posedge clk)
		if (rst) begin
			cycles_current <= 0;
			num_insns_current <= 0;
		end
		else begin
			cycles_current <= cycles_current + 1;
			num_insns_current <= num_insns_current + 1;
		end
	wire [31:0] rs1_data;
	wire [31:0] rs2_data;
	reg [31:0] rd_data;
	wire [4:0] rs1 = insn_rs1;
	wire [4:0] rs2 = insn_rs2;
	reg [4:0] rd;
	reg we;
	RegFile rf(
		.rd(rd),
		.rd_data(rd_data),
		.rs1(rs1),
		.rs1_data(rs1_data),
		.rs2(rs2),
		.rs2_data(rs2_data),
		.clk(clk),
		.we(we),
		.rst(rst)
	);
	reg illegal_insn;
	reg [31:0] cla_in1;
	reg [31:0] cla_in2;
	wire [31:0] cla_sum;
	reg cla_cin;
	CarryLookaheadAdder ALU_adder(
		.a(cla_in1),
		.b(cla_in2),
		.cin(cla_cin),
		.sum(cla_sum)
	);
	function automatic [31:0] twos_comp32;
		input reg [31:0] x;
		twos_comp32 = ~x + 32'd1;
	endfunction
	reg [31:0] div_in_dividend;
	reg [31:0] div_in_divisor;
	wire [31:0] div_out_quotient;
	wire [31:0] div_out_remainder;
	wire stall_active;
	DividerUnsignedPipelined u_div(
		.i_dividend(div_in_dividend),
		.i_divisor(div_in_divisor),
		.o_quotient(div_out_quotient),
		.o_remainder(div_out_remainder),
		.clk(clk),
		.rst(rst),
		.stall(stall_active)
	);
	reg div_use;
	reg div_signed;
	reg div_is_rem;
	reg div_div_by_zero;
	reg div_overflow;
	reg div_a_neg;
	reg div_b_neg;
	reg [31:0] div_a_abs;
	reg [31:0] div_b_abs;
	wire [2:0] div_stage;
	always @(*) begin
		if (_sv2v_0)
			;
		cla_in1 = 32'b00000000000000000000000000000000;
		cla_in2 = 32'b00000000000000000000000000000000;
		cla_cin = 1'b0;
		if (insn_addi) begin
			cla_in1 = rs1_data;
			cla_in2 = imm_i_sext;
			cla_cin = 1'b0;
		end
		else if (insn_add) begin
			cla_in1 = rs1_data;
			cla_in2 = rs2_data;
			cla_cin = 1'b0;
		end
		else if (insn_sub) begin
			cla_in1 = rs1_data;
			cla_in2 = ~rs2_data;
			cla_cin = 1'b1;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		div_in_dividend = 32'b00000000000000000000000000000000;
		div_in_divisor = 32'b00000000000000000000000000000000;
		div_use = ((insn_divu || insn_remu) || insn_div) || insn_rem;
		div_signed = insn_div || insn_rem;
		div_is_rem = insn_remu || insn_rem;
		div_div_by_zero = div_use && (rs2_data == 32'b00000000000000000000000000000000);
		div_overflow = (div_signed && (rs1_data == 32'h80000000)) && (rs2_data == 32'hffffffff);
		div_a_neg = rs1_data[31];
		div_b_neg = rs2_data[31];
		div_a_abs = (div_a_neg ? twos_comp32(rs1_data) : rs1_data);
		div_b_abs = (div_b_neg ? twos_comp32(rs2_data) : rs2_data);
		if (insn_divu || insn_remu) begin
			div_in_dividend = rs1_data;
			div_in_divisor = rs2_data;
		end
		else if (insn_div || insn_rem) begin
			div_in_dividend = div_a_abs;
			div_in_divisor = div_b_abs;
		end
	end
	always @(posedge clk)
		if (rst)
			div_stall_count <= 4'd0;
		else if (div_use && (div_stall_count < 4'd8))
			div_stall_count <= div_stall_count + 4'd1;
		else if (div_stall_count == 4'd8)
			div_stall_count <= 4'd0;
	assign stall_active = div_use && (div_stall_count < 4'd8);
	always @(*) begin
		if (_sv2v_0)
			;
		illegal_insn = 1'b0;
		halt = 1'b0;
		we = 1'b0;
		rd = 5'd0;
		rd_data = 32'd0;
		if (stall_active)
			pcNext = pcCurrent;
		else
			pcNext = pcCurrent + 32'd4;
		addr_to_dmem = 32'd0;
		store_data_to_dmem = 32'd0;
		store_we_to_dmem = 4'b0000;
		case (insn_opcode)
			OpLui: begin
				rd = insn_rd;
				we = 1'b1;
				rd_data = {imm_u, 12'b000000000000};
			end
			OpAuipc: begin
				rd = insn_rd;
				we = 1'b1;
				rd_data = pcCurrent + {imm_u, 12'b000000000000};
			end
			OpJal: begin
				rd = insn_rd;
				we = 1'b1;
				rd_data = pcCurrent + 32'd4;
				pcNext = pcCurrent + imm_j_sext;
			end
			OpJalr: begin
				rd = insn_rd;
				we = 1'b1;
				rd_data = pcCurrent + 32'd4;
				pcNext = (rs1_data + imm_i_sext) & 32'hfffffffc;
			end
			OpLoad: begin : sv2v_autoblock_1
				reg [31:0] eff_addr;
				reg [1:0] off;
				reg [31:0] w;
				reg [7:0] b;
				reg [15:0] h;
				rd = insn_rd;
				we = 1'b1;
				eff_addr = rs1_data + imm_i_sext;
				off = eff_addr[1:0];
				addr_to_dmem = eff_addr & 32'hfffffffc;
				w = load_data_from_dmem;
				if (insn_lw) begin
					if (off != 2'b00) begin
						illegal_insn = 1'b1;
						we = 1'b0;
					end
					else
						rd_data = w;
				end
				else if (insn_lb || insn_lbu) begin
					case (off)
						2'd0: b = w[7:0];
						2'd1: b = w[15:8];
						2'd2: b = w[23:16];
						default: b = w[31:24];
					endcase
					rd_data = (insn_lb ? {{24 {b[7]}}, b} : {24'b000000000000000000000000, b});
				end
				else if (insn_lh || insn_lhu) begin
					if (off[0] != 1'b0) begin
						illegal_insn = 1'b1;
						we = 1'b0;
					end
					else begin
						h = (off[1] ? w[31:16] : w[15:0]);
						rd_data = (insn_lh ? {{16 {h[15]}}, h} : {16'b0000000000000000, h});
					end
				end
				else begin
					illegal_insn = 1'b1;
					we = 1'b0;
				end
			end
			OpStore: begin : sv2v_autoblock_2
				reg [31:0] eff_addr;
				reg [1:0] off;
				eff_addr = rs1_data + imm_s_sext;
				off = eff_addr[1:0];
				addr_to_dmem = eff_addr & 32'hfffffffc;
				if (insn_sw) begin
					if (off != 2'b00)
						illegal_insn = 1'b1;
					else begin
						store_we_to_dmem = 4'b1111;
						store_data_to_dmem = rs2_data;
					end
				end
				else if (insn_sb) begin
					store_we_to_dmem = 4'b0001 << off;
					store_data_to_dmem = {24'b000000000000000000000000, rs2_data[7:0]} << (off * 8);
				end
				else if (insn_sh) begin
					if (off[0] != 1'b0)
						illegal_insn = 1'b1;
					else if (off[1] == 1'b0) begin
						store_we_to_dmem = 4'b0011;
						store_data_to_dmem = {16'b0000000000000000, rs2_data[15:0]};
					end
					else begin
						store_we_to_dmem = 4'b1100;
						store_data_to_dmem = {rs2_data[15:0], 16'b0000000000000000};
					end
				end
				else
					illegal_insn = 1'b1;
			end
			OpMiscMem:
				;
			OpRegImm: begin
				rd = insn_rd;
				we = 1'b1;
				if (insn_addi)
					rd_data = cla_sum;
				else if (insn_slti)
					rd_data = ($signed(rs1_data) < $signed(imm_i_sext) ? 32'd1 : 32'd0);
				else if (insn_sltiu)
					rd_data = (rs1_data < imm_i_sext ? 32'd1 : 32'd0);
				else if (insn_xori)
					rd_data = rs1_data ^ imm_i_sext;
				else if (insn_ori)
					rd_data = rs1_data | imm_i_sext;
				else if (insn_andi)
					rd_data = rs1_data & imm_i_sext;
				else if (insn_slli)
					rd_data = rs1_data << imm_shamt;
				else if (insn_srli)
					rd_data = rs1_data >> imm_shamt;
				else if (insn_srai)
					rd_data = $signed(rs1_data) >>> imm_shamt;
				else begin
					illegal_insn = 1'b1;
					we = 1'b0;
				end
			end
			OpRegReg: begin
				rd = insn_rd;
				if (stall_active)
					we = 1'b0;
				else
					we = 1'b1;
				if (insn_add || insn_sub)
					rd_data = cla_sum;
				else if (insn_sll)
					rd_data = rs1_data << rs2_data[4:0];
				else if (insn_slt)
					rd_data = ($signed(rs1_data) < $signed(rs2_data) ? 32'd1 : 32'd0);
				else if (insn_sltu)
					rd_data = (rs1_data < rs2_data ? 32'd1 : 32'd0);
				else if (insn_xor)
					rd_data = rs1_data ^ rs2_data;
				else if (insn_srl)
					rd_data = rs1_data >> rs2_data[4:0];
				else if (insn_sra)
					rd_data = $signed(rs1_data) >>> rs2_data[4:0];
				else if (insn_or)
					rd_data = rs1_data | rs2_data;
				else if (insn_and)
					rd_data = rs1_data & rs2_data;
				else if (((insn_mul || insn_mulh) || insn_mulhsu) || insn_mulhu) begin : sv2v_autoblock_3
					reg signed [63:0] a_s;
					reg signed [63:0] b_s;
					reg [63:0] a_u;
					reg [63:0] b_u;
					reg signed [63:0] prod_ss;
					reg signed [63:0] prod_su;
					reg [63:0] prod_uu;
					a_s = {{32 {rs1_data[31]}}, rs1_data};
					b_s = {{32 {rs2_data[31]}}, rs2_data};
					a_u = {32'b00000000000000000000000000000000, rs1_data};
					b_u = {32'b00000000000000000000000000000000, rs2_data};
					prod_ss = a_s * b_s;
					prod_su = a_s * $signed(b_u);
					prod_uu = a_u * b_u;
					if (insn_mul)
						rd_data = prod_ss[31:0];
					else if (insn_mulh)
						rd_data = prod_ss[63:32];
					else if (insn_mulhsu)
						rd_data = prod_su[63:32];
					else
						rd_data = prod_uu[63:32];
				end
				else if (((insn_div || insn_divu) || insn_rem) || insn_remu) begin
					if (div_div_by_zero) begin
						if (insn_div || insn_divu)
							rd_data = 32'hffffffff;
						else
							rd_data = rs1_data;
					end
					else if (div_overflow) begin
						if (insn_div)
							rd_data = 32'h80000000;
						else if (insn_rem)
							rd_data = 32'd0;
						else
							rd_data = (div_is_rem ? 32'd0 : 32'h80000000);
					end
					else if (insn_divu || insn_remu)
						rd_data = (insn_divu ? div_out_quotient : div_out_remainder);
					else begin : sv2v_autoblock_4
						reg [31:0] q_abs;
						reg [31:0] r_abs;
						reg [31:0] q_signed;
						reg [31:0] r_signed;
						q_abs = div_out_quotient;
						r_abs = div_out_remainder;
						q_signed = (div_a_neg ^ div_b_neg ? twos_comp32(q_abs) : q_abs);
						r_signed = (div_a_neg ? twos_comp32(r_abs) : r_abs);
						rd_data = (insn_div ? q_signed : r_signed);
					end
				end
				else begin
					illegal_insn = 1'b1;
					we = 1'b0;
				end
			end
			OpBranch: begin
				we = 1'b0;
				if (insn_beq) begin
					if (rs1_data == rs2_data)
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_bne) begin
					if (rs1_data != rs2_data)
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_blt) begin
					if ($signed(rs1_data) < $signed(rs2_data))
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_bge) begin
					if ($signed(rs1_data) >= $signed(rs2_data))
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_bltu) begin
					if (rs1_data < rs2_data)
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_bgeu) begin
					if (rs1_data >= rs2_data)
						pcNext = pcCurrent + imm_b_sext;
				end
				else
					illegal_insn = 1'b1;
			end
			OpEnviron:
				if (insn_ecall)
					halt = 1'b1;
				else
					illegal_insn = 1'b1;
			default: illegal_insn = 1'b1;
		endcase
	end
	assign trace_completed_pc = pcCurrent;
	assign trace_completed_insn = insn_from_imem;
	assign trace_completed_cycle_status = (stall_active ? 32'd2 : 32'd1);
	initial _sv2v_0 = 0;
endmodule
module MemorySingleCycle (
	rst,
	clock_mem,
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
	input wire clock_mem;
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
	always @(posedge clock_mem)
		if (rst)
			;
		else
			insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
	always @(negedge clock_mem)
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
	wire clk_mem;
	wire clk_locked;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_proc(clk_proc),
		.clk_mem(clk_mem),
		.locked(clk_locked)
	);
	wire [31:0] pc_to_imem;
	wire [31:0] insn_from_imem;
	wire [31:0] mem_data_addr;
	wire [31:0] mem_data_loaded_value;
	wire [31:0] mem_data_to_write;
	wire [3:0] mem_data_we;
	MemorySingleCycle #(.NUM_WORDS(128)) memory(
		.rst(!clk_locked),
		.clock_mem(clk_mem),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.load_data_from_dmem(mem_data_loaded_value),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we)
	);
	DatapathMultiCycle datapath(
		.clk(clk_proc),
		.rst(!clk_locked),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we),
		.load_data_from_dmem(mem_data_loaded_value),
		.halt(led[0])
	);
endmodule
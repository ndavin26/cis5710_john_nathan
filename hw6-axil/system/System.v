`default_nettype none
module MyClockGen (
	input_clk_25MHz,
	clk_125MHz,
	clk_25MHz,
	clk_proc,
	locked
);
	input input_clk_25MHz;
	output wire clk_125MHz;
	output wire clk_25MHz;
	output wire clk_proc;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "125" *) (* FREQUENCY_PIN_CLKOS = "25" *) (* FREQUENCY_PIN_CLKOS2 = "20.1613" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
		.PLLRST_ENA("DISABLED"),
		.INTFB_WAKE("DISABLED"),
		.STDBY_ENABLE("DISABLED"),
		.DPHASE_SOURCE("DISABLED"),
		.OUTDIVIDER_MUXA("DIVA"),
		.OUTDIVIDER_MUXB("DIVB"),
		.OUTDIVIDER_MUXC("DIVC"),
		.OUTDIVIDER_MUXD("DIVD"),
		.CLKI_DIV(1),
		.CLKOP_ENABLE("ENABLED"),
		.CLKOP_DIV(5),
		.CLKOP_CPHASE(2),
		.CLKOP_FPHASE(0),
		.CLKOS_ENABLE("ENABLED"),
		.CLKOS_DIV(25),
		.CLKOS_CPHASE(2),
		.CLKOS_FPHASE(0),
		.CLKOS2_ENABLE("ENABLED"),
		.CLKOS2_DIV(31),
		.CLKOS2_CPHASE(2),
		.CLKOS2_FPHASE(0),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(5)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_125MHz),
		.CLKOS(clk_25MHz),
		.CLKOS2(clk_proc),
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
module DividerUnsignedPipelined (
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
	function automatic [31:0] twos_comp32d;
		input reg [31:0] x;
		twos_comp32d = ~x + 32'd1;
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
		div_a_abs = (div_a_neg ? twos_comp32d(i_src1) : i_src1);
		div_b_abs = (div_b_neg ? twos_comp32d(i_src2) : i_src2);
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
				o_m_state[33-:32] = (divider_state[7][3] ? (divider_state[7][0] ? twos_comp32d(divider_state[7][100-:32]) : divider_state[7][100-:32]) : (divider_state[7][1] ? twos_comp32d(divider_state[7][132-:32]) : divider_state[7][132-:32]));
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
`default_nettype none
`default_nettype none
module skidbuffer (
	i_clk,
	i_reset,
	i_valid,
	o_ready,
	i_data,
	o_valid,
	i_ready,
	o_data
);
	parameter [0:0] OPT_LOWPOWER = 0;
	parameter [0:0] OPT_OUTREG = 1;
	parameter [0:0] OPT_PASSTHROUGH = 0;
	parameter DW = 8;
	parameter [0:0] OPT_INITIAL = 1'b1;
	input wire i_clk;
	input wire i_reset;
	input wire i_valid;
	output wire o_ready;
	input wire [DW - 1:0] i_data;
	output wire o_valid;
	input wire i_ready;
	output reg [DW - 1:0] o_data;
	wire [DW - 1:0] w_data;
	generate
		if (OPT_PASSTHROUGH) begin : PASSTHROUGH
			assign {o_valid, o_ready} = {i_valid, i_ready};
			always @(*)
				if (!i_valid && OPT_LOWPOWER)
					o_data = 0;
				else
					o_data = i_data;
			assign w_data = 0;
			wire unused_passthrough;
			assign unused_passthrough = &{1'b0, i_clk, i_reset};
		end
		else begin : LOGIC
			reg r_valid;
			reg [DW - 1:0] r_data;
			initial if (OPT_INITIAL)
				r_valid = 0;
			always @(posedge i_clk)
				if (i_reset)
					r_valid <= 0;
				else if ((i_valid && o_ready) && (o_valid && !i_ready))
					r_valid <= 1;
				else if (i_ready)
					r_valid <= 0;
			initial if (OPT_INITIAL)
				r_data = 0;
			always @(posedge i_clk)
				if (OPT_LOWPOWER && i_reset)
					r_data <= 0;
				else if (OPT_LOWPOWER && (!o_valid || i_ready))
					r_data <= 0;
				else if (((!OPT_LOWPOWER || !OPT_OUTREG) || i_valid) && o_ready)
					r_data <= i_data;
			assign w_data = r_data;
			assign o_ready = !r_valid;
			if (!OPT_OUTREG) begin : NET_OUTPUT
				assign o_valid = !i_reset && (i_valid || r_valid);
				always @(*)
					if (r_valid)
						o_data = r_data;
					else if (!OPT_LOWPOWER || i_valid)
						o_data = i_data;
					else
						o_data = 0;
			end
			else begin : REG_OUTPUT
				reg ro_valid;
				initial if (OPT_INITIAL)
					ro_valid = 0;
				always @(posedge i_clk)
					if (i_reset)
						ro_valid <= 0;
					else if (!o_valid || i_ready)
						ro_valid <= i_valid || r_valid;
				assign o_valid = ro_valid;
				initial if (OPT_INITIAL)
					o_data = 0;
				always @(posedge i_clk)
					if (OPT_LOWPOWER && i_reset)
						o_data <= 0;
					else if (!o_valid || i_ready) begin
						if (r_valid)
							o_data <= r_data;
						else if (!OPT_LOWPOWER || i_valid)
							o_data <= i_data;
						else
							o_data <= 0;
					end
			end
		end
	endgenerate
	wire unused;
	assign unused = &{1'b0, w_data};
endmodule
module Disasm (
	insn,
	disasm
);
	parameter PREFIX = "D";
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
`default_nettype none
module SystemResourceCheck (
	external_clk_25MHz,
	btn,
	led
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
	wire clk;
	wire clk_locked;
	wire ignore0;
	wire ignore1;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_125MHz(ignore0),
		.clk_25MHz(ignore1),
		.clk_proc(clk),
		.locked(clk_locked)
	);
	wire rst = !clk_locked;
	generate
		if (1) begin : axil_mem_ro
			localparam signed [31:0] ADDR_WIDTH = 32;
			localparam signed [31:0] DATA_WIDTH = 32;
			wire ARREADY;
			reg ARVALID;
			reg [31:0] ARADDR;
			reg [2:0] ARPROT;
			reg RREADY;
			wire RVALID;
			wire [31:0] RDATA;
			wire [1:0] RRESP;
			wire AWREADY;
			reg AWVALID;
			reg [31:0] AWADDR;
			reg [2:0] AWPROT;
			wire WREADY;
			reg WVALID;
			reg [31:0] WDATA;
			reg [3:0] WSTRB;
			reg BREADY;
			wire BVALID;
			wire [1:0] BRESP;
		end
		if (1) begin : axil_mem_rw
			localparam signed [31:0] ADDR_WIDTH = 32;
			localparam signed [31:0] DATA_WIDTH = 32;
			wire ARREADY;
			reg ARVALID;
			reg [31:0] ARADDR;
			reg [2:0] ARPROT;
			reg RREADY;
			wire RVALID;
			wire [31:0] RDATA;
			wire [1:0] RRESP;
			wire AWREADY;
			reg AWVALID;
			reg [31:0] AWADDR;
			reg [2:0] AWPROT;
			wire WREADY;
			reg WVALID;
			reg [31:0] WDATA;
			reg [3:0] WSTRB;
			reg BREADY;
			wire BVALID;
			wire [1:0] BRESP;
		end
	endgenerate
	localparam _param_F80E1_OPT_SKIDBUFFER = 1;
	localparam _param_F80E1_OPT_LOWPOWER = 0;
	localparam _param_F80E1_NUM_WORDS = 128;
	generate
		if (1) begin : memory
			localparam [0:0] OPT_SKIDBUFFER = _param_F80E1_OPT_SKIDBUFFER;
			localparam [0:0] OPT_LOWPOWER = _param_F80E1_OPT_LOWPOWER;
			localparam NUM_WORDS = _param_F80E1_NUM_WORDS;
			wire ACLK;
			wire ARESETn;
			localparam ADDRLSB = 2;
			wire i_reset = !ARESETn;
			wire axil_write_ready;
			wire [29:0] awskd_addr;
			wire [31:0] wskd_data;
			wire [3:0] wskd_strb;
			reg axil_bvalid;
			wire axil_read_ready;
			wire [29:0] arskd_addr;
			reg [31:0] axil_read_data;
			reg axil_read_valid;
			wire t_axil_read_ready;
			wire [29:0] t_arskd_addr;
			reg [31:0] t_axil_read_data;
			reg t_axil_read_valid;
			localparam signed [31:0] AddrLsb = 2;
			localparam signed [31:0] AddrMsb = 8;
			reg [31:0] mem_array [0:127];
			if (OPT_SKIDBUFFER) begin : SKIDBUFFER_WRITE
				wire awskd_valid;
				wire wskd_valid;
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(30)
				) axilawskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_rw.AWVALID),
					.o_ready(SystemResourceCheck.axil_mem_rw.AWREADY),
					.i_data(SystemResourceCheck.axil_mem_rw.AWADDR[31:ADDRLSB]),
					.o_valid(awskd_valid),
					.i_ready(axil_write_ready),
					.o_data(awskd_addr)
				);
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(36)
				) axilwskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_rw.WVALID),
					.o_ready(SystemResourceCheck.axil_mem_rw.WREADY),
					.i_data({SystemResourceCheck.axil_mem_rw.WDATA, SystemResourceCheck.axil_mem_rw.WSTRB}),
					.o_valid(wskd_valid),
					.i_ready(axil_write_ready),
					.o_data({wskd_data, wskd_strb})
				);
				assign axil_write_ready = (awskd_valid && wskd_valid) && (!SystemResourceCheck.axil_mem_rw.BVALID || SystemResourceCheck.axil_mem_rw.BREADY);
			end
			else begin : SIMPLE_WRITES
				reg axil_awready;
				initial axil_awready = 1'b0;
				always @(posedge ACLK)
					if (!ARESETn)
						axil_awready <= 1'b0;
					else
						axil_awready <= (!axil_awready && (SystemResourceCheck.axil_mem_rw.AWVALID && SystemResourceCheck.axil_mem_rw.WVALID)) && (!SystemResourceCheck.axil_mem_rw.BVALID || SystemResourceCheck.axil_mem_rw.BREADY);
				assign SystemResourceCheck.axil_mem_rw.AWREADY = axil_awready;
				assign SystemResourceCheck.axil_mem_rw.WREADY = axil_awready;
				assign awskd_addr = SystemResourceCheck.axil_mem_rw.AWADDR[31:ADDRLSB];
				assign wskd_data = SystemResourceCheck.axil_mem_rw.WDATA;
				assign wskd_strb = SystemResourceCheck.axil_mem_rw.WSTRB;
				assign axil_write_ready = axil_awready;
			end
			initial axil_bvalid = 0;
			always @(posedge ACLK)
				if (i_reset)
					axil_bvalid <= 0;
				else if (axil_write_ready)
					axil_bvalid <= 1;
				else if (SystemResourceCheck.axil_mem_rw.BREADY)
					axil_bvalid <= 0;
			assign SystemResourceCheck.axil_mem_rw.BVALID = axil_bvalid;
			assign SystemResourceCheck.axil_mem_rw.BRESP = 2'b00;
			if (OPT_SKIDBUFFER) begin : SKIDBUFFER_READ
				wire arskd_valid;
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(30)
				) axilarskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_rw.ARVALID),
					.o_ready(SystemResourceCheck.axil_mem_rw.ARREADY),
					.i_data(SystemResourceCheck.axil_mem_rw.ARADDR[31:ADDRLSB]),
					.o_valid(arskd_valid),
					.i_ready(axil_read_ready),
					.o_data(arskd_addr)
				);
				assign axil_read_ready = arskd_valid && (!axil_read_valid || SystemResourceCheck.axil_mem_rw.RREADY);
			end
			else begin : SIMPLE_READS
				reg axil_arready;
				always @(*) axil_arready = !SystemResourceCheck.axil_mem_rw.RVALID;
				assign arskd_addr = SystemResourceCheck.axil_mem_rw.ARADDR[31:ADDRLSB];
				assign SystemResourceCheck.axil_mem_rw.ARREADY = axil_arready;
				assign axil_read_ready = SystemResourceCheck.axil_mem_rw.ARVALID && SystemResourceCheck.axil_mem_rw.ARREADY;
			end
			initial axil_read_valid = 1'b0;
			always @(posedge ACLK)
				if (i_reset)
					axil_read_valid <= 1'b0;
				else if (axil_read_ready)
					axil_read_valid <= 1'b1;
				else if (SystemResourceCheck.axil_mem_rw.RREADY)
					axil_read_valid <= 1'b0;
			assign SystemResourceCheck.axil_mem_rw.RVALID = axil_read_valid;
			assign SystemResourceCheck.axil_mem_rw.RDATA = axil_read_data;
			assign SystemResourceCheck.axil_mem_rw.RRESP = 2'b00;
			if (OPT_SKIDBUFFER) begin : T_SKIDBUFFER_READ
				wire t_arskd_valid;
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(30)
				) axilarskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_ro.ARVALID),
					.o_ready(SystemResourceCheck.axil_mem_ro.ARREADY),
					.i_data(SystemResourceCheck.axil_mem_ro.ARADDR[31:ADDRLSB]),
					.o_valid(t_arskd_valid),
					.i_ready(t_axil_read_ready),
					.o_data(t_arskd_addr)
				);
				assign t_axil_read_ready = t_arskd_valid && (!t_axil_read_valid || SystemResourceCheck.axil_mem_ro.RREADY);
			end
			else begin : T_SIMPLE_READS
				reg t_axil_arready;
				always @(*) t_axil_arready = !SystemResourceCheck.axil_mem_ro.RVALID;
				assign t_arskd_addr = SystemResourceCheck.axil_mem_ro.ARADDR[31:ADDRLSB];
				assign SystemResourceCheck.axil_mem_ro.ARREADY = t_axil_arready;
				assign t_axil_read_ready = SystemResourceCheck.axil_mem_ro.ARVALID && SystemResourceCheck.axil_mem_ro.ARREADY;
			end
			initial t_axil_read_valid = 1'b0;
			always @(posedge ACLK)
				if (i_reset)
					t_axil_read_valid <= 1'b0;
				else if (t_axil_read_ready)
					t_axil_read_valid <= 1'b1;
				else if (SystemResourceCheck.axil_mem_ro.RREADY)
					t_axil_read_valid <= 1'b0;
			assign SystemResourceCheck.axil_mem_ro.RVALID = t_axil_read_valid;
			assign SystemResourceCheck.axil_mem_ro.RDATA = t_axil_read_data;
			assign SystemResourceCheck.axil_mem_ro.RRESP = 2'b00;
			always @(posedge ACLK)
				if (i_reset)
					;
				else if (axil_write_ready) begin
					if (wskd_strb[0])
						mem_array[awskd_addr[6:0]][7:0] <= wskd_data[7:0];
					if (wskd_strb[1])
						mem_array[awskd_addr[6:0]][15:8] <= wskd_data[15:8];
					if (wskd_strb[2])
						mem_array[awskd_addr[6:0]][23:16] <= wskd_data[23:16];
					if (wskd_strb[3])
						mem_array[awskd_addr[6:0]][31:24] <= wskd_data[31:24];
				end
			initial begin
				axil_read_data = 0;
				t_axil_read_data = 0;
			end
			always @(posedge ACLK) begin
				if (!SystemResourceCheck.axil_mem_rw.RVALID || SystemResourceCheck.axil_mem_rw.RREADY)
					axil_read_data <= mem_array[arskd_addr[6:0]];
				if (!SystemResourceCheck.axil_mem_ro.RVALID || SystemResourceCheck.axil_mem_ro.RREADY)
					t_axil_read_data <= mem_array[t_arskd_addr[6:0]];
			end
		end
	endgenerate
	assign memory.ACLK = clk;
	assign memory.ARESETn = ~rst;
	wire [31:0] trace_completed_pc;
	wire [31:0] trace_completed_insn;
	wire [31:0] trace_completed_cycle_status;
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
	generate
		if (1) begin : datapath
			reg _sv2v_0;
			wire clk;
			wire rst;
			reg halt;
			reg [31:0] trace_completed_pc;
			reg [31:0] trace_completed_insn;
			reg [31:0] trace_completed_cycle_status;
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
			function automatic [95:0] make_decode_bubble;
				input reg [31:0] st;
				reg [95:0] tmp;
				begin
					tmp = 1'sb0;
					tmp[31-:32] = st;
					make_decode_bubble = tmp;
				end
			endfunction
			function automatic [324:0] make_execute_bubble;
				input reg [31:0] st;
				reg [324:0] tmp;
				begin
					tmp = 1'sb0;
					tmp[260-:32] = st;
					make_execute_bubble = tmp;
				end
			endfunction
			function automatic [189:0] make_memory_bubble;
				input reg [31:0] st;
				reg [189:0] tmp;
				begin
					tmp = 1'sb0;
					tmp[125-:32] = st;
					make_memory_bubble = tmp;
				end
			endfunction
			reg [31:0] cycles_current;
			always @(posedge clk)
				if (rst)
					cycles_current <= 32'd0;
				else
					cycles_current <= cycles_current + 32'd1;
			reg [31:0] f_pc_current;
			reg [63:0] g_state;
			reg g_valid;
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
			wire [19:0] d_imm_u_raw = decode_state[63:44];
			wire [31:0] d_imm_i_sext = {{20 {d_imm_i[11]}}, d_imm_i};
			wire [31:0] d_imm_b_sext = {{19 {d_imm_b[12]}}, d_imm_b};
			wire [31:0] d_imm_s_sext = {{20 {d_imm_s[11]}}, d_imm_s};
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
			wire d_is_div = ((d_opcode == OpcodeRegReg) && (d_funct7 == 7'b0000001)) && ((((d_funct3 == 3'b100) || (d_funct3 == 3'b101)) || (d_funct3 == 3'b110)) || (d_funct3 == 3'b111));
			wire d_reg_write = (((((d_is_lui || d_is_auipc) || d_is_regimm) || d_is_regreg) || d_is_load) || d_is_jal) || d_is_jalr;
			reg [324:0] x_state;
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
			wire d_is_load_stall;
			wire [189:0] div_out_m_state;
			reg dependent_on_active_div;
			reg [4:0] active_div_rd [6:0];
			reg branch_refill_pending;
			reg [324:0] div_issue_state;
			wire divide_issue = x_state[0] && !dependent_on_active_div;
			always @(*) begin
				if (_sv2v_0)
					;
				div_issue_state = x_state;
				div_issue_state[0] = divide_issue;
			end
			DividerUnsignedPipelined u_div(
				.clk(clk),
				.rst(rst),
				.stall(d_is_load_stall),
				.i_x_state(div_issue_state),
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
							3'b100:
								if (x_state[18-:7] == 7'b0000000)
									x_alu_result = x_src1 ^ x_src2;
								else
									x_alu_result = 32'd0;
							3'b101:
								case (x_state[18-:7])
									7'b0000000: x_alu_result = x_src1 >> x_src2[4:0];
									7'b0100000: x_alu_result = $signed(x_src1) >>> x_src2[4:0];
									default: x_alu_result = 32'd0;
								endcase
							3'b110:
								if (x_state[18-:7] == 7'b0000000)
									x_alu_result = x_src1 | x_src2;
								else
									x_alu_result = 32'd0;
							3'b111:
								if (x_state[18-:7] == 7'b0000000)
									x_alu_result = x_src1 & x_src2;
								else
									x_alu_result = 32'd0;
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
				if (d_is_load_stall)
					x_branch_taken = 1'b0;
			end
			reg [189:0] m_state;
			wire [255:0] m_disasm;
			Disasm #(.PREFIX("M")) disasm_3memory(
				.insn(m_state[157-:32]),
				.disasm(m_disasm)
			);
			reg [31:0] m_result_to_wb;
			always @(*) begin
				if (_sv2v_0)
					;
				m_result_to_wb = m_state[33-:32];
				case (m_state[82-:7])
					OpcodeLoad:
						case (m_state[75-:3])
							3'b000:
								case (m_state[3:2])
									2'b00: m_result_to_wb = {{24 {SystemResourceCheck.axil_mem_rw.RDATA[7]}}, SystemResourceCheck.axil_mem_rw.RDATA[7:0]};
									2'b01: m_result_to_wb = {{24 {SystemResourceCheck.axil_mem_rw.RDATA[15]}}, SystemResourceCheck.axil_mem_rw.RDATA[15:8]};
									2'b10: m_result_to_wb = {{24 {SystemResourceCheck.axil_mem_rw.RDATA[23]}}, SystemResourceCheck.axil_mem_rw.RDATA[23:16]};
									2'b11: m_result_to_wb = {{24 {SystemResourceCheck.axil_mem_rw.RDATA[31]}}, SystemResourceCheck.axil_mem_rw.RDATA[31:24]};
									default: m_result_to_wb = 32'd0;
								endcase
							3'b100:
								case (m_state[3:2])
									2'b00: m_result_to_wb = {24'd0, SystemResourceCheck.axil_mem_rw.RDATA[7:0]};
									2'b01: m_result_to_wb = {24'd0, SystemResourceCheck.axil_mem_rw.RDATA[15:8]};
									2'b10: m_result_to_wb = {24'd0, SystemResourceCheck.axil_mem_rw.RDATA[23:16]};
									2'b11: m_result_to_wb = {24'd0, SystemResourceCheck.axil_mem_rw.RDATA[31:24]};
									default: m_result_to_wb = 32'd0;
								endcase
							3'b001:
								case (m_state[3])
									1'b0: m_result_to_wb = {{16 {SystemResourceCheck.axil_mem_rw.RDATA[15]}}, SystemResourceCheck.axil_mem_rw.RDATA[15:0]};
									1'b1: m_result_to_wb = {{16 {SystemResourceCheck.axil_mem_rw.RDATA[31]}}, SystemResourceCheck.axil_mem_rw.RDATA[31:16]};
									default: m_result_to_wb = 32'd0;
								endcase
							3'b101:
								case (m_state[3])
									1'b0: m_result_to_wb = {16'd0, SystemResourceCheck.axil_mem_rw.RDATA[15:0]};
									1'b1: m_result_to_wb = {16'd0, SystemResourceCheck.axil_mem_rw.RDATA[31:16]};
									default: m_result_to_wb = 32'd0;
								endcase
							3'b010: m_result_to_wb = SystemResourceCheck.axil_mem_rw.RDATA;
							default: m_result_to_wb = 32'd0;
						endcase
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
			reg [31:0] trace_status_out;
			always @(*) begin
				if (_sv2v_0)
					;
				trace_status_out = w_state[125-:32];
				if (trace_status_out != 32'd1) begin
					if (((w_state[125-:32] != 32'd16) && (w_state[125-:32] != 32'd4)) && (((((m_state[125-:32] == 32'd8) || (x_state[260-:32] == 32'd8)) || (decode_state[31-:32] == 32'd8)) || (g_state[31-:32] == 32'd8)) || branch_refill_pending))
						trace_status_out = 32'd8;
				end
				trace_completed_cycle_status = trace_status_out;
				trace_completed_pc = (trace_status_out == 32'd1 ? w_state[189-:32] : 32'd0);
				trace_completed_insn = (trace_status_out == 32'd1 ? w_state[157-:32] : 32'd0);
				halt = (trace_status_out == 32'd1) && w_state[1];
				rf_rd = w_state[88-:5];
				rf_rd_data = w_state[33-:32];
				rf_we = w_state[83];
			end
			reg [31:0] x_rs1_committed;
			reg [31:0] x_rs2_committed;
			always @(*) begin
				if (_sv2v_0)
					;
				x_rs1_committed = (x_state[228-:5] == 5'd0 ? 32'd0 : rf.regs[x_state[228-:5]]);
				x_rs2_committed = (x_state[223-:5] == 5'd0 ? 32'd0 : rf.regs[x_state[223-:5]]);
				x_src1 = x_rs1_committed;
				if ((((x_state[228-:5] != 5'd0) && m_state[83]) && (m_state[88-:5] == x_state[228-:5])) && (m_state[82-:7] != OpcodeLoad))
					x_src1 = m_state[33-:32];
				else if (((x_state[228-:5] != 5'd0) && w_state[83]) && (w_state[88-:5] == x_state[228-:5]))
					x_src1 = w_state[33-:32];
				x_src2 = x_rs2_committed;
				if ((((x_state[223-:5] != 5'd0) && m_state[83]) && (m_state[88-:5] == x_state[223-:5])) && (m_state[82-:7] != OpcodeLoad))
					x_src2 = m_state[33-:32];
				else if (((x_state[223-:5] != 5'd0) && w_state[83]) && (w_state[88-:5] == x_state[223-:5]))
					x_src2 = w_state[33-:32];
			end
			wire d_uses_rs2 = (d_is_regreg || d_is_branch) || d_is_store;
			assign d_is_load_stall = (x_state[1] && (x_state[218-:5] != 5'd0)) && ((x_state[218-:5] == d_rs1) || (d_uses_rs2 && (x_state[218-:5] == d_rs2)));
			wire divide = x_state[0];
			reg [6:0] div_stage_busy;
			wire divider_active = (div_stage_busy != 7'b0000000) || divide_issue;
			always @(*) begin
				if (_sv2v_0)
					;
				dependent_on_active_div = 1'b0;
				begin : sv2v_autoblock_1
					reg signed [31:0] i;
					for (i = 0; i < 7; i = i + 1)
						if ((div_stage_busy[i] && (active_div_rd[i] != 5'd0)) && (((active_div_rd[i] == x_state[228-:5]) && (x_state[228-:5] != 5'd0)) || ((active_div_rd[i] == x_state[223-:5]) && (x_state[223-:5] != 5'd0))))
							dependent_on_active_div = 1'b1;
				end
			end
			wire div_stall = (divider_active && !x_state[0]) || (dependent_on_active_div && x_state[0]);
			wire frontend_hold = d_is_load_stall || div_stall;
			wire mem_stall = (dependent_on_active_div && x_state[0]) || (divider_active && !div_stage_busy[6]);
			wire imem_resp_fire = (g_valid && SystemResourceCheck.axil_mem_ro.RVALID) && SystemResourceCheck.axil_mem_ro.RREADY;
			wire imem_issue_ok = !g_valid || imem_resp_fire;
			wire imem_req_fire = SystemResourceCheck.axil_mem_ro.ARVALID && SystemResourceCheck.axil_mem_ro.ARREADY;
			always @(*) begin
				if (_sv2v_0)
					;
				SystemResourceCheck.axil_mem_ro.AWADDR = 32'd0;
				SystemResourceCheck.axil_mem_ro.AWVALID = 1'b0;
				SystemResourceCheck.axil_mem_ro.AWPROT = 3'b000;
				SystemResourceCheck.axil_mem_ro.WDATA = 32'd0;
				SystemResourceCheck.axil_mem_ro.WSTRB = 4'b0000;
				SystemResourceCheck.axil_mem_ro.WVALID = 1'b0;
				SystemResourceCheck.axil_mem_ro.BREADY = 1'b1;
				SystemResourceCheck.axil_mem_ro.ARADDR = f_pc_current;
				SystemResourceCheck.axil_mem_ro.ARPROT = 3'b000;
				SystemResourceCheck.axil_mem_ro.ARVALID = 1'b0;
				SystemResourceCheck.axil_mem_ro.RREADY = 1'b0;
				if (!rst) begin
					if (x_branch_taken) begin
						SystemResourceCheck.axil_mem_ro.RREADY = 1'b1;
						SystemResourceCheck.axil_mem_ro.ARVALID = 1'b0;
					end
					else if (frontend_hold) begin
						SystemResourceCheck.axil_mem_ro.RREADY = 1'b0;
						SystemResourceCheck.axil_mem_ro.ARVALID = 1'b0;
					end
					else begin
						SystemResourceCheck.axil_mem_ro.RREADY = 1'b1;
						SystemResourceCheck.axil_mem_ro.ARVALID = imem_issue_ok;
					end
				end
			end
			reg [31:0] dmem_store_data;
			reg [3:0] dmem_store_strb;
			always @(*) begin
				if (_sv2v_0)
					;
				dmem_store_data = 32'd0;
				dmem_store_strb = 4'b0000;
				if ((x_state[260-:32] == 32'd1) && (x_state[11-:7] == OpcodeStore))
					case (x_state[21-:3])
						3'b000: begin
							dmem_store_data = {4 {x_src2[7:0]}};
							case (x_alu_result[1:0])
								2'b00: dmem_store_strb = 4'b0001;
								2'b01: dmem_store_strb = 4'b0010;
								2'b10: dmem_store_strb = 4'b0100;
								2'b11: dmem_store_strb = 4'b1000;
								default: dmem_store_strb = 4'b0000;
							endcase
						end
						3'b001: begin
							dmem_store_data = {2 {x_src2[15:0]}};
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
			always @(*) begin
				if (_sv2v_0)
					;
				SystemResourceCheck.axil_mem_rw.ARADDR = {x_alu_result[31:2], 2'b00};
				SystemResourceCheck.axil_mem_rw.ARVALID = (x_state[260-:32] == 32'd1) && (x_state[11-:7] == OpcodeLoad);
				SystemResourceCheck.axil_mem_rw.ARPROT = 3'b000;
				SystemResourceCheck.axil_mem_rw.RREADY = 1'b1;
				SystemResourceCheck.axil_mem_rw.AWADDR = {x_alu_result[31:2], 2'b00};
				SystemResourceCheck.axil_mem_rw.AWVALID = (x_state[260-:32] == 32'd1) && (x_state[11-:7] == OpcodeStore);
				SystemResourceCheck.axil_mem_rw.AWPROT = 3'b000;
				SystemResourceCheck.axil_mem_rw.WDATA = dmem_store_data;
				SystemResourceCheck.axil_mem_rw.WSTRB = dmem_store_strb;
				SystemResourceCheck.axil_mem_rw.WVALID = (x_state[260-:32] == 32'd1) && (x_state[11-:7] == OpcodeStore);
				SystemResourceCheck.axil_mem_rw.BREADY = 1'b1;
			end
			always @(posedge clk)
				if (rst) begin
					f_pc_current <= 32'd0;
					g_state <= 64'h0000000000000080;
					g_valid <= 1'b0;
					decode_state <= make_decode_bubble(32'd128);
					x_state <= make_execute_bubble(32'd4);
					m_state <= make_memory_bubble(32'd4);
					w_state <= make_memory_bubble(32'd4);
					div_stage_busy <= 7'b0000000;
					active_div_rd[0] <= 5'd0;
					active_div_rd[1] <= 5'd0;
					active_div_rd[2] <= 5'd0;
					active_div_rd[3] <= 5'd0;
					active_div_rd[4] <= 5'd0;
					active_div_rd[5] <= 5'd0;
					active_div_rd[6] <= 5'd0;
					branch_refill_pending <= 1'b0;
				end
				else begin
					w_state <= {sv2v_cast_32(m_state[189-:32]), sv2v_cast_32(m_state[157-:32]), sv2v_cast_32(m_state[125-:32]), sv2v_cast_5(m_state[93-:5]), sv2v_cast_5(m_state[88-:5]), m_state[83], sv2v_cast_7(m_state[82-:7]), sv2v_cast_3(m_state[75-:3]), sv2v_cast_7(m_state[72-:7]), sv2v_cast_32(m_state[65-:32]), m_result_to_wb, m_state[1], m_state[0]};
					div_stage_busy <= {div_stage_busy[5:0], divide_issue};
					active_div_rd[6] <= active_div_rd[5];
					active_div_rd[5] <= active_div_rd[4];
					active_div_rd[4] <= active_div_rd[3];
					active_div_rd[3] <= active_div_rd[2];
					active_div_rd[2] <= active_div_rd[1];
					active_div_rd[1] <= active_div_rd[0];
					active_div_rd[0] <= (divide_issue ? x_state[218-:5] : 5'd0);
					if (x_branch_taken)
						branch_refill_pending <= 1'b1;
					else if (branch_refill_pending && imem_resp_fire)
						branch_refill_pending <= 1'b0;
					if (div_out_m_state[0])
						m_state <= div_out_m_state;
					else if (!mem_stall)
						m_state <= {sv2v_cast_32(x_state[324-:32]), sv2v_cast_32(x_state[292-:32]), sv2v_cast_32(x_state[260-:32]), sv2v_cast_5(x_state[223-:5]), sv2v_cast_5(x_state[218-:5]), x_state[4], sv2v_cast_7(x_state[11-:7]), sv2v_cast_3(x_state[21-:3]), sv2v_cast_7(x_state[18-:7]), x_src2, x_alu_result, x_state[2], x_state[0]};
					else
						m_state <= make_memory_bubble(32'd2);
					if (d_is_load_stall) begin
						f_pc_current <= f_pc_current;
						g_state <= g_state;
						g_valid <= g_valid;
						decode_state <= decode_state;
						x_state <= make_execute_bubble(32'd16);
					end
					else if (x_branch_taken) begin
						f_pc_current <= x_branch_target;
						g_state <= 64'h0000000000000008;
						g_valid <= 1'b0;
						decode_state <= make_decode_bubble(32'd8);
						x_state <= make_execute_bubble(32'd8);
					end
					else if (div_stall) begin
						f_pc_current <= f_pc_current;
						g_state <= g_state;
						g_valid <= g_valid;
						decode_state <= decode_state;
						x_state <= {sv2v_cast_32(x_state[324-:32]), sv2v_cast_32(x_state[292-:32]), sv2v_cast_32(x_state[260-:32]), sv2v_cast_5(x_state[228-:5]), sv2v_cast_5(x_state[223-:5]), sv2v_cast_5(x_state[218-:5]), x_src1, x_src2, sv2v_cast_32(x_state[149-:32]), sv2v_cast_32(x_state[117-:32]), sv2v_cast_32(x_state[85-:32]), sv2v_cast_32(x_state[53-:32]), sv2v_cast_3(x_state[21-:3]), sv2v_cast_7(x_state[18-:7]), sv2v_cast_7(x_state[11-:7]), x_state[4], x_state[3], x_state[2], x_state[1], x_state[0]};
					end
					else begin
						if (imem_req_fire) begin
							g_state <= {f_pc_current, 32'd1};
							g_valid <= 1'b1;
							f_pc_current <= f_pc_current + 32'd4;
						end
						else if (imem_resp_fire) begin
							g_state <= 64'h0000000000000080;
							g_valid <= 1'b0;
							f_pc_current <= f_pc_current;
						end
						else begin
							g_state <= g_state;
							g_valid <= g_valid;
							f_pc_current <= f_pc_current;
						end
						if (imem_resp_fire)
							decode_state <= {sv2v_cast_32(g_state[63-:32]), sv2v_cast_32(SystemResourceCheck.axil_mem_ro.RDATA), 32'd1};
						else if (branch_refill_pending || (g_state[31-:32] == 32'd8))
							decode_state <= make_decode_bubble(32'd8);
						else
							decode_state <= make_decode_bubble(32'd128);
						x_state <= {sv2v_cast_32(decode_state[95-:32]), sv2v_cast_32(decode_state[63-:32]), sv2v_cast_32(decode_state[31-:32]), d_rs1, d_rs2, d_rd, rf_rs1_data, rf_rs2_data, d_imm_i_sext, d_imm_b_sext, d_imm_s_sext, d_imm_u, d_funct3, d_funct7, d_opcode, d_reg_write, d_is_branch, d_is_ecall, d_is_load, d_is_div};
					end
				end
			initial _sv2v_0 = 0;
		end
	endgenerate
	assign datapath.clk = clk;
	assign datapath.rst = rst;
	assign led[0] = datapath.halt;
	assign trace_completed_pc = datapath.trace_completed_pc;
	assign trace_completed_insn = datapath.trace_completed_insn;
	assign trace_completed_cycle_status = datapath.trace_completed_cycle_status;
endmodule
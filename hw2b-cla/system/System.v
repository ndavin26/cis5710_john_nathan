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
module SystemDemo (
	external_clk_25MHz,
	btn,
	led
);
	reg _sv2v_0;
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output reg [7:0] led;
	reg [31:0] ab;
	wire [15:0] a;
	wire [15:0] b;
	wire [31:0] expected_sum;
	wire [31:0] actual_sum;
	wire rst = ~btn[0];
	reg error;
	wire [2:0] chunk = ab[31:29];
	reg [7:0] completed;
	CarryLookaheadAdder cla_inst(
		.a(a),
		.b(b),
		.cin(1'b0),
		.sum(actual_sum)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		a = ab[31:16];
		b = ab[15:0];
		expected_sum = a + b;
	end
	always @(posedge external_clk_25MHz)
		if (rst) begin
			ab <= 32'd0;
			error <= 1'b0;
			completed <= 8'd0;
		end
		else if (!error) begin
			if (actual_sum != expected_sum)
				error <= 1'b1;
			else begin
				ab <= ab + 1;
				if (ab[28:0] == 29'h1fffffff)
					completed[chunk] <= 1'b1;
			end
		end
	reg [23:0] blink;
	always @(posedge external_clk_25MHz)
		if (rst)
			blink <= 0;
		else
			blink <= blink + 1;
	always @(*) begin
		if (_sv2v_0)
			;
		if (error)
			led = completed;
		else
			led = completed | ({7'd0, blink[23]} << chunk);
	end
	initial _sv2v_0 = 0;
endmodule
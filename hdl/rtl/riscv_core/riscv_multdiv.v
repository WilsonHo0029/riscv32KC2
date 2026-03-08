//=============================================================================
// RISC-V Multiplier/Divider Unit (M Extension) - Optimized
//=============================================================================
// Standard: Verilog 1995
// Updated to use:
//   - Radix-4 Booth Multiplier (Single-cycle combinational)
//   - Radix-4 SRT Divider (Sequential, 2-bits per cycle)
//=============================================================================

`include "riscv_defines.v"

module riscv_multdiv (
    clk,
    rst_n,
    valid,
    a,
    b,
    op,
    result,
    ready
);
    input               clk;
    input               rst_n;
    input               valid;
    input  [31:0]       a;
    input  [31:0]       b;
    input  [2:0]        op;
    output reg [31:0]       result;
    output              ready;


    //----------------------------------------------------------------------------
    // Multiplier Instantiation (Radix-4 Booth)
    //----------------------------------------------------------------------------
    // Prepare 33-bit operands based on RISC-V sign rules
    wire [32:0] mult_a;
    wire [32:0] mult_b;
    wire [65:0] mult_out;

    assign mult_a = (op == `MD_MULHU) ? {1'b0, a} : {a[31], a};
    assign mult_b = (op == `MD_MULHU || op == `MD_MULHSU) ? {1'b0, b} : {b[31], b};
    wire ready_mulhu, ready_mulhsu;
    wire mul_ready;
`ifdef MULT_PIPELINE
    booth_mult_r4_b u_multiplier (
        .clk(clk),
        .valid(~op[2] & valid),
        .a(mult_a),
        .b(mult_b),
        .ready(mul_ready),     
        .p(mult_out)
    );
`else
    booth_mult_r4 u_multiplier (
        .a(mult_a),
        .b(mult_b),   
        .p(mult_out)
    );
    assign mul_ready = 1'b1;
`endif
    //----------------------------------------------------------------------------
    // Divider Instantiation (Radix-4 SRT)
    //----------------------------------------------------------------------------
    wire is_div_op;
    wire is_signed;
    wire div_start;
    wire [31:0] div_q, div_r;
    wire div_done;

    assign is_div_op = op[2]; // op[2] is 1 for DIV/REM operations
    assign is_signed = (op == `MD_DIV || op == `MD_REM);
    assign div_start = valid & is_div_op &~div_done;
    div_r4 u_divider (
        .clk(clk),
        .rst_n(rst_n),
        .start(div_start),
        .is_signed(is_signed),
        .dividend(a),
        .divisor(b),
        .quotient(div_q),
        .remainder(div_r),
        .ready(), 
        .done(div_done)
    );
assign ready = (is_div_op) ? (~div_start | div_done): mul_ready;
always@(*)
	if(is_div_op)
		if(op == `MD_DIV || op == `MD_DIVU)
			result <=  div_q;
		else
			result <=  div_r;
	else begin
		if(op == `MD_MUL)
			result <= mult_out[31:0];
		else
			result <= mult_out[63:32];
	end
		
endmodule

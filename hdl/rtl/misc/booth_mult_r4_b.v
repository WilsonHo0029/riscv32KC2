//=============================================================================
// Radix-4 Booth Multiplier (33x33 -> 66-bit) - Structural
//=============================================================================
// Standard: Verilog 1995
// This version uses explicit partial product blocks for visibility.
//=============================================================================

module booth_mult_r4_b (clk, valid, a, b, ready, p);
	input 		  clk;
	input         valid;
    input  [32:0] a; // Multiplicand
    input  [32:0] b; // Multiplier
    output         ready;
    output [65:0] p; // Product (a * b)

    // Padded multiplier for Radix-4 encoding (Exactly 35 bits)
    wire [34:0] b_padded;
    assign b_padded = {b[32], b, 1'b0};

    // --- 1. Base Partial Products (34 bits each) ---
    wire [33:0] pp0,  pp1,  pp2,  pp3,  pp4,  pp5,  pp6,  pp7;
    wire [33:0] pp8,  pp9,  pp10, pp11, pp12, pp13, pp14, pp15, pp16;

    booth_pp_base_r4 u_pp0 (.a(a), .sel(b_padded[2:0]),   .pp(pp0));
    booth_pp_base_r4 u_pp1 (.a(a), .sel(b_padded[4:2]),   .pp(pp1));
    booth_pp_base_r4 u_pp2 (.a(a), .sel(b_padded[6:4]),   .pp(pp2));
    booth_pp_base_r4 u_pp3 (.a(a), .sel(b_padded[8:6]),   .pp(pp3));
    booth_pp_base_r4 u_pp4 (.a(a), .sel(b_padded[10:8]),  .pp(pp4));
    booth_pp_base_r4 u_pp5 (.a(a), .sel(b_padded[12:10]), .pp(pp5));
    booth_pp_base_r4 u_pp6 (.a(a), .sel(b_padded[14:12]), .pp(pp6));
    booth_pp_base_r4 u_pp7 (.a(a), .sel(b_padded[16:14]), .pp(pp7));
    booth_pp_base_r4 u_pp8 (.a(a), .sel(b_padded[18:16]), .pp(pp8));
    booth_pp_base_r4 u_pp9 (.a(a), .sel(b_padded[20:18]), .pp(pp9));
    booth_pp_base_r4 u_pp10(.a(a), .sel(b_padded[22:20]), .pp(pp10));
    booth_pp_base_r4 u_pp11(.a(a), .sel(b_padded[24:22]), .pp(pp11));
    booth_pp_base_r4 u_pp12(.a(a), .sel(b_padded[26:24]), .pp(pp12));
    booth_pp_base_r4 u_pp13(.a(a), .sel(b_padded[28:26]), .pp(pp13));
    booth_pp_base_r4 u_pp14(.a(a), .sel(b_padded[30:28]), .pp(pp14));
    booth_pp_base_r4 u_pp15(.a(a), .sel(b_padded[32:30]), .pp(pp15));
    booth_pp_base_r4 u_pp16(.a(a), .sel(b_padded[34:32]), .pp(pp16));

    // --- 2. Shifted and Extended Partial Products (66 bits each) ---
    wire [65:0] pp0_ext  = { {32{pp0[33]}},  pp0 };
    wire [65:0] pp1_ext  = { {30{pp1[33]}},  pp1,   2'b0 };
    wire [65:0] pp2_ext  = { {28{pp2[33]}},  pp2,   4'b0 };
    wire [65:0] pp3_ext  = { {26{pp3[33]}},  pp3,   6'b0 };
    wire [65:0] pp4_ext  = { {24{pp4[33]}},  pp4,   8'b0 };
    wire [65:0] pp5_ext  = { {22{pp5[33]}},  pp5,  10'b0 };
    wire [65:0] pp6_ext  = { {20{pp6[33]}},  pp6,  12'b0 };
    wire [65:0] pp7_ext  = { {18{pp7[33]}},  pp7,  14'b0 };
    wire [65:0] pp8_ext  = { {16{pp8[33]}},  pp8,  16'b0 };
    wire [65:0] pp9_ext  = { {14{pp9[33]}},  pp9,  18'b0 };
    wire [65:0] pp10_ext = { {12{pp10[33]}}, pp10, 20'b0 };
    wire [65:0] pp11_ext = { {10{pp11[33]}}, pp11, 22'b0 };
    wire [65:0] pp12_ext = { { 8{pp12[33]}}, pp12, 24'b0 };
    wire [65:0] pp13_ext = { { 6{pp13[33]}}, pp13, 26'b0 };
    wire [65:0] pp14_ext = { { 4{pp14[33]}}, pp14, 28'b0 };
    wire [65:0] pp15_ext = { { 2{pp15[33]}}, pp15, 30'b0 };
    wire [65:0] pp16_ext = {                 pp16, 32'b0 };
	reg [65:0] pp_gp0;
	reg [65:0] pp_gp1;
	reg [65:0] pp_gp2;
	reg [65:0] pp_gp3;
	reg [65:0] pp_gp4;
	reg [65:0] pp_gp5;
	reg [65:0] pp_gp6;
	reg [65:0] pp_gp7;
	reg [65:0] pp_gp8;
	reg ready_mul;
	reg done;
	
    assign ready = ~(valid & ~done);
	always@(posedge clk) begin
	   pp_gp0 <= pp0_ext + pp1_ext;
	   pp_gp1 <= pp2_ext + pp3_ext;
	   pp_gp2 <= pp4_ext + pp5_ext;
	   pp_gp3 <= pp6_ext + pp7_ext;
	   pp_gp4 <= pp8_ext + pp9_ext;
	   pp_gp5 <= pp10_ext + pp11_ext;
	   pp_gp6 <= pp12_ext + pp13_ext;
	   pp_gp7 <= pp14_ext + pp15_ext;
	   pp_gp8 <= pp16_ext;
	   done <= valid;
	end

	       
	assign p = pp_gp0 + pp_gp1 + pp_gp2 +  pp_gp3 + pp_gp4 + pp_gp5 + pp_gp6 + pp_gp7 + pp_gp8;
    // --- 3. Final Summation ---
/*	
    assign p = (pp0_ext + pp1_ext + pp2_ext + pp3_ext) + 
               (pp4_ext + pp5_ext + pp6_ext + pp7_ext) + 
               (pp8_ext + pp9_ext + pp10_ext + pp11_ext) + 
               (pp12_ext + pp13_ext + pp14_ext + pp15_ext) + 
               pp16_ext;
*/
endmodule

//=============================================================================
// Radix-4 Booth Partial Product Generator
//=============================================================================
// Standard: Verilog 1995
//=============================================================================
module booth_pp_base_r4 (
    a,
    sel,
    pp
);
    input  [32:0] a;   // Multiplicand
    input  [2:0]  sel; // 3-bit Booth window
    output [33:0] pp;  // Generated Partial Product Base

    reg [33:0] pp_reg;

    always @(a or sel) begin
        case (sel)
            3'b000, 3'b111: pp_reg = 34'b0;
            3'b001, 3'b010: pp_reg = {a[32], a};          // +1 * a
            3'b011:         pp_reg = {a, 1'b0};           // +2 * a
            3'b100:         pp_reg = (~{a, 1'b0}) + 34'b1; // -2 * a
            3'b101, 3'b110: pp_reg = (~{a[32], a}) + 34'b1; // -1 * a
            default:        pp_reg = 34'b0;
        endcase
    end

    assign pp = pp_reg;

endmodule
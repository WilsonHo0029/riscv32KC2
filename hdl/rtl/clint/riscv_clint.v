module riscv_clint#(
	parameter HART_NUM = 2
)(
	input                    clk,
	input                    rst_n,
	input  [15:0]            clint_addr,
	input                    wr_en,
	input  [31:0]            clint_wdata,
	output [31:0]            clint_rdata,

	input                    rtc_syn_i, // 32768 clk syn with clk

	output reg [HART_NUM-1:0]    clint_tmr_irq,
	output reg [HART_NUM-1:0]    clint_sft_irq
);

localparam MSIP_BASE  = 16'h0000;
localparam MTCMP_BASE = 16'h4000;
localparam MTIME_BASE = 16'hBFF8;

reg                    rtc_syn_i_d;
reg [HART_NUM-1:0]     msip;
reg [HART_NUM-1:0]     tmr_irq;
reg [63:0]             mtcmp [0:HART_NUM-1];
reg [63:0]             mtime;
reg [31:0]             rd_clint [0:HART_NUM-1];
reg [31:0]             rd_clint_or;

wire rtc_rise = rtc_syn_i & ~rtc_syn_i_d;

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		rtc_syn_i_d <= 1'd0;
	end else begin
		rtc_syn_i_d <= rtc_syn_i;
	end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		mtime <= 64'd0;
	end else begin
		if (wr_en & (clint_addr == MTIME_BASE)) begin
			mtime[31:0] <= clint_wdata[31:0];
		end else if (wr_en & (clint_addr == (MTIME_BASE + 16'h0004))) begin
			mtime[63:32] <= clint_wdata[31:0];
		end else if (rtc_rise) begin
			mtime <= mtime + 64'd1;
		end
	end
end
integer i;

always @(posedge clk, negedge rst_n) begin
	for (i = 0; i < HART_NUM; i = i + 1) begin
		if (~rst_n) begin
			mtcmp[i] <= 64'hFFFF_FFFF_FFFF_FFFF;
		end else begin
			if (wr_en & (clint_addr == (MTCMP_BASE + i * 16'd8))) begin
				mtcmp[i][31:0] <= clint_wdata[31:0];
			end
			if (wr_en & (clint_addr == (MTCMP_BASE + i * 16'd8 + 16'h4))) begin
				mtcmp[i][63:32] <= clint_wdata[31:0];
			end
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	for (i = 0; i < HART_NUM; i = i + 1) begin
		if (~rst_n) begin
			msip[i] <= 1'b0;
		end else begin
			if (wr_en & (clint_addr == (MSIP_BASE + i * 16'd4))) begin
				msip[i] <= clint_wdata[0];
			end
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	for (i = 0; i < HART_NUM; i = i + 1) begin
		if (~rst_n) begin
			tmr_irq[i] <= 1'b0;
		end else begin
			tmr_irq[i] <= (mtime >= mtcmp[i]);
		end
	end
end

always @(*) begin
	for (i = 0; i < HART_NUM; i = i + 1) begin
		clint_tmr_irq[i] = tmr_irq[i];
		clint_sft_irq[i] = msip[i];
	end
end

always @(*) begin
	for (i = 0; i < HART_NUM; i = i + 1) begin
		case (clint_addr)
			(MSIP_BASE + i * 16'd4): begin
				rd_clint[i][0]     = msip[i];
				rd_clint[i][31:1]  = 31'd0;
			end
			(MTCMP_BASE + i * 16'd8): begin
				rd_clint[i] = mtcmp[i][31:0];
			end
			(MTCMP_BASE + i * 16'd8 + 16'd4): begin
				rd_clint[i] = mtcmp[i][63:32];
			end
			default: begin
				rd_clint[i] = 32'd0;
			end
		endcase
	end
end
integer j;

always @(*) begin
	rd_clint_or = 32'd0;
	for (j = 0; j < HART_NUM; j = j + 1) begin : HART_OR
		rd_clint_or = rd_clint_or | rd_clint[j];
	end
end

assign clint_rdata = (clint_addr == MTIME_BASE) ? mtime[31:0] : rd_clint_or;

endmodule
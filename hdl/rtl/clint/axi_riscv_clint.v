// Top-level AXI RISC-V CLINT Module
module axi_riscv_clint #(
	parameter HART_NUM = 2,
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32
)(
	// Clock and Reset
	input                    aclk,
	input                    aresetn,

	// AXI Lite Slave Interface
	// Write Address Channel
	input  [ADDR_WIDTH-1:0]  s_axi_awaddr,
	input  [2:0]             s_axi_awsize,
	input                     s_axi_awvalid,
	output                    s_axi_awready,

	// Write Data Channel
	input  [DATA_WIDTH-1:0]   s_axi_wdata,
	input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
	input                     s_axi_wvalid,
	output                    s_axi_wready,

	// Write Response Channel
	output  [1:0]             s_axi_bresp,
	output                    s_axi_bvalid,
	input                     s_axi_bready,

	// Read Address Channel
	input  [ADDR_WIDTH-1:0]   s_axi_araddr,
	input  [2:0]              s_axi_arsize,
	input                     s_axi_arvalid,
	output                    s_axi_arready,

	// Read Data Channel
	output [DATA_WIDTH-1:0]   s_axi_rdata,
	output [1:0]              s_axi_rresp,
	output                    s_axi_rvalid,
	input                     s_axi_rready,

	// RTC Synchronization Input
	input                     rtc_i, // 32768 Hz clock synced with aclk

	// Interrupt Outputs
	output [HART_NUM-1:0]     clint_tmr_irq,
	output [HART_NUM-1:0]     clint_sft_irq
);

	//----------------------------------------------------------------------------
	// Internal Signals
	//----------------------------------------------------------------------------
	wire [ADDR_WIDTH-1:0]             axi_addr;
	wire [15:0]             clint_addr;
	wire                    clint_wr_en;
	wire [31:0]             clint_wdata;
	wire [31:0]             clint_rdata;

	//----------------------------------------------------------------------------
	// AXI Slave to Device Interface Instance
	//----------------------------------------------------------------------------
	axi_slv_to_dev_inf #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) u_axi_slv_to_dev_inf (
		.aclk                   (aclk),
		.aresetn                (aresetn),
		.s_axi_awaddr           (s_axi_awaddr),
		.s_axi_awsize           (s_axi_awsize),
		.s_axi_awvalid          (s_axi_awvalid),
		.s_axi_awready          (s_axi_awready),
		.s_axi_wdata            (s_axi_wdata),
		.s_axi_wstrb            (s_axi_wstrb),
		.s_axi_wvalid           (s_axi_wvalid),
		.s_axi_wready           (s_axi_wready),
		.s_axi_bresp            (s_axi_bresp),
		.s_axi_bvalid           (s_axi_bvalid),
		.s_axi_bready           (s_axi_bready),
		.s_axi_araddr           (s_axi_araddr),
		.s_axi_arsize           (s_axi_arsize),
		.s_axi_arvalid          (s_axi_arvalid),
		.s_axi_arready          (s_axi_arready),
		.s_axi_rdata            (s_axi_rdata),
		.s_axi_rresp            (s_axi_rresp),
		.s_axi_rvalid           (s_axi_rvalid),
		.s_axi_rready           (s_axi_rready),
		.addr                   (axi_addr),
		.wr_en                  (clint_wr_en),
		.wdata                  (clint_wdata),
		.rdata                  (clint_rdata)
	);

	// Connect memory interface to CLINT
        assign clint_addr = axi_addr[15:0];
	//----------------------------------------------------------------------------
	// RTC Synchronization
	//----------------------------------------------------------------------------
	reg rtc_i_d;
	reg rtc_i_d2;
	always@(posedge aclk or negedge aresetn)
		if(~aresetn) begin
			rtc_i_d  <= 1'b0;
			rtc_i_d2 <= 1'b0;
		end
		else begin
			rtc_i_d <= rtc_i;
			rtc_i_d2 <= rtc_i_d;
		end

	//----------------------------------------------------------------------------
	// CLINT Instance
	//----------------------------------------------------------------------------
	riscv_clint #(
		.HART_NUM(HART_NUM)
	) u_riscv_clint (
		.clk          (aclk),
		.rst_n        (aresetn),
		.clint_addr   (clint_addr),
		.wr_en        (clint_wr_en),
		.clint_wdata  (clint_wdata),
		.clint_rdata  (clint_rdata),
		.rtc_syn_i    (rtc_i_d2),
		.clint_tmr_irq(clint_tmr_irq),
		.clint_sft_irq(clint_sft_irq)
	);

endmodule



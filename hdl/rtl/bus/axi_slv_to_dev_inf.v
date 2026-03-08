// AXI Lite Wrapper for RISC-V CLINT (Core Local Interruptor)
// Converts AXI Lite interface to riscv_clint module interface
// Supports MSIP, MTIMECMP, and MTIME registers for multiple HARTs

// AXI Slave to Device Interface Module
// Groups all AXI signals and converts to simple device interface
module axi_slv_to_dev_inf #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32
)(
	// Clock and Reset
	input                    aclk,
	input                    aresetn,

	// AXI Lite Slave Interface (grouped as input)
	input  [ADDR_WIDTH-1:0]  s_axi_awaddr,
	input  [2:0]             s_axi_awsize,
	input                     s_axi_awvalid,
	output                    s_axi_awready,
	input  [DATA_WIDTH-1:0]   s_axi_wdata,
	input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
	input                     s_axi_wvalid,
	output                    s_axi_wready,
	output [1:0]              s_axi_bresp,
	output                    s_axi_bvalid,
	input                     s_axi_bready,
	input  [ADDR_WIDTH-1:0]   s_axi_araddr,
	input  [2:0]              s_axi_arsize,
	input                     s_axi_arvalid,
	output                    s_axi_arready,
	output   [DATA_WIDTH-1:0] s_axi_rdata,
	output     [1:0]          s_axi_rresp,
	output                    s_axi_rvalid,
	input                     s_axi_rready,

	// Device Interface Outputs
	output [ADDR_WIDTH-1:0]   addr,
	output                    wr_en,
	output [DATA_WIDTH-1:0]   wdata,
	input  [DATA_WIDTH-1:0]   rdata
);

	//----------------------------------------------------------------------------
	// Unified State Machine for AXI Lite Write and Read
	//----------------------------------------------------------------------------
	// Note: AXI4-Lite only performs one transaction at a time (write or read)
	//       Therefore, a single state machine can handle both operations
	localparam IDLE      = 3'b000;
	localparam WR_DATA   = 3'b001;
	localparam WR_RESP   = 3'b010;
	localparam RD_DATA   = 3'b011;

	reg [2:0]               state;
	reg [ADDR_WIDTH-1:0]   addr_reg;

	// AXI control signals
	assign s_axi_awready = (state == IDLE) & ~s_axi_arvalid;  // Only ready if no read pending
	assign s_axi_arready = (state == IDLE) & ~s_axi_awvalid;  // Only ready if no write pending
	assign s_axi_wready  = (state == WR_DATA);
        assign s_axi_bresp = 2'b00;
	assign s_axi_bvalid = (state == WR_RESP);
	assign s_axi_rresp = 2'b00;
        assign s_axi_rvalid = (state == RD_DATA);
        assign s_axi_rdata = rdata;
	// Device interface signals
	assign wr_en         = (state == WR_DATA) & s_axi_wvalid;
	assign addr          = (state == IDLE) ? {ADDR_WIDTH{1'b0}} : addr_reg;
	assign wdata         = s_axi_wdata;

	// AXI response signals
	always @(posedge aclk or negedge aresetn) begin
		if (~aresetn) begin
			state         <= IDLE;
			addr_reg      <= {ADDR_WIDTH{1'b0}};
		end else begin
			case (state)
				IDLE: begin
					
					// Priority: Write has higher priority than read (AXI4-Lite allows this)
					if (s_axi_awvalid) begin
						addr_reg <= s_axi_awaddr;
						state    <= WR_DATA;
					end else if (s_axi_arvalid) begin
						addr_reg <= s_axi_araddr;
						state    <= RD_DATA;
					end
				end
				
				WR_DATA: begin
					if (s_axi_wvalid) begin
						state <= WR_RESP;
					end
				end
				
				WR_RESP: begin
					if (s_axi_bready) begin
						state        <= IDLE;
					end
				end
				
				RD_DATA: begin
					if (s_axi_rready) begin
						state        <= IDLE;
					end
				end
				
				default: begin
					state <= IDLE;
				end
			endcase
		end
	end

endmodule





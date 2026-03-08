module axi_lite_demux#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NumMst = 3
)(
    input			    clk,
    input			    rst_n,
    // Write Address Channel
    input  [ADDR_WIDTH-1:0]         s_axi_awaddr,
    input  [7:0]                    s_axi_awlen,
    input  [2:0]                    s_axi_awsize,
    input  [1:0]                    s_axi_awburst,
    input                           s_axi_awvalid,
    output                          s_axi_awready,
    
    // Write Data Channel
    input  [DATA_WIDTH-1:0]         s_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0]     s_axi_wstrb,
    input                           s_axi_wlast,
    input                           s_axi_wvalid,
    output                          s_axi_wready,
    
    // Write Response Channel
    output [1:0]                    s_axi_bresp,
    output                          s_axi_bvalid,
    input                           s_axi_bready,
    
    // Read Address Channel
    input  [ADDR_WIDTH-1:0]         s_axi_araddr,
    input  [7:0]                    s_axi_arlen,
    input  [2:0]                    s_axi_arsize,
    input  [1:0]                    s_axi_arburst,
    input                           s_axi_arvalid,
    output                          s_axi_arready,
    
    // Read Data Channel
    output [DATA_WIDTH-1:0]         s_axi_rdata,
    output [1:0]                    s_axi_rresp,
    output                          s_axi_rlast,
    output                          s_axi_rvalid,
    input                           s_axi_rready,	
    // Select 
    input [NumMst-1:0]	            select_ar_i,
    input [NumMst-1:0]	            select_aw_i,
    // Master interface
    // Write Address Channel
    output [NumMst*ADDR_WIDTH-1:0]     m_axi_awaddr,
    output [NumMst*8-1:0]                m_axi_awlen,
    output [NumMst*3-1:0]                m_axi_awsize,
    output [NumMst*2-1:0]                m_axi_awburst,
    output [NumMst-1:0]                     m_axi_awvalid,
    input  [NumMst-1:0]                         m_axi_awready,
    
    // Write Data Channel
    output [NumMst*DATA_WIDTH-1:0]     m_axi_wdata,
    output [NumMst*(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output [NumMst-1:0]                m_axi_wlast,
    output [NumMst-1:0]                m_axi_wvalid,
    input  [NumMst-1:0]                        m_axi_wready,
    
    // Write Response Channel
    input  [NumMst*2-1:0]                    m_axi_bresp,
    input  [NumMst-1:0]                         m_axi_bvalid,
    output [NumMst-1:0]                       m_axi_bready, 
    
    // Read Address Channel
    output  [NumMst*ADDR_WIDTH-1:0]     m_axi_araddr,
    output  [NumMst*8-1:0]                m_axi_arlen,
    output  [NumMst*3-1:0]                m_axi_arsize,
    output  [NumMst*2-1:0]                m_axi_arburst,
    output  [NumMst-1:0]                    m_axi_arvalid,
    input   [NumMst-1:0]                        m_axi_arready,
    
    // Read Data Channel
    input  [NumMst*DATA_WIDTH-1:0]         m_axi_rdata,
    input  [NumMst*2-1:0]                    m_axi_rresp,
    input  [NumMst-1:0]                         m_axi_rlast,
    input  [NumMst-1:0]                         m_axi_rvalid,
    output [NumMst-1:0]                      m_axi_rready
);
wire [NumMst-1:0] rd_sel;
wire rd_empty;
wire [NumMst-1:0] w_sel;
wire w_empty;
wire [NumMst-1:0] b_sel;
wire b_empty;
// AW
assign m_axi_awaddr = {NumMst{s_axi_awaddr}};
assign m_axi_awlen = {NumMst{s_axi_awlen}};
assign m_axi_awsize = {NumMst{s_axi_awsize}};
assign m_axi_awburst = {NumMst{s_axi_awburst}};
assign m_axi_awvalid = select_aw_i & {NumMst{s_axi_awvalid}}; 
assign s_axi_awready = {|{select_aw_i & m_axi_awready}};
wire w_fifo_push = w_empty & s_axi_awready & {|m_axi_awvalid};
wire w_fifo_pop = ~w_empty & s_axi_wready & s_axi_wvalid;
axi_fifo#(
	.DW(NumMst)
)u_fifo_w(
	.clk	(clk),
	.rst_n	(rst_n),
	
	.data_i	(select_aw_i),
	.push_i	(w_fifo_push),
	.empty_o(w_empty),
	
	.data_o (w_sel),
	.pop_i	(w_fifo_pop)
);
// W
assign s_axi_wready = {|{w_sel & m_axi_wready}};
assign m_axi_wdata = {NumMst{s_axi_wdata}};
assign m_axi_wstrb = {NumMst{s_axi_wstrb}};
assign m_axi_wlast = {NumMst{s_axi_wlast}};
assign m_axi_wvalid = w_sel;
wire b_pop_cond = {|{b_sel & m_axi_bvalid}};
wire b_fifo_pop = ~b_empty & b_pop_cond; 
axi_fifo#(
	.DW(NumMst)
)u_fifo_b(
	.clk	(clk),
	.rst_n	(rst_n),
	
	.data_i	(w_sel),
	.push_i	(w_fifo_pop),
	.empty_o(b_empty),
	
	.data_o (b_sel),
	.pop_i	(b_fifo_pop)
);
// B
assign s_axi_bresp = 2'b00;//Not Used
assign s_axi_bvalid = b_fifo_pop;
assign m_axi_bready = b_sel;
// AR
assign m_axi_araddr = {NumMst{s_axi_araddr}};
assign m_axi_arlen = {NumMst{s_axi_arlen}};
assign m_axi_arsize = {NumMst{s_axi_arsize}};
assign m_axi_arburst = {NumMst{s_axi_arburst}};
assign m_axi_arvalid = select_ar_i & {NumMst{s_axi_arvalid}}; 
assign s_axi_arready = {|{select_ar_i & m_axi_arready}} & rd_empty;
wire rd_fifo_push = rd_empty & s_axi_arready & {|m_axi_arvalid};
wire rd_fifo_pop = ~rd_empty & s_axi_rready & s_axi_rvalid;
// R
assign m_axi_rready = {NumMst{s_axi_rready}} & rd_sel;
reg [DATA_WIDTH-1:0]         s_axi_rdata_or;
reg [1:0]                    s_axi_rresp_or;
reg                          s_axi_rlast_or;
reg                          s_axi_rvalid_or;

assign s_axi_rdata = s_axi_rdata_or;
assign s_axi_rresp = s_axi_rresp_or;
assign s_axi_rlast = s_axi_rlast_or;
assign s_axi_rvalid = s_axi_rvalid_or;

axi_fifo#(
	.DW(NumMst)
)u_fifo_r(
	.clk	(clk),
	.rst_n	(rst_n),
	
	.data_i	(select_ar_i),
	.push_i	(rd_fifo_push),
	.empty_o(rd_empty),
	
	.data_o (rd_sel),
	.pop_i	(rd_fifo_pop)
);

integer i;		
always@(*) begin
    	s_axi_rdata_or  = 0;
   	s_axi_rresp_or  = 0;
    	s_axi_rlast_or  = 0;
    	s_axi_rvalid_or = 0;
	for (i=0 ; i<NumMst; i=i+1) begin
		s_axi_rdata_or = s_axi_rdata_or | ((m_axi_rdata >> (i * DATA_WIDTH)) & {DATA_WIDTH{rd_sel[i]}});
		s_axi_rresp_or = s_axi_rresp_or | ((m_axi_rresp >> (i * 2))          & {2{rd_sel[i]}});
		s_axi_rlast_or = s_axi_rlast_or |   (m_axi_rlast[i] & rd_sel[i]);
		s_axi_rvalid_or = s_axi_rvalid_or | (m_axi_rvalid[i] & rd_sel[i]);
	end
end	
endmodule

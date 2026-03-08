module axi_lite_mux#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NumSlv = 3
)(
    input			    clk,
    input			    rst_n,

    // Write Address Channel
    input  [NumSlv*ADDR_WIDTH-1:0]           s_axi_awaddr,
    input  [NumSlv*8-1:0]                    s_axi_awlen,
    input  [NumSlv*3-1:0]                    s_axi_awsize,
    input  [NumSlv*2-1:0]                    s_axi_awburst,
    input  [NumSlv-1:0]                      s_axi_awvalid,
    output [NumSlv-1:0]                      s_axi_awready,
    
    // Write Data Channel
    input  [NumSlv*DATA_WIDTH-1:0]         s_axi_wdata,
    input  [NumSlv*(DATA_WIDTH/8)-1:0]     s_axi_wstrb,
    input  [NumSlv-1:0]                         s_axi_wlast,
    input  [NumSlv-1:0]                        s_axi_wvalid,
    output [NumSlv-1:0]                         s_axi_wready,
    
    // Write Response Channel
    output [NumSlv*2-1:0]                    s_axi_bresp,
    output [NumSlv-1:0]                         s_axi_bvalid,
    input  [NumSlv-1:0]                        s_axi_bready,
    
    // Read Address Channel
    input  [NumSlv*ADDR_WIDTH-1:0]         s_axi_araddr,
    input  [NumSlv*8-1:0]                    s_axi_arlen,
    input  [NumSlv*3-1:0]                    s_axi_arsize,
    input  [NumSlv*2-1:0]                    s_axi_arburst,
    input  [NumSlv-1:0]                          s_axi_arvalid,
    output [NumSlv-1:0]                          s_axi_arready,
    
    // Read Data Channel
    output [NumSlv*DATA_WIDTH-1:0]         s_axi_rdata,
    output [NumSlv*2-1:0]                    s_axi_rresp,
    output [NumSlv-1:0]                          s_axi_rlast,
    output [NumSlv-1:0]                          s_axi_rvalid,
    input  [NumSlv-1:0]                          s_axi_rready,

 // Master interface
    // Write Address Channel
    output [ADDR_WIDTH-1:0]     m_axi_awaddr,
    output [7:0]                m_axi_awlen,
    output [2:0]                m_axi_awsize,
    output [1:0]                m_axi_awburst,
    output                      m_axi_awvalid,
    input                          m_axi_awready,
    
    // Write Data Channel
    output [DATA_WIDTH-1:0]     m_axi_wdata,
    output [(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output                 m_axi_wlast,
    output                 m_axi_wvalid,
    input                          m_axi_wready,
    
    // Write Response Channel
    input  [1:0]                    m_axi_bresp,
    input                           m_axi_bvalid,
    output                        m_axi_bready, 
    
    // Read Address Channel
    output reg  [ADDR_WIDTH-1:0]     m_axi_araddr,
    output reg  [7:0]                m_axi_arlen,
    output reg  [2:0]                m_axi_arsize,
    output reg  [1:0]                m_axi_arburst,
    output reg                     m_axi_arvalid,
    input                           m_axi_arready,
    
    // Read Data Channel
    input  [DATA_WIDTH-1:0]         m_axi_rdata,
    input  [1:0]                    m_axi_rresp,
    input                           m_axi_rlast,
    input                           m_axi_rvalid,
    output                       m_axi_rready
);
integer i;
always@(*) begin
    	m_axi_araddr = 0;
    	m_axi_arlen = 0;
        m_axi_arsize = 0;
        m_axi_arburst=  0;
        m_axi_arvalid = 0;
	for(i=0; i<NumSlv; i=i+1) begin
		if(m_axi_arready & m_axi_arvalid[i]) begin
    			m_axi_araddr = s_axi_araddr[(i+1)*ADDR_WIDTH: ADDR_WIDTH*i];
    			m_axi_arlen = s_axi_arlen[(i+1)*8: 8*i];
        		m_axi_arsize = s_axi_arsize[(i+1)*3: 3*i];
        		m_axi_arburst=  s_axi_arburst[(i+1)*2: 2*i];
        		m_axi_arvalid = 1'b1;			
		end
	end


end



endmodule

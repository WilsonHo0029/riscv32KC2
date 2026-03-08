// AXI4-Lite Slave to APB Master Bridge
// Converts AXI transactions to APB transactions
//
// Features:
// - Supports single-word read/write
// - Handles AXI channel synchronization
// - Full APB master protocol implementation
// - Uses absolute system addresses

module axi2apb_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Global Signals
    input                       aclk,
    input                       aresetn,

    // AXI Slave Interface
    // Write Address Channel
    input  [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  [2:0]                s_axi_awsize,
    input                       s_axi_awvalid,
    output                      s_axi_awready,

    // Write Data Channel
    input  [DATA_WIDTH-1:0]     s_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                       s_axi_wvalid,
    output                      s_axi_wready,

    // Write Response Channel
    output reg [1:0]            s_axi_bresp,
    output reg                  s_axi_bvalid,
    input                       s_axi_bready,

    // Read Address Channel
    input  [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  [2:0]                s_axi_arsize,
    input                       s_axi_arvalid,
    output                      s_axi_arready,

    // Read Data Channel
    output reg [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg [1:0]                s_axi_rresp,
    output reg                      s_axi_rvalid,
    input                           s_axi_rready,

    // APB Master Interface
    output reg [ADDR_WIDTH-1:0]     m_apb_paddr,
    output reg                      m_apb_psel,
    output reg                      m_apb_penable,
    output reg                      m_apb_pwrite,
    output reg [DATA_WIDTH-1:0]     m_apb_pwdata,
    output reg [3:0]                m_apb_pstrb,
    input  [DATA_WIDTH-1:0]         m_apb_prdata,
    input                           m_apb_pready,
    input                           m_apb_pslverr
);

    // State Machine States
    localparam STATE_IDLE   	= 3'b000;
    localparam STATE_READ_AR    = 3'b001;
    localparam STATE_READ_R     = 3'b010;
    localparam STATE_WRITE_AW   = 3'b011;
    localparam STATE_WRITE_W   	= 3'b100;
    localparam STATE_WRITE_B   	= 3'b101;	

    reg [2:0]  state, nstate;
    assign s_axi_arready = (state == STATE_READ_AR);
    assign s_axi_awready = (state == STATE_WRITE_AW);
    assign s_axi_wready = (state == STATE_WRITE_W);
    always@(posedge aclk or negedge aresetn)
	if(~aresetn)
		state <= STATE_IDLE;
	else
		state <= nstate;

    always@(*)
	case(state)
		STATE_IDLE:
			if(s_axi_arvalid)
				nstate = STATE_READ_AR;
			else if(s_axi_awvalid)
				nstate = STATE_WRITE_AW;
			else
				nstate = STATE_IDLE;
		STATE_READ_AR:
			nstate = STATE_READ_R;
		STATE_READ_R:
			if(s_axi_rready & s_axi_rvalid)
				nstate = STATE_IDLE;
			else
				nstate = STATE_READ_R;
		STATE_WRITE_AW:
			nstate = STATE_WRITE_W;
		STATE_WRITE_W:
			nstate = STATE_WRITE_B;
		STATE_WRITE_B:
			if(s_axi_bready)
				nstate = STATE_IDLE;
			else
				nstate = STATE_WRITE_B;
		default:
			nstate = STATE_IDLE;
	endcase
   // APB signals
   always@(posedge aclk or negedge aresetn)
	if(~aresetn) begin
    		m_apb_paddr <= 'd0;
    		m_apb_psel <= 1'b0;
    		m_apb_penable <= 'd0;
    		m_apb_pwrite <= 1'b0;
    		m_apb_pwdata <= 'd0;
    		m_apb_pstrb <= 'd0;
	end
	else begin
		m_apb_paddr <= (state == STATE_READ_AR) ? s_axi_araddr:
			       (state == STATE_WRITE_AW) ? s_axi_awaddr:
				m_apb_paddr;
		if(state == STATE_IDLE) begin
    			m_apb_psel <= 1'b0;	
		end
		else if(state == STATE_READ_AR || state == STATE_WRITE_AW) begin
    			m_apb_psel <= 1'b1;
		end
		if(state == STATE_IDLE)
			m_apb_penable <= 1'b0;
		else if(state == STATE_READ_R || state == STATE_WRITE_W)
			m_apb_penable <= 1'b1;
		m_apb_pwrite <= (state == STATE_WRITE_W);
		m_apb_pwdata <= (state == STATE_WRITE_W)?s_axi_wdata:m_apb_pwdata;
		m_apb_pstrb <= (state == STATE_WRITE_W)?s_axi_wstrb:m_apb_pstrb;

	end
   // AXI signals
   always@(posedge aclk or negedge aresetn)
	if(~aresetn) begin
    		s_axi_rdata <= 'd0;
    		s_axi_rresp <= 'd0;
    		s_axi_rvalid <= 'd0;
                s_axi_bresp <= 'd0;
                s_axi_bvalid <= 'd0;
	end
	else begin
		if(state == STATE_IDLE) begin
			s_axi_rvalid <= 1'b0;
		end
		else if(state == STATE_READ_R) begin
			s_axi_rvalid <= m_apb_pready;
		end
		if(state == STATE_READ_R && m_apb_pready) begin
			s_axi_rdata <= m_apb_prdata;
			s_axi_rresp <= (m_apb_pslverr)?2'b01:2'b00;
		end
		if(state == STATE_IDLE) begin
			s_axi_bvalid <= 1'b0;
		end
		else if(state == STATE_WRITE_B) begin
			s_axi_bvalid <= 1'b1;
		end
		if(state == STATE_WRITE_B && m_apb_pready) begin
			s_axi_bresp <= (m_apb_pslverr)?2'b01:2'b00;
		end	
	end


endmodule


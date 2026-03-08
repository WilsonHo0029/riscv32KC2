module write_req_to_axi(
    input		req,
    input [31:0]	req_addr,
    output		req_ready,
    input [31:0]	req_wdata,
    input [3:0]    	req_wbe,
    // 
    input               aclk,
    input               aresetn,	
    // AXI4 Write Address Channel
    output reg [31:0]   awaddr,
    output     [7:0]    awlen,
    output     [2:0]    awsize,
    output     [1:0]    awburst,
    output              awvalid,
    input               awready,
    
    // AXI4 Write Data Channel
    output  reg [31:0]  wdata,
    output  reg [3:0]   wstrb,
    output              wlast,
    output              wvalid,
    input               wready,
    
    // AXI4 Write Response Channel
    input  [1:0]        bresp,
    input               bvalid,
    output              bready
);

    localparam [2:0] STATE_IDLE        = 2'b00;
    localparam [2:0] STATE_WRITE_AW    = 2'b01;
    localparam [2:0] STATE_WRITE_W     = 2'b10;
    localparam [2:0] STATE_WRITE_B     = 2'b11;
    // AXI parameters
    localparam AXI_AWLEN_SINGLE = 8'h0;      // Single beat transfer
    localparam AXI_AWSIZE_WORD  = 3'b010;    // 4 bytes (32 bits)
    localparam AXI_AWBURST_INCR = 2'b01;     // Incrementing burst
    reg [1:0] state, nstate;
    assign req_ready = (state == STATE_IDLE);
    assign awlen = AXI_AWLEN_SINGLE;
    assign awsize = AXI_AWSIZE_WORD;
    assign awburst = AXI_AWBURST_INCR;
    assign awvalid = (state == STATE_WRITE_AW);
    
    assign wvalid = (state == STATE_WRITE_AW | state == STATE_WRITE_W);
    assign wlast  = (state == STATE_WRITE_AW | state == STATE_WRITE_W);
    assign bready = ~req_ready;

    always@(posedge aclk or negedge aresetn)
	if(~aresetn)
		state <= STATE_IDLE;
	else
		state <= nstate;

    always@(*)
	case(state)
		STATE_IDLE:
			if(req)
				nstate = STATE_WRITE_AW;
			else
				nstate = STATE_IDLE;
		STATE_WRITE_AW:
                    if (awready)
                        nstate = STATE_WRITE_W;
                    else 
			nstate = STATE_WRITE_AW;	
		STATE_WRITE_W:
		    if(wready)
			nstate = STATE_WRITE_B;
		    else
			nstate = STATE_WRITE_W;
		STATE_WRITE_B:
		    if(bvalid)
			nstate =  STATE_IDLE;
		    else
			nstate =  STATE_WRITE_B;
			
	endcase

    always@(posedge aclk or negedge aresetn)
	if(~aresetn) begin
		awaddr <= 'd0;
		wdata <= 'd0;
		wstrb <= 'd0;
	end
	else
		if( (state == STATE_IDLE) & req) begin
			awaddr <= req_addr;
			wdata <=  req_wdata;
			wstrb <=  req_wbe;			
		end



endmodule

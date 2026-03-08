module read_req_to_axi(
    input		req,
    input [31:0]	req_addr,
    output		req_ready,
    output [31:0]	req_rdata,
    output		req_rvalid,
    input		req_rready,
    input		flush,
    // 
    input               aclk,
    input               aresetn,	
    // AXI4 Read Address Channel (Instruction Fetch AXI)
    output     [31:0]   araddr,
    output     [7:0]    arlen,
    output     [2:0]    arsize,
    output     [1:0]    arburst,
    output              arvalid,
    input               arready,
    
    // AXI4 Read Data Channel (Instruction Fetch AXI)
    input  [31:0]       rdata,
    input  [1:0]        rresp,
    input               rlast,
    input               rvalid,
    output           	rready
);

    // State machine states
    localparam STATE_IDLE = 2'b00;
    localparam STATE_AR   = 2'b01;  // Address Ready - waiting for ARREADY
    localparam STATE_R    = 2'b10;  // Read - waiting for RVALID
    localparam STATE_HOLD = 2'b11;  // Dst unit not Ready 
    // AXI parameters
    localparam AXI_ARLEN_SINGLE = 8'h0;      // Single beat transfer
    localparam AXI_ARSIZE_WORD  = 3'b010;    // 4 bytes (32 bits)
    localparam AXI_ARBURST_INCR = 2'b01;     // Incrementing burst
    // Internal state
    reg [1:0] state, nstate;
    reg r_flush;
    reg [31:0] r_data_hold;
    reg [31:0] r_araddr;
    wire pipe_flush = r_flush | flush;
    assign araddr = r_araddr;
    assign arlen = AXI_ARLEN_SINGLE;
    assign arsize = AXI_ARSIZE_WORD;
    assign arburst = AXI_ARBURST_INCR;
    assign rready = (state == STATE_AR | state == STATE_R);
    assign req_ready = (state == STATE_IDLE);
    assign req_rdata = (state == STATE_HOLD)?r_data_hold: rdata;
    assign req_rvalid = ((state == STATE_R & rvalid) & ~pipe_flush & req_rready) | (state == STATE_HOLD); 
    assign arvalid = (state == STATE_AR);
    always@(posedge aclk)
        if(state == STATE_IDLE & req & ~flush)
            r_araddr <= req_addr;
    always@(posedge aclk or negedge aresetn)
	if(~aresetn) begin
		state <= STATE_IDLE;
	end
	else begin
		state <= nstate;
	end

    always@(*)
	case(state)
		default://STATE_IDLE
			if(req & ~flush)
				nstate = STATE_AR;
			else
				nstate = STATE_IDLE;
		STATE_AR:
			if(arready)
				nstate = STATE_R;
			else
				nstate = STATE_AR;
		STATE_R:
			if(~req_rready & rvalid)
				nstate = STATE_HOLD;
			else if(rvalid & rlast)
				nstate = STATE_IDLE;
			else
				nstate = STATE_R;
		STATE_HOLD:
			if(req_rready)
				nstate = STATE_IDLE;
			else
				nstate = STATE_HOLD;
	endcase
/*
    always@(posedge aclk or negedge aresetn)
	if(~aresetn)
		arvalid <= 1'b0;
	else 
		if(state == STATE_IDLE)
			arvalid <= req;
		else if(state == STATE_AR & arready)
			arvalid <= 1'b0;
*/
    always@(posedge aclk or negedge aresetn)
	if(~aresetn) begin
		r_flush <= 1'b0;
		r_data_hold <= 32'd0;
	end
	else begin 
		if(state == STATE_IDLE)
			r_flush <= 1'b0;
		else if((state == STATE_AR | state == STATE_R) & flush)
			r_flush <= 1'b1;

		if(state == STATE_R & ~req_rready & rvalid)
			r_data_hold <= rdata;
	end
endmodule

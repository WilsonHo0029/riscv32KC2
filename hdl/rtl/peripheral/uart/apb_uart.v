module apb_uart #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
)(
    input               clk,
    input               rst_n,

    // APB Slave Interface
    input  [ADDR_WIDTH-1:0] paddr,
    input               psel,
    input               penable,
    input               pwrite,
    input  [DATA_WIDTH-1:0] pwdata,
    output reg [DATA_WIDTH-1:0] prdata,
    output              pready,
    output              pslverr,

    // UART Signals
    input               uart_rxd,
    output              uart_txd,
    output              uart_irq
);
    assign pready  = 1'b1;
    assign pslverr = 1'b0;
    assign uart_irq = 1'b0;
    // --- Register Offsets ---
    localparam R_TXBUF = 3'h0;
    localparam R_CTRL  = 3'h1;
    localparam R_RXBUF = 3'h2;
    localparam R_BAUD  = 3'h3;

    // --- Internal Registers ---
    reg         tx_en;
    wire        tx_busy;
    reg [15:0]  baud_cnt;  // DLL (bits 7:0) + DLM (bits 15:8)
    wire [2:0]  reg_idx = paddr[4:2];  // Word-aligned indexing
    wire        pwr_en = psel & penable & pwrite;
    wire	prd_en = psel & penable & ~pwrite;
    reg		rx_en;
    wire	rx_busy;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_en <= 1'b0;
	    rx_en <= 1'b0;
            baud_cnt <= 'd0;
        end else begin
            tx_en <= (reg_idx == R_CTRL & pwr_en) ? pwdata[0] : tx_en;
	    rx_en <= (reg_idx == R_CTRL & pwr_en) ? pwdata[1] : rx_en;
            baud_cnt <= (reg_idx == R_BAUD & pwr_en) ? pwdata[15:0] : baud_cnt;
        end
    end
    wire        tx_fifo_push = (reg_idx == R_TXBUF & pwr_en);
    wire        tx_fifo_full;
    wire        tx_fifo_empty;
    wire [7:0]  tx_fifo_data_o;
    wire        tx_fifo_pop;

    wire        rx_fifo_push;
    wire        rx_fifo_full;
    wire        rx_fifo_empty;
    wire [7:0]  rx_fifo_data_o;
    wire        rx_fifo_pop = (reg_idx == R_RXBUF & prd_en);
    wire [7:0]  rx_data;
    sync_fifo #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH(16),
        .ADDR_WIDTH(4)  // Log2 of FIFO_DEPTH
    ) u_tx_fifo (
        .clk     (clk),
        .rst_n   (rst_n),
        .srst    (1'b0),
        // Write Interface
        .push    (tx_fifo_push),
        .data_i  (pwdata[7:0]),  // Input data
        .full    (tx_fifo_full), // FIFO is full
        
        // Read Interface
        .pop     (tx_fifo_pop),
        .data_o  (tx_fifo_data_o), // Output data
        .empty   (tx_fifo_empty)    // FIFO is empty
    );

    uart_tx u_tx (
        .clk        (clk),
        .rst_n      (rst_n),
        
        .tx_en      (tx_en),
        .fifo_empty (tx_fifo_empty),
        .data       (tx_fifo_data_o),
        .baud_cnt   (baud_cnt),
        .parity_en  (1'b0),
        .parity_e   (1'b0),
        .fifo_pop   (tx_fifo_pop),
        .tx_busy    (tx_busy),
        
        .uart_txd   (uart_txd)
    );

    sync_fifo #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH(16),
        .ADDR_WIDTH(4)  // Log2 of FIFO_DEPTH
    ) u_rx_fifo (
        .clk     (clk),
        .rst_n   (rst_n),
        .srst    (1'b0),
        // Write Interface
        .push    (rx_fifo_push),
        .data_i  (rx_data),  // Input data
        .full    (rx_fifo_full), // FIFO is full
        
        // Read Interface
        .pop     (rx_fifo_pop),
        .data_o  (rx_fifo_data_o), // Output data
        .empty   (rx_fifo_empty)    // FIFO is empty
    );
  
    uart_rx u_rx(
   	.clk		(clk),
    	.rst_n		(rst_n),
    
    	.rx_en		(1'b1),
    	.fifo_full	(rx_fifo_full),
    	.data		(rx_data),
    	.baud_cnt	(baud_cnt),
    	.parity_en	(1'b0),
    	.parity_e	(1'b0),  // 1=even, 0=odd
    	.fifo_push	(rx_fifo_push),
    	.rx_busy	(rx_busy),
    
 	.uart_rxd	(uart_rxd)
    );
    always @(*) begin
        case (reg_idx)
            R_TXBUF: prdata = {24'd0, tx_fifo_data_o};
            R_CTRL:  prdata = {16'd0, {tx_fifo_full, tx_busy, tx_fifo_empty, 
				       rx_fifo_full, rx_busy, rx_fifo_empty, 
				       8'd0, rx_en, tx_en}};
            R_RXBUF: prdata = {24'd0, rx_fifo_data_o};
            R_BAUD:  prdata = {16'd0, baud_cnt};
            default: prdata = 32'h0;
        endcase
    end

endmodule


module uart_tx (
    input               clk,
    input               rst_n,
    
    input               tx_en,
    input               fifo_empty,
    input [7:0]         data,
    input [15:0]        baud_cnt,
    input               parity_en,
    input               parity_e,  // 1=even, 0=odd
    output              fifo_pop,
    output              tx_busy,
    
    output reg          uart_txd
);
    
    localparam S_IDLE   = 2'b00;
    localparam S_DATA   = 2'b01;
    localparam S_PARITY = 2'b10;
    localparam S_STOP   = 2'b11;
    
    reg [1:0]   state, nstate;
    reg [8:0]   sbf_buf;
    reg [15:0]  clk_cnt;
    reg [3:0]   bit_cnt;
    
    wire        clk_cnt_end = (clk_cnt >= baud_cnt);
    wire        parity = 1'b0;
    
    assign fifo_pop = (clk_cnt_end & state == S_STOP);
    assign tx_busy = (state != S_IDLE || (state == S_IDLE & tx_en & ~fifo_empty));
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= nstate;
        end
    end
    
    always @(*) begin
        case (state)
            S_IDLE: begin
                if (tx_en & ~fifo_empty) begin
                    nstate = S_DATA;
                end else begin
                    nstate = S_IDLE;
                end
            end
            S_DATA: begin
                if (bit_cnt[3] & parity_en & clk_cnt_end) begin
                    nstate = S_PARITY;
                end else if (bit_cnt[3] & clk_cnt_end) begin
                    nstate = S_STOP;
                end else begin
                    nstate = S_DATA;
                end
            end
            S_PARITY: begin
                if (clk_cnt_end) begin
                    nstate = S_STOP;
                end else begin
                    nstate = S_PARITY;
                end
            end
            S_STOP: begin
                if (clk_cnt_end) begin
                    nstate = S_IDLE;
                end else begin
                    nstate = S_STOP;
                end
            end
            default: nstate = S_IDLE;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            clk_cnt <= 'd0;
        end else if (state == S_IDLE || clk_cnt >= baud_cnt) begin
            clk_cnt <= 'd0;
        end else if (state != S_IDLE) begin
            clk_cnt <= clk_cnt + 1;
        end
    end
    
    always @(posedge clk) 
        if (state == S_IDLE)
            bit_cnt <= 'd0;
        else if (state == S_DATA & clk_cnt_end)
            bit_cnt <= bit_cnt + 1;
       
    
    always @(posedge clk)
        if (state == S_IDLE & tx_en & ~fifo_empty)
            sbf_buf <= {data, 1'b0};
        else if (state == S_DATA & clk_cnt_end) begin
            sbf_buf[7] <= 1'b0;
            sbf_buf[6:0] <= sbf_buf[7:1];
        end
   
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            uart_txd <= 1'b1;
        end else if (state == S_IDLE) begin
            uart_txd <= 1'b1;
        end else if (state == S_DATA) begin
            uart_txd <= sbf_buf[0];
        end else if (state == S_PARITY) begin
            uart_txd <= parity;  // Not yet implemented
        end else begin  // STOP state
            uart_txd <= 1'b1;
        end
    end
    
endmodule


module uart_rx (
    input               clk,
    input               rst_n,
    
    input               rx_en,
    input               fifo_full,
    output [7:0]    	data,
    input [15:0]        baud_cnt,
    input               parity_en,
    input               parity_e,  // 1=even, 0=odd
    output              fifo_push,
    output              rx_busy,
    
    input	        uart_rxd
);

    localparam S_IDLE   = 2'b00;
    localparam S_DATA   = 2'b01;
    localparam S_PARITY = 2'b10;
    localparam S_STOP   = 2'b11;

    reg [1:0]   state, nstate;
    reg [8:0]   sbf_buf;
    reg [15:0]  clk_cnt;
    reg [3:0]   bit_cnt;
    reg		r_rxd_i;
    wire        clk_cnt_end = (clk_cnt >= baud_cnt);
    wire        rx_data_cap = (clk_cnt == {1'b0, baud_cnt[14:1]});

    assign rx_busy = (state != S_IDLE || (state == S_IDLE & rx_en & ~r_rxd_i & ~fifo_full));
    assign data =  sbf_buf[8:1];
    assign fifo_push = (state == S_STOP & clk_cnt_end);
    always@(posedge clk or negedge rst_n)
	if(~rst_n)
		r_rxd_i <= 1'b1;
	else
		r_rxd_i <= uart_rxd;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= nstate;
        end
    end

   always@(*)
	case(state)
		S_IDLE:
			if(rx_en & ~r_rxd_i & ~fifo_full)
				nstate = S_DATA;
			else
				nstate = S_IDLE;
		S_DATA: begin
			if(bit_cnt == 4'd0 & sbf_buf[8] & clk_cnt_end)
				nstate = S_IDLE;
               		else if (bit_cnt[3] & parity_en & clk_cnt_end)
                   		nstate = S_PARITY;
                	else if (bit_cnt[3] & clk_cnt_end)
                    		nstate = S_STOP;
                	else
                    		nstate = S_DATA;
            	end	
		S_PARITY:begin
                	if (clk_cnt_end) begin
                    		nstate = S_STOP;
                	end else begin
                    		nstate = S_PARITY;
                	end
            	end
		S_STOP:begin
                	if (clk_cnt_end) begin
                    		nstate = S_IDLE;
                	end else begin
                    		nstate = S_STOP;
               		end
            	end	
	endcase

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            clk_cnt <= 'd0;
        end else if (state == S_IDLE || clk_cnt >= baud_cnt) begin
            clk_cnt <= 'd0;
        end else if (state != S_IDLE) begin
            clk_cnt <= clk_cnt + 1;
        end
    end
    
    always @(posedge clk) 
        if (state == S_IDLE)
            bit_cnt <= 'd0;
        else if (state == S_DATA & clk_cnt_end)
            bit_cnt <= bit_cnt + 1;
       

   always@(posedge clk)
	if(state == S_DATA & rx_data_cap) begin
		sbf_buf[8] <= r_rxd_i;
		sbf_buf[7:0] <= sbf_buf[8:1];
	end
	

			
endmodule

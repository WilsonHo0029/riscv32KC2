//------------------------------------------------------------------------------
// Module: sync_fifo
// Purpose: Synchronous FIFO with push/full and pop/empty status ports.
//          Internal count register used for status logic.
//------------------------------------------------------------------------------

module sync_fifo #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16,
    parameter ADDR_WIDTH = 4  // Log2 of FIFO_DEPTH
)(
    input  	                   clk,
    input                        rst_n,
	input					  srst,
    // Write Interface
    input                     push,
    input   [DATA_WIDTH-1:0]  data_i,     // Input data
    output                    full,       // FIFO is full

    // Read Interface
    input                     pop,
    output  [DATA_WIDTH-1:0]  data_o,     // Output data
    output                    empty       // FIFO is empty
);

    //--------------------------------------------------------------------------
    // Internal Signals
    //--------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    //--------------------------------------------------------------------------
    // Status Logic
    //--------------------------------------------------------------------------
    wire [ADDR_WIDTH-1:0] nxt_wr_ptr = wr_ptr + 1;
    assign full  = (nxt_wr_ptr == rd_ptr);
    assign empty = (wr_ptr == rd_ptr);

    //--------------------------------------------------------------------------
    // Output Data (First-Word Fall-Through)
    //--------------------------------------------------------------------------
    assign data_o = mem[rd_ptr];

    //--------------------------------------------------------------------------
    // Control Logic
    //--------------------------------------------------------------------------
    wire do_push = push && !full;
    wire do_pop  = pop && !empty;
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
        end else begin
            if(do_push)
                wr_ptr <= nxt_wr_ptr;
        end
    end

    always @(posedge clk) begin
          if(do_push)
               mem[wr_ptr] <= data_i;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= {ADDR_WIDTH{1'b0}};
        end else begin
            if(do_pop)
                rd_ptr <= rd_ptr + 1;
        end
    end    
endmodule









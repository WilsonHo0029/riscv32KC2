// Clock Domain Crossing Receiver (4-phase to standard handshake)
// Converts asynchronous 4-phase handshake to synchronous standard handshake
// Input: Async 4-phase handshake (i_vld_a, i_rdy, i_dat)
// Output: Sync standard handshake (o_vld, o_rdy, o_dat)
// Clocked by destination clock domain

module buf_cdc_rx #(
    parameter DW = 32  // Data width
)(
    // Async input (4-phase handshake from source clock domain)
    input               i_vld_a, 
    output reg          i_rdy, 
    input  [DW-1:0]     i_dat,
    
    // Sync output (standard handshake to destination clock domain)
    output              o_vld, 
    input               o_rdy, 
    output [DW-1:0]     o_dat,
    
    // Clock and reset (destination clock domain)
    input               clk,
    input               rst_n 
);

    //----------------------------------------------------------------------------
    // Internal Signals
    //----------------------------------------------------------------------------
    // 3-flop synchronizer for async valid signal
    reg i_vld_sync0, i_vld_sync1, i_vld_sync2;
    wire i_vld_sync = i_vld_sync1;
    wire i_vld_sync_nedge = (~i_vld_sync1) & i_vld_sync2;
    
    // Buffer control
    reg buf_valid;
    reg [DW-1:0] buf_dat;
    wire buf_rdy = ~buf_valid;
    wire i_rdy_set = ~i_rdy & i_vld_sync & buf_rdy;
    
    //----------------------------------------------------------------------------
    // Synchronizer for Async Valid Signal
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            i_vld_sync0 <= 1'b0;
            i_vld_sync1 <= 1'b0;
            i_vld_sync2 <= 1'b0;
        end else begin
            i_vld_sync0 <= i_vld_a;
            i_vld_sync1 <= i_vld_sync0;	
            i_vld_sync2 <= i_vld_sync1;
        end
    end
    
    //----------------------------------------------------------------------------
    // Ready Signal (4-phase handshake)
    //----------------------------------------------------------------------------
    // i_rdy is set (assert to high) when the buf is ready (can save data) and incoming valid detected
    // i_rdy is cleared when i_vld neg-edge is detected
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            i_rdy <= 1'b0;
        end else begin
            if (i_rdy_set) begin
                i_rdy <= 1'b1;
            end else if (i_vld_sync_nedge) begin
                i_rdy <= 1'b0;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Data Buffer
    //----------------------------------------------------------------------------
    // Buffer is loaded with data when i_rdy is set high
    // (i.e., when the buf is ready and incoming valid detected)
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            buf_dat <= {DW{1'b0}};
        end else begin
            if (i_rdy_set) begin
                buf_dat <= i_dat;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Valid Signal (standard handshake)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            buf_valid <= 1'b0;
        end else begin
            if (i_rdy_set) begin
                buf_valid <= 1'b1;
            end else if (o_rdy & buf_valid) begin
                buf_valid <= 1'b0;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Output Assignments
    //----------------------------------------------------------------------------
    assign o_vld = buf_valid;
    assign o_dat = buf_dat;
    
endmodule

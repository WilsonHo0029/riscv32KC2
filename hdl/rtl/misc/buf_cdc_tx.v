// Clock Domain Crossing Transmitter (standard to 4-phase handshake)
// Converts synchronous standard handshake to asynchronous 4-phase handshake
// Input: Sync standard handshake (i_vld, i_rdy, i_dat)
// Output: Async 4-phase handshake (o_vld, o_rdy_a, o_dat)
// Clocked by source clock domain
//
// 4-phase handshake steps:
//   (1) o_vld is asserted high
//   (2) o_rdy_a is asserted high
//   (3) o_vld is asserted low
//   (4) o_rdy_a is asserted low

module buf_cdc_tx #(
    parameter DW = 32  // Data width
)(
    // Sync input (standard handshake from source clock domain)
    input               i_vld, 
    output              i_rdy, 
    input  [DW-1:0]     i_dat,
    
    // Async output (4-phase handshake to destination clock domain)
    output              o_vld, 
    input               o_rdy_a, 
    output [DW-1:0]     o_dat,
    
    // Clock and reset (source clock domain)
    input               clk,
    input               rst_n 
);

    //----------------------------------------------------------------------------
    // Internal Signals
    //----------------------------------------------------------------------------
    // 3-flop synchronizer for async ready signal
    reg o_rdy_sync0, o_rdy_sync1, o_rdy_sync2;
    wire o_rdy_sync = o_rdy_sync1;
    wire o_rdy_nedge = ~o_rdy_sync1 & o_rdy_sync2;
    
    // Control registers
    reg vld;
    reg i_rdy_r;
    reg [DW-1:0] buf_dat;
    
    //----------------------------------------------------------------------------
    // Synchronizer for Async Ready Signal
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            o_rdy_sync0 <= 1'b0;
            o_rdy_sync1 <= 1'b0;
            o_rdy_sync2 <= 1'b0;
        end else begin
            o_rdy_sync0 <= o_rdy_a;
            o_rdy_sync1 <= o_rdy_sync0;
            o_rdy_sync2 <= o_rdy_sync1;
        end
    end
    
    //----------------------------------------------------------------------------
    // Valid Signal (4-phase handshake output)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            vld <= 1'b0;
        end else begin
            if (i_vld & i_rdy_r) begin
                vld <= 1'b1;
            end else if (vld & o_rdy_sync) begin
                vld <= 1'b0;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Data Buffer
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            buf_dat <= {DW{1'b0}};
        end else begin
            if (i_vld & i_rdy_r) begin
                buf_dat <= i_dat;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Ready Signal (standard handshake input)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            i_rdy_r <= 1'b1;
        end else begin
            if (vld) begin
                i_rdy_r <= 1'b0;
            end else if (o_rdy_nedge) begin
                i_rdy_r <= 1'b1;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Output Assignments
    //----------------------------------------------------------------------------
    assign i_rdy = i_rdy_r | o_rdy_nedge;
    assign o_vld = vld;
    assign o_dat = buf_dat;
    
endmodule

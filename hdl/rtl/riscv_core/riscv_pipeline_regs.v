module riscv_pipeline_regs #(
    parameter DW = 32,
    parameter INITIAL_VALUE = {DW{1'b0}}
) (
    input               clk,
    input               rstn,
    
    input               flush,
    input               stall, 
    
    input      [DW-1:0] data_i,

    output     [DW-1:0] data_o
);
    reg [DW-1:0] r_data;
    assign data_o = r_data;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_data <= INITIAL_VALUE;
        end else begin
            if (flush)
                r_data <= INITIAL_VALUE;
            else if(~stall)
                r_data <= data_i;
        end
    end


endmodule

module riscv_iram_arbit(
    input               clk,
    input               rst_n,
    
    input  [31:0]       iram_from_data_addr,
    input               iram_from_data_cs,
    input               iram_from_data_we,
    input  [3:0]        iram_from_data_wem,
    input  [31:0]       iram_from_data_din, 
    output   [31:0]     iram_from_data_dout,
    output reg          iram_from_data_rready,
    output  reg         iram_from_data_rvalid,
    
    input  [31:0]       iram_from_ifetch_addr,
    input               iram_from_ifetch_cs,
    output [31:0]       iram_from_ifetch_dout,
    output reg          iram_from_ifetch_rready,
    output reg          iram_from_ifetch_rvalid,   
    
    output reg  [31:0]      iram_addr,
    output reg              iram_cs,
    output                  iram_we,
    output      [3:0]       iram_wem,
    output      [31:0]      iram_din, 
    input       [31:0]      iram_dout  
);
assign iram_we = iram_from_data_we & iram_from_data_cs;
assign iram_wem = iram_from_data_wem;
assign iram_din = iram_from_data_din;
assign iram_from_data_dout = iram_dout;
assign iram_from_ifetch_dout = iram_dout;
always@(*) begin
        if(iram_from_data_cs & iram_from_data_we) begin
               iram_addr = iram_from_data_addr;
               iram_cs  = iram_from_data_cs;
               iram_from_data_rready = 1'b1;
               iram_from_ifetch_rready = 1'b0;
        end
        else if(iram_from_data_cs & ~iram_from_data_we) begin
               iram_addr = iram_from_data_addr;
               iram_cs  = iram_from_data_cs;        
               iram_from_data_rready = 1'b1;
               iram_from_ifetch_rready = 1'b0;        
        end
        else begin
               iram_addr = iram_from_ifetch_addr;
               iram_cs = iram_from_ifetch_cs;
               iram_from_data_rready = 1'b1;
               iram_from_ifetch_rready = 1'b1;               
        end

end

always@(posedge clk or negedge rst_n)
    if(~rst_n) begin
        iram_from_data_rvalid <= 1'b0;
        iram_from_ifetch_rvalid <= 1'b0;
    end
    else begin
        iram_from_data_rvalid <= iram_from_data_cs & ~iram_from_data_we & iram_from_data_rready;
        iram_from_ifetch_rvalid <= iram_from_ifetch_cs & iram_from_ifetch_rready;    
    end

endmodule
// AXI Lite Wrapper for MROM (Boot ROM)
// Converts AXI Lite interface to mrom module interface
// Address Region: 0x0000_1000 - 0x0000_7FFF (28 KB address space)
// Actual ROM Size: 256 bytes (64 words)

module mrom_axi_lite #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ROM_BASE_ADDR = 32'h00001000,  // ROM base address
    parameter ROM_ADDR_SIZE = 32'h00007000,  // ROM address space size (28 KB)
    parameter ROM_SIZE = 32'h00000100,        // Actual ROM size (256 bytes = 64 words)
    parameter ROM_AW = 12,                    // ROM address width
    parameter ROM_DW = 32,                    // ROM data width
    parameter ROM_DP = 64                     // ROM depth (64 words = 256 bytes)
)(
    // Clock and Reset
    input               aclk,
    input               aresetn,
    
    // AXI Lite Slave Interface (Read-Only)
    // Read Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_araddr,
    input               s_axi_arvalid,
    output              s_axi_arready,
    
    // Read Data Channel
    output reg [DATA_WIDTH-1:0] s_axi_rdata,
    output reg [1:0]    s_axi_rresp,
    output reg          s_axi_rvalid,
    input               s_axi_rready
);

    //----------------------------------------------------------------------------
    // Address Decode Functions
    //----------------------------------------------------------------------------
    function is_in_address_space;
        input [ADDR_WIDTH-1:0] addr;
        begin
            is_in_address_space = (addr >= ROM_BASE_ADDR) && 
                                  (addr < (ROM_BASE_ADDR + ROM_ADDR_SIZE));
        end
    endfunction
    
    function is_in_rom;
        input [ADDR_WIDTH-1:0] addr;
        begin
            is_in_rom = (addr >= ROM_BASE_ADDR) && 
                       (addr < (ROM_BASE_ADDR + ROM_SIZE));
        end
    endfunction

    //----------------------------------------------------------------------------
    // ROM Instance
    //----------------------------------------------------------------------------
    reg  [ADDR_WIDTH-1:0] araddr_reg;
    wire [ROM_AW-1:2] rom_word_addr = araddr_reg[ROM_AW-1:2];
    wire [ROM_DW-1:0] rom_data;

    mrom #(
        .ADDR_WIDTH(ROM_AW),
        .DATA_WIDTH(ROM_DW),
        .DEPTH(ROM_DP)
    ) u_mrom (
        .rom_addr(rom_word_addr),
        .clk(aclk),
        .rom_dout(rom_data)
    );
	wire is_in_arom = (araddr_reg >= ROM_BASE_ADDR) &&  (araddr_reg < (ROM_BASE_ADDR + ROM_SIZE));
    //----------------------------------------------------------------------------
    // AXI Lite Read Logic
    //----------------------------------------------------------------------------
    localparam RD_IDLE = 1'b0;
    localparam RD_RESP = 1'b1;
    reg read_state;
    assign s_axi_arready = (read_state == RD_IDLE);
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            araddr_reg    <= {ADDR_WIDTH{1'b0}};
            read_state    <= RD_IDLE;
        end else begin
            case (read_state)
                RD_IDLE: begin
		    s_axi_rvalid <= 1'b0;
                    if (s_axi_arvalid) begin
                        araddr_reg    <= s_axi_araddr;
                        read_state    <= RD_RESP;
                    end
                end
                RD_RESP: begin
                    s_axi_rvalid  <= 1'b1;
                    // Check if address is valid and within ROM
                    if (is_in_arom) begin
                        s_axi_rdata <= rom_data;
                        s_axi_rresp <= 2'b00; // OKAY
                    end else begin
                        s_axi_rdata <= {DATA_WIDTH{1'b0}};
                        s_axi_rresp <= 2'b11; // DECERR
                    end
                    
                    if (s_axi_rready) begin
                    
                        read_state   <= RD_IDLE;
                    end
                end
            endcase
        end
    end

endmodule

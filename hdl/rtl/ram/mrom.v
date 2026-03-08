// Boot ROM Module
// Read-only memory containing minimal bootloader code
// Size: 64 words (256 bytes)

module mrom #(
    parameter ADDR_WIDTH = 12,     // Address width
    parameter DATA_WIDTH = 32,     // Data width
    parameter DEPTH = 64            // Depth in words (64 words = 256 bytes)
)(
    input  [ADDR_WIDTH-1:2] rom_addr,  // Word address input (bits [ADDR_WIDTH-1:2])
    input                   clk,       // Clock (not used - combinational)
    output reg [DATA_WIDTH-1:0] rom_dout   // Data output
);

    //----------------------------------------------------------------------------
    // Constants
    //----------------------------------------------------------------------------
    // Bootloader instruction constants
    localparam [31:0] BOOT_INST_0 = 32'h7ffff297;  // AUIPC t0, 0x7ffff
    localparam [31:0] BOOT_INST_1 = 32'h00028067;  // JALR x0, t0, 0
    localparam [31:0] ROM_ZERO    = 32'h00000000;  // Zero for unused addresses
    
    // Address constants
    localparam [9:0] ROM_ADDR_0 = 10'd0;  // First bootloader instruction
    localparam [9:0] ROM_ADDR_1 = 10'd1;  // Second bootloader instruction
    
    //----------------------------------------------------------------------------
    // ROM Content (Combinational Read)
    //----------------------------------------------------------------------------
    always @(*) begin
        case (rom_addr)
            ROM_ADDR_0: rom_dout = BOOT_INST_0;  // AUIPC t0, 0x7ffff
            ROM_ADDR_1: rom_dout = BOOT_INST_1;  // JALR x0, t0, 0
		 10'd2: rom_dout = 32'h0000006F; // J .
            // Unused ROM space (addresses 2-63)
            default: rom_dout = ROM_ZERO;
        endcase
    end

endmodule

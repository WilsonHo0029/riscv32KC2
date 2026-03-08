// RISC-V AXI Instruction Fetch Interface
// AXI4 Master for instruction fetch
// Uses absolute PC addresses directly
// Can fallback to data AXI interface for other address spaces (e.g., Boot ROM)
//
// Address Routing:
//   - Instruction RAM (0x7000_0000 - 0x8FFF_FFFF): Uses instruction fetch AXI directly
//   - Boot ROM (0x0000_1000 - 0x0000_7FFF): Uses data AXI -> APB -> Boot ROM
//   - Other addresses: Uses data AXI -> APB -> appropriate peripheral
//
// Features:
//   - Instruction fetch via AXI4 interface
//   - Fallback to data AXI for Boot ROM and other peripherals

`include "riscv_defines.v"

module riscv_axi_ifetch #(
    parameter INSTR_RAM_BASE = 32'h70000000,  // Instruction RAM base address
    parameter INSTR_RAM_SIZE = 32'h20000000   // Instruction RAM size (512 MB)
)(
    input               clk,
    input               rst_n,
    
    // Core interface
    input  [31:0]       ifetch_addr,
    input               ifetch_rvalid,
    output [31:0]       instr_i,
    output              instr_rvalid,
    output              ifu_ready,
    input               instr_rready,
    input               flush,
   // I-SRAM interface
   
    output [31:0]       isram_addr,
    output              isram_cs,
    input  [31:0]       isram_dout,
    input               isram_rready,
    input               isram_rvalid,   
    // AXI4 Read Address Channel (Instruction Fetch AXI)
    output [31:0]       araddr,
    output [7:0]        arlen,
    output [2:0]        arsize,
    output [1:0]        arburst,
    output              arvalid,
    input               arready,
    
    // AXI4 Read Data Channel (Instruction Fetch AXI)
    input  [31:0]       rdata,
    input  [1:0]        rresp,
    input               rlast,
    input               rvalid,
    output              rready
);
    wire        is_iram = (ifetch_addr[31:28]==4'h8);
    assign      isram_addr = ifetch_addr;
    assign      isram_cs = ifetch_rvalid & is_iram & ~flush;
    wire        axi_instr_req = ifetch_rvalid & ~is_iram & ~flush;
    wire        axi_instr_ready;
    wire [31:0] axi_instr_rdata;
    wire        axi_instr_rvalid;

    assign instr_rvalid = (is_iram)?  isram_rvalid : axi_instr_rvalid;
    assign ifu_ready = (is_iram)? isram_rready : axi_instr_ready;
    assign instr_i = (is_iram)? isram_dout : axi_instr_rdata;
    
    read_req_to_axi u_instr_axi (
        .req        (axi_instr_req),
        .req_addr   (ifetch_addr),
        .req_ready  (axi_instr_ready),
        .req_rdata  (axi_instr_rdata),
        .req_rvalid (axi_instr_rvalid),
        .req_rready (instr_rready),
        .flush      (flush),

        .aclk       (clk),
        .aresetn    (rst_n),
        // AXI4 Read Address Channel (Instruction Fetch AXI)
        .araddr     (araddr),
        .arlen      (arlen),
        .arsize     (arsize),
        .arburst    (arburst),
        .arvalid    (arvalid),
        .arready    (arready),

        // AXI4 Read Data Channel (Instruction Fetch AXI)
        .rdata      (rdata),
        .rresp      (rresp),
        .rlast      (rlast),
        .rvalid     (rvalid),
        .rready     (rready)
    );


endmodule


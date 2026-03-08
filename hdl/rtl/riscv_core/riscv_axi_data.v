// RISC-V AXI Data Access Interface
// AXI4 Master for load/store operations
// Also supports instruction fetch fallback requests (e.g., Boot ROM access)
//
// Instruction Fetch Support:
//   - When instruction fetch unit requests access to non-instruction-RAM addresses
//   - Routes through AXI -> APB splitter -> APB decoder -> appropriate peripheral
//   - Boot ROM (0x0000_1000) is accessible via this path

module riscv_axi_data (
    input               clk,
    input               rst_n,
    
    // Core interface (data memory access)
    input               mem_req,
    input               mem_we,
    input  [31:0]       mem_addr,
    input  [31:0]       mem_wdata,
    input  [3:0]        mem_be,      // Byte enable
    output [31:0]       mem_rdata,
    output              mem_ready,
    output              mem_rvalid,  // Read data valid signal
    // D-SRAM interface
    output  [31:0]      dsram_addr,
    output              dsram_cs,
    output              dsram_we,
    output  [3:0]       dsram_wem,
    output  [31:0]      dsram_din, 
    input   [31:0]      dsram_dout,    
    // I-SRAM interface
    output  [31:0]      isram_addr,
    output              isram_cs,
    output              isram_we,
    output  [3:0]       isram_wem,
    output  [31:0]      isram_din, 
    input   [31:0]      isram_dout,  
    input               isram_rready,  
    input               isram_rvalid,   
    // AXI4 Write Address Channel
    output    [31:0]    awaddr,
    output    [7:0]     awlen,
    output    [2:0]     awsize,
    output    [1:0]     awburst,
    output              awvalid,
    input               awready,
    
    // AXI4 Write Data Channel
    output    [31:0]    wdata,
    output     [3:0]    wstrb,
    output              wlast,
    output              wvalid,
    input               wready,
    
    // AXI4 Write Response Channel
    input  [1:0]        bresp,
    input               bvalid,
    output              bready,
    
    // AXI4 Read Address Channel
    output     [31:0]   araddr,
    output     [7:0]    arlen,
    output     [2:0]    arsize,
    output     [1:0]    arburst,
    output              arvalid,
    input               arready,
    
    // AXI4 Read Data Channel
    input  [31:0]       rdata,
    input  [1:0]        rresp,
    input               rlast,
    input               rvalid,
    output              rready
);

    wire write_axi_ready;
    wire read_axi_ready;
    wire [31:0] axi_rdata;
    wire        axi_rvalid;
    wire        is_dsram =  (mem_addr[31:28] == 4'h9);
    assign dsram_addr = mem_addr;
    assign dsram_cs = mem_req & is_dsram;
    assign dsram_we = mem_we;
    assign dsram_wem = mem_be;
    assign dsram_din = mem_wdata;
    
    wire        is_isram =  (mem_addr[31:28] == 4'h8);
    assign isram_addr = mem_addr;
    assign isram_cs = mem_req & is_isram;
    assign isram_we = mem_we;
    assign isram_wem = mem_be;
    assign isram_din = mem_wdata;    
    
    reg dsram_rvalid;
    always@(posedge clk or negedge rst_n)
        if(~rst_n)
            dsram_rvalid <= 1'b0;
        else
            dsram_rvalid <= mem_req & is_dsram & ~mem_we;
            
    wire        axi_r_req = (mem_req & ~mem_we & ~is_dsram & ~is_isram);
    wire        axi_w_req = (mem_req & mem_we & ~is_dsram & ~is_isram);
    assign mem_ready = (is_dsram)? 1'b1:
                       (is_isram)? isram_rready : (read_axi_ready & write_axi_ready);
    assign mem_rdata = (is_dsram)? dsram_dout : 
                       (is_isram)? isram_dout : axi_rdata;
    assign mem_rvalid = (is_dsram)? dsram_rvalid :
                        (is_isram)? isram_rvalid : axi_rvalid; 

    read_req_to_axi u_instr_axi (
        .req        (axi_r_req),
        .req_addr   (mem_addr),
        .req_ready  (read_axi_ready),
        .req_rdata  (axi_rdata),
        .req_rvalid (axi_rvalid),
        .req_rready (1'b1),
        .flush      (1'b0),

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

    write_req_to_axi u_write_axi (
        .req        (axi_w_req),
        .req_addr   (mem_addr),
        .req_ready  (write_axi_ready),
        .req_wdata  (mem_wdata),
        .req_wbe    (mem_be),
        // 
        .aclk       (clk),
        .aresetn    (rst_n),
        // AXI4 Write Address Channel
        .awaddr     (awaddr),
        .awlen      (awlen),
        .awsize     (awsize),
        .awburst    (awburst),
        .awvalid    (awvalid),
        .awready    (awready),

        // AXI4 Write Data Channel
        .wdata      (wdata),
        .wstrb      (wstrb),
        .wlast      (wlast),
        .wvalid     (wvalid),
        .wready     (wready),

        // AXI4 Write Response Channel
        .bresp      (bresp),
        .bvalid     (bvalid),
        .bready     (bready)
    );

endmodule



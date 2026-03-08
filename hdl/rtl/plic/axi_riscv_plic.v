// Top-level AXI RISC-V PLIC Module
// Converts AXI-Lite interface to riscv_plic module interface
module axi_riscv_plic #(
    parameter HART_NUM = 1,
    parameter PLIC_PRIO_WIDTH = 3,
    parameter PLIC_NUM = 52,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Clock and Reset
    input                    aclk,
    input                    aresetn,

    // AXI Lite Slave Interface
    // Write Address Channel
    input  [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  [2:0]              s_axi_awsize,
    input                     s_axi_awvalid,
    output                    s_axi_awready,

    // Write Data Channel
    input  [DATA_WIDTH-1:0]   s_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                     s_axi_wvalid,
    output                    s_axi_wready,

    // Write Response Channel
    output [1:0]              s_axi_bresp,
    output                    s_axi_bvalid,
    input                     s_axi_bready,

    // Read Address Channel
    input  [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  [2:0]              s_axi_arsize,
    input                     s_axi_arvalid,
    output                    s_axi_arready,

    // Read Data Channel
    output [DATA_WIDTH-1:0]   s_axi_rdata,
    output [1:0]              s_axi_rresp,
    output                    s_axi_rvalid,
    input                     s_axi_rready,

    // External Interrupt Sources Input
    input  [PLIC_NUM-1:0]     ext_irq_src,

    // Interrupt Output to Core
    output [HART_NUM-1:0]     ext_irq
);

    //----------------------------------------------------------------------------
    // Internal Signals
    //----------------------------------------------------------------------------
    wire [ADDR_WIDTH-1:0]     axi_addr;
    wire [23:0]               plic_addr;
    wire                      plic_wr_en;
    wire [31:0]               plic_wdata;
    wire [31:0]               plic_rdata;

    //----------------------------------------------------------------------------
    // AXI Slave to Device Interface Instance
    //----------------------------------------------------------------------------
    axi_slv_to_dev_inf #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_axi_slv_to_dev_inf (
        .aclk          (aclk),
        .aresetn       (aresetn),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awsize  (s_axi_awsize),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arsize  (s_axi_arsize),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),
        .addr          (axi_addr),
        .wr_en         (plic_wr_en),
        .wdata         (plic_wdata),
        .rdata         (plic_rdata)
    );

    // Extract lower 24 bits of address for PLIC (PLIC uses 24-bit addressing)
    assign plic_addr = axi_addr[23:0];

    //----------------------------------------------------------------------------
    // PLIC Instance
    //----------------------------------------------------------------------------
    riscv_plic #(
        .HART_NUM      (HART_NUM),
        .PLIC_PRIO_WIDTH(PLIC_PRIO_WIDTH),
        .PLIC_NUM      (PLIC_NUM)
    ) u_riscv_plic (
        .clk           (aclk),
        .rst_n         (aresetn),
        .plic_addr     (plic_addr),
        .wr_en         (plic_wr_en),
        .wdata         (plic_wdata),
        .rdata         (plic_rdata),
        .ext_irq       (ext_irq_src),
        .irq           (ext_irq)
    );


endmodule




// RISC-V 32KC2 Peripheral Subsystem
// Includes AXI-to-APB bridge, APB decoder, UART peripheral, ADC/DAC interface, and GPIO

module riscv32KC2_peripheral #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter UART_BASE_ADDR = 32'h10000000,
    parameter UART_SIZE      = 32'h00001000
)(
    // Clock and Reset
    input                       clk,
    input                       rst_n,

    // AXI4-Lite Slave Interface (connected to bus m4)
    input  [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  [2:0]                s_axi_awsize,
    input                       s_axi_awvalid,
    output                      s_axi_awready,
    input  [DATA_WIDTH-1:0]     s_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                       s_axi_wvalid,
    output                      s_axi_wready,
    output [1:0]                s_axi_bresp,
    output                      s_axi_bvalid,
    input                       s_axi_bready,
    input  [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  [2:0]                s_axi_arsize,
    input                       s_axi_arvalid,
    output                      s_axi_arready,
    output [DATA_WIDTH-1:0]     s_axi_rdata,
    output [1:0]                s_axi_rresp,
    output                      s_axi_rvalid,
    input                       s_axi_rready,

    // UART External Interface
    input                       uart_rxd,
    output                      uart_txd,
    output                      uart_irq,

    // GPIO External Interface
    input  [31:0]               gpio_i,
    output [31:0]               gpio_o,
    output [31:0]               gpio_oe,
    output [31:0]               gpio_ie,
    output [31:0]               gpio_pue,
    output [31:0]               gpio_pde,
    output [31:0]               gpio_ds0,
    output [31:0]               gpio_ds1,
    output [31:0]               gpio_irq
);

    // Internal APB signals from Bridge to Decoder
    wire [ADDR_WIDTH-1:0]       bridge_apb_paddr;
    wire                        bridge_apb_psel;
    wire                        bridge_apb_penable;
    wire                        bridge_apb_pwrite;
    wire [DATA_WIDTH-1:0]       bridge_apb_pwdata;
    wire [3:0]                  bridge_apb_pstrb;
    wire [DATA_WIDTH-1:0]       bridge_apb_prdata;
    wire                        bridge_apb_pready;
    wire                        bridge_apb_pslverr;

    // Master 0 signals for UART
    wire [ADDR_WIDTH-1:0]       m0_paddr;
    wire                        m0_psel;
    wire                        m0_penable;
    wire                        m0_pwrite;
    wire [DATA_WIDTH-1:0]       m0_pwdata;
    wire [3:0]                  m0_pstrb;
    wire [DATA_WIDTH-1:0]       m0_prdata;
    wire                        m0_pready;
    wire                        m0_pslverr;

    // Master 2 signals for GPIO
    wire [ADDR_WIDTH-1:0]       m2_paddr;
    wire                        m2_psel;
    wire                        m2_penable;
    wire                        m2_pwrite;
    wire [DATA_WIDTH-1:0]       m2_pwdata;
    wire [3:0]                  m2_pstrb;
    wire [DATA_WIDTH-1:0]       m2_prdata;
    wire                        m2_pready;
    wire                        m2_pslverr;

    // 1. AXI to APB Bridge
    axi2apb_bridge #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_bridge (
        .aclk(clk),
        .aresetn(rst_n),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awsize(s_axi_awsize),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arsize(s_axi_arsize),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .m_apb_paddr(bridge_apb_paddr),
        .m_apb_psel(bridge_apb_psel),
        .m_apb_penable(bridge_apb_penable),
        .m_apb_pwrite(bridge_apb_pwrite),
        .m_apb_pwdata(bridge_apb_pwdata),
        .m_apb_pstrb(bridge_apb_pstrb),
        .m_apb_prdata(bridge_apb_prdata),
        .m_apb_pready(bridge_apb_pready),
        .m_apb_pslverr(bridge_apb_pslverr)
    );

    // 2. 16-Way APB Decoder
    apb_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BASE_ADDR(32'h10000000)
    ) u_decoder (
        .clk(clk),
        .rst_n(rst_n),
        .s_apb_paddr(bridge_apb_paddr),
        .s_apb_psel(bridge_apb_psel),
        .s_apb_penable(bridge_apb_penable),
        .s_apb_pwrite(bridge_apb_pwrite),
        .s_apb_pwdata(bridge_apb_pwdata),
        .s_apb_pstrb(bridge_apb_pstrb),
        .s_apb_prdata(bridge_apb_prdata),
        .s_apb_pready(bridge_apb_pready),
        .s_apb_pslverr(bridge_apb_pslverr),
        
        // Port 0: UART
        .m0_apb_paddr(m0_paddr),
        .m0_apb_psel(m0_psel),
        .m0_apb_penable(m0_penable),
        .m0_apb_pwrite(m0_pwrite),
        .m0_apb_pwdata(m0_pwdata),
        .m0_apb_pstrb(m0_pstrb),
        .m0_apb_prdata(m0_prdata),
        .m0_apb_pready(m0_pready),
        .m0_apb_pslverr(m0_pslverr),
        
        // Port 1: Reserved (was ADC/DAC)
        .m1_apb_paddr(),
        .m1_apb_psel(),
        .m1_apb_penable(),
        .m1_apb_pwrite(),
        .m1_apb_pwdata(),
        .m1_apb_pstrb(),
        .m1_apb_prdata(32'h0),
        .m1_apb_pready(1'b1),
        .m1_apb_pslverr(1'b0),
        
        // Port 2: GPIO (Base address: 0x1000_2000)
        .m2_apb_paddr(m2_paddr),
        .m2_apb_psel(m2_psel),
        .m2_apb_penable(m2_penable),
        .m2_apb_pwrite(m2_pwrite),
        .m2_apb_pwdata(m2_pwdata),
        .m2_apb_pstrb(m2_pstrb),
        .m2_apb_prdata(m2_prdata),
        .m2_apb_pready(m2_pready),
        .m2_apb_pslverr(m2_pslverr),
        
        // Tie off ports 3-15

        .m3_apb_paddr(),
        .m3_apb_psel(),
        .m3_apb_penable(),
        .m3_apb_pwrite(),
        .m3_apb_pwdata(),
        .m3_apb_pstrb(),
        .m3_apb_prdata(32'h0),
        .m3_apb_pready(1'b1),
        .m3_apb_pslverr(1'b1),

        .m4_apb_paddr(),
        .m4_apb_psel(),
        .m4_apb_penable(),
        .m4_apb_pwrite(),
        .m4_apb_pwdata(),
        .m4_apb_pstrb(),
        .m4_apb_prdata(32'h0),
        .m4_apb_pready(1'b1),
        .m4_apb_pslverr(1'b1),

        .m5_apb_paddr(),
        .m5_apb_psel(),
        .m5_apb_penable(),
        .m5_apb_pwrite(),
        .m5_apb_pwdata(),
        .m5_apb_pstrb(),
        .m5_apb_prdata(32'h0),
        .m5_apb_pready(1'b1),
        .m5_apb_pslverr(1'b1),

        .m6_apb_paddr(),
        .m6_apb_psel(),
        .m6_apb_penable(),
        .m6_apb_pwrite(),
        .m6_apb_pwdata(),
        .m6_apb_pstrb(),
        .m6_apb_prdata(32'h0),
        .m6_apb_pready(1'b1),
        .m6_apb_pslverr(1'b1),

        .m7_apb_paddr(),
        .m7_apb_psel(),
        .m7_apb_penable(),
        .m7_apb_pwrite(),
        .m7_apb_pwdata(),
        .m7_apb_pstrb(),
        .m7_apb_prdata(32'h0),
        .m7_apb_pready(1'b1),
        .m7_apb_pslverr(1'b1),

        .m8_apb_paddr(),
        .m8_apb_psel(),
        .m8_apb_penable(),
        .m8_apb_pwrite(),
        .m8_apb_pwdata(),
        .m8_apb_pstrb(),
        .m8_apb_prdata(32'h0),
        .m8_apb_pready(1'b1),
        .m8_apb_pslverr(1'b1),

        .m9_apb_paddr(),
        .m9_apb_psel(),
        .m9_apb_penable(),
        .m9_apb_pwrite(),
        .m9_apb_pwdata(),
        .m9_apb_pstrb(),
        .m9_apb_prdata(32'h0),
        .m9_apb_pready(1'b1),
        .m9_apb_pslverr(1'b1),

        .m10_apb_paddr(),
        .m10_apb_psel(),
        .m10_apb_penable(),
        .m10_apb_pwrite(),
        .m10_apb_pwdata(),
        .m10_apb_pstrb(),
        .m10_apb_prdata(32'h0),
        .m10_apb_pready(1'b1),
        .m10_apb_pslverr(1'b1),

        .m11_apb_paddr(),
        .m11_apb_psel(),
        .m11_apb_penable(),
        .m11_apb_pwrite(),
        .m11_apb_pwdata(),
        .m11_apb_pstrb(),
        .m11_apb_prdata(32'h0),
        .m11_apb_pready(1'b1),
        .m11_apb_pslverr(1'b1),

        .m12_apb_paddr(),
        .m12_apb_psel(),
        .m12_apb_penable(),
        .m12_apb_pwrite(),
        .m12_apb_pwdata(),
        .m12_apb_pstrb(),
        .m12_apb_prdata(32'h0),
        .m12_apb_pready(1'b1),
        .m12_apb_pslverr(1'b1),

        .m13_apb_paddr(),
        .m13_apb_psel(),
        .m13_apb_penable(),
        .m13_apb_pwrite(),
        .m13_apb_pwdata(),
        .m13_apb_pstrb(),
        .m13_apb_prdata(32'h0),
        .m13_apb_pready(1'b1),
        .m13_apb_pslverr(1'b1),

        .m14_apb_paddr(),
        .m14_apb_psel(),
        .m14_apb_penable(),
        .m14_apb_pwrite(),
        .m14_apb_pwdata(),
        .m14_apb_pstrb(),
        .m14_apb_prdata(32'h0),
        .m14_apb_pready(1'b1),
        .m14_apb_pslverr(1'b1),

        .m15_apb_paddr(),
        .m15_apb_psel(),
        .m15_apb_penable(),
        .m15_apb_pwrite(),
        .m15_apb_pwdata(),
        .m15_apb_pstrb(),
        .m15_apb_prdata(32'h0),
        .m15_apb_pready(1'b1),
        .m15_apb_pslverr(1'b1)
    );

    // 3. UART
    apb_uart #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(16)
    ) u_uart (
        .clk(clk),
        .rst_n(rst_n),
        .paddr(m0_paddr),
        .psel(m0_psel),
        .penable(m0_penable),
        .pwrite(m0_pwrite),
        .pwdata(m0_pwdata),
        .prdata(m0_prdata),
        .pready(m0_pready),
        .pslverr(m0_pslverr),
        .uart_rxd(uart_rxd),
        .uart_txd(uart_txd),
        .uart_irq(uart_irq)
    );

    // 5. GPIO Interface (Base address: 0x1000_2000)
    apb_gpio #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_IO(32)
    ) u_gpio (
        .clk(clk),
        .rst_n(rst_n),
        .paddr(m2_paddr),
        .psel(m2_psel),
        .penable(m2_penable),
        .pwrite(m2_pwrite),
        .pwdata(m2_pwdata),
        .prdata(m2_prdata),
        .pready(m2_pready),
        .pslverr(m2_pslverr),
        .gpio_irq(gpio_irq),
        .gpio_i(gpio_i),
        .gpio_o(gpio_o),
        .gpio_oe(gpio_oe),
        .gpio_ie(gpio_ie),
        .gpio_pue(gpio_pue),
        .gpio_pde(gpio_pde),
        .gpio_ds0(gpio_ds0),
        .gpio_ds1(gpio_ds1)
    );

endmodule


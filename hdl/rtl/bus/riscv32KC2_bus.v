module riscv32KC2_bus #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Clock and Reset
    input                           aclk,
    input                           aresetn,
    
    // AXI Slave Interface 0 (from Instruction Fetch)
    // Write Address Channel
    input  [ADDR_WIDTH-1:0]         s0_axi_awaddr,
    input  [7:0]                    s0_axi_awlen,
    input  [2:0]                    s0_axi_awsize,
    input  [1:0]                    s0_axi_awburst,
    input                           s0_axi_awvalid,
    output                          s0_axi_awready,
    
    // Write Data Channel
    input  [DATA_WIDTH-1:0]         s0_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0]     s0_axi_wstrb,
    input                           s0_axi_wlast,
    input                           s0_axi_wvalid,
    output                          s0_axi_wready,
    
    // Write Response Channel
    output [1:0]                    s0_axi_bresp,
    output                          s0_axi_bvalid,
    input                           s0_axi_bready,
    
    // Read Address Channel
    input  [ADDR_WIDTH-1:0]         s0_axi_araddr,
    input  [7:0]                    s0_axi_arlen,
    input  [2:0]                    s0_axi_arsize,
    input  [1:0]                    s0_axi_arburst,
    input                           s0_axi_arvalid,
    output                          s0_axi_arready,
    
    // Read Data Channel
    output [DATA_WIDTH-1:0]         s0_axi_rdata,
    output [1:0]                    s0_axi_rresp,
    output                          s0_axi_rlast,
    output                          s0_axi_rvalid,
    input                           s0_axi_rready,

    // AXI Slave Interface 1 (from Data Bus)
    input  [ADDR_WIDTH-1:0]         s1_axi_awaddr,
    input  [7:0]                    s1_axi_awlen,
    input  [2:0]                    s1_axi_awsize,
    input  [1:0]                    s1_axi_awburst,
    input                           s1_axi_awvalid,
    output                          s1_axi_awready,
    
    // Write Data Channel
    input  [DATA_WIDTH-1:0]         s1_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0]     s1_axi_wstrb,
    input                           s1_axi_wlast,
    input                           s1_axi_wvalid,
    output                          s1_axi_wready,
    
    // Write Response Channel
    output [1:0]                    s1_axi_bresp,
    output                          s1_axi_bvalid,
    input                           s1_axi_bready,
    
    // Read Address Channel
    input  [ADDR_WIDTH-1:0]         s1_axi_araddr,
    input  [7:0]                    s1_axi_arlen,
    input  [2:0]                    s1_axi_arsize,
    input  [1:0]                    s1_axi_arburst,
    input                           s1_axi_arvalid,
    output                          s1_axi_arready,
    
    // Read Data Channel
    output [DATA_WIDTH-1:0]         s1_axi_rdata,
    output [1:0]                    s1_axi_rresp,
    output                          s1_axi_rlast,
    output                          s1_axi_rvalid,
    input                           s1_axi_rready,

    // AXI Master Interface 0 --- IRAM
    output [ADDR_WIDTH-1:0]         m0_axi_awaddr,
    output [7:0]                    m0_axi_awlen,
    output [2:0]                    m0_axi_awsize,
    output [1:0]                    m0_axi_awburst,
    output                          m0_axi_awvalid,
    input                           m0_axi_awready,
    
    // Write Data Channel
    output [DATA_WIDTH-1:0]         m0_axi_wdata,
    output [(DATA_WIDTH/8)-1:0]     m0_axi_wstrb,
    output                          m0_axi_wlast,
    output                          m0_axi_wvalid,
    input                           m0_axi_wready,
    
    // Write Response Channel
    input  [1:0]                    m0_axi_bresp,
    input                           m0_axi_bvalid,
    output                          m0_axi_bready, 
    
    // Read Address Channel
    output [ADDR_WIDTH-1:0]         m0_axi_araddr,
    output [7:0]                    m0_axi_arlen,
    output [2:0]                    m0_axi_arsize,
    output [1:0]                    m0_axi_arburst,
    output                          m0_axi_arvalid,
    input                           m0_axi_arready,
    
    // Read Data Channel
    input  [DATA_WIDTH-1:0]         m0_axi_rdata,
    input  [1:0]                    m0_axi_rresp,
    input                           m0_axi_rlast,
    input                           m0_axi_rvalid,
    output                          m0_axi_rready,

    // AXI Master Interface 1 --- DRAM
    output [ADDR_WIDTH-1:0]         m1_axi_awaddr,
    output [7:0]                    m1_axi_awlen,
    output [2:0]                    m1_axi_awsize,
    output [1:0]                    m1_axi_awburst,
    output                          m1_axi_awvalid,
    input                           m1_axi_awready,
    
    // Write Data Channel
    output [DATA_WIDTH-1:0]         m1_axi_wdata,
    output [(DATA_WIDTH/8)-1:0]     m1_axi_wstrb,
    output                          m1_axi_wlast,
    output                          m1_axi_wvalid,
    input                           m1_axi_wready,
    
    // Write Response Channel
    input  [1:0]                    m1_axi_bresp,
    input                           m1_axi_bvalid,
    output                          m1_axi_bready, 
    
    // Read Address Channel
    output [ADDR_WIDTH-1:0]         m1_axi_araddr,
    output [7:0]                    m1_axi_arlen,
    output [2:0]                    m1_axi_arsize,
    output [1:0]                    m1_axi_arburst,
    output                          m1_axi_arvalid,
    input                           m1_axi_arready,
    
    // Read Data Channel
    input  [DATA_WIDTH-1:0]         m1_axi_rdata,
    input  [1:0]                    m1_axi_rresp,
    input                           m1_axi_rlast,
    input                           m1_axi_rvalid,
    output                          m1_axi_rready,

    // AXI Master Interface 2 --- MROM
    output [ADDR_WIDTH-1:0]         m2_axi_awaddr,
    output [7:0]                    m2_axi_awlen,
    output [2:0]                    m2_axi_awsize,
    output [1:0]                    m2_axi_awburst,
    output                          m2_axi_awvalid,
    input                           m2_axi_awready,
    
    // Write Data Channel
    output [DATA_WIDTH-1:0]         m2_axi_wdata,
    output [(DATA_WIDTH/8)-1:0]     m2_axi_wstrb,
    output                          m2_axi_wlast,
    output                          m2_axi_wvalid,
    input                           m2_axi_wready,
    
    // Write Response Channel
    input  [1:0]                    m2_axi_bresp,
    input                           m2_axi_bvalid,
    output                          m2_axi_bready, 
    
    // Read Address Channel
    output [ADDR_WIDTH-1:0]         m2_axi_araddr,
    output [7:0]                    m2_axi_arlen,
    output [2:0]                    m2_axi_arsize,
    output [1:0]                    m2_axi_arburst,
    output                          m2_axi_arvalid,
    input                           m2_axi_arready,
    
    // Read Data Channel
    input  [DATA_WIDTH-1:0]         m2_axi_rdata,
    input  [1:0]                    m2_axi_rresp,
    input                           m2_axi_rlast,
    input                           m2_axi_rvalid,
    output                          m2_axi_rready,

    // AXI Master Interface 3 --- Debug
    output [ADDR_WIDTH-1:0]         m3_axi_awaddr,
    output [7:0]                    m3_axi_awlen,
    output [2:0]                    m3_axi_awsize,
    output [1:0]                    m3_axi_awburst,
    output                          m3_axi_awvalid,
    input                           m3_axi_awready,
    
    // Write Data Channel
    output [DATA_WIDTH-1:0]         m3_axi_wdata,
    output [(DATA_WIDTH/8)-1:0]     m3_axi_wstrb,
    output                          m3_axi_wlast,
    output                          m3_axi_wvalid,
    input                           m3_axi_wready,
    
    // Write Response Channel
    input  [1:0]                    m3_axi_bresp,
    input                           m3_axi_bvalid,
    output                          m3_axi_bready, 
    
    // Read Address Channel
    output [ADDR_WIDTH-1:0]         m3_axi_araddr,
    output [7:0]                    m3_axi_arlen,
    output [2:0]                    m3_axi_arsize,
    output [1:0]                    m3_axi_arburst,
    output                          m3_axi_arvalid,
    input                           m3_axi_arready,
    
    // Read Data Channel
    input  [DATA_WIDTH-1:0]         m3_axi_rdata,
    input  [1:0]                    m3_axi_rresp,
    input                           m3_axi_rlast,
    input                           m3_axi_rvalid,
    output                          m3_axi_rready,

    // AXI Master Interface 4 --- Perperial
    output [ADDR_WIDTH-1:0]         m4_axi_awaddr,
    output [7:0]                    m4_axi_awlen,
    output [2:0]                    m4_axi_awsize,
    output [1:0]                    m4_axi_awburst,
    output                          m4_axi_awvalid,
    input                           m4_axi_awready,
    
    // Write Data Channel
    output [DATA_WIDTH-1:0]         m4_axi_wdata,
    output [(DATA_WIDTH/8)-1:0]     m4_axi_wstrb,
    output                          m4_axi_wlast,
    output                          m4_axi_wvalid,
    input                           m4_axi_wready,
    
    // Write Response Channel
    input  [1:0]                    m4_axi_bresp,
    input                           m4_axi_bvalid,
    output                          m4_axi_bready, 
    
    // Read Address Channel
    output [ADDR_WIDTH-1:0]         m4_axi_araddr,
    output [7:0]                    m4_axi_arlen,
    output [2:0]                    m4_axi_arsize,
    output [1:0]                    m4_axi_arburst,
    output                          m4_axi_arvalid,
    input                           m4_axi_arready,
    
    // Read Data Channel
    input  [DATA_WIDTH-1:0]         m4_axi_rdata,
    input  [1:0]                    m4_axi_rresp,
    input                           m4_axi_rlast,
    input                           m4_axi_rvalid,
    output                          m4_axi_rready,
	
    // AXI Master Interface 5 --- Clint
    output [ADDR_WIDTH-1:0]         m5_axi_awaddr,
    output [7:0]                    m5_axi_awlen,
    output [2:0]                    m5_axi_awsize,
    output [1:0]                    m5_axi_awburst,
    output                          m5_axi_awvalid,
    input                           m5_axi_awready,
    
    // Write Data Channel
    output [DATA_WIDTH-1:0]         m5_axi_wdata,
    output [(DATA_WIDTH/8)-1:0]     m5_axi_wstrb,
    output                          m5_axi_wlast,
    output                          m5_axi_wvalid,
    input                           m5_axi_wready,
    
    // Write Response Channel
    input  [1:0]                    m5_axi_bresp,
    input                           m5_axi_bvalid,
    output                          m5_axi_bready, 
    
    // Read Address Channel
    output [ADDR_WIDTH-1:0]         m5_axi_araddr,
    output [7:0]                    m5_axi_arlen,
    output [2:0]                    m5_axi_arsize,
    output [1:0]                    m5_axi_arburst,
    output                          m5_axi_arvalid,
    input                           m5_axi_arready,
    
    // Read Data Channel
    input  [DATA_WIDTH-1:0]         m5_axi_rdata,
    input  [1:0]                    m5_axi_rresp,
    input                           m5_axi_rlast,
    input                           m5_axi_rvalid,
    output                          m5_axi_rready,

    // AXI Master Interface 6 --- PLIC
    output [ADDR_WIDTH-1:0]         m6_axi_awaddr,
    output [7:0]                    m6_axi_awlen,
    output [2:0]                    m6_axi_awsize,
    output [1:0]                    m6_axi_awburst,
    output                          m6_axi_awvalid,
    input                           m6_axi_awready,
    
    // Write Data Channel
    output [DATA_WIDTH-1:0]         m6_axi_wdata,
    output [(DATA_WIDTH/8)-1:0]     m6_axi_wstrb,
    output                          m6_axi_wlast,
    output                          m6_axi_wvalid,
    input                           m6_axi_wready,
    
    // Write Response Channel
    input  [1:0]                    m6_axi_bresp,
    input                           m6_axi_bvalid,
    output                          m6_axi_bready, 
    
    // Read Address Channel
    output [ADDR_WIDTH-1:0]         m6_axi_araddr,
    output [7:0]                    m6_axi_arlen,
    output [2:0]                    m6_axi_arsize,
    output [1:0]                    m6_axi_arburst,
    output                          m6_axi_arvalid,
    input                           m6_axi_arready,
    
    // Read Data Channel
    input  [DATA_WIDTH-1:0]         m6_axi_rdata,
    input  [1:0]                    m6_axi_rresp,
    input                           m6_axi_rlast,
    input                           m6_axi_rvalid,
    output                          m6_axi_rready		
);

    localparam NumSlvtoMst_S0 = 3;
    localparam NumSlvtoMst_S1 = 8;

    wire m0_s0_ar_select = (s0_axi_araddr >= 32'h7000_0000 && s0_axi_araddr < 32'h8000_0000); // IRAM
    wire m2_s0_ar_select = (s0_axi_araddr >= 32'h0000_1000 && s0_axi_araddr < 32'h0000_8000); // MROM
    wire m3_s0_ar_select = (s0_axi_araddr >= 32'h0000_0000 && s0_axi_araddr < 32'h0000_1000); // Debug

    wire m0_s1_ar_select = (s1_axi_araddr >= 32'h7000_0000 && s1_axi_araddr < 32'h8000_0000); // IRAM
    wire m1_s1_ar_select = (s1_axi_araddr >= 32'hA000_0000 && s1_axi_araddr < 32'hB000_0000); // DRAM
    wire m3_s1_ar_select = (s1_axi_araddr >= 32'h0000_0000 && s1_axi_araddr < 32'h0000_1000); // Debug
    wire m4_s1_ar_select = (s1_axi_araddr >= 32'h1000_0000 && s1_axi_araddr < 32'h1001_0000); // PER
	wire m5_s1_ar_select = (s1_axi_araddr >= 32'h0200_0000 && s1_axi_araddr < 32'h0201_0000); // CLINT
	wire m6_s1_ar_select = (s1_axi_araddr >= 32'h0C00_0000 && s1_axi_araddr < 32'h0C04_0000); // PLIC
	
    wire m0_s1_aw_select = (s1_axi_awaddr >= 32'h7000_0000 && s1_axi_awaddr < 32'h8000_0000); // IRAM
    wire m1_s1_aw_select = (s1_axi_awaddr >= 32'hA000_0000 && s1_axi_awaddr < 32'hB000_0000); // DRAM
    wire m3_s1_aw_select = (s1_axi_awaddr >= 32'h0000_0000 && s1_axi_awaddr < 32'h0000_1000); // Debug
    wire m4_s1_aw_select = (s1_axi_awaddr >= 32'h1000_0000 && s1_axi_awaddr < 32'h1001_0000); // PER
    wire m5_s1_aw_select = (s1_axi_awaddr >= 32'h0200_0000 && s1_axi_awaddr < 32'h0201_0000); // CLINT
	wire m6_s1_aw_select = (s1_axi_awaddr >= 32'h0C00_0000 && s1_axi_awaddr < 32'h0C04_0000); // PLIC
	
    // S0 internal signals
    wire [NumSlvtoMst_S0*ADDR_WIDTH-1:0]     m_s0_axi_awaddr;
    wire [NumSlvtoMst_S0*8-1:0]              m_s0_axi_awlen;
    wire [NumSlvtoMst_S0*3-1:0]              m_s0_axi_awsize;
    wire [NumSlvtoMst_S0*2-1:0]              m_s0_axi_awburst;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_awvalid;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_awready;
    
    wire [NumSlvtoMst_S0*DATA_WIDTH-1:0]     m_s0_axi_wdata;
    wire [NumSlvtoMst_S0*(DATA_WIDTH/8)-1:0] m_s0_axi_wstrb;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_wlast;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_wvalid;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_wready;
    
    wire [NumSlvtoMst_S0*2-1:0]              m_s0_axi_bresp;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_bvalid;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_bready;
    
    wire [NumSlvtoMst_S0*ADDR_WIDTH-1:0]     m_s0_axi_araddr;
    wire [NumSlvtoMst_S0*8-1:0]              m_s0_axi_arlen;
    wire [NumSlvtoMst_S0*3-1:0]              m_s0_axi_arsize;
    wire [NumSlvtoMst_S0*2-1:0]              m_s0_axi_arburst;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_arvalid;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_arready;
    
    wire [NumSlvtoMst_S0*DATA_WIDTH-1:0]     m_s0_axi_rdata;
    wire [NumSlvtoMst_S0*2-1:0]              m_s0_axi_rresp;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_rlast;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_rvalid;
    wire [NumSlvtoMst_S0-1:0]                m_s0_axi_rready;

    // S1 internal signals
    wire [NumSlvtoMst_S1*ADDR_WIDTH-1:0]     m_s1_axi_awaddr;
    wire [NumSlvtoMst_S1*8-1:0]              m_s1_axi_awlen;
    wire [NumSlvtoMst_S1*3-1:0]              m_s1_axi_awsize;
    wire [NumSlvtoMst_S1*2-1:0]              m_s1_axi_awburst;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_awvalid;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_awready;
    
    wire [NumSlvtoMst_S1*DATA_WIDTH-1:0]     m_s1_axi_wdata;
    wire [NumSlvtoMst_S1*(DATA_WIDTH/8)-1:0] m_s1_axi_wstrb;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_wlast;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_wvalid;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_wready;
    
    wire [NumSlvtoMst_S1*2-1:0]              m_s1_axi_bresp;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_bvalid;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_bready;
    
    wire [NumSlvtoMst_S1*ADDR_WIDTH-1:0]     m_s1_axi_araddr;
    wire [NumSlvtoMst_S1*8-1:0]              m_s1_axi_arlen;
    wire [NumSlvtoMst_S1*3-1:0]              m_s1_axi_arsize;
    wire [NumSlvtoMst_S1*2-1:0]              m_s1_axi_arburst;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_arvalid;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_arready;
    
    wire [NumSlvtoMst_S1*DATA_WIDTH-1:0]     m_s1_axi_rdata;
    wire [NumSlvtoMst_S1*2-1:0]              m_s1_axi_rresp;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_rlast;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_rvalid;
    wire [NumSlvtoMst_S1-1:0]                m_s1_axi_rready;

    axi_lite_demux #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .NumMst         (NumSlvtoMst_S0)
    ) u_s0 (
        .clk            (aclk),
        .rst_n          (aresetn),
        // Write Address Channel
        .s_axi_awaddr   (s0_axi_awaddr),
        .s_axi_awlen    (s0_axi_awlen),
        .s_axi_awsize   (s0_axi_awsize),
        .s_axi_awburst  (s0_axi_awburst),
        .s_axi_awvalid  (s0_axi_awvalid),
        .s_axi_awready  (s0_axi_awready),
        
        // Write Data Channel
        .s_axi_wdata    (s0_axi_wdata),
        .s_axi_wstrb    (s0_axi_wstrb),
        .s_axi_wlast    (s0_axi_wlast),
        .s_axi_wvalid   (s0_axi_wvalid),
        .s_axi_wready    (s0_axi_wready),
        
        // Write Response Channel
        .s_axi_bresp    (s0_axi_bresp),
        .s_axi_bvalid   (s0_axi_bvalid),
        .s_axi_bready   (s0_axi_bready),
        
        // Read Address Channel
        .s_axi_araddr   (s0_axi_araddr),
        .s_axi_arlen    (s0_axi_arlen),
        .s_axi_arsize   (s0_axi_arsize),
        .s_axi_arburst  (s0_axi_arburst),
        .s_axi_arvalid  (s0_axi_arvalid),
        .s_axi_arready  (s0_axi_arready),
        
        // Read Data Channel
        .s_axi_rdata    (s0_axi_rdata),
        .s_axi_rresp    (s0_axi_rresp),
        .s_axi_rlast    (s0_axi_rlast),
        .s_axi_rvalid   (s0_axi_rvalid),
        .s_axi_rready   (s0_axi_rready),
        // Select 
        .select_ar_i    ({m3_s0_ar_select, m2_s0_ar_select, m0_s0_ar_select}),
        .select_aw_i    (3'b000),
        // Master interface
        // Write Address Channel
        .m_axi_awaddr   (m_s0_axi_awaddr),
        .m_axi_awlen    (m_s0_axi_awlen),
        .m_axi_awsize   (m_s0_axi_awsize),
        .m_axi_awburst  (m_s0_axi_awburst),
        .m_axi_awvalid  (m_s0_axi_awvalid),
        .m_axi_awready  (m_s0_axi_awready),
        
        // Write Data Channel
        .m_axi_wdata    (m_s0_axi_wdata),
        .m_axi_wstrb    (m_s0_axi_wstrb),
        .m_axi_wlast    (m_s0_axi_wlast),
        .m_axi_wvalid   (m_s0_axi_wvalid),
        .m_axi_wready   (m_s0_axi_wready),
        
        // Write Response Channel
        .m_axi_bresp    (m_s0_axi_bresp),
        .m_axi_bvalid   (m_s0_axi_bvalid),
        .m_axi_bready   (m_s0_axi_bready), 
        
        // Read Address Channel
        .m_axi_araddr   (m_s0_axi_araddr),
        .m_axi_arlen    (m_s0_axi_arlen),
        .m_axi_arsize   (m_s0_axi_arsize),
        .m_axi_arburst  (m_s0_axi_arburst),
        .m_axi_arvalid  (m_s0_axi_arvalid),
        .m_axi_arready  (m_s0_axi_arready),
        
        // Read Data Channel
        .m_axi_rdata    (m_s0_axi_rdata),
        .m_axi_rresp    (m_s0_axi_rresp),
        .m_axi_rlast    (m_s0_axi_rlast),
        .m_axi_rvalid   (m_s0_axi_rvalid),
        .m_axi_rready   (m_s0_axi_rready)
    );

    axi_lite_demux #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .NumMst         (NumSlvtoMst_S1)
    ) u_s1 (
        .clk            (aclk),
        .rst_n          (aresetn),
        // Write Address Channel
        .s_axi_awaddr   (s1_axi_awaddr),
        .s_axi_awlen    (s1_axi_awlen),
        .s_axi_awsize   (s1_axi_awsize),
        .s_axi_awburst  (s1_axi_awburst),
        .s_axi_awvalid  (s1_axi_awvalid),
        .s_axi_awready  (s1_axi_awready),
        
        // Write Data Channel
        .s_axi_wdata    (s1_axi_wdata),
        .s_axi_wstrb    (s1_axi_wstrb),
        .s_axi_wlast    (s1_axi_wlast),
        .s_axi_wvalid   (s1_axi_wvalid),
        .s_axi_wready   (s1_axi_wready),
        
        // Write Response Channel
        .s_axi_bresp    (s1_axi_bresp),
        .s_axi_bvalid   (s1_axi_bvalid),
        .s_axi_bready   (s1_axi_bready),
        
        // Read Address Channel
        .s_axi_araddr   (s1_axi_araddr),
        .s_axi_arlen    (s1_axi_arlen),
        .s_axi_arsize   (s1_axi_arsize),
        .s_axi_arburst  (s1_axi_arburst),
        .s_axi_arvalid  (s1_axi_arvalid),
        .s_axi_arready  (s1_axi_arready),
        
        // Read Data Channel
        .s_axi_rdata    (s1_axi_rdata),
        .s_axi_rresp    (s1_axi_rresp),
        .s_axi_rlast    (s1_axi_rlast),
        .s_axi_rvalid   (s1_axi_rvalid),
        .s_axi_rready   (s1_axi_rready),
        // Select 
        .select_ar_i    ({2'd0, m6_s1_ar_select, m5_s1_ar_select, m4_s1_ar_select, m3_s1_ar_select, m1_s1_ar_select, m0_s1_ar_select}),
        .select_aw_i    ({2'd0, m6_s1_aw_select, m5_s1_aw_select, m4_s1_aw_select, m3_s1_aw_select, m1_s1_aw_select, m0_s1_aw_select}),
        // Master interface
        // Write Address Channel
        .m_axi_awaddr   (m_s1_axi_awaddr),
        .m_axi_awlen    (m_s1_axi_awlen),
        .m_axi_awsize   (m_s1_axi_awsize),
        .m_axi_awburst  (m_s1_axi_awburst),
        .m_axi_awvalid  (m_s1_axi_awvalid),
        .m_axi_awready  (m_s1_axi_awready),
        
        // Write Data Channel
        .m_axi_wdata    (m_s1_axi_wdata),
        .m_axi_wstrb    (m_s1_axi_wstrb),
        .m_axi_wlast    (m_s1_axi_wlast),
        .m_axi_wvalid   (m_s1_axi_wvalid),
        .m_axi_wready   (m_s1_axi_wready),
        
        // Write Response Channel
        .m_axi_bresp    (m_s1_axi_bresp),
        .m_axi_bvalid   (m_s1_axi_bvalid),
        .m_axi_bready   (m_s1_axi_bready), 
        
        // Read Address Channel
        .m_axi_araddr   (m_s1_axi_araddr),
        .m_axi_arlen    (m_s1_axi_arlen),
        .m_axi_arsize   (m_s1_axi_arsize),
        .m_axi_arburst  (m_s1_axi_arburst),
        .m_axi_arvalid  (m_s1_axi_arvalid),
        .m_axi_arready  (m_s1_axi_arready),
        
        // Read Data Channel
        .m_axi_rdata    (m_s1_axi_rdata),
        .m_axi_rresp    (m_s1_axi_rresp),
        .m_axi_rlast    (m_s1_axi_rlast),
        .m_axi_rvalid   (m_s1_axi_rvalid),
        .m_axi_rready   (m_s1_axi_rready)
    );

    axi_lite_mux2 #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .NumSlv         (2)
    ) u_m0 (
        .clk            (aclk),
        .rst_n          (aresetn),

        // Write Address Channel
        .s_axi_awaddr   (),
        .s_axi_awlen    (),
        .s_axi_awsize   (),
        .s_axi_awburst  (),
        .s_axi_awvalid  (),
        .s_axi_awready  (),
        
        // Write Data Channel
        .s_axi_wdata    (),
        .s_axi_wstrb    (),
        .s_axi_wlast    (),
        .s_axi_wvalid   (),
        .s_axi_wready   (),
        
        // Write Response Channel
        .s_axi_bresp    (),
        .s_axi_bvalid   (),
        .s_axi_bready   (),
        
        // Read Address Channel
        .s_axi_araddr   ({m_s0_axi_araddr[(0+1)*ADDR_WIDTH-1: ADDR_WIDTH*0], m_s1_axi_araddr[(0+1)*ADDR_WIDTH-1: ADDR_WIDTH*0]}),
        .s_axi_arlen    ({m_s0_axi_arlen[(0+1)*8-1:8*0], m_s1_axi_arlen[(0+1)*8-1:8*0]}),
        .s_axi_arsize   ({m_s0_axi_arsize[(0+1)*3-1:3*0], m_s1_axi_arsize[(0+1)*3-1:3*0]}),
        .s_axi_arburst  ({m_s0_axi_arburst[(0+1)*2-1:2*0], m_s1_axi_arburst[(0+1)*2-1:2*0]}),
        .s_axi_arvalid  ({m_s0_axi_arvalid[0], m_s1_axi_arvalid[0]}),
        .s_axi_arready  ({m_s0_axi_arready[0], m_s1_axi_arready[0]}),
        
        // Read Data Channel
        .s_axi_rdata    ({m_s0_axi_rdata[(0+1)*DATA_WIDTH-1: DATA_WIDTH*0], m_s1_axi_rdata[(0+1)*DATA_WIDTH-1: DATA_WIDTH*0]}),
        .s_axi_rresp    ({m_s0_axi_rresp[(0+1)*2-1:2*0], m_s1_axi_rresp[(0+1)*2-1:2*0]}),
        .s_axi_rlast    ({m_s0_axi_rlast[0], m_s1_axi_rlast[0]}),
        .s_axi_rvalid   ({m_s0_axi_rvalid[0], m_s1_axi_rvalid[0]}),
        .s_axi_rready   ({m_s0_axi_rready[0], m_s1_axi_rready[0]}),

        // Master interface
        // Write Address Channel
        .m_axi_awaddr   (),
        .m_axi_awlen    (),
        .m_axi_awsize   (),
        .m_axi_awburst  (),
        .m_axi_awvalid  (),
        .m_axi_awready  (),
        
        // Write Data Channel
        .m_axi_wdata    (),
        .m_axi_wstrb    (),
        .m_axi_wlast    (),
        .m_axi_wvalid   (),
        .m_axi_wready   (),
        
        // Write Response Channel
        .m_axi_bresp    (),
        .m_axi_bvalid   (),
        .m_axi_bready   (), 
        
        // Read Address Channel
        .m_axi_araddr   (m0_axi_araddr),
        .m_axi_arlen    (m0_axi_arlen),
        .m_axi_arsize   (m0_axi_arsize),
        .m_axi_arburst  (m0_axi_arburst),
        .m_axi_arvalid  (m0_axi_arvalid),
        .m_axi_arready  (m0_axi_arready),
        
        // Read Data Channel
        .m_axi_rdata    (m0_axi_rdata),
        .m_axi_rresp    (m0_axi_rresp),
        .m_axi_rlast    (m0_axi_rlast),
        .m_axi_rvalid   (m0_axi_rvalid),
        .m_axi_rready   (m0_axi_rready)
    );

    // M0 -- IRAM Port S0-ID0 S1-ID0
    // AW
    assign m0_axi_awaddr      = m_s1_axi_awaddr[(0+1)*ADDR_WIDTH-1: ADDR_WIDTH*0];
    assign m0_axi_awlen       = m_s1_axi_awlen[(0+1)*8-1:8*0];
    assign m0_axi_awsize      = m_s1_axi_awsize[(0+1)*3-1:3*0];
    assign m0_axi_awburst     = m_s1_axi_awburst[(0+1)*2-1:2*0];
    assign m0_axi_awvalid     = m_s1_axi_awvalid[(0+1)*1-1:1*0];
    assign m_s1_axi_awready[0] = m0_axi_awready;
    // W
    assign m0_axi_wdata       = m_s1_axi_wdata[(0+1)*DATA_WIDTH-1: DATA_WIDTH*0];
    assign m0_axi_wstrb       = m_s1_axi_wstrb[(0+1)*(DATA_WIDTH/8)-1:(DATA_WIDTH/8)*0];
    assign m0_axi_wlast       = m_s1_axi_wlast[0];
    assign m0_axi_wvalid      = m_s1_axi_wvalid[0];
    assign m_s1_axi_wready[0] = m0_axi_wready;
    // B    
    assign m_s1_axi_bresp[(0+1)*2-1:2*0] = m0_axi_bresp;
    assign m_s1_axi_bvalid[0]            = m0_axi_bvalid;
    assign m0_axi_bready                 = m_s1_axi_bready[0];

    // M1 --- DRAM Port S1-ID1
    // AW
    assign m1_axi_awaddr      = m_s1_axi_awaddr[(1+1)*ADDR_WIDTH-1: ADDR_WIDTH*1];
    assign m1_axi_awlen       = m_s1_axi_awlen[(1+1)*8-1:8*1];
    assign m1_axi_awsize      = m_s1_axi_awsize[(1+1)*3-1:3*1];
    assign m1_axi_awburst     = m_s1_axi_awburst[(1+1)*2-1:2*1];
    assign m1_axi_awvalid     = m_s1_axi_awvalid[(1+1)*1-1:1*1];
    assign m_s1_axi_awready[1] = m1_axi_awready;
    // W
    assign m1_axi_wdata       = m_s1_axi_wdata[(1+1)*DATA_WIDTH-1: DATA_WIDTH*1];
    assign m1_axi_wstrb       = m_s1_axi_wstrb[(1+1)*(DATA_WIDTH/8)-1:(DATA_WIDTH/8)*1];
    assign m1_axi_wlast       = m_s1_axi_wlast[1];
    assign m1_axi_wvalid      = m_s1_axi_wvalid[1];
    assign m_s1_axi_wready[1] = m1_axi_wready;
    // B    
    assign m_s1_axi_bresp[(1+1)*2-1:2*1] = m1_axi_bresp;
    assign m_s1_axi_bvalid[1]            = m1_axi_bvalid;
    assign m1_axi_bready                 = m_s1_axi_bready[1];

    // AR    
    assign m1_axi_araddr      = m_s1_axi_araddr[(1+1)*ADDR_WIDTH-1: ADDR_WIDTH*1];
    assign m1_axi_arlen       = m_s1_axi_arlen[(1+1)*8-1:8*1];
    assign m1_axi_arsize      = m_s1_axi_arsize[(1+1)*3-1:3*1];
    assign m1_axi_arburst     = m_s1_axi_arburst[(1+1)*2-1:2*1];
    assign m1_axi_arvalid     = m_s1_axi_arvalid[(1+1)*1-1:1*1];
    assign m_s1_axi_arready[1] = m1_axi_arready;
    
    // R
    assign m_s1_axi_rdata[(1+1)*DATA_WIDTH-1: DATA_WIDTH*1] = m1_axi_rdata;
    assign m_s1_axi_rresp[(1+1)*2-1:2*1]                   = m1_axi_rresp;
    assign m_s1_axi_rlast[1]                               = m1_axi_rlast;
    assign m_s1_axi_rvalid[1]                              = m1_axi_rvalid;
    assign m1_axi_rready                                   = m_s1_axi_rready[1];

    // M2 -- MROM
    // AW
    assign m2_axi_awaddr      = m_s0_axi_awaddr[(1+1)*ADDR_WIDTH-1: ADDR_WIDTH*1];
    assign m2_axi_awlen       = m_s0_axi_awlen[(1+1)*8-1:8*1];
    assign m2_axi_awsize      = m_s0_axi_awsize[(1+1)*3-1:3*1];
    assign m2_axi_awburst     = m_s0_axi_awburst[(1+1)*2-1:2*1];
    assign m2_axi_awvalid     = m_s0_axi_awvalid[(1+1)*1-1:1*1];
    assign m_s0_axi_awready[1] = m2_axi_awready;
    // W
    assign m2_axi_wdata       = m_s0_axi_wdata[(1+1)*DATA_WIDTH-1: DATA_WIDTH*1];
    assign m2_axi_wstrb       = m_s0_axi_wstrb[(1+1)*(DATA_WIDTH/8)-1:(DATA_WIDTH/8)*1];
    assign m2_axi_wlast       = m_s0_axi_wlast[1];
    assign m2_axi_wvalid      = m_s0_axi_wvalid[1];
    assign m_s0_axi_wready[1] = m2_axi_wready;
    // B    
    assign m_s0_axi_bresp[(1+1)*2-1:2*1] = m2_axi_bresp;
    assign m_s0_axi_bvalid[1]            = m2_axi_bvalid;
    assign m2_axi_bready                 = m_s0_axi_bready[1];

    // AR    
    assign m2_axi_araddr      = m_s0_axi_araddr[(1+1)*ADDR_WIDTH-1: ADDR_WIDTH*1];
    assign m2_axi_arlen       = m_s0_axi_arlen[(1+1)*8-1:8*1];
    assign m2_axi_arsize      = m_s0_axi_arsize[(1+1)*3-1:3*1];
    assign m2_axi_arburst     = m_s0_axi_arburst[(1+1)*2-1:2*1];
    assign m2_axi_arvalid     = m_s0_axi_arvalid[(1+1)*1-1:1*1];
    assign m_s0_axi_arready[1] = m2_axi_arready;
    
    // R
    assign m_s0_axi_rdata[(1+1)*DATA_WIDTH-1: DATA_WIDTH*1] = m2_axi_rdata;
    assign m_s0_axi_rresp[(1+1)*2-1:2*1]                   = m2_axi_rresp;
    assign m_s0_axi_rlast[1]                               = m2_axi_rlast;
    assign m_s0_axi_rvalid[1]                              = m2_axi_rvalid;
    assign m2_axi_rready                                   = m_s0_axi_rready[1];

    // M3 -- DEBUG S0-ID2 S1-ID2
    axi_lite_mux2 #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .NumSlv         (2)
    ) u_m3 (
        .clk            (aclk),
        .rst_n          (aresetn),

        // Write Address Channel
        .s_axi_awaddr   (),
        .s_axi_awlen    (),
        .s_axi_awsize   (),
        .s_axi_awburst  (),
        .s_axi_awvalid  (),
        .s_axi_awready  (),
        
        // Write Data Channel
        .s_axi_wdata    (),
        .s_axi_wstrb    (),
        .s_axi_wlast    (),
        .s_axi_wvalid   (),
        .s_axi_wready   (),
        
        // Write Response Channel
        .s_axi_bresp    (),
        .s_axi_bvalid   (),
        .s_axi_bready   (),
        
        // Read Address Channel
        .s_axi_araddr   ({m_s0_axi_araddr[(2+1)*ADDR_WIDTH-1: ADDR_WIDTH*2], m_s1_axi_araddr[(2+1)*ADDR_WIDTH-1: ADDR_WIDTH*2]}),
        .s_axi_arlen    ({m_s0_axi_arlen[(2+1)*8-1:8*2], m_s1_axi_arlen[(2+1)*8-1:8*2]}),
        .s_axi_arsize   ({m_s0_axi_arsize[(2+1)*3-1:3*2], m_s1_axi_arsize[(2+1)*3-1:3*2]}),
        .s_axi_arburst  ({m_s0_axi_arburst[(2+1)*2-1:2*2], m_s1_axi_arburst[(2+1)*2-1:2*2]}),
        .s_axi_arvalid  ({m_s0_axi_arvalid[2], m_s1_axi_arvalid[2]}),
        .s_axi_arready  ({m_s0_axi_arready[2], m_s1_axi_arready[2]}),
        
        // Read Data Channel
        .s_axi_rdata    ({m_s0_axi_rdata[(2+1)*DATA_WIDTH-1: DATA_WIDTH*2], m_s1_axi_rdata[(2+1)*DATA_WIDTH-1: DATA_WIDTH*2]}),
        .s_axi_rresp    ({m_s0_axi_rresp[(2+1)*2-1:2*2], m_s1_axi_rresp[(2+1)*2-1:2*2]}),
        .s_axi_rlast    ({m_s0_axi_rlast[2], m_s1_axi_rlast[2]}),
        .s_axi_rvalid   ({m_s0_axi_rvalid[2], m_s1_axi_rvalid[2]}),
        .s_axi_rready   ({m_s0_axi_rready[2], m_s1_axi_rready[2]}),

        // Master interface
        // Write Address Channel
        .m_axi_awaddr   (),
        .m_axi_awlen    (),
        .m_axi_awsize   (),
        .m_axi_awburst  (),
        .m_axi_awvalid  (),
        .m_axi_awready  (),
        
        // Write Data Channel
        .m_axi_wdata    (),
        .m_axi_wstrb    (),
        .m_axi_wlast    (),
        .m_axi_wvalid   (),
        .m_axi_wready   (),
        
        // Write Response Channel
        .m_axi_bresp    (),
        .m_axi_bvalid   (),
        .m_axi_bready   (), 
        
        // Read Address Channel
        .m_axi_araddr   (m3_axi_araddr),
        .m_axi_arlen    (m3_axi_arlen),
        .m_axi_arsize   (m3_axi_arsize),
        .m_axi_arburst  (m3_axi_arburst),
        .m_axi_arvalid  (m3_axi_arvalid),
        .m_axi_arready  (m3_axi_arready),
        
        // Read Data Channel
        .m_axi_rdata    (m3_axi_rdata),
        .m_axi_rresp    (m3_axi_rresp),
        .m_axi_rlast    (m3_axi_rlast),
        .m_axi_rvalid   (m3_axi_rvalid),
        .m_axi_rready   (m3_axi_rready)
    );

    // AW
    assign m3_axi_awaddr      = m_s1_axi_awaddr[(2+1)*ADDR_WIDTH-1: ADDR_WIDTH*2];
    assign m3_axi_awlen       = m_s1_axi_awlen[(2+1)*8-1:8*2];
    assign m3_axi_awsize      = m_s1_axi_awsize[(2+1)*3-1:3*2];
    assign m3_axi_awburst     = m_s1_axi_awburst[(2+1)*2-1:2*2];
    assign m3_axi_awvalid     = m_s1_axi_awvalid[(2+1)*1-1:1*2];
    assign m_s1_axi_awready[2] = m3_axi_awready;
    // W
    assign m3_axi_wdata       = m_s1_axi_wdata[(2+1)*DATA_WIDTH-1: DATA_WIDTH*2];
    assign m3_axi_wstrb       = m_s1_axi_wstrb[(2+1)*(DATA_WIDTH/8)-1:(DATA_WIDTH/8)*2];
    assign m3_axi_wlast       = m_s1_axi_wlast[2];
    assign m3_axi_wvalid      = m_s1_axi_wvalid[2];
    assign m_s1_axi_wready[2] = m3_axi_wready;
    // B    
    assign m_s1_axi_bresp[(2+1)*2-1:2*2] = m3_axi_bresp;
    assign m_s1_axi_bvalid[2]            = m3_axi_bvalid;
    assign m3_axi_bready                 = m_s1_axi_bready[2];

    // M4 -- PER S1-ID3
    // AW
    assign m4_axi_awaddr      = m_s1_axi_awaddr[(3+1)*ADDR_WIDTH-1: ADDR_WIDTH*3];
    assign m4_axi_awlen       = m_s1_axi_awlen[(3+1)*8-1:8*3];
    assign m4_axi_awsize      = m_s1_axi_awsize[(3+1)*3-1:3*3];
    assign m4_axi_awburst     = m_s1_axi_awburst[(3+1)*2-1:2*3];
    assign m4_axi_awvalid     = m_s1_axi_awvalid[(3+1)*1-1:1*3];
    assign m_s1_axi_awready[3] = m4_axi_awready;
    // W
    assign m4_axi_wdata       = m_s1_axi_wdata[(3+1)*DATA_WIDTH-1: DATA_WIDTH*3];
    assign m4_axi_wstrb       = m_s1_axi_wstrb[(3+1)*(DATA_WIDTH/8)-1:(DATA_WIDTH/8)*3];
    assign m4_axi_wlast       = m_s1_axi_wlast[3];
    assign m4_axi_wvalid      = m_s1_axi_wvalid[3];
    assign m_s1_axi_wready[3] = m4_axi_wready;
    // B    
    assign m_s1_axi_bresp[(3+1)*2-1:2*3] = m4_axi_bresp;
    assign m_s1_axi_bvalid[3]            = m4_axi_bvalid;
    assign m4_axi_bready                 = m_s1_axi_bready[3];

    // AR    
    assign m4_axi_araddr      = m_s1_axi_araddr[(3+1)*ADDR_WIDTH-1: ADDR_WIDTH*3];
    assign m4_axi_arlen       = m_s1_axi_arlen[(3+1)*8-1:8*3];
    assign m4_axi_arsize      = m_s1_axi_arsize[(3+1)*3-1:3*3];
    assign m4_axi_arburst     = m_s1_axi_arburst[(3+1)*2-1:2*3];
    assign m4_axi_arvalid     = m_s1_axi_arvalid[(3+1)*1-1:1*3];
    assign m_s1_axi_arready[3] = m4_axi_arready;
    
    // R
    assign m_s1_axi_rdata[(3+1)*DATA_WIDTH-1: DATA_WIDTH*3] = m4_axi_rdata;
    assign m_s1_axi_rresp[(3+1)*2-1:2*3]                   = m4_axi_rresp;
    assign m_s1_axi_rlast[3]                               = m4_axi_rlast;
    assign m_s1_axi_rvalid[3]                              = m4_axi_rvalid;
    assign m4_axi_rready                                   = m_s1_axi_rready[3];

    // M5 -- CLINT S1-ID4
    // AW
    assign m5_axi_awaddr      = m_s1_axi_awaddr[(4+1)*ADDR_WIDTH-1: ADDR_WIDTH*4];
    assign m5_axi_awlen       = m_s1_axi_awlen[(4+1)*8-1:8*4];
    assign m5_axi_awsize      = m_s1_axi_awsize[(4+1)*3-1:3*4];
    assign m5_axi_awburst     = m_s1_axi_awburst[(4+1)*2-1:2*4];
    assign m5_axi_awvalid     = m_s1_axi_awvalid[(4+1)*1-1:1*4];
    assign m_s1_axi_awready[4] = m5_axi_awready;
    // W
    assign m5_axi_wdata       = m_s1_axi_wdata[(4+1)*DATA_WIDTH-1: DATA_WIDTH*4];
    assign m5_axi_wstrb       = m_s1_axi_wstrb[(4+1)*(DATA_WIDTH/8)-1:(DATA_WIDTH/8)*4];
    assign m5_axi_wlast       = m_s1_axi_wlast[4];
    assign m5_axi_wvalid      = m_s1_axi_wvalid[4];
    assign m_s1_axi_wready[4] = m5_axi_wready;
    // B    
    assign m_s1_axi_bresp[(4+1)*2-1:2*4] = m5_axi_bresp;
    assign m_s1_axi_bvalid[4]            = m5_axi_bvalid;
    assign m5_axi_bready                 = m_s1_axi_bready[4];

    // AR    
    assign m5_axi_araddr      = m_s1_axi_araddr[(4+1)*ADDR_WIDTH-1: ADDR_WIDTH*4];
    assign m5_axi_arlen       = m_s1_axi_arlen[(4+1)*8-1:8*4];
    assign m5_axi_arsize      = m_s1_axi_arsize[(4+1)*3-1:3*4];
    assign m5_axi_arburst     = m_s1_axi_arburst[(4+1)*2-1:2*4];
    assign m5_axi_arvalid     = m_s1_axi_arvalid[(4+1)*1-1:1*4];
    assign m_s1_axi_arready[4] = m5_axi_arready;
    
    // R
    assign m_s1_axi_rdata[(4+1)*DATA_WIDTH-1: DATA_WIDTH*4] = m5_axi_rdata;
    assign m_s1_axi_rresp[(4+1)*2-1:2*4]                   = m5_axi_rresp;
    assign m_s1_axi_rlast[4]                               = m5_axi_rlast;
    assign m_s1_axi_rvalid[4]                              = m5_axi_rvalid;
    assign m5_axi_rready                                   = m_s1_axi_rready[4];
	
    // M6 -- PLIC S1-ID5
    // AW
    assign m6_axi_awaddr      = m_s1_axi_awaddr[(5+1)*ADDR_WIDTH-1: ADDR_WIDTH*5];
    assign m6_axi_awlen       = m_s1_axi_awlen[(5+1)*8-1:8*5];
    assign m6_axi_awsize      = m_s1_axi_awsize[(5+1)*3-1:3*5];
    assign m6_axi_awburst     = m_s1_axi_awburst[(5+1)*2-1:2*5];
    assign m6_axi_awvalid     = m_s1_axi_awvalid[(5+1)*1-1:1*5];
    assign m_s1_axi_awready[5] = m6_axi_awready;
    // W
    assign m6_axi_wdata       = m_s1_axi_wdata[(5+1)*DATA_WIDTH-1: DATA_WIDTH*5];
    assign m6_axi_wstrb       = m_s1_axi_wstrb[(5+1)*(DATA_WIDTH/8)-1:(DATA_WIDTH/8)*5];
    assign m6_axi_wlast       = m_s1_axi_wlast[5];
    assign m6_axi_wvalid      = m_s1_axi_wvalid[5];
    assign m_s1_axi_wready[5] = m6_axi_wready;
    // B    
    assign m_s1_axi_bresp[(5+1)*2-1:2*5] = m6_axi_bresp;
    assign m_s1_axi_bvalid[5]            = m6_axi_bvalid;
    assign m6_axi_bready                 = m_s1_axi_bready[5];

    // AR    
    assign m6_axi_araddr      = m_s1_axi_araddr[(5+1)*ADDR_WIDTH-1: ADDR_WIDTH*4];
    assign m6_axi_arlen       = m_s1_axi_arlen[(5+1)*8-1:8*5];
    assign m6_axi_arsize      = m_s1_axi_arsize[(5+1)*3-1:3*5];
    assign m6_axi_arburst     = m_s1_axi_arburst[(5+1)*2-1:2*5];
    assign m6_axi_arvalid     = m_s1_axi_arvalid[(5+1)*1-1:1*5];
    assign m_s1_axi_arready[5] = m6_axi_arready;
    
    // R
    assign m_s1_axi_rdata[(5+1)*DATA_WIDTH-1: DATA_WIDTH*5] = m6_axi_rdata;
    assign m_s1_axi_rresp[(5+1)*2-1:2*5]                   = m6_axi_rresp;
    assign m_s1_axi_rlast[5]                               = m6_axi_rlast;
    assign m_s1_axi_rvalid[5]                              = m6_axi_rvalid;
    assign m6_axi_rready                                   = m_s1_axi_rready[5];
	
endmodule


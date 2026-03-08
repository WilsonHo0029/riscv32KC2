// RISC-V 32KC2 System Top Level
// Complete RISC-V system including core, debug, and external interfaces
// Architecture: RV32IMC_Zicsr_Zifencei
// Debug: RISC-V Debug Specification 0.13

`include "../riscv_core/riscv_defines.v"

module riscv32KC2_system (
    // System Clock and Reset
    input               sys_clk,            // System clock
    input               sys_rst_n,          // System reset (active low)
    
    // JTAG Debug Interface (optional - for external debugger)
    input               jtag_tck,           // JTAG test clock
    input               jtag_tms,           // JTAG test mode select
    input               jtag_tdi,           // JTAG test data input
    output              jtag_tdo,           // JTAG test data output
    input               jtag_trst_n,        // JTAG test reset (optional, active low)
    output              uart_txd,           // UART Transmit
    input               uart_rxd,           // UART Receive
    
    // GPIO External Interface
    input  [31:0]       gpio_i,             // GPIO input
    output [31:0]       gpio_o,             // GPIO output
    output [31:0]       gpio_oe,            // GPIO output enable
    output [31:0]       gpio_ie,            // GPIO input enable
    output [31:0]       gpio_pue,           // GPIO pull-up enable
    output [31:0]       gpio_pde,          // GPIO pull-down enable
    output [31:0]       gpio_ds0,          // GPIO drive strength 0
    output [31:0]       gpio_ds1,          // GPIO drive strength 1
    
    // CLINT RTC Input
    input               rtc_i               // CLINT RTC synchronization input (32768 Hz)

);
    
    // Internal debug interface signals (multi-hart support)
    // For single-hart system, HART_NUM=1, arrays become [0:0]
    wire                debug_req;
    wire                debug_mode;
    wire 		ndmreset;
    wire [31:0]         core_pc;
    
    // Multi-hart arrays (for HART_NUM=1, these are single-bit arrays)
    wire [0:0]          debug_req_array;
    wire [31:0]         pc_array;
    
    // Connect single-hart signals to arrays (HART_NUM=1)
    assign debug_req = debug_req_array[0];
    assign pc_array[31:0] = core_pc;
    
    // Internal APB signals - Debug block to APB interconnect
    wire [31:0]         debug_apb_paddr;
    wire                debug_apb_psel;
    wire                debug_apb_penable;
    wire                debug_apb_pwrite;
    wire [31:0]         debug_apb_pwdata;
    wire [3:0]          debug_apb_pstrb;
    wire [31:0]         debug_apb_prdata;
    wire                debug_apb_pready;
    wire                debug_apb_pslverr;
    
    // Internal AXI signals - Bus to Boot ROM (AXI Lite)
    wire [31:0]         rom_axi_araddr;
    wire                rom_axi_arvalid;
    wire                rom_axi_arready;
    wire [31:0]         rom_axi_rdata;
    wire [1:0]          rom_axi_rresp;
    wire                rom_axi_rvalid;
    wire                rom_axi_rready;
    
    wire                uart_irq;
    
    // Internal AXI signals - RISC-V core instruction fetch AXI to instruction SRAM
    wire [31:0]         core_if_araddr;
    wire [7:0]          core_if_arlen;
    wire [2:0]          core_if_arsize;
    wire [1:0]          core_if_arburst;
    wire                core_if_arvalid;
    wire                core_if_arready;
    wire [31:0]         core_if_rdata;
    wire [1:0]          core_if_rresp;
    wire                core_if_rlast;
    wire                core_if_rvalid;
    wire                core_if_rready;
    
    // Internal AXI signals - RISC-V core data AXI to splitter
    wire [31:0]         core_data_awaddr;
    wire [7:0]          core_data_awlen;
    wire [2:0]          core_data_awsize;
    wire [1:0]          core_data_awburst;
    wire                core_data_awvalid;
    wire                core_data_awready;
    wire [31:0]         core_data_wdata;
    wire [3:0]          core_data_wstrb;
    wire                core_data_wlast;
    wire                core_data_wvalid;
    wire                core_data_wready;
    wire [1:0]          core_data_bresp;
    wire                core_data_bvalid;
    wire                core_data_bready;
    wire [31:0]         core_data_araddr;
    wire [7:0]          core_data_arlen;
    wire [2:0]          core_data_arsize;
    wire [1:0]          core_data_arburst;
    wire                core_data_arvalid;
    wire                core_data_arready;
    wire [31:0]         core_data_rdata;
    wire [1:0]          core_data_rresp;
    wire                core_data_rlast;
    wire                core_data_rvalid;
    wire                core_data_rready;
   
    
    // Internal AXI signals - Peripheral AXI
    wire [31:0]         axi_perip_awaddr;
    wire [7:0]          axi_perip_awlen;
    wire [2:0]          axi_perip_awsize;
    wire [1:0]          axi_perip_awburst;
    wire                axi_perip_awvalid;
    wire                axi_perip_awready;
    wire [31:0]         axi_perip_wdata;
    wire [3:0]          axi_perip_wstrb;
    wire                axi_perip_wlast;
    wire                axi_perip_wvalid;
    wire                axi_perip_wready;
    wire [1:0]          axi_perip_bresp;
    wire                axi_perip_bvalid;
    wire                axi_perip_bready;
    wire [31:0]         axi_perip_araddr;
    wire [7:0]          axi_perip_arlen;
    wire [2:0]          axi_perip_arsize;
    wire [1:0]          axi_perip_arburst;
    wire                axi_perip_arvalid;
    wire                axi_perip_arready;
    wire [31:0]         axi_perip_rdata;
    wire [1:0]          axi_perip_rresp;
    wire                axi_perip_rlast;
    wire                axi_perip_rvalid;
    wire                axi_perip_rready;

    // Internal AXI signals - Debug AXI to axi2apb bridge
    wire [31:0]         axi_debug_awaddr;
    wire [7:0]          axi_debug_awlen;
    wire [2:0]          axi_debug_awsize;
    wire [1:0]          axi_debug_awburst;
    wire                axi_debug_awvalid;
    wire                axi_debug_awready;
    wire [31:0]         axi_debug_wdata;
    wire [3:0]          axi_debug_wstrb;
    wire                axi_debug_wlast;
    wire                axi_debug_wvalid;
    wire                axi_debug_wready;
    wire [1:0]          axi_debug_bresp;
    wire                axi_debug_bvalid;
    wire                axi_debug_bready;
    wire [31:0]         axi_debug_araddr;
    wire [7:0]          axi_debug_arlen;
    wire [2:0]          axi_debug_arsize;
    wire [1:0]          axi_debug_arburst;
    wire                axi_debug_arvalid;
    wire                axi_debug_arready;
    wire [31:0]         axi_debug_rdata;
    wire [1:0]          axi_debug_rresp;
    wire                axi_debug_rlast;
    wire                axi_debug_rvalid;
    wire                axi_debug_rready;
	
    wire [31:0]         gpio_irq;            // GPIO interrupt
    
    // Internal AXI signals - CLINT
    wire [31:0]         axi_clint_awaddr;
    wire [7:0]          axi_clint_awlen;
    wire [2:0]          axi_clint_awsize;
    wire [1:0]          axi_clint_awburst;
    wire                axi_clint_awvalid;
    wire                axi_clint_awready;
    wire [31:0]         axi_clint_wdata;
    wire [3:0]          axi_clint_wstrb;
    wire                axi_clint_wlast;
    wire                axi_clint_wvalid;
    wire                axi_clint_wready;
    wire [1:0]          axi_clint_bresp;
    wire                axi_clint_bvalid;
    wire                axi_clint_bready;
    wire [31:0]         axi_clint_araddr;
    wire [7:0]          axi_clint_arlen;
    wire [2:0]          axi_clint_arsize;
    wire [1:0]          axi_clint_arburst;
    wire                axi_clint_arvalid;
    wire                axi_clint_arready;
    wire [31:0]         axi_clint_rdata;
    wire [1:0]          axi_clint_rresp;
    wire                axi_clint_rlast;
    wire                axi_clint_rvalid;
    wire                axi_clint_rready;

    // CLINT interrupt outputs
    wire                clint_tmr_irq;
    wire                clint_sft_irq;
    
    // Internal AXI signals - PLIC
    wire [31:0]         axi_plic_awaddr;
    wire [7:0]          axi_plic_awlen;
    wire [2:0]          axi_plic_awsize;
    wire [1:0]          axi_plic_awburst;
    wire                axi_plic_awvalid;
    wire                axi_plic_awready;
    wire [31:0]         axi_plic_wdata;
    wire [3:0]          axi_plic_wstrb;
    wire                axi_plic_wlast;
    wire                axi_plic_wvalid;
    wire                axi_plic_wready;
    wire [1:0]          axi_plic_bresp;
    wire                axi_plic_bvalid;
    wire                axi_plic_bready;
    wire [31:0]         axi_plic_araddr;
    wire [7:0]          axi_plic_arlen;
    wire [2:0]          axi_plic_arsize;
    wire [1:0]          axi_plic_arburst;
    wire                axi_plic_arvalid;
    wire                axi_plic_arready;
    wire [31:0]         axi_plic_rdata;
    wire [1:0]          axi_plic_rresp;
    wire                axi_plic_rlast;
    wire                axi_plic_rvalid;
    wire                axi_plic_rready;
    
    // PLIC interrupt outputs
    wire [0:0]          plic_ext_irq;  // Single-hart system, so [0:0]
    wire		sys_debug_rstn = sys_rst_n & ~ndmreset;
    reg  [1:0]          r_sys_debug_rstn;
    reg  [1:0]          r_sys_rstn;
    wire 		sys_debug_rstn_sync = r_sys_debug_rstn[1];
    wire		sys_rst_n_sync = r_sys_rstn[1];
    always@(posedge sys_clk or negedge sys_debug_rstn)
	if(~sys_debug_rstn) begin
		r_sys_debug_rstn <= 2'b00;
	end
	else begin
		r_sys_debug_rstn[0] <= 1'b1;
		r_sys_debug_rstn[1] <= r_sys_debug_rstn[0];

	end
   always@(posedge sys_clk or negedge sys_rst_n)
	if(~sys_rst_n) begin
		r_sys_rstn <= 2'b00;
	end
	else begin
		r_sys_rstn[0] <= 1'b1;
		r_sys_rstn[1] <= r_sys_rstn[0];
	end
    // Instantiate RISC-V Core
    riscv_core #(
        .RESET_PC       (32'h00001000),     // Reset address (Boot ROM start)
        .INSTR_RAM_BASE (32'h70000000),     // Instruction RAM base address
        .INSTR_RAM_SIZE (32'h20000000)      // Instruction RAM size (512 MB)
    ) u_riscv_core (
        // Clock and Reset
        .clk            (sys_clk),
        .rst_n          (sys_debug_rstn_sync),
        
        // AXI4 Instruction Fetch Interface (connected to instruction SRAM)
        .axi_araddr     (core_if_araddr),
        .axi_arlen      (core_if_arlen),
        .axi_arsize     (core_if_arsize),
        .axi_arburst    (core_if_arburst),
        .axi_arvalid    (core_if_arvalid),
        .axi_arready    (core_if_arready),
        .axi_rdata      (core_if_rdata),
        .axi_rresp      (core_if_rresp),
        .axi_rlast      (core_if_rlast),
        .axi_rvalid     (core_if_rvalid),
        .axi_rready     (core_if_rready),
        
        // AXI4 Data Access Interface (connected to axi_apb_splitter)
        .axi_awaddr     (core_data_awaddr),
        .axi_awlen      (core_data_awlen),
        .axi_awsize     (core_data_awsize),
        .axi_awburst    (core_data_awburst),
        .axi_awvalid    (core_data_awvalid),
        .axi_awready    (core_data_awready),
        .axi_wdata      (core_data_wdata),
        .axi_wstrb      (core_data_wstrb),
        .axi_wlast      (core_data_wlast),
        .axi_wvalid     (core_data_wvalid),
        .axi_wready     (core_data_wready),
        .axi_bresp      (core_data_bresp),
        .axi_bvalid     (core_data_bvalid),
        .axi_bready     (core_data_bready),
        .axi_daraddr    (core_data_araddr),
        .axi_darlen     (core_data_arlen),
        .axi_darsize    (core_data_arsize),
        .axi_darburst   (core_data_arburst),
        .axi_darvalid   (core_data_arvalid),
        .axi_darready   (core_data_arready),
        .axi_drdata     (core_data_rdata),
        .axi_drresp     (core_data_rresp),
        .axi_drlast     (core_data_rlast),
        .axi_drvalid    (core_data_rvalid),
        .axi_drready    (core_data_rready),
        
        // Debug Interface (Hart Control)
        .debug_req      (debug_req),
        .debug_mode     (debug_mode),
        .pc             (core_pc),
        
        // CLINT Interrupt Inputs
        .clint_tmr_irq  (clint_tmr_irq),
        .clint_sft_irq  (clint_sft_irq),
        
        // External Interrupt Input (from PLIC)
        .ext_irq        (plic_ext_irq[0])
    );

    riscv32KC2_bus #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32)
    ) u_bus (
        // Clock and Reset
        .aclk           (sys_clk),
        .aresetn        (sys_debug_rstn_sync),
        
        // AXI Slave Interface 0 (from Instruction Fetch)
        // Write Address Channel
        .s0_axi_awaddr  (),
        .s0_axi_awlen   (),
        .s0_axi_awsize  (),
        .s0_axi_awburst (),
        .s0_axi_awvalid (),
        .s0_axi_awready (),
        
        // Write Data Channel
        .s0_axi_wdata   (),
        .s0_axi_wstrb   (),
        .s0_axi_wlast   (),
        .s0_axi_wvalid  (),
        .s0_axi_wready  (),
        
        // Write Response Channel
        .s0_axi_bresp   (),
        .s0_axi_bvalid  (),
        .s0_axi_bready  (),
        
        // Read Address Channel
        .s0_axi_araddr  (core_if_araddr),
        .s0_axi_arlen   (core_if_arlen),
        .s0_axi_arsize  (core_if_arsize),
        .s0_axi_arburst (core_if_arburst),
        .s0_axi_arvalid (core_if_arvalid),
        .s0_axi_arready (core_if_arready),
                             
        // Read Data Channel 
        .s0_axi_rdata   (core_if_rdata),
        .s0_axi_rresp   (core_if_rresp),
        .s0_axi_rlast   (core_if_rlast),
        .s0_axi_rvalid  (core_if_rvalid),
        .s0_axi_rready  (core_if_rready),
   
        // AXI Slave Interface 1 (from Data Bus)
        .s1_axi_awaddr  (core_data_awaddr),
        .s1_axi_awlen   (core_data_awlen),
        .s1_axi_awsize  (core_data_awsize),
        .s1_axi_awburst (core_data_awburst),
        .s1_axi_awvalid (core_data_awvalid),
        .s1_axi_awready (core_data_awready),
        
        // Write Data Channel
        .s1_axi_wdata   (core_data_wdata),	
        .s1_axi_wstrb   (core_data_wstrb),
        .s1_axi_wlast   (core_data_wlast),
        .s1_axi_wvalid  (core_data_wvalid),  
        .s1_axi_wready  (core_data_wready),
        
        // Write Response Channel
        .s1_axi_bresp   (core_data_bresp),
        .s1_axi_bvalid  (core_data_bvalid),
        .s1_axi_bready  (core_data_bready),
        
        // Read Address Channel
        .s1_axi_araddr  (core_data_araddr),
        .s1_axi_arlen   (core_data_arlen),
        .s1_axi_arsize  (core_data_arsize),
        .s1_axi_arburst (core_data_arburst),
        .s1_axi_arvalid (core_data_arvalid),
        .s1_axi_arready (core_data_arready),
        
        // Read Data Channel
        .s1_axi_rdata   (core_data_rdata),
        .s1_axi_rresp   (core_data_rresp),
        .s1_axi_rlast   (core_data_rlast),		
        .s1_axi_rvalid  (core_data_rvalid),
        .s1_axi_rready  (core_data_rready),

        // AXI Master Interface 0 --- IRAM
        .m0_axi_awaddr  (),
        .m0_axi_awlen   (),
        .m0_axi_awsize  (),
        .m0_axi_awburst (),
        .m0_axi_awvalid (),
        .m0_axi_awready (1'b0),
        
        // Write Data Channel
        .m0_axi_wdata   (),
        .m0_axi_wstrb   (),
        .m0_axi_wlast   (),
        .m0_axi_wvalid  (),
        .m0_axi_wready  (1'b0),
            
        // Write Response Channel
        .m0_axi_bresp   (2'b00),
        .m0_axi_bvalid  (1'b0),
        .m0_axi_bready  (), 
        // Read Address Channel
        .m0_axi_araddr  (),
        .m0_axi_arlen   (),
        .m0_axi_arsize  (),
        .m0_axi_arburst (),
        .m0_axi_arvalid (),
        .m0_axi_arready (1'b0),
        
        // Read Data Channel
        .m0_axi_rdata   (32'd0),
        .m0_axi_rresp   (2'b00),
        .m0_axi_rlast   (1'b0),
        .m0_axi_rvalid  (1'b0),
        .m0_axi_rready  (),

        // AXI Master Interface 1 --- DRAM
        .m1_axi_awaddr  (),
        .m1_axi_awlen   (),
        .m1_axi_awsize  (),
        .m1_axi_awburst (),
        .m1_axi_awvalid (),
        .m1_axi_awready (1'b0),
        
        // Write Data Channel
        .m1_axi_wdata   (),
        .m1_axi_wstrb   (),
        .m1_axi_wlast   (),
        .m1_axi_wvalid  (),
        .m1_axi_wready  (1'b0),
        
        // Write Response Channel
        .m1_axi_bresp   (2'b00),
        .m1_axi_bvalid  (1'b0),
        .m1_axi_bready  (),	 
        
        // Read Address Channel
        .m1_axi_araddr  (),
        .m1_axi_arlen   (),
        .m1_axi_arsize  (),
        .m1_axi_arburst (),
        .m1_axi_arvalid (),
        .m1_axi_arready (1'b0),
        
        // Read Data Channel
        .m1_axi_rdata   (32'd0),
        .m1_axi_rresp   (2'b00),
        .m1_axi_rlast   (1'b0),
        .m1_axi_rvalid  (1'b0),
        .m1_axi_rready  (),

        // AXI Master Interface 2 --- MROM (Read-Only)
        // Read Address Channel
        .m2_axi_araddr  (rom_axi_araddr),
        .m2_axi_arlen   (),
        .m2_axi_arsize  (),
        .m2_axi_arburst (),	
        .m2_axi_arvalid (rom_axi_arvalid),
        .m2_axi_arready (rom_axi_arready),
        
        // Read Data Channel
        .m2_axi_rdata   (rom_axi_rdata),
        .m2_axi_rresp   (rom_axi_rresp),
        .m2_axi_rlast   (1'b1),
        .m2_axi_rvalid  (rom_axi_rvalid),
        .m2_axi_rready  (rom_axi_rready),

        // AXI Master Interface 3 --- Debug
        .m3_axi_awaddr  (axi_debug_awaddr),
        .m3_axi_awlen   (axi_debug_awlen),
        .m3_axi_awsize  (axi_debug_awsize),
        .m3_axi_awburst (axi_debug_awburst),
        .m3_axi_awvalid (axi_debug_awvalid),
        .m3_axi_awready (axi_debug_awready),
        
        // Write Data Channel
        .m3_axi_wdata   (axi_debug_wdata),
        .m3_axi_wstrb   (axi_debug_wstrb),
        .m3_axi_wlast   (axi_debug_wlast),
        .m3_axi_wvalid  (axi_debug_wvalid),
        .m3_axi_wready  (axi_debug_wready),
        
        // Write Response Channel
        .m3_axi_bresp   (axi_debug_bresp),
        .m3_axi_bvalid  (axi_debug_bvalid),
        .m3_axi_bready  (axi_debug_bready), 
        
        // Read Address Channel
        .m3_axi_araddr  (axi_debug_araddr),
        .m3_axi_arlen   (axi_debug_arlen),
        .m3_axi_arsize  (axi_debug_arsize),
        .m3_axi_arburst (axi_debug_arburst),
        .m3_axi_arvalid (axi_debug_arvalid),
        .m3_axi_arready (axi_debug_arready),
        
        // Read Data Channel
        .m3_axi_rdata   (axi_debug_rdata),
        .m3_axi_rresp   (axi_debug_rresp),
        .m3_axi_rlast   (axi_debug_rlast),
        .m3_axi_rvalid  (axi_debug_rvalid),
        .m3_axi_rready  (axi_debug_rready),

        // AXI Master Interface 4 --- Perperial
        .m4_axi_awaddr  (axi_perip_awaddr),
        .m4_axi_awlen   (axi_perip_awlen),
        .m4_axi_awsize  (axi_perip_awsize),
        .m4_axi_awburst (axi_perip_awburst),
        .m4_axi_awvalid (axi_perip_awvalid),
        .m4_axi_awready (axi_perip_awready),
        
        // Write Data Channel
        .m4_axi_wdata   (axi_perip_wdata),
        .m4_axi_wstrb   (axi_perip_wstrb),
        .m4_axi_wlast   (axi_perip_wlast),
        .m4_axi_wvalid  (axi_perip_wvalid),
        .m4_axi_wready  (axi_perip_wready),
        
        // Write Response Channel
        .m4_axi_bresp   (axi_perip_bresp),
        .m4_axi_bvalid  (axi_perip_bvalid),
        .m4_axi_bready  (axi_perip_bready), 
        
        // Read Address Channel
        .m4_axi_araddr  (axi_perip_araddr),
        .m4_axi_arlen   (axi_perip_arlen),
        .m4_axi_arsize  (axi_perip_arsize),
        .m4_axi_arburst (axi_perip_arburst),
        .m4_axi_arvalid (axi_perip_arvalid),
        .m4_axi_arready (axi_perip_arready),
        
        // Read Data Channel
        .m4_axi_rdata   (axi_perip_rdata),
        .m4_axi_rresp   (axi_perip_rresp),
        .m4_axi_rlast   (axi_perip_rlast),
        .m4_axi_rvalid  (axi_perip_rvalid),
        .m4_axi_rready  (axi_perip_rready),

        // AXI Master Interface 5 --- CLINT
        .m5_axi_awaddr  (axi_clint_awaddr),
        .m5_axi_awlen   (axi_clint_awlen),
        .m5_axi_awsize  (axi_clint_awsize),
        .m5_axi_awburst (axi_clint_awburst),
        .m5_axi_awvalid (axi_clint_awvalid),
        .m5_axi_awready (axi_clint_awready),
        
        // Write Data Channel
        .m5_axi_wdata   (axi_clint_wdata),
        .m5_axi_wstrb   (axi_clint_wstrb),
        .m5_axi_wlast   (axi_clint_wlast),
        .m5_axi_wvalid  (axi_clint_wvalid),
        .m5_axi_wready  (axi_clint_wready),
        
        // Write Response Channel
        .m5_axi_bresp   (axi_clint_bresp),
        .m5_axi_bvalid  (axi_clint_bvalid),
        .m5_axi_bready  (axi_clint_bready),
        
        // Read Address Channel
        .m5_axi_araddr  (axi_clint_araddr),
        .m5_axi_arlen   (axi_clint_arlen),
        .m5_axi_arsize  (axi_clint_arsize),
        .m5_axi_arburst (axi_clint_arburst),
        .m5_axi_arvalid (axi_clint_arvalid),
        .m5_axi_arready (axi_clint_arready),
        
        // Read Data Channel
        .m5_axi_rdata   (axi_clint_rdata),
        .m5_axi_rresp   (axi_clint_rresp),
        .m5_axi_rlast   (axi_clint_rlast),
        .m5_axi_rvalid  (axi_clint_rvalid),
        .m5_axi_rready  (axi_clint_rready),

        // AXI Master Interface 6 --- PLIC
        .m6_axi_awaddr  (axi_plic_awaddr),
        .m6_axi_awlen   (axi_plic_awlen),
        .m6_axi_awsize  (axi_plic_awsize),
        .m6_axi_awburst (axi_plic_awburst),
        .m6_axi_awvalid (axi_plic_awvalid),
        .m6_axi_awready (axi_plic_awready),
        
        // Write Data Channel
        .m6_axi_wdata   (axi_plic_wdata),
        .m6_axi_wstrb   (axi_plic_wstrb),
        .m6_axi_wlast   (axi_plic_wlast),
        .m6_axi_wvalid  (axi_plic_wvalid),
        .m6_axi_wready  (axi_plic_wready),
        
        // Write Response Channel
        .m6_axi_bresp   (axi_plic_bresp),
        .m6_axi_bvalid  (axi_plic_bvalid),
        .m6_axi_bready  (axi_plic_bready),
        
        // Read Address Channel
        .m6_axi_araddr  (axi_plic_araddr),
        .m6_axi_arlen   (axi_plic_arlen),
        .m6_axi_arsize  (axi_plic_arsize),
        .m6_axi_arburst (axi_plic_arburst),
        .m6_axi_arvalid (axi_plic_arvalid),
        .m6_axi_arready (axi_plic_arready),
        
        // Read Data Channel
        .m6_axi_rdata   (axi_plic_rdata),
        .m6_axi_rresp   (axi_plic_rresp),
        .m6_axi_rlast   (axi_plic_rlast),
        .m6_axi_rvalid  (axi_plic_rvalid),
        .m6_axi_rready  (axi_plic_rready)
    );

    // Instantiate Debug Block (JTAG DTM + Debug Module)
    riscv_debug_block #(
        .HART_NUM       (1),                // Single-hart system
        .HART_ID_W      (1)                 // Hart ID width for 1 hart
    ) u_debug_block (
        // System Clock and Reset
        .clk            (sys_clk),
        .rst_n          (sys_rst_n_sync),
        
        // JTAG Interface
        .tck            (jtag_tck),
        .tms            (jtag_tms),
        .tdi            (jtag_tdi),
        .tdo            (jtag_tdo),
        .trst_n         (jtag_trst_n),
        
        // Hart Control Interface (to/from RISC-V core) - multi-hart arrays
        .debug_req      (debug_req_array),
        .debug_mode     (debug_mode),
        .ndmreset	(ndmreset),
        // APB Slave Interface (from APB decoder)
        .m_apb_paddr    (debug_apb_paddr),
        .m_apb_psel     (debug_apb_psel),
        .m_apb_penable  (debug_apb_penable),
        .m_apb_pwrite   (debug_apb_pwrite),
        .m_apb_pwdata   (debug_apb_pwdata),
        .m_apb_pstrb    (debug_apb_pstrb),
        .m_apb_prdata   (debug_apb_prdata),
        .m_apb_pready   (debug_apb_pready),
        .m_apb_pslverr  (debug_apb_pslverr)
    );
    
    // Instantiate Boot ROM (AXI Lite wrapper)
    mrom_axi_lite #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32),
        .ROM_BASE_ADDR  (32'h00001000),     // Boot ROM base address
        .ROM_ADDR_SIZE  (32'h00007000),     // Boot ROM address space (28KB)
        .ROM_SIZE       (32'h00000100),     // Actual Boot ROM size (256 bytes)
        .ROM_AW         (12),               // ROM address width
        .ROM_DW         (32),               // ROM data width
        .ROM_DP         (64)                // ROM depth (64 words = 256 bytes)
    ) u_boot_rom (
        // Clock and Reset
        .aclk           (sys_clk),
        .aresetn        (sys_debug_rstn_sync),
        
        // AXI Lite Slave Interface (Read-Only)
        .s_axi_araddr   (rom_axi_araddr),
        .s_axi_arvalid  (rom_axi_arvalid),
        .s_axi_arready  (rom_axi_arready),
        .s_axi_rdata    (rom_axi_rdata),
        .s_axi_rresp    (rom_axi_rresp),
        .s_axi_rvalid   (rom_axi_rvalid),
        .s_axi_rready   (rom_axi_rready)
    );
    
    riscv32KC2_peripheral #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32)
    ) u_peripheral (
        .clk            (sys_clk),
        .rst_n          (sys_debug_rstn_sync),

        // AXI4-Lite Slave Interface (from Bus m4)
        .s_axi_awaddr   (axi_perip_awaddr),
        .s_axi_awsize   (axi_perip_awsize),
        .s_axi_awvalid  (axi_perip_awvalid),
        .s_axi_awready  (axi_perip_awready),
        .s_axi_wdata    (axi_perip_wdata),
        .s_axi_wstrb    (axi_perip_wstrb),
        .s_axi_wvalid   (axi_perip_wvalid),
        .s_axi_wready   (axi_perip_wready),
        .s_axi_bresp    (axi_perip_bresp),
        .s_axi_bvalid   (axi_perip_bvalid),
        .s_axi_bready   (axi_perip_bready),
        .s_axi_araddr   (axi_perip_araddr),
        .s_axi_arsize   (axi_perip_arsize),
        .s_axi_arvalid  (axi_perip_arvalid),
        .s_axi_arready  (axi_perip_arready),
        .s_axi_rdata    (axi_perip_rdata),
        .s_axi_rresp    (axi_perip_rresp),
        .s_axi_rvalid   (axi_perip_rvalid),
        .s_axi_rready   (axi_perip_rready),

        // UART External Interface
        .uart_rxd       (uart_rxd),
        .uart_txd       (uart_txd),
        .uart_irq       (uart_irq),

        // GPIO External Interface
        .gpio_i         (gpio_i),
        .gpio_o         (gpio_o),
        .gpio_oe        (gpio_oe),
        .gpio_ie        (gpio_ie),
        .gpio_pue       (gpio_pue),
        .gpio_pde       (gpio_pde),
        .gpio_ds0       (gpio_ds0),
        .gpio_ds1       (gpio_ds1),
        .gpio_irq       (gpio_irq)
    );

    // Drive AXI rlast for the bus (APB is always single-cycle)
    assign axi_perip_rlast = 1'b1;
    assign axi_debug_rlast = 1'b1;

    // Instantiate Debug AXI to APB Bridge
    axi2apb_bridge #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32)
    ) u_debug_axi2apb (
        .aclk           (sys_clk),
        .aresetn        (sys_debug_rstn_sync),
        
        // AXI Slave Interface (from Bus M3)
        .s_axi_awaddr   (axi_debug_awaddr),
        .s_axi_awsize   (axi_debug_awsize),
        .s_axi_awvalid  (axi_debug_awvalid),
        .s_axi_awready  (axi_debug_awready),
        .s_axi_wdata    (axi_debug_wdata),
        .s_axi_wstrb    (axi_debug_wstrb),
        .s_axi_wvalid   (axi_debug_wvalid),
        .s_axi_wready   (axi_debug_wready),
        .s_axi_bresp    (axi_debug_bresp),
        .s_axi_bvalid   (axi_debug_bvalid),
        .s_axi_bready   (axi_debug_bready),
        .s_axi_araddr   (axi_debug_araddr),
        .s_axi_arsize   (axi_debug_arsize),
        .s_axi_arvalid  (axi_debug_arvalid),
        .s_axi_arready  (axi_debug_arready),
        .s_axi_rdata    (axi_debug_rdata),
        .s_axi_rresp    (axi_debug_rresp),
        .s_axi_rvalid   (axi_debug_rvalid),
        .s_axi_rready   (axi_debug_rready),
        
        // APB Master Interface (to Debug Block)
        .m_apb_paddr    (debug_apb_paddr),
        .m_apb_psel     (debug_apb_psel),
        .m_apb_penable  (debug_apb_penable),
        .m_apb_pwrite   (debug_apb_pwrite),
        .m_apb_pwdata   (debug_apb_pwdata),
        .m_apb_pstrb    (debug_apb_pstrb),
        .m_apb_prdata   (debug_apb_prdata),
        .m_apb_pready   (debug_apb_pready),
        .m_apb_pslverr  (debug_apb_pslverr)
    );
    
    // Instantiate CLINT (Core Local Interruptor)
    axi_riscv_clint #(
        .HART_NUM       (1),                // Single-hart system
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32)
    ) u_clint (
        // Clock and Reset
        .aclk           (sys_clk),
        .aresetn        (sys_debug_rstn_sync),
        
        // AXI Lite Slave Interface (from Bus m5)
        .s_axi_awaddr   (axi_clint_awaddr),
        .s_axi_awsize   (axi_clint_awsize),
        .s_axi_awvalid  (axi_clint_awvalid),
        .s_axi_awready  (axi_clint_awready),
        .s_axi_wdata    (axi_clint_wdata),
        .s_axi_wstrb    (axi_clint_wstrb),
        .s_axi_wvalid   (axi_clint_wvalid),
        .s_axi_wready   (axi_clint_wready),
        .s_axi_bresp    (axi_clint_bresp),
        .s_axi_bvalid   (axi_clint_bvalid),
        .s_axi_bready   (axi_clint_bready),
        .s_axi_araddr   (axi_clint_araddr),
        .s_axi_arsize   (axi_clint_arsize),
        .s_axi_arvalid  (axi_clint_arvalid),
        .s_axi_arready  (axi_clint_arready),
        .s_axi_rdata    (axi_clint_rdata),
        .s_axi_rresp    (axi_clint_rresp),
        .s_axi_rvalid   (axi_clint_rvalid),
        .s_axi_rready   (axi_clint_rready),
        
        // RTC Synchronization Input (32768 Hz clock - can be tied to sys_clk divided or external)
        .rtc_i          (rtc_i),            // Connected to system output port
        
        // Interrupt Outputs
        .clint_tmr_irq  (clint_tmr_irq),
        .clint_sft_irq  (clint_sft_irq)
    );
    
    // Drive AXI rlast for CLINT (single-cycle responses)
    assign axi_clint_rlast = 1'b1;

    // Instantiate PLIC (Platform-Level Interrupt Controller)
    axi_riscv_plic #(
        .HART_NUM       (1),                // Single-hart system
        .PLIC_PRIO_WIDTH(3),                // Priority width (3 bits)
        .PLIC_NUM       (32),               // Number of interrupt sources
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32)
    ) u_plic (
        // Clock and Reset
        .aclk           (sys_clk),
        .aresetn        (sys_debug_rstn_sync),
        
        // AXI Lite Slave Interface (from Bus m6)
        .s_axi_awaddr   (axi_plic_awaddr),
        .s_axi_awsize   (axi_plic_awsize),
        .s_axi_awvalid  (axi_plic_awvalid),
        .s_axi_awready  (axi_plic_awready),
        .s_axi_wdata    (axi_plic_wdata),
        .s_axi_wstrb    (axi_plic_wstrb),
        .s_axi_wvalid   (axi_plic_wvalid),
        .s_axi_wready   (axi_plic_wready),
        .s_axi_bresp    (axi_plic_bresp),
        .s_axi_bvalid   (axi_plic_bvalid),
        .s_axi_bready   (axi_plic_bready),
        .s_axi_araddr   (axi_plic_araddr),
        .s_axi_arsize   (axi_plic_arsize),
        .s_axi_arvalid  (axi_plic_arvalid),
        .s_axi_arready  (axi_plic_arready),
        .s_axi_rdata    (axi_plic_rdata),
        .s_axi_rresp    (axi_plic_rresp),
        .s_axi_rvalid   (axi_plic_rvalid),
        .s_axi_rready   (axi_plic_rready),
        
        // External Interrupt Sources Input
        // TODO: Connect actual interrupt sources (UART, GPIO, etc.)
        .ext_irq_src    ({32{1'b0}}),       // Placeholder - connect actual interrupt sources
        
        // Interrupt Output to Core
        .ext_irq        (plic_ext_irq)
    );
    
    // Drive AXI rlast for PLIC (single-cycle responses)
    assign axi_plic_rlast = 1'b1;
    // Drive AXI awlen, arlen, awburst, arburst for PLIC (AXI-Lite doesn't use these, but bus requires them)
    assign axi_plic_awlen = 8'h00;
    assign axi_plic_arlen = 8'h00;
    assign axi_plic_awburst = 2'b01;  // INCR
    assign axi_plic_arburst = 2'b01;  // INCR

endmodule


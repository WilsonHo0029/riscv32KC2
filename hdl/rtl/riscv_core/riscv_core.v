// RISC-V Core Top Level
// Architecture: RV32IMC_Zicsr_Zifencei
// Debug: 0.13 Specification
// Bus: AXI4

`include "riscv_defines.v"

module riscv_core #(
    parameter RESET_PC = 32'h00001000,        // Reset address (default: Boot ROM start)
    parameter INSTR_RAM_BASE = 32'h70000000,  // Instruction RAM base address
    parameter INSTR_RAM_SIZE = 32'h20000000   // Instruction RAM size (512 MB)
)(
    // Clock and Reset
    input               clk,
    input               rst_n,
    
    // AXI4 Master Interface (Instruction Fetch)
    // Read Address Channel
    output [31:0]       axi_araddr,
    output [7:0]        axi_arlen,
    output [2:0]        axi_arsize,
    output [1:0]        axi_arburst,
    output              axi_arvalid,
    input               axi_arready,
    // Read Data Channel
    input  [31:0]       axi_rdata,
    input  [1:0]        axi_rresp,
    input               axi_rlast,
    input               axi_rvalid,
    output              axi_rready,
    
    // AXI4 Master Interface (Data Access)
    // Write Address Channel
    output [31:0]       axi_awaddr,
    output [7:0]        axi_awlen,
    output [2:0]        axi_awsize,
    output [1:0]        axi_awburst,
    output              axi_awvalid,
    input               axi_awready,
    // Write Data Channel
    output [31:0]       axi_wdata,
    output [3:0]        axi_wstrb,
    output              axi_wlast,
    output              axi_wvalid,
    input               axi_wready,
    // Write Response Channel
    input  [1:0]        axi_bresp,
    input               axi_bvalid,
    output              axi_bready,
    // Read Address Channel
    output [31:0]       axi_daraddr,
    output [7:0]        axi_darlen,
    output [2:0]        axi_darsize,
    output [1:0]        axi_darburst,
    output              axi_darvalid,
    input               axi_darready,
    // Read Data Channel
    input  [31:0]       axi_drdata,
    input  [1:0]        axi_drresp,
    input               axi_drlast,
    input               axi_drvalid,
    output              axi_drready,
    
    // Debug Interface (Hart Control)
    input               debug_req,      // Debug halt request
    output              debug_mode,     // Debug mode (hart is in debug mode)
    output [31:0]       pc,             // Current PC (for debug)
    
    // CLINT Interrupt Inputs
    input               clint_tmr_irq,  // Timer interrupt from CLINT
    input               clint_sft_irq,  // Software interrupt from CLINT
    
    // External Interrupt Input (from PLIC)
    input               ext_irq         // External interrupt from PLIC
);

    // Internal signals
    wire [31:0] instr_i;
    wire        instr_rvalid;
    wire        ifetch_rvalid;
    wire        ifu_ready;
    wire        instr_rready;
    wire        mem_req;
    wire        mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_be;
    wire [31:0] mem_rdata;
    wire        mem_ready;
    wire        mem_rvalid;  // Read data valid signal
    wire        pipeline_stall;  // Pipeline stall signal (from pipeline)
    wire        pipeline_flush;  // Pipeline flush signal (from pipeline to IFU)
    wire        clr_cmd_ack;
    wire        mem_rd_cmd_ack;
    wire        mem_wr_cmd_ack;   
    // Instantiate pipeline
    riscv_pipeline #(
        .RESET_PC(RESET_PC)
    ) u_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .instr_i(instr_i),
        .instr_rvalid(instr_rvalid),
        .ifetch_addr(pc),
        .ifetch_rvalid(ifetch_rvalid),
        .ifu_ready(ifu_ready),
        .instr_rready(instr_rready),
        .debug_req(debug_req),
        .debug_mode(debug_mode), 
        .pipeline_stall_out(pipeline_stall),  // Get pipeline stall signal
        .pipeline_flush_out(pipeline_flush),  // Get pipeline flush for IFU

        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_be(mem_be),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),
        .mem_rvalid(mem_rvalid),
        .clint_tmr_irq(clint_tmr_irq),
        .clint_sft_irq(clint_sft_irq),
        .ext_irq(ext_irq)              // External interrupt from PLIC
    );
wire [31:0] iram_addr;
wire        iram_cs;
wire        iram_we;
wire [3:0]  iram_wem;
wire [31:0] iram_din;
wire [31:0] iram_dout;     

wire [31:0] iram_from_ifetch_addr;
wire        iram_from_ifetch_cs;
wire [31:0] iram_from_ifetch_dout;
wire        iram_from_ifetch_rready;
wire        iram_from_ifetch_rvalid;
  
    // Instantiate instruction fetch AXI interface
    riscv_axi_ifetch #(
        .INSTR_RAM_BASE(INSTR_RAM_BASE),
        .INSTR_RAM_SIZE(INSTR_RAM_SIZE)
    ) u_ifetch (
        .clk(clk),
        .rst_n(rst_n),
        .ifetch_addr(pc),
        .ifetch_rvalid(ifetch_rvalid),
        .instr_i(instr_i),
        .instr_rvalid(instr_rvalid),
        .ifu_ready(ifu_ready),
        .instr_rready(instr_rready),
        .flush(pipeline_flush),

        .isram_addr(iram_from_ifetch_addr),
        .isram_cs(iram_from_ifetch_cs),
        .isram_dout(iram_from_ifetch_dout),
        .isram_rready(iram_from_ifetch_rready),
        .isram_rvalid(iram_from_ifetch_rvalid), 
        
        .araddr(axi_araddr),
        .arlen(axi_arlen),
        .arsize(axi_arsize),
        .arburst(axi_arburst),
        .arvalid(axi_arvalid),
        .arready(axi_arready),
        .rdata(axi_rdata),
        .rresp(axi_rresp),
        .rlast(axi_rlast),
        .rvalid(axi_rvalid),
        .rready(axi_rready)
    );
    
wire [31:0] dram_addr;
wire        dram_cs;
wire        dram_we;
wire [3:0]  dram_wem;
wire [31:0] dram_din;
wire [31:0] dram_dout;    

wire [31:0] iram_from_data_addr;
wire        iram_from_data_cs;
wire        iram_from_data_we;
wire [3:0]  iram_from_data_wem;
wire [31:0] iram_from_data_din;
wire [31:0] iram_from_data_dout;  
wire        iram_from_data_rvalid;
wire        iram_from_data_rready;
    // Instantiate data access AXI interface
    riscv_axi_data u_data (
        .clk(clk),
        .rst_n(rst_n),
        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_be(mem_be),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),
        .mem_rvalid(mem_rvalid),

        .dsram_addr(dram_addr),
        .dsram_cs(dram_cs),
        .dsram_we(dram_we),
        .dsram_wem(dram_wem),
        .dsram_din(dram_din), 
        .dsram_dout(dram_dout), 

        .isram_addr(iram_from_data_addr),
        .isram_cs(iram_from_data_cs),
        .isram_we(iram_from_data_we),
        .isram_wem(iram_from_data_wem),
        .isram_din(iram_from_data_din), 
        .isram_dout(iram_from_data_dout),  
        .isram_rready(iram_from_data_rready),
        .isram_rvalid(iram_from_data_rvalid),  
        
        .awaddr(axi_awaddr),
        .awlen(axi_awlen),
        .awsize(axi_awsize),
        .awburst(axi_awburst),
        .awvalid(axi_awvalid),
        .awready(axi_awready),
        .wdata(axi_wdata),
        .wstrb(axi_wstrb),
        .wlast(axi_wlast),
        .wvalid(axi_wvalid),
        .wready(axi_wready),
        .bresp(axi_bresp),
        .bvalid(axi_bvalid),
        .bready(axi_bready),
        .araddr(axi_daraddr),
        .arlen(axi_darlen),
        .arsize(axi_darsize),
        .arburst(axi_darburst),
        .arvalid(axi_darvalid),
        .arready(axi_darready),
        .rdata(axi_drdata),
        .rresp(axi_drresp),
        .rlast(axi_drlast),
        .rvalid(axi_drvalid),
        .rready(axi_drready)
    );

    // D-SRAM instance
    ram_model #(
        .DP(4096),
        .DW(32),
        .MW(32/8),
        .AW($clog2(4096))
    ) u_dram_sram (
        .clk(clk),
        .din(dram_din),
        .addr(dram_addr[27:2]),
        .cs(dram_cs),
        .we(dram_we),
        .wem(dram_wem),
        .dout(dram_dout)
    );
 
riscv_iram_arbit u_iram_arbit(
    .clk(clk),
    .rst_n(rst_n),
    
    .iram_from_data_addr    (iram_from_data_addr),
    .iram_from_data_cs      (iram_from_data_cs),
    .iram_from_data_we      (iram_from_data_we),
    .iram_from_data_wem     (iram_from_data_wem),
    .iram_from_data_din     (iram_from_data_din), 
    .iram_from_data_dout    (iram_from_data_dout), 
    .iram_from_data_rready  (iram_from_data_rready), 
    .iram_from_data_rvalid  (iram_from_data_rvalid),
 
    .iram_from_ifetch_addr  (iram_from_ifetch_addr),
    .iram_from_ifetch_cs    (iram_from_ifetch_cs),
    .iram_from_ifetch_dout  (iram_from_ifetch_dout),
    .iram_from_ifetch_rready (iram_from_ifetch_rready),
    .iram_from_ifetch_rvalid(iram_from_ifetch_rvalid),  
        
    .iram_addr              (iram_addr),
    .iram_cs                (iram_cs),
    .iram_we                (iram_we),
    .iram_wem               (iram_wem),
    .iram_din               (iram_din), 
    .iram_dout              (iram_dout)  
); 

    // I-SRAM instance
    ram_model #(
        .DP(4096),
        .DW(32),
        .MW(32/8),
        .AW($clog2(4096))
    ) u_iram_sram (
        .clk(clk),
        .din(iram_din),
        .addr(iram_addr[27:2]),
        .cs(iram_cs),
        .we(iram_we),
        .wem(iram_wem),
        .dout(iram_dout)
    );
        
endmodule


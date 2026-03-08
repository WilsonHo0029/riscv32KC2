// Testbench for riscv32KC2_system
// Tests the complete RISC-V system including core, debug, memory, and bus routing
// Uses JTAG task library for debug operations

`timescale 1ns / 1ps

`include "../rtl/riscv_core/riscv_defines.v"

module tb_riscv32KC2_system;

    // Clock and Reset
    reg         sys_clk;
    reg         sys_rst_n;
    
    // JTAG Interface (connected to global signals for jtag_task.v)
    reg         tck;        // JTAG test clock (global for jtag_task.v)
    reg         tms;        // JTAG test mode select (global for jtag_task.v)
    reg         tdi;        // JTAG test data input (global for jtag_task.v)
    wire        tdo;        // JTAG test data output (global for jtag_task.v)
    reg         trst_n;     // JTAG test reset (global for jtag_task.v)
    wire 	uart_txd;
    reg		uart_rxd;
    
    // ADC/DAC Interface
    reg  [13:0] adc_in;      // ADC input data
    wire        adc_en;      // ADC enable
    wire        adc_trk;     // ADC track signal
    wire        adc_clk;     // ADC clock
    wire [2:0]  da_out;      // DAC outputs
    wire        da_clk;      // DAC clock
    wire        da_sync;     // DAC sync signal
    
    // GPIO Interface
    reg  [31:0] gpio_i;      // GPIO input
    wire [31:0] gpio_o;      // GPIO output
    wire [31:0] gpio_oe;     // GPIO output enable
    wire [31:0] gpio_ie;     // GPIO input enable
    wire [31:0] gpio_pue;    // GPIO pull-up enable
    wire [31:0] gpio_pde;    // GPIO pull-down enable
    wire [31:0] gpio_ds0;    // GPIO drive strength 0
    wire [31:0] gpio_ds1;    // GPIO drive strength 1
    
    // CLINT RTC Interface
    reg         rtc_i;       // CLINT RTC synchronization input (32768 Hz)
    
    // JTAG buffer for reading values (64-bit)
    reg [63:0]  jtag_buf;
    
    // Include JTAG task library inside the module (after signal declarations)
    `include "task/jtag_task.v"
    
    // Clock generation
    initial begin
        sys_clk = 0;
        forever #10 sys_clk = ~sys_clk;  // 50MHz clock (20ns period)
    end
    
    // Reset generation
    initial begin
        sys_rst_n = 1'b0;
        trst_n = 1'b0;
        uart_rxd = 1'b1;
        adc_in = 14'h0;      // Initialize ADC input
        gpio_i = 32'h0;      // Initialize GPIO input
        rtc_i = 1'b0;        // Initialize RTC input
        #100;
        sys_rst_n = 1'b1;
        trst_n = 1'b1;
        #100;
    end
    
    // RTC clock generation (32768 Hz = 30.518 us period)
    // For 50MHz sys_clk, divide by 1525.9 (use 1526 for approximation)
    reg [10:0] rtc_counter;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rtc_counter <= 11'd0;
            rtc_i <= 1'b0;
        end else begin
            if (rtc_counter >= 11'd1525) begin
                rtc_counter <= 11'd0;
                rtc_i <= ~rtc_i;
            end else begin
                rtc_counter <= rtc_counter + 11'd1;
            end
        end
    end
    
    
    // Instantiate the system under test
    riscv32KC2_system u_system (
        // Clock and Reset
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        
        // JTAG Interface (connected to global signals)
        .jtag_tck(tck),
        .jtag_tms(tms),
        .jtag_tdi(tdi),
        .jtag_tdo(tdo),
        .jtag_trst_n(trst_n),
	
	.uart_txd(uart_txd),
	.uart_rxd(uart_rxd),
	
	// ADC/DAC Interface
	.adc_in(adc_in),
	.adc_en(adc_en),
	.adc_trk(adc_trk),
	.adc_clk(adc_clk),
	.da_out(da_out),
	.da_clk(da_clk),
	.da_sync(da_sync),
	
	// GPIO Interface
	.gpio_i(gpio_i),
	.gpio_o(gpio_o),
	.gpio_oe(gpio_oe),
	.gpio_ie(gpio_ie),
	.gpio_pue(gpio_pue),
	.gpio_pde(gpio_pde),
	.gpio_ds0(gpio_ds0),
	.gpio_ds1(gpio_ds1),
	
	// CLINT RTC Interface
	.rtc_i(rtc_i)
    );
    reg [7:0] instr_ram [0:4096*4];
    reg [31:0] tmp;
    reg [31:0] addr;
    integer i;
    initial begin
	$readmemh("firmware.verilog", instr_ram);
    end
    //----------------------------------------------------------------------------
    // Test Procedure
    //----------------------------------------------------------------------------
    initial begin
        // Initialize JTAG signals using task library
        init_jtag_signals;
        
        // Wait for system reset release
        wait(sys_rst_n);
        #500;
        jtag_reset;
        jtag_read_IDCODE(jtag_buf[31:0]);
        #10000000;
        jtag_read_dmstatus_013(jtag_buf);
        jtag_hart_sel_013(20'd0);
        jtag_hart_set_haltreq_013(20'd0);
		#20000;
		jtag_hart_clear_haltreq_013(20'd0);
        #2000000;
        jtag_write_csr_013(12'h7b0,64'h00000000_400086c7);
        #1000000;
        jtag_set_riscv_regs_013(6'h11, 64'h00000000_12345678);
        addr = 32'h8000_0000;
	//for(i=0; i<4096*4;i=i+4) begin
	for(i=0; i<4*4;i=i+4) begin
        	jtag_write_sysbus_013(addr,{instr_ram[i+3], instr_ram[i+2], instr_ram[i+1], instr_ram[i]});
		addr = addr + 4;
		#1000;
	end
	jtag_set_pc_013(64'h00000000_80000000);
        #1000; 
	jtag_hart_resume_013(20'd0);
	#100000;
        jtag_hart_resume_013(20'd0);
        #100000; 
        $stop;
    end
    
    // Monitor critical signals (optional - can be expanded)
    initial begin
        #100;
        $monitor("Time=%0t | Reset=%b | JTAG_TDO=%b", 
                 $time, sys_rst_n, tdo);
    end


endmodule


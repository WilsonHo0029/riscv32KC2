
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
        forever #12.5 sys_clk = ~sys_clk;  // 40MHz clock (20ns period)
    end
 
    initial begin
        rtc_i = 0;
        forever #(119.22/2) rtc_i = ~rtc_i;  // 40MHz clock (20ns period)
    end
   
    // Reset generation
    initial begin
        sys_rst_n = 1'b0;
        trst_n = 1'b0;
	uart_rxd = 1'b1;
        adc_in = 14'h423;      // Initialize ADC input
        gpio_i = 32'h0;        // Initialize GPIO input
        #10000;
        sys_rst_n = 1'b1;
        trst_n = 1'b1;
        #100;
    end
    
    reg [7:0] rtc_counter;
    always @(posedge rtc_i or negedge sys_rst_n)
        if (~sys_rst_n) begin
            rtc_counter <= 11'd0;
        end else begin
              rtc_counter <= rtc_counter + 11'd1;
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
	.rtc_i(rtc_counter[7])
    );
	
uart_rxd_model #(
	.BAUD_RATE(115200)	
)u_uart_rx(
   .rxd		(uart_txd),
   .rxd_data()
);
    reg [7:0] instr_mem [0:4096*4];
    integer i;
    initial begin
	$readmemh("riscv32KC2_instr.verilog", instr_mem);
	for(i=0; i<4096;i=i+1) begin
		u_system.u_riscv_core.u_iram_sram.mem[i][07:00] = instr_mem[i*4 + 0];
		u_system.u_riscv_core.u_iram_sram.mem[i][15:08] = instr_mem[i*4 + 1];
		u_system.u_riscv_core.u_iram_sram.mem[i][23:16] = instr_mem[i*4 + 2];
		u_system.u_riscv_core.u_iram_sram.mem[i][31:24] = instr_mem[i*4 + 3];		 
	end
    end
    //----------------------------------------------------------------------------
    // Test Procedure
    //----------------------------------------------------------------------------
    initial begin
        // Initialize JTAG signals using task library
        
        // Wait for system reset release
        wait(sys_rst_n);
        #500;
        
	#100000000; 
   //     $stop;
    end
    


endmodule


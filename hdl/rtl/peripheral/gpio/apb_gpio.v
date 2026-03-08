// APB GPIO Peripheral Wrapper
// Provides APB interface for the GPIO module
// Address Map (word-aligned, 4KB window):
//   0x0000: GPIO_INPUT_VAL     - Read input values
//   0x0004: GPIO_INPUT_EN      - Input enable (gpio_ie)
//   0x0008: GPIO_OUTPUT_EN     - Output enable (gpio_oe)
//   0x000C: GPIO_OUTPUT_VAL    - Output value (gpio_o)
//   0x0010: GPIO_PULLUP        - Pull-up enable
//   0x0014: GPIO_PULLDN        - Pull-down enable
//   0x0018: GPIO_DRIVE0        - Drive strength 0
//   0x001C: GPIO_DRIVE1        - Drive strength 1
//   0x0020: GPIO_RISE_IE       - Rising edge interrupt enable
//   0x0024: GPIO_FALL_IE       - Falling edge interrupt enable
//   0x0028: GPIO_HIGH_IE       - High level interrupt enable
//   0x002C: GPIO_LOW_IE        - Low level interrupt enable
//   0x0038: GPIO_INT_STATUS    - Interrupt status (read-only)
//   0x003C: GPIO_INT_CLEAR     - Interrupt clear (write-only)
//   0x0040: GPIO_OUTPUT_SET    - Set output bits (write-only)
//   0x0044: GPIO_OUTPUT_CLEAR  - Clear output bits (write-only)
//   0x0048: GPIO_OUTPUT_TOGGLE - Toggle output bits (write-only)

module apb_gpio #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_IO     = 32
)(
    // Clock and Reset
    input                    clk,
    input                    rst_n,
    
    // APB Slave Interface
    input  [ADDR_WIDTH-1:0]  paddr,
    input                    psel,
    input                    penable,
    input                    pwrite,
    input  [DATA_WIDTH-1:0]  pwdata,
    output [DATA_WIDTH-1:0]  prdata,
    output                   pready,
    output                   pslverr,
    
    // GPIO Interrupt
    output [NUM_IO-1:0]      gpio_irq,
    
    // GPIO Pins
    input  [NUM_IO-1:0]      gpio_i,
    output [NUM_IO-1:0]      gpio_o,
    output [NUM_IO-1:0]      gpio_oe,
    output [NUM_IO-1:0]      gpio_ie,
    output [NUM_IO-1:0]      gpio_pue,
    output [NUM_IO-1:0]      gpio_pde,
    output [NUM_IO-1:0]      gpio_ds0,
    output [NUM_IO-1:0]      gpio_ds1
);

    //----------------------------------------------------------------------------
    // APB Interface Signals
    //----------------------------------------------------------------------------
    wire apb_write_en = psel & penable & pwrite;
    
    // Address decoding (word-aligned, convert byte address to register index)
    // APB byte addresses: 0x00, 0x04, 0x08, 0x0C... -> GPIO indices: 0, 1, 2, 3...
    wire [7:0] gpio_addr = {2'b0, paddr[7:2]};
    
    // APB response signals
    assign pready  = 1'b1;  // GPIO responds immediately
    assign pslverr = 1'b0;  // No errors
    
    //----------------------------------------------------------------------------
    // GPIO Core Instance
    //----------------------------------------------------------------------------
    wire [31:0] gpio_data_out;
    
    gpio #(
        .NUM_IO(NUM_IO)
    ) u_gpio (
        .clk        (clk),
        .rst_n      (rst_n),
        .wr_en      (apb_write_en),
        .addr       (gpio_addr),
        .data_in    (pwdata),
        .data_out   (prdata),
        .gpio_irq   (gpio_irq),
        .gpio_i     (gpio_i),
        .gpio_o     (gpio_o),
        .gpio_oe    (gpio_oe),
        .gpio_ie    (gpio_ie),
        .gpio_pue   (gpio_pue),
        .gpio_pde   (gpio_pde),
        .gpio_ds0   (gpio_ds0),
        .gpio_ds1   (gpio_ds1)
    );
    

endmodule


module gpio #(
    parameter NUM_IO = 32
)(
    input                    clk,
    input                    rst_n,
    
    input                    wr_en,
    input  [7:0]             addr,
    input  [31:0]            data_in,
    output reg [31:0]        data_out,
    
    output [NUM_IO-1:0]      gpio_irq,
    
    input  [NUM_IO-1:0]      gpio_i,
    output [NUM_IO-1:0]      gpio_o,
    output reg [NUM_IO-1:0]      gpio_oe,
    output reg [NUM_IO-1:0]      gpio_ie,
    output [NUM_IO-1:0]      gpio_pue,
    output [NUM_IO-1:0]      gpio_pde,
    output reg [NUM_IO-1:0]  gpio_ds0,
    output reg [NUM_IO-1:0]  gpio_ds1
);
localparam GPIO_INPUT_VAL     = 0;
localparam GPIO_INPUT_EN      = 1;
localparam GPIO_OUTPUT_EN     = 2;
localparam GPIO_OUTPUT_VAL    = 3;
localparam GPIO_PULLUP        = 4;
localparam GPIO_PULLDN        = 5;
localparam GPIO_DRIVE0        = 6;
localparam GPIO_DRIVE1        = 7;
localparam GPIO_RISE_IE       = 8;
localparam GPIO_FALL_IE       = 9;
localparam GPIO_HIGH_IE       = 10;
localparam GPIO_LOW_IE        = 11;
localparam GPIO_INT_STATUS    = 14;
localparam GPIO_INT_CLEAR     = 15;
localparam GPIO_OUTPUT_SET    = 16;
localparam GPIO_OUTPUT_CLEAR  = 17;
localparam GPIO_OUTPUT_TOGGLE = 18;

reg [NUM_IO-1:0] gpio_output_val;
reg [NUM_IO-1:0] gpio_pullup, gpio_pulldown;
reg [NUM_IO-1:0] gpio_rise_ie, gpio_fall_ie;
reg [NUM_IO-1:0] gpio_high_ie, gpio_low_ie;
reg [NUM_IO-1:0] r_gpio_irq;
reg [NUM_IO-1:0] gpio_val_d0, gpio_val_d1, gpio_val_d2;

assign gpio_o = gpio_output_val;
assign gpio_pue = gpio_pullup;
assign gpio_pde = gpio_pulldown;

always @(*) begin
    case (addr)
        GPIO_INPUT_VAL:    data_out = gpio_val_d1;
        GPIO_INPUT_EN:     data_out = gpio_ie;
        GPIO_OUTPUT_EN:    data_out = gpio_oe;
        GPIO_OUTPUT_VAL:   data_out = gpio_output_val;
	GPIO_OUTPUT_SET:   data_out = gpio_output_val;
	GPIO_OUTPUT_CLEAR: data_out = gpio_output_val;
        GPIO_OUTPUT_TOGGLE:data_out = gpio_output_val;
        GPIO_PULLUP:       data_out = gpio_pullup;
        GPIO_PULLDN:       data_out = gpio_pulldown;
        GPIO_DRIVE0:       data_out = gpio_ds0;
        GPIO_DRIVE1:       data_out = gpio_ds1;
        GPIO_RISE_IE:      data_out = gpio_rise_ie;
        GPIO_FALL_IE:      data_out = gpio_fall_ie;
        GPIO_HIGH_IE:      data_out = gpio_high_ie;
        GPIO_LOW_IE:       data_out = gpio_low_ie;
        GPIO_INT_STATUS:   data_out = r_gpio_irq;
        default:           data_out = 32'dx;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        gpio_ie       <= {NUM_IO{1'b0}};
        gpio_oe       <= {NUM_IO{1'b0}};
        gpio_pullup   <= {NUM_IO{1'b0}};
        gpio_pulldown <= {NUM_IO{1'b0}};
        gpio_ds0      <= {NUM_IO{1'b0}};
        gpio_ds1      <= {NUM_IO{1'b0}};
    end else if (wr_en) begin
        gpio_ie       <= (addr == GPIO_INPUT_EN)  ? data_in : gpio_ie;
        gpio_oe       <= (addr == GPIO_OUTPUT_EN) ? data_in : gpio_oe;
        gpio_pullup   <= (addr == GPIO_PULLUP)    ? data_in : gpio_pullup;
        gpio_pulldown <= (addr == GPIO_PULLDN)    ? data_in : gpio_pulldown;
        gpio_ds0      <= (addr == GPIO_DRIVE0)    ? data_in : gpio_ds0;
        gpio_ds1      <= (addr == GPIO_DRIVE1)    ? data_in : gpio_ds1;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        gpio_rise_ie <= {NUM_IO{1'b0}};
        gpio_fall_ie <= {NUM_IO{1'b0}};
        gpio_high_ie <= {NUM_IO{1'b0}};
        gpio_low_ie  <= {NUM_IO{1'b0}};
    end else if (wr_en) begin
        gpio_rise_ie <= (addr == GPIO_RISE_IE) ? data_in : gpio_rise_ie;
        gpio_fall_ie <= (addr == GPIO_FALL_IE) ? data_in : gpio_fall_ie;
        gpio_high_ie <= (addr == GPIO_HIGH_IE) ? data_in : gpio_high_ie;
        gpio_low_ie  <= (addr == GPIO_LOW_IE)  ? data_in : gpio_low_ie;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        gpio_output_val <= {NUM_IO{1'b0}};
    end else if (wr_en) begin
        if (addr == GPIO_OUTPUT_VAL) begin
            gpio_output_val <= data_in;
        end else if (addr == GPIO_OUTPUT_SET) begin
            gpio_output_val <= data_in | gpio_output_val;
        end else if (addr == GPIO_OUTPUT_CLEAR) begin
            gpio_output_val <= ~data_in & gpio_output_val;
        end else if (addr == GPIO_OUTPUT_TOGGLE) begin
            gpio_output_val <= data_in ^ gpio_output_val;
        end
    end
end

always @(posedge clk) begin
    gpio_val_d0 <= gpio_i;
    gpio_val_d1 <= gpio_val_d0;
    gpio_val_d2 <= gpio_val_d1;
end

wire [NUM_IO-1:0] gpio_val_in_r  = ~gpio_val_d2 & gpio_val_d1;
wire [NUM_IO-1:0] gpio_val_in_f  = gpio_val_d2 & ~gpio_val_d1;
wire [NUM_IO-1:0] gpio_irq_clear = (addr == GPIO_INT_STATUS & wr_en) ? data_in : {NUM_IO{1'b0}};

integer i;
always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        r_gpio_irq <= {NUM_IO{1'b0}};
    end else begin
        for (i = 0; i < NUM_IO; i = i + 1) begin
            if (gpio_irq_clear[i]) begin
                r_gpio_irq[i] <= 1'b0;
            end else if ((gpio_val_d1[i] & gpio_high_ie[i]) | (~gpio_val_d1[i] & gpio_low_ie[i]) |
                         (gpio_val_in_r[i] & gpio_rise_ie[i]) | (gpio_val_in_f[i] & gpio_fall_ie[i])) begin
                r_gpio_irq[i] <= 1'b1;
            end
        end
    end
end

assign gpio_irq = r_gpio_irq;

endmodule

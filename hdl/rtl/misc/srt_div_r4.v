//=============================================================================
// Radix-4 Integer Divider (32-bit / 32-bit -> 32-bit)
//=============================================================================
// Standard: Verilog 1995
// Calculates 2 bits of quotient per cycle.
// This module implements a sequential Radix-4 Restoring Divider,
// which is robust for all integer ranges and RISC-V compliant.
//=============================================================================

module srt_div_r4 (
    clk,
    rst_n,
    start,
    is_signed,
    dividend,
    divisor,
    quotient,
    remainder,
    ready,
    done
);
    input         clk;
    input         rst_n;
    input         start;
    input         is_signed;
    input  [31:0] dividend;
    input  [31:0] divisor;
    output [31:0] quotient;
    output [31:0] remainder;
    output reg    ready;
    output reg    done;

    // FSM States
    parameter IDLE = 2'b00;
    parameter INIT = 2'b01;
    parameter LOOP = 2'b10;
    parameter POST = 2'b11;

    reg [1:0]  state;
    reg [4:0]  count;
    reg [31:0] q_reg; // Quotient shift register
    reg [31:0] d_reg; // Divisor (1x)
    reg [32:0] d2_reg; // Divisor (2x)
    reg [33:0] d3_reg; // Divisor (3x)
    reg [31:0] v_reg; // Dividend shift register
    reg [31:0] r_reg; // Partial Remainder
    
    reg        sign_q;
    reg        sign_r;
    reg        div_zero;
    reg        overflow;
    // Radix-4 Restoring Iteration
    reg [33:0] next_r;
    // Absolute values for calculation
    wire [31:0] abs_dividend = (is_signed && dividend[31]) ? (~dividend + 32'b1) : dividend;
    wire [31:0] abs_divisor  = (is_signed && divisor[31])  ? (~divisor + 32'b1)  : divisor;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            count    <= 5'd0;
            q_reg    <= 32'd0;
            d_reg    <= 32'd0;
            d2_reg   <= 33'd0;
            d3_reg   <= 34'd0;
            v_reg    <= 32'd0;
            r_reg    <= 32'd0;
            ready    <= 1'b1;
            done     <= 1'b0;
            sign_q   <= 1'b0;
            sign_r   <= 1'b0;
            div_zero <= 1'b0;
            overflow <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state    <= INIT;
                        ready    <= 1'b0;
                        // RISC-V special cases
                        div_zero <= (divisor == 32'b0);
                        overflow <= (is_signed && (dividend == 32'h80000000) && (divisor == 32'hFFFFFFFF));
                        sign_q   <= is_signed ? (dividend[31] ^ divisor[31]) : 1'b0;
                        sign_r   <= is_signed ? dividend[31] : 1'b0;
                    end
                end

                INIT: begin
                    // Pre-calculate multiples for Radix-4
                    d_reg  <= abs_divisor;
                    d2_reg <= {abs_divisor, 1'b0};
                    d3_reg <= {abs_divisor, 1'b0} + abs_divisor;
                    v_reg  <= abs_dividend;
                    r_reg  <= 32'b0;
                    q_reg  <= 32'b0;
                    count  <= 5'd16; // 32 bits / 2 bits per cycle
                    state  <= LOOP;
                end

                LOOP: begin
                    if (div_zero || overflow) begin
                        state <= POST;
                    end else begin

                        next_r = {r_reg[29:0], v_reg[31:30]};
                        
                        if (next_r >= d3_reg) begin
                            r_reg <= next_r[31:0] - d3_reg[31:0];
                            q_reg <= {q_reg[29:0], 2'b11};
                        end else if (next_r >= d2_reg) begin
                            r_reg <= next_r[31:0] - d2_reg[31:0];
                            q_reg <= {q_reg[29:0], 2'b10};
                        end else if (next_r >= d_reg) begin
                            r_reg <= next_r[31:0] - d_reg;
                            q_reg <= {q_reg[29:0], 2'b01};
                        end else begin
                            r_reg <= next_r[31:0];
                            q_reg <= {q_reg[29:0], 2'b00};
                        end
                        
                        v_reg <= {v_reg[29:0], 2'b00};
                        count <= count - 5'd1;
                        if (count == 5'd1) state <= POST;
                    end
                end

                POST: begin
                    ready <= 1'b1;
                    done  <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

    // Result assembly with RISC-V compliance
    wire [31:0] q_final = overflow ? 32'h80000000 : 
                          div_zero ? 32'hFFFFFFFF :
                          sign_q   ? (~q_reg + 32'b1) : q_reg;
                          
    wire [31:0] r_final = overflow ? 32'b0 :
                          div_zero ? dividend :
                          sign_r   ? (~r_reg + 32'b1) : r_reg;

    assign quotient  = q_final;
    assign remainder = r_final;

endmodule

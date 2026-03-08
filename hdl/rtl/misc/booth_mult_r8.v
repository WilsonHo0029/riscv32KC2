//=============================================================================
// Radix-8 Booth Multiplier (33x33 -> 66-bit)
//=============================================================================
// Standard: Verilog 1995
// This module implements a combinational Radix-8 Booth Multiplier.
// It handles 33-bit operands to support all RISC-V multiplication variants.
//
// Radix-8 encoding looks at 4 bits at a time with 1-bit overlap.
// This reduces the number of partial products to 12.
//=============================================================================

module booth_mult_r8 (a, b, p);
    input  [32:0] a; // Multiplicand
    input  [32:0] b; // Multiplier
    output [65:0] p; // Product (a * b)

    // Pre-calculate hard partial products
    // 3A = 2A + A
    wire [34:0] a_3;
    assign a_3 = {a[32], a[32], a} + {a[32], a, 1'b0};

    // Padded multiplier for Radix-8 encoding
    // Window: 4 bits, Step: 3 bits
    // Groups: (b2,b1,b0,b-1), (b5,b4,b3,b2), ..., (b35,b34,b33,b32)
    // b_padded = {b[32], b[32], b[32], b[32], b, 1'b0} -> 38 bits [37:0]
    wire [37:0] b_padded;
    assign b_padded = {{4{b[32]}}, b, 1'b0};

    reg [65:0] p_sum;
    reg [35:0] pp_base;
    reg [65:0] pp_shifted;
    reg [3:0]  booth_bits;
    
    integer i;

    // Combinational summation of partial products
    always @(a or b or b_padded or a_3) begin
        p_sum = 66'b0;
        
        // Iterate through 12 groups of 4 bits (Radix-8)
        for (i = 0; i < 12; i = i + 1) begin
            // Extract the 4-bit Booth encoding group
            case (i)
                0:  booth_bits = b_padded[3:0];
                1:  booth_bits = b_padded[6:3];
                2:  booth_bits = b_padded[9:6];
                3:  booth_bits = b_padded[12:9];
                4:  booth_bits = b_padded[15:12];
                5:  booth_bits = b_padded[18:15];
                6:  booth_bits = b_padded[21:18];
                7:  booth_bits = b_padded[24:21];
                8:  booth_bits = b_padded[27:24];
                9:  booth_bits = b_padded[30:27];
                10: booth_bits = b_padded[33:30];
                11: booth_bits = b_padded[36:33];
                default: booth_bits = 4'b0;
            endcase

            // Generate base partial product based on Radix-8 encoding table
            case (booth_bits)
                4'b0000, 4'b1111: pp_base = 36'b0;
                4'b0001, 4'b0010: pp_base = { {3{a[32]}}, a };          // +1 * a
                4'b0011, 4'b0100: pp_base = { {2{a[32]}}, a, 1'b0 };    // +2 * a
                4'b0101, 4'b0110: pp_base = { a[32], a_3 };             // +3 * a
                4'b0111:          pp_base = { a[32], a, 2'b0 };         // +4 * a
                4'b1000:          pp_base = (~{a[32], a, 2'b0}) + 36'b1; // -4 * a
                4'b1001, 4'b1010: pp_base = (~{a[32], a_3}) + 36'b1;    // -3 * a
                4'b1011, 4'b1100: pp_base = (~{ {2{a[32]}}, a, 1'b0 }) + 36'b1; // -2 * a
                4'b1101, 4'b1110: pp_base = (~{ {3{a[32]}}, a }) + 36'b1; // -1 * a
                default:          pp_base = 36'b0;
            endcase

            // Shift and sign-extend the base partial product to 66 bits
            // Shift is 3*i.
            case (i)
                0:  pp_shifted = { {30{pp_base[35]}}, pp_base };
                1:  pp_shifted = { {27{pp_base[35]}}, pp_base,  3'b0 };
                2:  pp_shifted = { {24{pp_base[35]}}, pp_base,  6'b0 };
                3:  pp_shifted = { {21{pp_base[35]}}, pp_base,  9'b0 };
                4:  pp_shifted = { {18{pp_base[35]}}, pp_base, 12'b0 };
                5:  pp_shifted = { {15{pp_base[35]}}, pp_base, 15'b0 };
                6:  pp_shifted = { {12{pp_base[35]}}, pp_base, 18'b0 };
                7:  pp_shifted = { { 9{pp_base[35]}}, pp_base, 21'b0 };
                8:  pp_shifted = { { 6{pp_base[35]}}, pp_base, 24'b0 };
                9:  pp_shifted = { { 3{pp_base[35]}}, pp_base, 27'b0 };
                10: pp_shifted = { pp_base, 30'b0 };
                11: pp_shifted = { pp_base[32:0], 33'b0 };
                default: pp_shifted = 66'b0;
            endcase
            
            p_sum = p_sum + pp_shifted;
        end
    end

    assign p = p_sum;

endmodule

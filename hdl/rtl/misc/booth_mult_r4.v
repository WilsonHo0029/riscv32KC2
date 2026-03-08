//=============================================================================
// Radix-4 Booth Multiplier (33x33 -> 66-bit)
//=============================================================================
// Standard: Verilog 1995
// This module implements a combinational Radix-4 Booth Multiplier.
// It handles 33-bit operands to support all RISC-V multiplication variants.
//=============================================================================

module booth_mult_r4 (a, b, p);
    input  [32:0] a; // Multiplicand
    input  [32:0] b; // Multiplier
    output [65:0] p; // Product (a * b)

    // Padded multiplier for Radix-4 encoding
    // For 33-bit input, we need bits up to index 34 for the 17th group
    wire [34:0] b_padded;
    assign b_padded = {b[32], b, 1'b0}; // Exactly 35 bits: {Sign, Data, Pad0}

    reg [65:0] p_sum;
    reg [33:0] pp_base;
    reg [65:0] pp_shifted;
    
    integer i;

    // Combinational summation of partial products
    // Note: Verilog 1995 requires explicit sensitivity list (a or b)
    always @(a or b or b_padded) begin
        p_sum = 66'b0;
        
        // Iterate through 17 groups of 3 bits (Radix-4)
        for (i = 0; i < 17; i = i + 1) begin
            // Extract the 3-bit Booth encoding group
            // In Verilog 1995, bit-select indices must be constant or based on a loop variable
            case ({b_padded[2*i+2], b_padded[2*i+1], b_padded[2*i]})
                3'b000, 3'b111: pp_base = 34'b0;
                3'b001, 3'b010: pp_base = {a[32], a};          // +1 * a
                3'b011:         pp_base = {a, 1'b0};           // +2 * a
                3'b100:         pp_base = (~{a, 1'b0}) + 34'b1; // -2 * a (Two's complement)
                3'b101, 3'b110: pp_base = (~{a[32], a}) + 34'b1; // -1 * a (Two's complement)
                default:        pp_base = 34'b0;
            endcase

            // Shift and sign-extend the base partial product to 66 bits
            // Shift is 2*i. Sign extension is (66 - 34 - 2*i) = (32 - 2*i) bits.
            // Using a loop for shifting/extension to remain compatible with 1995 constraints 
            // if concatenation width must be constant. 
            // However, nested concatenation was supported.
            
            case (i)
                0:  pp_shifted = { {32{pp_base[33]}}, pp_base };
                1:  pp_shifted = { {30{pp_base[33]}}, pp_base,  2'b0 };
                2:  pp_shifted = { {28{pp_base[33]}}, pp_base,  4'b0 };
                3:  pp_shifted = { {26{pp_base[33]}}, pp_base,  6'b0 };
                4:  pp_shifted = { {24{pp_base[33]}}, pp_base,  8'b0 };
                5:  pp_shifted = { {22{pp_base[33]}}, pp_base, 10'b0 };
                6:  pp_shifted = { {20{pp_base[33]}}, pp_base, 12'b0 };
                7:  pp_shifted = { {18{pp_base[33]}}, pp_base, 14'b0 };
                8:  pp_shifted = { {16{pp_base[33]}}, pp_base, 16'b0 };
                9:  pp_shifted = { {14{pp_base[33]}}, pp_base, 18'b0 };
                10: pp_shifted = { {12{pp_base[33]}}, pp_base, 20'b0 };
                11: pp_shifted = { {10{pp_base[33]}}, pp_base, 22'b0 };
                12: pp_shifted = { { 8{pp_base[33]}}, pp_base, 24'b0 };
                13: pp_shifted = { { 6{pp_base[33]}}, pp_base, 26'b0 };
                14: pp_shifted = { { 4{pp_base[33]}}, pp_base, 28'b0 };
                15: pp_shifted = { { 2{pp_base[33]}}, pp_base, 30'b0 };
                16: pp_shifted = { pp_base, 32'b0 }; // Full 34-bit base shifted by 32
                default: pp_shifted = 66'b0;
            endcase
            
            p_sum = p_sum + pp_shifted;
        end
    end

    assign p = p_sum;

endmodule

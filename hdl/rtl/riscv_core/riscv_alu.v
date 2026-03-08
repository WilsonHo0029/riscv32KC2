// RISC-V ALU (Arithmetic Logic Unit)
// Supports all RV32I arithmetic and logical operations
`include "riscv_defines.v"

module riscv_alu (
    input  [31:0]       a,
    input  [31:0]       b,
    input  [3:0]        alu_op,
    output reg [31:0]   result,
    output              zero,
    output              lt,      // signed less than
    output              ltu      // unsigned less than
);

    //----------------------------------------------------------------------------
    // Constants
    //----------------------------------------------------------------------------
    localparam DATA_WIDTH = 32;
    localparam SHIFT_WIDTH = 5;  // Bits [4:0] for shift amount
    
    //----------------------------------------------------------------------------
    // ALU Operation Logic
    //----------------------------------------------------------------------------
    always @(*) begin
        case (alu_op)
            `ALU_ADD:  result = a + b;
            `ALU_SUB:  result = a - b;
            `ALU_SLL:  result = a << b[SHIFT_WIDTH-1:0];
            `ALU_SLT:  result = ($signed(a) < $signed(b)) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : {DATA_WIDTH{1'b0}};
            `ALU_SLTU: result = (a < b) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : {DATA_WIDTH{1'b0}};
            `ALU_XOR:  result = a ^ b;
            `ALU_SRL:  result = a >> b[SHIFT_WIDTH-1:0];
            `ALU_SRA:  result = $signed(a) >>> b[SHIFT_WIDTH-1:0];
            `ALU_OR:   result = a | b;
            `ALU_AND:  result = a & b;
            default:   result = {DATA_WIDTH{1'b0}};
        endcase
    end
    
    //----------------------------------------------------------------------------
    // Comparison Outputs
    //----------------------------------------------------------------------------
    assign zero = (result == {DATA_WIDTH{1'b0}});
    assign lt   = $signed(a) < $signed(b);
    assign ltu  = a < b;

endmodule


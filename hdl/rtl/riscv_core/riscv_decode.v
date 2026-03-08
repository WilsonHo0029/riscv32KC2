//=============================================================================
// RISC-V Decode Stage Module
//=============================================================================
// This module is a wrapper that instantiates riscv_decoder.v
// All decode functionality is consolidated in riscv_decoder.v
//
// This module maintains the same interface for compatibility with existing
// pipeline code while using the consolidated decoder implementation.
//=============================================================================

`include "riscv_defines.v"

module riscv_decode (
    // Inputs
    input  [31:0]       instruction,        // Instruction from IF/ID stage
    input  [31:0]       pc,                 // Program Counter for return address calculation
    
    // Instruction fields (decoded from instruction)
    output [4:0]        rd,                 // Destination register
    output [4:0]        rs1,                // Source register 1
    output [4:0]        rs2,                // Source register 2
    
    // Immediate values
    output [31:0]       selected_imm,       // Selected immediate based on instruction type (for ALU operations)
   
    
    output              dec_jal,
    output              dec_bxx,
    output              dec_rv32,
    // Control Signals
    output [47:0]       ctrl_signals
);
wire [3:0]        alu_op;
wire              alu_src_a;
wire              alu_src_b;
    
wire              reg_we;
wire              reg_src;

wire              mem_req;
wire              mem_we;
wire [2:0]        mem_size;
wire              mem_sign_ext;

wire              branch;
wire [2:0]        branch_type;
wire              jump;
wire              jump_save_ra;

wire [11:0]       csr_addr;
wire              csr_imm;
wire              csr_we;
wire [1:0]        csr_op;

wire              multdiv_req;
wire [2:0]        multdiv_op;

wire              fence;
wire              fence_i;

wire              ecall;
wire              ebreak;
wire              mret;
wire              dret;
wire              wfi;

wire              illegal_inst;
    //----------------------------------------------------------------------------
    // Decoder Instantiation
    //----------------------------------------------------------------------------
    // All decode functionality is consolidated in riscv_decoder.v
    riscv_decoder u_decoder (
        .instruction(instruction),
        .pc(pc),
        
        // Instruction fields
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        
        // Immediate values
        .selected_imm(selected_imm),
       
        .dec_jal        (dec_jal),
        .dec_bxx        (dec_bxx),   
        .dec_rv32       (dec_rv32),    
        // ALU Control Signals
        .alu_op(alu_op),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        
        // Register Control Signals
        .reg_we(reg_we),
        .reg_src(reg_src),
        
        // Memory Control Signals
        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_size(mem_size),
        .mem_sign_ext(mem_sign_ext),
        
        // Branch/Jump Control Signals
        .branch(branch),
        .branch_type(branch_type),
        .jump(jump),
        .jump_save_ra(jump_save_ra),
        
        // CSR Control Signals
        .csr_addr(csr_addr),
        .csr_imm(csr_imm),
        .csr_we(csr_we),
        .csr_op(csr_op),
        
        // Multiplier/Divider Control Signals
        .multdiv_req(multdiv_req),
        .multdiv_op(multdiv_op),
        
        // Fence Instructions
        .fence(fence),
        .fence_i(fence_i),
        
        // Exception/Interrupt Control Signals
        .ecall(ecall),
        .ebreak(ebreak),
        .mret(mret),
        .dret(dret),
        .wfi(wfi),
        
        // Exception Flags
        .illegal_inst(illegal_inst)
    );
    // Control Signals
    assign ctrl_signals[3:0]  = alu_op;
    assign ctrl_signals[4]  = alu_src_a;
    assign ctrl_signals[5]  = alu_src_b;
 
    assign ctrl_signals[6]  = reg_we;
    assign ctrl_signals[7]  = reg_src;
  
    assign ctrl_signals[8]  = mem_req;
    assign ctrl_signals[9]  = mem_we;
    assign ctrl_signals[12:10]  = mem_size;     
    assign ctrl_signals[13]  = mem_sign_ext;  
    
    assign ctrl_signals[14] =  branch;
    assign ctrl_signals[17:15] =  branch_type;  
    assign ctrl_signals[18] = jump;
    assign ctrl_signals[19] = jump_save_ra;
    
    assign ctrl_signals[31:20] = csr_addr;
    assign ctrl_signals[32] = csr_imm;
    assign ctrl_signals[33] = csr_we;
    assign ctrl_signals[35:34] = csr_op;
    
    assign ctrl_signals[36] = multdiv_req;
    assign ctrl_signals[39:37] = multdiv_op;    

    assign ctrl_signals[40] = fence;
    assign ctrl_signals[41] = fence_i;    
     
    assign ctrl_signals[42] = ecall;    
    assign ctrl_signals[43] = ebreak;    
    assign ctrl_signals[44] = mret;    
    assign ctrl_signals[45] = dret;    
    assign ctrl_signals[46] = wfi;        
    
    assign ctrl_signals[47] = illegal_inst;        
  
endmodule


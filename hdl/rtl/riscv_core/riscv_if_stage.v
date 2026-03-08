//=============================================================================
// RISC-V Instruction Fetch (IF) Stage Module
//=============================================================================
// This module implements Stage 1 (IF) of the 2-stage RISC-V pipeline.
// It handles instruction fetching, PC management, and early jump prediction.
//
// Features:
//   - Program Counter (PC) management
//   - Early jump prediction using mini decoder
//   - Next PC calculation with priority-based selection
//   - Pipeline register interface (IF/ID boundary)
//=============================================================================

`include "riscv_defines.v"

module riscv_if_stage #(
    parameter RESET_PC = 32'h00001000            // Reset address (default: Boot ROM start)
) (
    input               clk,
    input               rst_n,
    
    // Instruction Fetch Interface
    input  [31:0]       instr_i,                 // Raw instruction from memory
    input               instr_rvalid,            // High when instruction is ready
    output [31:0]       ifetch_addr,             // Program Counter to fetch memory
    output              ifetch_rvalid,           // Signal to memory that PC is valid
    input               ifu_ready,               // External ready signal for instruction fetch
    output              instr_rready,            // Internal ready signal (inverted stall)
    
    // Pipeline Control
    output              pipeline_flush,          // Pipeline flush signal (computed in this module)
    input               pipeline_stall,
    
    // Next PC Selection Inputs (from Stage 2)
    input               debug_mode_pc,           // Debug mode PC redirection
    input               dret_taken,              // DRET instruction executed
    input               mret_taken,              // MRET instruction executed
    input               trap_taken,              // Trap (exception/interrupt) taken
    input  [31:0]       dpc,                     // Debug PC (for DRET)
    input  [31:0]       mepc,                    // Machine exception PC (for MRET)
    input  [31:0]       trap_vector,             // Trap handler address
    input  [31:0]       jump_target,             // Actual jump target (for misprediction recovery)
    input               early_jump_wrong_taken,  // Early jump wrong taken
    input               early_not_jump_need_jump,// Not predicted but jump needed
    
    // IF Pipeline  Outputs
    output [31:0]       if_pc,                   // PC value passed to Stage 2
    output [4:0]        if_rd,                   // Instruction word passed to Stage 2
    output [4:0]        if_rs1,                   // Instruction word passed to Stage 2
    output [4:0]        if_rs2,                   // Instruction word passed to Stage 2
    output [31:0]       if_sel_imm,
    output [31:0]       if_pc_ra,
    output [47:0]       if_ctrl_signals,
    
    output              if_valid,                // Valid flag for instruction in Stage 2
    output reg [31:0]   if_restore_mis_target,
    output              if_early_jump_taken     // Early jump prediction taken flag
);

    //----------------------------------------------------------------------------
    // Constants
    //----------------------------------------------------------------------------
    localparam [31:0] DEBUG_EXCEPTION_ADDR = 32'h00000800;
    //----------------------------------------------------------------------------
    // Mini Decoder for Early Jump Detection
    //----------------------------------------------------------------------------
    wire              dec_jal;
    wire              dec_bxx;
    wire              dec_rv32;
    
    wire [31:0]       pc;
    wire [31:0]       pc_incr;                    // PC increment (2 or 4)
    wire [31:0]       early_jump_target;          // Early jump target prediction
    wire              early_jump_valid;           // Early jump prediction valid
    wire              early_jump_taken;           // Early jump prediction taken flag
    wire [31:0]       instr_o;
    wire              fetch_rvalid;
    assign if_pc                = pc;
    assign if_instruction       = instr_o;
    assign if_valid             = fetch_rvalid;
    assign if_early_jump_taken  = early_jump_taken;
    assign instr_rready         = ~pipeline_stall;

 riscv_decode u_decode(
    // Inputs
    .instruction        (instr_o),        // Instruction from IF/ID stage
    .pc                 (pc),                 // Program Counter for return address calculation
    
    // Instruction fields (decoded from instruction)
    .rd                 (if_rd),                 // Destination register
    .rs1                (if_rs1),                // Source register 1
    .rs2                (if_rs2),                // Source register 2
    
    // Immediate values
    .selected_imm       (if_sel_imm),       // Selected immediate based on instruction type (for ALU operations)
   
    
    // Return address calculation (for JAL/JALR)  
    .dec_jal            (dec_jal),
    .dec_bxx            (dec_bxx),
    .dec_rv32           (dec_rv32),
    // Control Signals
    .ctrl_signals       (if_ctrl_signals)
);   
    
    //----------------------------------------------------------------------------
    // Early Jump Target Calculation
    //----------------------------------------------------------------------------
    // Predicts jump/branch targets during the Fetch stage to reduce branch penalty.
    // Logic is validated in the Decode stage; mismatches trigger a pipeline flush.
    //
    // Prediction Strategy:
    //   - JAL/JALR: Always predicted TAKEN (unconditional).
    //   - Branches: Static prediction (TAKEN if backward, NOT TAKEN if forward).
    //

    
    // Select jump target based on instruction type
    assign early_jump_target = pc + if_sel_imm;
    
    // Jump Prediction Logic:
    //   - JAL: Always predicted taken (unconditional jumps)
    //   - Branches: Predicted taken if backward (imm[31] = 1)
    assign early_jump_taken = dec_jal || dec_bxx;
    
    // Early jump is valid when:
    //   - Instruction is valid (instr_rvalid = 1)
    //   - Instruction is a jump/branch (minidec_bjp = 1)
    assign early_jump_valid = fetch_rvalid && early_jump_taken;
    
    //----------------------------------------------------------------------------
    // PC Increment Calculation
    //----------------------------------------------------------------------------
    // PC increment: 2 for compressed instructions, 4 for RV32I
    assign pc_incr = (dec_rv32) ? 32'd4 : 32'd2;
    
    //----------------------------------------------------------------------------
    // Next PC Selection Priority
    //----------------------------------------------------------------------------
    // Defines the priority of PC redirection sources (Highest to Lowest):
    //   1. Debug Entry: Redirection to Debug ROM/RAM.
    //   2. DRET/MRET: Return from Debug/Machine mode.
    //   3. Trap/Exception: Redirection to mtvec vector table.
    //   4. Early Jump: Predicted branch/jump target (to start fetching sooner).
    //   5. Misprediction Recovery: Correcting the PC if Stage 2 detects a mistake.
    //   6. Sequential: pc + 2 (Compressed) or pc + 4 (RV32I).
    wire [31:0] next_pc1 = debug_mode_pc                      ? DEBUG_EXCEPTION_ADDR :
                           dret_taken                         ? dpc :
                           mret_taken                         ? mepc :
                           trap_taken                         ? trap_vector :
                           (early_not_jump_need_jump)         ? jump_target :
                           early_jump_wrong_taken             ? if_restore_mis_target :
                                                                early_jump_target;
                                                                
    wire pc1_sel = (debug_mode_pc | dret_taken | mret_taken | trap_taken | early_jump_valid | early_jump_wrong_taken | early_not_jump_need_jump);
    //----------------------------------------------------------------------------
    // IF Stage: Program Counter (PC) Update Logic
    //----------------------------------------------------------------------------

    riscv_fetch_pc_unit #(
        .RESET_PC (RESET_PC)
    ) u_fetch_pc (	
        .clk           (clk), 
        .rst_n         (rst_n),
        .next_pc1      (next_pc1),
        .pc1_sel       (pc1_sel),
        .instr_rv32    (dec_rv32),
        .flush         (pipeline_flush),
        .stall         (pipeline_stall),
        .ifu_ready     (ifu_ready),
        .fetch_addr    (ifetch_addr),
        .pc            (pc),
        .pc_incr       (pc_incr),
        .pc_ra         (if_pc_ra),
        .ifetch_rvalid (ifetch_rvalid),
        .instr_rvalid  (instr_rvalid),
        .instr_i       (instr_i),
        .instr_o       (instr_o),
        .fetch_rvalid  (fetch_rvalid)
    ); 
    
    //----------------------------------------------------------------------------
    // Early Jump Target Capture
    //----------------------------------------------------------------------------
    // Capture predicted jump target and sequential PC for misprediction recovery
    // Only capture when early jump is valid and no higher-priority events occur
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_restore_mis_target <= {32{1'b0}};
        end else begin
            if (early_jump_valid & ~debug_mode_pc & ~dret_taken & ~mret_taken & ~trap_taken) begin
                if_restore_mis_target <= if_pc_ra;
            end
        end
    end


    //----------------------------------------------------------------------------
    // Pipeline Flush Logic
    //----------------------------------------------------------------------------
    // Pipeline flush signal: Asserted on traps, jumps, branches, mispredictions, or explicit flush
    wire flush_on_trap = trap_taken || mret_taken || dret_taken || debug_mode_pc;
    assign pipeline_flush = flush_on_trap || early_not_jump_need_jump || early_jump_wrong_taken;

endmodule

//=============================================================================
// RISC-V 2-Stage Pipeline Implementation
//=============================================================================
// This module integrates the pipeline stage modules for a 2-stage RISC-V pipeline:
//
// Pipeline Structure:
//   Stage 1 (IF): Instruction Fetch
//     - Module: riscv_if_stage
//     - Fetches instructions, manages PC, handles early jump prediction
//
//   Stage 2 (ID/EX/MEM/WB): Instruction Decode, Execute, Memory Access, Writeback
//     - All phases execute in the same clock cycle
//     - Modules:
//       * riscv_decode (ID): Instruction decoding and control signal generation
//       * riscv_exu (EX): ALU, multiplier/divider, CSR, branch/jump evaluation
//       * riscv_mem (MEM): Memory operations (load/store/AMO) - includes riscv_amo module
//       * riscv_wb (WB): Register file and writeback logic
//
// Features:
//   - Modular pipeline stage implementation (if_stage, decode, exu, mem, wb)
//   - Early jump prediction with misprediction recovery
//   - Combinational pipeline stall logic (zero latency)
//   - Debug mode support (RISC-V Debug Spec 0.13)
//   - Exception and interrupt handling
//   - CLINT interrupt support (timer and software interrupts)
//   - Compressed instruction support
//=============================================================================

`include "riscv_defines.v"

module riscv_pipeline #(
    parameter RESET_PC = 32'h00001000  // Reset address (default: Boot ROM start)
)(
    input                       clk,
    input                       rst_n,
    
    // Instruction fetch interface (IFU Interface)
    input  [31:0]               instr_i,            // Raw instruction from memory
    input                       instr_rvalid,       // High when instruction is ready
    output [31:0]               ifetch_addr,        // Program Counter to fetch memory (from IF stage)
    output                      ifetch_rvalid,      // Signal to memory that PC is valid (from IF stage)
    input                       ifu_ready,          // External ready signal for instruction fetch
    output                      instr_rready,       // Internal ready signal (inverted stall)
    
    // Pipeline Control & Status
    input                       debug_req,          // Request from Debug Module to enter Debug Mode
    output                      debug_mode,         // Status: Core is currently in Debug Mode
    output                      pipeline_flush_out, // Internal flush signal exported for IFU/Cache
    output                      pipeline_stall_out, // Internal stall signal exported for external units
    
    // Data memory interface (Load/Store/AMO) - controlled by riscv_mem module
    output                      mem_req,            // Memory access request (Load/Store/AMO) - from riscv_mem
    output                      mem_we,             // Memory write enable - from riscv_mem
    output [31:0]               mem_addr,           // Memory address - from riscv_mem
    output [31:0]               mem_wdata,          // Memory write data - from riscv_mem
    output [3:0]                mem_be,             // Memory byte enable - from riscv_mem
    input  [31:0]               mem_rdata,          // Memory read data
    input                       mem_ready,          // Memory ready signal
    input                       mem_rvalid,         // Read data valid signal
    
    // CLINT Interrupt Inputs
    input                       clint_tmr_irq,      // Timer interrupt from CLINT
    input                       clint_sft_irq,      // Software interrupt from CLINT
    
    // External Interrupt Input (from PLIC)
    input                       ext_irq             // External interrupt from PLIC
);

    //----------------------------------------------------------------------------
    // Constants
    //----------------------------------------------------------------------------

    //----------------------------------------------------------------------------
    // Pipeline Register Signals
    //----------------------------------------------------------------------------
    // IF/ID Pipeline Register: Managed by riscv_if_stage module
    // These signals provide the interface between Stage 1 (IF) and Stage 2 (ID/EX/MEM/WB)
    wire [31:0]                 if_pc;
    wire [4:0]                  if_rd;
    wire [4:0]                  if_rs1;
    wire [4:0]                  if_rs2;
    wire [31:0]                 if_sel_imm;
    wire [31:0]                 if_pc_ra;
    wire [47:0]                 if_ctrl_signals;
    wire                        if_valid;
    wire [31:0]                 if_restore_mis_target;
    wire                        if_early_jump_taken;

    wire [31:0]                 id_pc;
    wire [4:0]                  id_rd;
    wire [4:0]                  id_rs1;
    wire [4:0]                  id_rs2;
    wire [31:0]                 id_sel_imm;
    wire [31:0]                 id_pc_ra;
    wire [47:0]                 id_ctrl_signals;
    wire                        id_valid;
    wire [31:0]                 id_restore_mis_target;
    wire                        id_early_jump_taken;

    //----------------------------------------------------------------------------
    // Stage 2: Execution and Writeback Signals
    //----------------------------------------------------------------------------
    // Jump target (used by riscv_if_stage)
    wire [31:0] jump_target;           // Jump target (from riscv_exu)
   
    
    //----------------------------------------------------------------------------
    // Stage 1: Instruction Fetch (IF)
    //----------------------------------------------------------------------------
    // Module: riscv_if_stage
    // Handles instruction fetch, PC generation, early jump prediction, and IF/ID pipeline register
    //----------------------------------------------------------------------------
    // Early jump misprediction signals (from riscv_exu)
    wire                        early_not_jump_need_jump; // From riscv_exu
    wire                        early_jump_wrong_taken;   // From riscv_exu
    
    // Pipeline control signals (declared early for IF stage)
    wire                        pipeline_stall;           // Pipeline stall (from riscv_final_stage)
    wire                        pipeline_flush;           // Pipeline flush (computed in riscv_if_stage)
    
    // Stage 2 signals for IF stage (declared early, assigned later)
    wire [31:0]                 dpc;                      // Debug PC (from riscv_exu)
    wire [31:0]                 mepc;                     // Machine exception PC (from riscv_exu)
    wire [31:0]                 trap_vector;              // Trap handler address (from riscv_exu)
    
    wire                        trap_taken;               // Trap (exception/interrupt) taken
    wire                        mret_taken;               // MRET instruction executed
    wire                        dret_taken;               // DRET instruction executed
    
    // Trap/debug signals (declared early for riscv_exu, assigned later)
    wire [31:0]                 trap_pc_val;              // Trap PC value
    wire [31:0]                 trap_cause_val;           // Trap cause value
    wire [31:0]                 trap_value;               // Trap value
    
    // Debug mode control signals (from riscv_final_stage)
    wire                        debug_mode_pc;
    
    riscv_if_stage #(
        .RESET_PC                        (RESET_PC)
    ) u_if_stage (
        .clk                             (clk),
        .rst_n                           (rst_n),
        
        // Instruction Fetch Interface
        .instr_i                         (instr_i),
        .instr_rvalid                    (instr_rvalid),
        .ifetch_addr                     (ifetch_addr),
        .ifetch_rvalid                   (ifetch_rvalid),
        .ifu_ready                       (ifu_ready),
        .instr_rready                    (instr_rready),
        
        // Pipeline Control
        .pipeline_flush                  (pipeline_flush),    // Pipeline flush (computed in riscv_if_stage)
        .pipeline_stall                  (pipeline_stall),
        
        // Next PC Selection Inputs (from Stage 2)
        .debug_mode_pc                   (debug_mode_pc),
        .dret_taken                      (dret_taken),
        .mret_taken                      (mret_taken),
        .trap_taken                      (trap_taken),
        .dpc                             (dpc),
        .mepc                            (mepc),
        .trap_vector                     (trap_vector),
        .jump_target                     (jump_target),
        .early_jump_wrong_taken          (early_jump_wrong_taken),
        .early_not_jump_need_jump        (early_not_jump_need_jump),
        
        // IF/ID Pipeline Register Outputs
        .if_pc                           (if_pc),
        .if_rd                           (if_rd),           
        .if_rs1                          (if_rs1),                   
        .if_rs2                          (if_rs2),                   
        .if_sel_imm                      (if_sel_imm),
        .if_pc_ra                        (if_pc_ra),
        .if_ctrl_signals                 (if_ctrl_signals),
        
        .if_valid                        (if_valid),
        .if_restore_mis_target           (if_restore_mis_target),
        .if_early_jump_taken             (if_early_jump_taken)
    );
    
    riscv_pipeline_regs #(
        .DW                      ((5 + 5 + 5)),
        .INITIAL_VALUE           ({{5{1'b0}}, {5{1'b0}}, {5{1'b0}}})
    ) u_if_id_regs (
        .clk                     (clk),
        .rstn                    (rst_n),
        .flush                   (pipeline_flush),
        .stall                   (pipeline_stall),
        
        .data_i                  ({if_rs2, if_rs1, if_rd}),
        .data_o                  ({id_rs2, id_rs1, id_rd})
    );
 
     riscv_pipeline_regs #(
        .DW                      ((1 + 32 +  32)),
        .INITIAL_VALUE           ({{1{1'b0}}, {32{1'b0}}, {32{1'b0}}})
    ) u_if_id_pc_imm_regs (
        .clk                     (clk),
        .rstn                    (rst_n),
        .flush                   (pipeline_flush),
        .stall                   (pipeline_stall),
        
        .data_i                  ({if_valid, if_sel_imm, if_pc}),
        .data_o                  ({id_valid, id_sel_imm, id_pc})
    );

     riscv_pipeline_regs #(
        .DW                      ((32)),
        .INITIAL_VALUE           ({32{1'b0}})
    ) u_if_id_pc_ra_regs (
        .clk                     (clk),
        .rstn                    (rst_n),
        .flush                   (1'b0),
        .stall                   (pipeline_stall | pipeline_flush),
        
        .data_i                  ({if_pc_ra}),
        .data_o                  ({id_pc_ra})
    );
     
      riscv_pipeline_regs #(
        .DW                      (( 1 + 32  + 48)),
        .INITIAL_VALUE           ({{1{1'b0}}, {32{1'b0}}, {48{1'b0}}})
    ) u_if_id_ctrl_regs (
        .clk                     (clk),
        .rstn                    (rst_n),
        .flush                   (pipeline_flush),
        .stall                   (pipeline_stall),
        
        .data_i                  ({if_early_jump_taken, if_restore_mis_target, if_ctrl_signals}),
        .data_o                  ({id_early_jump_taken, id_restore_mis_target, id_ctrl_signals})
    );
         
    // Pipeline Stall Logic:
    //   - Pipeline stall is now computed in riscv_final_stage.v
    //   - Stall when memory, AMO, or multdiv operation is pending
    //   - Stall on FENCE instruction until memory operations complete
    //   - Combinational logic eliminates registered state latency
    assign pipeline_stall_out = pipeline_stall;
    
    //----------------------------------------------------------------------------
    // Stage 2: Final Stage (ID/EX/MEM/WB)
    //----------------------------------------------------------------------------
    // Module: riscv_final_stage
    // Integrates all Stage 2 pipeline modules:
    //   - riscv_decode (ID): Instruction decoding and control signal generation
    //   - riscv_exu (EX): ALU, multiplier/divider, CSR, branch/jump evaluation, exception/interrupt handling
    //   - riscv_mem (MEM): Memory operations (load/store/AMO)
    //   - riscv_wb (WB): Register file and writeback logic
    // All phases execute in the same clock cycle
    //----------------------------------------------------------------------------
    
    riscv_final_stage u_final_stage (
        // Clock and Reset
        .clk                             (clk),
        .rst_n                           (rst_n),
        
        // Pipeline Control
        .if_id_valid                     (id_valid),
        // Pipeline Control Outputs
        .pipeline_stall                  (pipeline_stall),
       
        // Instruction Inputs (from IF Stage)
        .pc                              (id_pc),
        .ctrl_signals                    (id_ctrl_signals),        
        .rd                              (id_rd),
        .rs1                             (id_rs1),
        .rs2                             (id_rs2),
        .selected_imm                    (id_sel_imm),
        .return_address                  (id_pc_ra),       
        // Early Jump Prediction Inputs (from IF Stage)
        .id_restore_mis_target           (id_restore_mis_target),   
        .if_early_jump_taken             (id_early_jump_taken),
       
        // System-level inputs (for CSR trap/interrupt/debug handling)
        .ext_irq                         (ext_irq),
        .clint_tmr_irq                   (clint_tmr_irq),
        .clint_sft_irq                   (clint_sft_irq),
        
        .ifetch_addr                     (if_pc),
        .debug_req                       (debug_req),
        
        // External Memory Interface (to AXI4/Data Bus)
        .mem_req                         (mem_req),
        .mem_we                          (mem_we),
        .mem_addr                        (mem_addr),
        .mem_wdata                       (mem_wdata),
        .mem_be                          (mem_be),
        .mem_rdata                       (mem_rdata),
        .mem_ready                       (mem_ready),
        .mem_rvalid                      (mem_rvalid),
        
        // Branch/Jump Control
        .jump_target                     (jump_target),
        
        // Branch/Jump Misprediction Detection Outputs
        .early_jump_wrong_taken          (early_jump_wrong_taken),
        .early_not_jump_need_jump        (early_not_jump_need_jump),
        
        // MRET and DRET taken signals
        .mret_taken                      (mret_taken),
        .dret_taken                      (dret_taken),
        
        // CSR Results (unused in riscv_pipeline.v)
        .mepc                            (mepc),
        .dpc                             (dpc),
        
        // Exception and Interrupt Handling Outputs
        .trap_taken                      (trap_taken),
        .trap_vector                     (trap_vector),
        
        
        // Debug Mode Control Outputs (from riscv_exu)
        .debug_mode                      (debug_mode),              // Debug mode status (registered in riscv_exu)
        .debug_mode_pc                   (debug_mode_pc)
    );
    
    
    assign pipeline_flush_out = pipeline_flush;  // Output for IFU
    
    //----------------------------------------------------------------------------
    // Debug: Completed Instruction Tracking (Simulation Only)
    //----------------------------------------------------------------------------
    // synopsys translate_off
    reg  [31:0]                 completed_pc;           // PC of completed instruction
    reg  [31:0]                 completed_instruction;  // Completed instruction
    reg                         instruction_complete;   // High when instruction completes
    always @(posedge clk, negedge rst_n)
        if (~rst_n) begin
            completed_pc          <= RESET_PC;
            completed_instruction <= {32{1'b0}};
            instruction_complete  <= 1'b0;
        end else begin
            if (id_valid & ~pipeline_stall) begin
                completed_pc  <= id_pc;
                completed_instruction       <= 'd0;
                instruction_complete         <= 1'b1;
            end else begin
                instruction_complete         <= 1'b0;
            end
        end
    // synopsys translate_on

endmodule

//=============================================================================
// RISC-V Execution Unit Module
//=============================================================================
// This module encapsulates all execution unit logic for the RISC-V pipeline:
//   - ALU operations and input selection
//   - Multiplier/Divider operations (M extension)
//   - CSR operations (Zicsr extension)
//   - Branch condition evaluation
//   - Jump/Branch target calculation
//   - Branch/Jump misprediction detection (compares early prediction with actual result)
//   - Result selection logic (ALU, Multdiv, CSR, Return Address)
//=============================================================================

`include "riscv_defines.v"

module riscv_exu (
    // Clock and Reset
    input               clk,
    input               rst_n,
    
    // Pipeline Control
    input               if_id_valid,                     // Instruction valid in decode stage
    
    // Instruction Fields (from Decode Stage)
    input  [4:0]        rd,                              // Destination register
    input  [4:0]        rs1,                             // Source register 1 (for CSR write data selection)
    input  [31:0]       pc,                              // Program Counter (for branch/jump target calculation)
    
    // Register File Data
    input  [31:0]       rs1_data,                        // Source register 1 data
    input  [31:0]       rs2_data,                        // Source register 2 data
    
    // Immediate Values (from Decode Stage)
    input  [31:0]       selected_imm,                    // Selected immediate based on instruction type
    input  [31:0]       return_address,                  // Return address for JAL/JALR (from Decode Stage)
    
    // Control Signals (from Decode Stage)
    input  [3:0]        ctrl_alu_op,                     // ALU operation
    input               ctrl_alu_src_a,                  // ALU source A select (0: rs1_data, 1: PC)
    input               ctrl_alu_src_b,                  // ALU source B select (0: rs2_data, 1: immediate)
    input               ctrl_branch,                     // Branch instruction
    input  [2:0]        ctrl_branch_type,                // Branch type
    input               ctrl_jump,                       // Jump instruction (JAL/JALR)
    input               ctrl_jump_save_ra,               // Jump save return address
    input  [11:0]       ctrl_csr_addr,                   // CSR Address
    input               ctrl_csr_imm,
    input               ctrl_csr_we,                     // CSR write enable
    input  [1:0]        ctrl_csr_op,                     // CSR operation type
    input               ctrl_multdiv_req,                // Multiplier/Divider request
    input  [2:0]        ctrl_multdiv_op,                 // Multiplier/Divider operation
    input               ctrl_reg_we,                     // Register write enable control
    input               ctrl_mret,                       // MRET instruction
    input               ctrl_dret,                       // DRET instruction
    input               ctrl_ecall,                      // ECALL instruction
    input               ctrl_ebreak,                     // EBREAK instruction
    input               ctrl_wfi,
    // Pipeline Stall Signal (for pending operations)
    input               pipeline_stall,                  // Pipeline stall signal
    
    // Exception/Interrupt Detection Inputs
    input               ctrl_illegal_inst,               // Illegal instruction from decode
    input               exception_load_addr_misaligned,  // Load address misalignment from riscv_mem
    input               exception_store_addr_misaligned, // Store address misalignment from riscv_mem
    input  [31:0]       ifetch_addr,                     // Instruction fetch address (Point to next address)
    
    // System-level inputs (for CSR trap/interrupt/debug handling)
    input               ext_irq,                         // External interrupt from PLIC
    input               clint_tmr_irq,                   // Timer interrupt from CLINT
    input               clint_sft_irq,                   // Software interrupt from CLINT

    input  [1:0]        prv_mode,                        // Current privilege mode (always 2'b11 for M-mode)
    input               debug_req,                       // Request from Debug Module to enter Debug Mode
    input               csr_instret_inc,
    input               reg_we,                          // Register write enable (for instruction completion check)
    
    output [31:0]       alu_mem_addr,         
    
    // Branch/Jump Control
    output [31:0]       jump_target,                     // Jump target address (JAL/JALR)
    
    // Early Jump Prediction Inputs (from IF Stage)
    input  [31:0]       id_restore_mis_target,
    input               if_early_jump_taken,             // Early predicted jump taken from IF stage
    
    // Branch/Jump Misprediction Detection Outputs
    output              early_jump_wrong_taken,          // Early branch prediction wrong (taken but not taken)
    output              early_not_jump_need_jump,        // Early prediction missed (not taken but should be taken)

    //
    output              dret_taken,
    output              mret_taken,
    // Multiplier/Divider Results
    output              multdiv_pending,                 // Multiplier/Divider operation in progress

    // CSR Result
    output [31:0]       mepc,                            // Machine exception PC
    output [31:0]       dpc,                             // Debug PC (for DRET return)
    
    // Exception and Interrupt Handling Outputs
    output              trap_taken,                      // Trap (exception/interrupt) taken
    output [31:0]       trap_vector,                     // Trap handler address
    
    // Pipeline Stall Signals
    output              wfi_stall,                       // WFI stall signal
    
    // Debug Mode Control Outputs
    output reg          debug_mode,                      // Debug mode status (registered)
    output              debug_mode_pc,                   // Debug mode PC redirection
    
    // Writeback Results
    output [4:0]        reg_rd,                          // Destination register (for writeback)
    output [31:0]       reg_wdata,                       // Register write data (selected result)
    output              reg_we_out                       // Register write enable
);

    //----------------------------------------------------------------------------
    // ALU Input Selection
    //----------------------------------------------------------------------------
    // For LUI: alu_a = rs0, alu_b = imm_u (result = imm_u)
    // For JAL: alu_a = PC, alu_b = imm_j (jump target = PC + imm_j)
    // For JALR: alu_a = rs1, alu_b = imm_i (jump target = rs1 + imm_i)
    wire [31:0]       alu_a;
    wire [31:0]       alu_b;
    wire [31:0]       alu_result;
    wire              alu_zero;                           // ALU zero flag
    wire              alu_lt;                             // ALU signed less than
    wire              alu_ltu;                            // ALU unsigned less than      
    assign alu_a        = (ctrl_alu_src_a) ? pc : rs1_data;
    assign alu_b        = (ctrl_alu_src_b) ? selected_imm : rs2_data;
    assign alu_mem_addr = alu_result;
    //----------------------------------------------------------------------------
    // ALU Module
    //----------------------------------------------------------------------------
    riscv_alu u_alu (
        .a      (alu_a),
        .b      (alu_b),
        .alu_op (ctrl_alu_op),
        .result (alu_result),
        .zero   (alu_zero),
        .lt     (alu_lt),
        .ltu    (alu_ltu)
    );
    
    //----------------------------------------------------------------------------
    // Multiplier/Divider Module
    //----------------------------------------------------------------------------
    wire [31:0]       multdiv_result;                    // Multiplier/Divider result
    wire              multdiv_ready;                     // Multiplier/Divider operation complete    
    riscv_multdiv u_multdiv (
        .clk    (clk),
        .rst_n  (rst_n),
        .valid  (ctrl_multdiv_req && if_id_valid),
        .a      (alu_a),                                 // Use ALU input A (rs1_data or PC)
        .b      (alu_b),                                 // Use ALU input B (rs2_data or immediate)
        .op     (ctrl_multdiv_op),
        .result (multdiv_result),
        .ready  (multdiv_ready)
    );
    
    // Multiplier/Divider pending: operation requested but not complete
    assign multdiv_pending = ctrl_multdiv_req && if_id_valid && !multdiv_ready;
    
    //----------------------------------------------------------------------------
    // CSR Module
    //----------------------------------------------------------------------------
    // CSR write data selection: 
    // For immediate variants (CSRRWI/CSRRSI/CSRRCI), use rs1 field zero-extended as immediate
    // For register variants (CSRRW/CSRRS/CSRRC), use rs1_data
    wire [31:0]       csr_wdata = ctrl_csr_imm ? {{27{1'b0}}, rs1[4:0]} : rs1_data;
    wire [31:0]       csr_rdata;
    // MRET and DRET taken signals (need to be computed before CSR instantiation for trap signals)
    assign mret_taken = ctrl_mret && if_id_valid;
    // Note: dret_taken uses debug_mode which is registered, so it uses previous cycle's value
    assign dret_taken = ctrl_dret && !pipeline_stall && if_id_valid && debug_mode;
    
    // Declare trap signals as wires (will be assigned in exception/interrupt handling)
    wire              trap_taken_int;
    wire [31:0]       trap_cause;
    wire [31:0]       trap_pc;
    wire [31:0]       trap_value;
    wire [31:0]       mtvec;
    wire              mie;                                // Machine interrupt enable
    wire              meie;                               // Machine external interrupt enable
    wire              mtie;                               // Machine timer interrupt enable
    wire              msie;                               // Machine software interrupt enable    
    wire [31:0]       mip;
    wire [31:0]       dcsr_out;                           // DCSR output for ebreak checking

    wire              debug_mode_entry;
    wire [31:0]       dbg_entry_pc;
    wire [2:0]        dbg_cause_val;                      // Debug cause value (computed)
    riscv_csr u_csr (
        .clk             (clk),
        .rst_n           (rst_n),
        .csr_addr        (ctrl_csr_addr),
        .csr_wdata       (csr_wdata),
        .csr_op          (ctrl_csr_op),
        .csr_we          (ctrl_csr_we && !pipeline_stall && if_id_valid),
        .csr_rdata       (csr_rdata),
        .trap            (trap_taken_int),
        .trap_pc         (trap_pc),
        .trap_cause      (trap_cause),
        .trap_value      (trap_value),
        .mtvec           (mtvec),
        .mepc            (mepc),
        .ext_irq         (ext_irq),
        .clint_tmr_irq   (clint_tmr_irq),
        .clint_sft_irq   (clint_sft_irq),
        .mie             (mie),
        .meie            (meie),
        .mtie            (mtie),
        .msie            (msie),
        .mip             (mip),
        .mret            (mret_taken),
        .dbg_mode        (debug_mode),                   // Use registered debug_mode output
        .dbg_mode_entry  (debug_mode_entry),
        .dbg_entry_pc    (dbg_entry_pc),
        .dbg_cause       (dbg_cause_val),
        .dret            (dret_taken),
        .prv_mode        (prv_mode),
        .csr_instret_inc (csr_instret_inc),
        .dpc             (dpc),
        .dcsr_out        (dcsr_out)
    );
    
    //----------------------------------------------------------------------------
    // Exception and Interrupt Handling
    //----------------------------------------------------------------------------
    // Exception and interrupt detection, cause encoding, and trap handling
    // Interrupts are detected by checking MIP register bits (from CSR module)
    // and corresponding MIE enable bits.
    //
    // MIP Register Bits (from CSR module):
    //   - Bit 3 (MSIP): Read-only, reflects CLINT MSIP register (software interrupt)
    //   - Bit 7 (MTIP): Read-only, reflects CLINT timer interrupt (MTIME >= MTIMECMP)
    //   - Bit 11 (MEIP): Writable via CSR for external interrupts
    //----------------------------------------------------------------------------
    localparam [1:0] WORD_ALIGNED = 2'b00;
    
    wire        exception_ecall;
    wire        exception_ebreak;
    wire        exception_illegal_inst;
    wire        exception_taken;
    reg  [31:0] exception_cause;
    reg  [31:0] exception_value;
    
    wire        msi_enabled;
    wire        mti_enabled;
    wire        mei_enabled;
    wire        interrupt_pending;
    wire        interrupt_taken;
    reg  [31:0] interrupt_cause;
    
    // ebreak control signals (dcsr comes from CSR module)
    wire dcsr_ebreakm = dcsr_out[15];
    wire dcsr_step = dcsr_out[2];
    wire exception_ebreak_normal;
    
    // Exception Detection:
    //   Exceptions are detected when instruction is valid in decode stage
    assign exception_ecall          = ctrl_ecall && if_id_valid;
    assign exception_ebreak         = ctrl_ebreak && if_id_valid;
    // Illegal instruction: either from control unit or invalid compressed instruction
    assign exception_illegal_inst   = if_id_valid && ctrl_illegal_inst;
    
    // Update exception_ebreak to exclude ebreak when it enters debug mode
    assign exception_ebreak_normal  = exception_ebreak && !dcsr_ebreakm;
    
    // Exception Cause and Value Encoding:
    always @(*) begin
        exception_cause = {32{1'b0}};
        exception_value = {32{1'b0}};
        if (exception_ecall) begin
            exception_cause = `EXC_ECALL_M;
            exception_value = {32{1'b0}};
        end else if (exception_ebreak_normal) begin
            exception_cause = `EXC_BREAKPOINT;
            exception_value = pc;
        end else if (exception_illegal_inst) begin
            exception_cause = `EXC_ILLEGAL_INST;
            exception_value = pc;
        end else if (exception_load_addr_misaligned) begin
            exception_cause = `EXC_LOAD_ADDR_MISALIGNED;
            exception_value = alu_result;
        end else if (exception_store_addr_misaligned) begin
            exception_cause = `EXC_STORE_ADDR_MISALIGNED;
            exception_value = alu_result;
        end
    end
    
    // Exception Taken Signal:
    //   Excludes ebreak when it enters debug mode (handled separately)
    assign exception_taken = exception_ecall || exception_ebreak_normal || exception_illegal_inst ||
                            exception_load_addr_misaligned || exception_store_addr_misaligned;
    
    // Interrupt Detection:
    //   Checks MIP register bits (from CSR module) and corresponding MIE enable bits
    //   MSI: Machine Software Interrupt (MIP bit 3, from CLINT MSIP register)
    //   MTI: Machine Timer Interrupt (MIP bit 7, from CLINT timer interrupt)
    //   MEI: Machine External Interrupt (MIP bit 11, writable via CSR)
    //   Interrupt is enabled if: (mip[bit] == 1) && (mie == 1) && (mie[bit] == 1)
    wire irq_mask     = debug_mode | dcsr_step | ~mie;
    wire wfi_irq_mask = debug_mode | dcsr_step;
    assign msi_enabled = mip[`MIP_MSI_BIT] && msie;
    assign mti_enabled = mip[`MIP_MTI_BIT] && mtie;
    assign mei_enabled = mip[`MIP_MEI_BIT] && meie;
    
    assign interrupt_pending = mei_enabled || mti_enabled || msi_enabled;
    
    //----------------------------------------------------------------------------
    // Pipeline Stall Logic
    //----------------------------------------------------------------------------
    // WFI stall: Wait for interrupt when WFI instruction is executed
    assign wfi_stall = ctrl_wfi & if_id_valid & ~interrupt_pending & ~wfi_irq_mask;
    
    // Interrupt Cause Encoding:
    //   Priority: MEI > MTI > MSI (external interrupts have highest priority)
    //   Interrupt cause is encoded with bit 31 set (interrupt flag)
    always @(*) begin
        interrupt_cause = {32{1'b0}};
        if (mei_enabled) begin
            interrupt_cause = `IRQ_EXTERNAL_M;
        end else if (mti_enabled) begin
            interrupt_cause = `IRQ_TIMER_M;
        end else if (msi_enabled) begin
            interrupt_cause = `IRQ_SOFTWARE_M;
        end
    end
    
    assign interrupt_taken = interrupt_pending && !irq_mask & !exception_taken && !pipeline_stall;
    
    // Trap Handling:
    //   Trap = Exception OR Interrupt
    //   Trap PC: Use return_address 
    //   Trap Value: 0 for interrupts, exception-specific value for exceptions
    wire [31:0] interrupt_pc =(early_not_jump_need_jump)?  jump_target:
                              (early_jump_wrong_taken)? id_restore_mis_target:
                               ifetch_addr;
    assign trap_taken_int = (~debug_mode) & (exception_taken || interrupt_taken);
    assign trap_cause     = exception_taken ? exception_cause : interrupt_cause;
    assign trap_pc        = exception_taken ? pc: interrupt_pc;
    assign trap_value     = interrupt_taken ? {32{1'b0}} : exception_value;
    
    // Assign to output ports
    assign trap_taken = trap_taken_int;
    
    // Trap Vector Calculation:
    //   Direct mode (mtvec[1:0] = 00): Use mtvec directly
    //   Vectored mode (mtvec[1:0] = 01): Use mtvec + (cause << 2)
    assign trap_vector = (mtvec[1:0] == WORD_ALIGNED) ? mtvec : (mtvec + (trap_cause << 2));
    
    //----------------------------------------------------------------------------
    // Branch Logic
    //----------------------------------------------------------------------------
    // Evaluate branch condition based on branch type
    reg branch_taken; 
    always @(*) begin
        case (ctrl_branch_type)
            `F3_BEQ:  branch_taken = alu_zero;
            `F3_BNE:  branch_taken = !alu_zero;
            `F3_BLT:  branch_taken = alu_lt;
            `F3_BGE:  branch_taken = !alu_lt;
            `F3_BLTU: branch_taken = alu_ltu;
            `F3_BGEU: branch_taken = !alu_ltu;
            default:  branch_taken = 1'b0;
        endcase
    end
    
    // Branch target calculation: PC + selected_imm
    wire [31:0] branch_target = pc + selected_imm;
    
    // Jump target calculation:
    //   JAL: PC + imm_j (calculated by ALU with alu_a=PC, alu_b=imm_j)
    //   JALR: (rs1 + imm_i) & ~1 (calculated by ALU with alu_a=rs1, alu_b=imm_i)
    //   For JALR, lower bit is cleared for alignment
    assign jump_target = (ctrl_jump) ? ({alu_result[31:1], 1'b0}) : branch_target;
    
    //----------------------------------------------------------------------------
    // Branch/Jump Misprediction Detection
    //----------------------------------------------------------------------------
    // Compare early jump prediction from IF stage with actual branch/jump evaluation
    // Early Jump Misprediction Detection:
    //   Mismatch occurs when:
    //   1. Early jump was predicted taken AND instruction is in decode
    //   2. AND one of:
    //      a) Actual jump/branch target != predicted target
    //      b) Branch was predicted taken but actually not taken
    //      c) Instruction is not actually a jump/branch (not taken but should be taken)
    
    wire ctrl_jmp_taken        = (ctrl_jump || (ctrl_branch && branch_taken));
    wire ctrl_branch_not_taken = (ctrl_branch & ~branch_taken);
    
    assign early_jump_wrong_taken   = ctrl_branch_not_taken & if_early_jump_taken & if_id_valid;
    assign early_not_jump_need_jump = ~if_early_jump_taken & ctrl_jmp_taken & if_id_valid;
    
    //----------------------------------------------------------------------------
    // Register Writeback Logic
    //----------------------------------------------------------------------------
    // Register destination
    assign reg_rd = rd;
    
    // Register write enable:
    //   - Control signal indicates writeback needed (ctrl_reg_we)
    //   - Pipeline not stalled (!pipeline_stall)
    //   - Instruction valid in decode stage (if_id_valid)
    //   - Multdiv operations complete: wait for multdiv_ready
    assign reg_we_out = ctrl_reg_we && !pipeline_stall && if_id_valid &&
                        (!ctrl_multdiv_req || (ctrl_multdiv_req && multdiv_ready));
    
    // Register write data selection priority:
    //   1. CSR operations -> csr_rdata
    //   2. Multdiv operations -> multdiv_result
    //   3. Jump save return address -> return_address
    //   4. ALU operations -> alu_result
    assign reg_wdata = ctrl_csr_we       ? csr_rdata :
                       ctrl_multdiv_req  ? multdiv_result :
                       ctrl_jump_save_ra ? return_address :
                                           alu_result;
    
    //----------------------------------------------------------------------------
    // Debug Mode Entry Logic
    //----------------------------------------------------------------------------
    // Per RISC-V Debug Spec 0.13, debug entry occurs at instruction boundaries.
    // Must wait for current instruction to complete before entering debug mode.
    //
    // Entry Conditions:
    //   1. debug_req asserted OR ebreak with ebreakm=1
    //   2. Not already in debug mode
    //   3. Wait for final pipeline empty
    //
    // Instruction Completion Check:
    //   - No instruction in pipeline: Can enter immediately
    //   - Instruction present: Wait for pipeline_stall = 0 and writeback completes
    //----------------------------------------------------------------------------
      
    // Check if ebreak should enter debug mode
    assign ebreak_enters_debug_mode = ctrl_ebreak && if_id_valid && debug_mode;
    
    // Step entry debug mode (registered)
    reg step_entry_debug_mode;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            step_entry_debug_mode <= 1'b0;
        end else begin
            step_entry_debug_mode <= dcsr_step & ~debug_mode & if_id_valid;
        end
    end
    
    //----------------------------------------------------------------------------
    // Debug Mode Register
    //----------------------------------------------------------------------------
    // Debug mode: assert when entering debug mode, clear on exit or when debug_req deasserted
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debug_mode <= 1'b0;
        end else begin
            if (debug_mode_entry) begin
                debug_mode <= 1'b1;  // Enter debug mode
            end else if (dret_taken) begin
                debug_mode <= 1'b0;  // Exit debug mode via DRET
            end
        end
    end
    
    // Debug Mode Entry Triggers:
    //   1. debug_req from debug module 
    //   2. ebreak instruction when ebreakm=1 (DCSR bit 15)
    //   3. step_entry_debug_mode (from DCSR step bit)
    assign debug_mode_entry = ((debug_req | 
                                step_entry_debug_mode |
                                ebreak_enters_debug_mode) &
                               !debug_mode & ~pipeline_stall);
    
    // Debug mode PC redirection
    assign debug_mode_pc    = ((debug_req & !debug_mode) |
                               (ebreak_enters_debug_mode) | 
                               step_entry_debug_mode) & ~pipeline_stall;
    
    // Debug Cause Encoding (per RISC-V Debug Spec):
    //   1 = ebreak instruction
    //   3 = haltreq from debug module
    //   4 = step entry
    assign dbg_cause_val    = ebreak_enters_debug_mode ? 3'd1 :
                               debug_req                ? 3'd3 :
                               step_entry_debug_mode    ? 3'd4 :
                                                          3'd0;
    
    //----------------------------------------------------------------------------
    // Debug Entry PC Calculation
    //----------------------------------------------------------------------------
    // DPC (Debug PC): Saved PC for debug mode entry
    // When entering debug mode, save the PC of the instruction after the one currently in pipeline
    assign dbg_entry_pc     = ifetch_addr;
endmodule


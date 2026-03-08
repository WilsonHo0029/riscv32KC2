//=============================================================================
// RISC-V Final Stage Module (ID/EX/MEM/WB)
//=============================================================================
// This module integrates all Stage 2 pipeline modules:
//   - riscv_decode (ID): Instruction decoding and control signal generation
//   - riscv_exu (EX): ALU, multiplier/divider, CSR, branch/jump evaluation, exception/interrupt handling
//   - riscv_mem (MEM): Memory operations (load/store)
//   - riscv_wb (WB): Register file and writeback logic
//
// All phases (ID, EX, MEM, WB) execute in the same clock cycle in this 2-stage pipeline.
//=============================================================================

`include "riscv_defines.v"

module riscv_final_stage (
    // Clock and Reset
    input               clk,
    input               rst_n,
    
    // Pipeline Control
    input               if_id_valid,        // Instruction valid in final stage
     // Pipeline Control Outputs
    output              pipeline_stall,     // Pipeline stall signal (computed in this module)   
    // Instruction Inputs (from IF Stage)
    input  [31:0]       pc,                 // Program Counter
    input  [47:0]       ctrl_signals,        
    input  [4:0]        rd,
    input  [4:0]        rs1,
    input  [4:0]        rs2,
    input  [31:0]       selected_imm,
    input  [31:0]       return_address,
    // Early Jump Prediction Inputs (from IF Stage)
    input  [31:0]       id_restore_mis_target,
    input               if_early_jump_taken,   // Early predicted jump taken
    
    // System-level inputs (for CSR trap/interrupt/debug handling)
    input               ext_irq,            // External interrupt from PLIC
    input               clint_tmr_irq,      // Timer interrupt from CLINT
    input               clint_sft_irq,      // Software interrupt from CLINT

    input  [31:0]       ifetch_addr,        // Instruction fetch address (for trap PC)
    input               debug_req,          // Request from Debug Module to enter Debug Mode
    
    // External Memory Interface (to AXI4/Data Bus)
    output              mem_req,            // Memory access request
    output              mem_we,             // Memory write enable
    output [31:0]       mem_addr,            // Memory address
    output [31:0]       mem_wdata,           // Memory write data
    output [3:0]        mem_be,              // Memory byte enable
    input  [31:0]       mem_rdata,           // Memory read data
    input               mem_ready,           // Memory ready signal
    input               mem_rvalid,          // Read data valid signal
    
    // Branch/Jump Control
    output [31:0]       jump_target,         // Jump target address
    
    // Branch/Jump Misprediction Detection Outputs
    output              early_jump_wrong_taken,    // Early branch prediction wrong
    output              early_not_jump_need_jump,  // Early prediction missed
    
    // MRET and DRET taken signals
    output              mret_taken,
    output              dret_taken,
    
    // CSR Results
    output [31:0]       mepc,                 // Machine exception PC
    output [31:0]       dpc,                  // Debug PC (for DRET return)
    
    // Exception and Interrupt Handling Outputs
    output              trap_taken,          // Trap (exception/interrupt) taken
    output [31:0]       trap_vector,         // Trap handler address
    
    
    // Debug Mode Control Outputs (from riscv_exu)
    output              debug_mode,         // Debug mode status (registered in riscv_exu)
    output              debug_mode_pc             // Debug mode PC redirection

);

    //----------------------------------------------------------------------------
    // Internal Signals
    //----------------------------------------------------------------------------
    // Instruction fields (from riscv_decode)
   // wire [4:0]        rd;
   // wire [4:0]        rs1;
   // wire [4:0]        rs2;
    
    // Immediate values (from riscv_decode)
    //wire [31:0]       selected_imm;
    //wire [31:0]       return_address;
    // Control signals (from riscv_decode)
    wire [3:0]        ctrl_alu_op = ctrl_signals[3:0]; 
    wire              ctrl_alu_src_a = ctrl_signals[4]; 
    wire              ctrl_alu_src_b = ctrl_signals[5];    
    wire              ctrl_reg_we= ctrl_signals[6];    
    wire              ctrl_reg_src= ctrl_signals[7];    
    wire              ctrl_mem_req= ctrl_signals[8];    
    wire              ctrl_mem_we= ctrl_signals[9];
    wire [2:0]        ctrl_mem_size= ctrl_signals[12:10]; 
    wire              ctrl_mem_sign_ext= ctrl_signals[13];
    wire              ctrl_branch= ctrl_signals[14];
    wire [2:0]        ctrl_branch_type= ctrl_signals[17:15];
    wire              ctrl_jump= ctrl_signals[18];
    wire              ctrl_jump_save_ra= ctrl_signals[19];
    wire [11:0]       ctrl_csr_addr= ctrl_signals[31:20];
    wire              ctrl_csr_imm= ctrl_signals[32];
    wire              ctrl_csr_we= ctrl_signals[33];
    wire [1:0]        ctrl_csr_op= ctrl_signals[35:34];
    wire              ctrl_multdiv_req= ctrl_signals[36];
    wire [2:0]        ctrl_multdiv_op= ctrl_signals[39:37];
    wire              ctrl_fence= ctrl_signals[40];
    wire              ctrl_fence_i= ctrl_signals[41];
    wire              ctrl_ecall= ctrl_signals[42];
    wire              ctrl_ebreak= ctrl_signals[43];
    wire              ctrl_mret= ctrl_signals[44];
    wire              ctrl_dret= ctrl_signals[45];
    wire              ctrl_wfi= ctrl_signals[46];
    wire              ctrl_illegal_inst= ctrl_signals[47];
    
    // Register file data (from riscv_wb)
    wire [31:0]       rs1_data;
    wire [31:0]       rs2_data;
    
    // Execution unit outputs
    wire [4:0]        reg_rd;
    wire [31:0]       reg_wdata_exu;
    wire              reg_we_exu;
    
    wire [31:0]       alu_mem_addr;
    // Pipeline stall signals
    wire              wfi_stall;
    
    // Memory operation results
    wire [31:0]       mem_result;
    wire              mem_pending;
    wire              multdiv_pending;   

    wire 	          csr_instret_inc =  if_id_valid & ~pipeline_stall & ~trap_taken;

    wire              exception_load_addr_misaligned;   // Load address misalignment
    wire              exception_store_addr_misaligned;  // Store address misalignment
    //----------------------------------------------------------------------------
    // Module Instantiations
    //----------------------------------------------------------------------------
      
    //----------------------------------------------------------------------------
    // Writeback Stage (WB)
    //----------------------------------------------------------------------------
    riscv_wb u_wb (
        .clk(clk),
        .rst_n(rst_n),
        
        // Register Read Addresses (from Decode Stage)
        .rs1_addr(rs1),
        .rs2_addr(rs2),
       
        // Register Read Data Outputs
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        
        // Writeback Control Signals (from Execution Unit)
        .reg_we_exu(reg_we_exu),
        .reg_rd(reg_rd),
        .reg_wdata_exu(reg_wdata_exu),
        
        // Memory Operation Control Signals (from Decode Stage)
        .ctrl_mem_req(ctrl_mem_req),
        .ctrl_mem_we(ctrl_mem_we),
        .ctrl_reg_src(ctrl_reg_src),
        
        // Memory Operation Completion Signals
        .mem_rvalid(mem_rvalid),
        .mem_ready(mem_ready),
        
        // Memory/AMO Result Data
        .mem_result(mem_result),
        
        // Final Writeback Signals
        .reg_we(reg_we)
    );
    
    //----------------------------------------------------------------------------
    // Execution Stage (EX)
    //----------------------------------------------------------------------------
    riscv_exu u_exu (
        // Clock and Reset
        .clk(clk),
        .rst_n(rst_n),
        
        // Pipeline Control
        .if_id_valid(if_id_valid),
        
        // Instruction Fields (from Decode Stage)
        .rd(rd),
        .rs1(rs1),
        .pc(pc),
        
        // Register File Data
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        
        // Immediate Values (from Decode Stage)
        .selected_imm(selected_imm),
        .return_address(return_address),
        
        // Control Signals (from Decode Stage)
        .ctrl_alu_op(ctrl_alu_op),
        .ctrl_alu_src_a(ctrl_alu_src_a),
        .ctrl_alu_src_b(ctrl_alu_src_b),
        .ctrl_branch(ctrl_branch),
        .ctrl_branch_type(ctrl_branch_type),
        .ctrl_jump(ctrl_jump),
        .ctrl_jump_save_ra(ctrl_jump_save_ra),
        .ctrl_csr_addr(ctrl_csr_addr),
        .ctrl_csr_imm(ctrl_csr_imm),
        .ctrl_csr_we(ctrl_csr_we),
        .ctrl_csr_op(ctrl_csr_op),
        .ctrl_multdiv_req(ctrl_multdiv_req),
        .ctrl_multdiv_op(ctrl_multdiv_op),
        .ctrl_reg_we(ctrl_reg_we),
        .ctrl_mret(ctrl_mret),
        .ctrl_dret(ctrl_dret),
        .ctrl_ecall(ctrl_ecall),
        .ctrl_ebreak(ctrl_ebreak),
        .ctrl_wfi(ctrl_wfi),
        // Pipeline Stall Signal (computed below, passed to riscv_exu)
        .pipeline_stall(pipeline_stall),
        
        // Exception/Interrupt Detection Inputs
        .ctrl_illegal_inst(ctrl_illegal_inst),

        .exception_load_addr_misaligned(exception_load_addr_misaligned),
        .exception_store_addr_misaligned(exception_store_addr_misaligned),
        .ifetch_addr(ifetch_addr),
        
        // System-level inputs (for CSR trap/interrupt/debug handling)
        .ext_irq(ext_irq),
        .clint_tmr_irq(clint_tmr_irq),
        .clint_sft_irq(clint_sft_irq),

        .prv_mode(2'b11),
        .debug_req(debug_req),
	    .csr_instret_inc(csr_instret_inc),
        .reg_we(reg_we),                   // Register write enable from riscv_wb
        
        // ALU Results
        .alu_mem_addr(alu_mem_addr),
        
        // Branch/Jump Control
        .jump_target(jump_target),
        
        // Early Jump Prediction Inputs (from IF Stage)
        .id_restore_mis_target(id_restore_mis_target),
        .if_early_jump_taken(if_early_jump_taken),
        
        // Branch/Jump Misprediction Detection Outputs
        .early_jump_wrong_taken(early_jump_wrong_taken),
        .early_not_jump_need_jump(early_not_jump_need_jump),
        
        .dret_taken(dret_taken),
        .mret_taken(mret_taken),
        
        // Multiplier/Divider Results
        .multdiv_pending(multdiv_pending),
        
        // CSR Results
        .mepc(mepc),
        .dpc(dpc),
        
        // Exception and Interrupt Handling Outputs
        .trap_taken(trap_taken),
        .trap_vector(trap_vector),
        
        // Pipeline Stall Signals
        .wfi_stall(wfi_stall),
        
        // Debug Mode Control Outputs
        .debug_mode(debug_mode),
        .debug_mode_pc(debug_mode_pc),
        
        // Writeback Results
        .reg_rd(reg_rd),
        .reg_wdata(reg_wdata_exu),
        .reg_we_out(reg_we_exu)
    );
    
    //----------------------------------------------------------------------------
    // Memory Stage (MEM)
    //----------------------------------------------------------------------------
    riscv_mem u_mem (
        // Clock and Reset
        .clk(clk),
        .rst_n(rst_n),
        
        // Pipeline Control
        .if_id_valid(if_id_valid),
        
        // Memory Address (from Execution Unit)
        .alu_mem_addr(alu_mem_addr),
        
        // Register File Data (for store operations and AMO)
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        
        // Control Signals (from Decode Stage)
        .ctrl_mem_req(ctrl_mem_req),
        .ctrl_mem_we(ctrl_mem_we),
        .ctrl_mem_size(ctrl_mem_size),
        .ctrl_mem_sign_ext(ctrl_mem_sign_ext),
        
        // External Memory Interface (to AXI4/Data Bus)
        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_be(mem_be),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),
        .mem_rvalid(mem_rvalid),
        
        // Memory Operation Results
        .mem_result(mem_result),
        
        // Pipeline Control Outputs
        .mem_pending(mem_pending),
        
        // Exception Outputs
        .exception_load_addr_misaligned(exception_load_addr_misaligned),
        .exception_store_addr_misaligned(exception_store_addr_misaligned)
    );
    
    //----------------------------------------------------------------------------
    // Pipeline Stall Logic
    //----------------------------------------------------------------------------
    // Pipeline stall: Stall when memory, AMO, or multdiv operation is pending,
    // or on FENCE instruction until memory operations complete, or on WFI
    // Note: This is computed here and passed to riscv_exu as input, and also output to riscv_pipeline
    assign pipeline_stall = mem_pending || multdiv_pending || 
                                (ctrl_fence && mem_pending) || wfi_stall;
    
endmodule


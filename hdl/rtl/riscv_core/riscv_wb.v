//=============================================================================
// RISC-V Writeback Stage Module
//=============================================================================
// This module encapsulates all writeback stage logic for the RISC-V pipeline:
//   - Register file (32x32 registers with 2 read ports + 1 IFU read port)
//   - Register writeback enable logic (combines execution unit enable with memory completion)
//   - Register writeback data selection (combines execution unit and memory results)
//=============================================================================

`include "riscv_defines.v"

module riscv_wb (
    // Clock and Reset
    input               clk,
    input               rst_n,
    
    // Register Read Addresses (from Decode Stage)
    input  [4:0]        rs1_addr,           // Source register 1 address
    input  [4:0]        rs2_addr,           // Source register 2 address
  
    
    // Register Read Data Outputs
    output [31:0]       rs1_data,           // Source register 1 data
    output [31:0]       rs2_data,           // Source register 2 data
    
    // Writeback Control Signals (from Execution Unit)
    input               reg_we_exu,         // Register write enable from execution unit
    input  [4:0]        reg_rd,             // Destination register address
    input  [31:0]       reg_wdata_exu,      // Register write data from execution unit (ALU/Multdiv/CSR/Return Address)
    
    // Memory Operation Control Signals (from Decode Stage)
    input               ctrl_mem_req,       // Memory request
    input               ctrl_mem_we,        // Memory write enable
    input               ctrl_reg_src,       // Register source (0: ALU, 1: Memory)
    
    // Memory Operation Completion Signals
    input               mem_rvalid,         // Memory read data valid
    input               mem_ready,          // Memory write ready
    
    // Memory Result Data
    input  [31:0]       mem_result,         // Memory read result (sign-extended)
    
    output              reg_we
);
    //----------------------------------------------------------------------------
    // Register Writeback Data Selection
    //----------------------------------------------------------------------------
    // Register write data selection priority:
    //   1. CSR operations -> csr_rdata (from riscv_exu via reg_wdata_exu)
    //   2. Multdiv operations -> multdiv_result (from riscv_exu via reg_wdata_exu)
    //   3. Memory loads -> mem_result (sign-extended)
    //   4. Jump save return address -> return_address (from riscv_exu via reg_wdata_exu)
    //   5. ALU operations -> alu_result (from riscv_exu via reg_wdata_exu)
    // Note: reg_wdata_exu from riscv_exu handles CSR, Multdiv, Return Address, and ALU
    //       We override it here to add Memory result
    wire [31:0] reg_wdata = ctrl_reg_src      ? mem_result :
                                          reg_wdata_exu;

    //----------------------------------------------------------------------------
    // Register File Instantiation
    //----------------------------------------------------------------------------
    riscv_regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr(rs1_addr),
        .rs1_data(rs1_data),
        .rs2_addr(rs2_addr),
        .rs2_data(rs2_data),
        .we(reg_we),
        .wr_addr(reg_rd),
        .wr_data(reg_wdata)
    );
    
    //----------------------------------------------------------------------------
    // Register Writeback Enable Logic
    //----------------------------------------------------------------------------
    // Register write enable: Combine execution unit enable with memory operation completion
    //   - Execution unit provides base enable (reg_we_exu)
    //   - Memory operations complete:
    //     * Loads: wait for mem_rvalid
    //     * Stores: wait for mem_ready (no writeback, but included for consistency)
    assign reg_we = reg_we_exu &&
                    (!ctrl_mem_req || 
                     (ctrl_mem_req && !ctrl_mem_we && mem_rvalid) ||
                     (ctrl_mem_req && ctrl_mem_we && mem_ready));
    


endmodule


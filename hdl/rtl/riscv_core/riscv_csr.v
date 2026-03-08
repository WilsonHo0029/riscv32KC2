// RISC-V Control and Status Register File (Zicsr Extension)
// Implements standard CSRs for machine mode

`include "riscv_defines.v"

module riscv_csr (
    input               clk,
    input               rst_n,
    
    // CSR access
    input  [11:0]       csr_addr,
    input  [31:0]       csr_wdata,
    input  [1:0]        csr_op,      // 00: CSRR. 01: CSRRW, 10: CSRRS, 11: CSRRC
    input               csr_we,
    output reg [31:0]   csr_rdata,
    
    // Exception/Trap interface
    input               trap,
    input  [31:0]       trap_pc,
    input  [31:0]       trap_cause,
    input  [31:0]       trap_value,
    output reg [31:0]   mtvec,
    output reg [31:0]   mepc,
    
    // Interrupt interface
    input               ext_irq,
    input               clint_tmr_irq,  // Timer interrupt from CLINT
    input               clint_sft_irq,  // Software interrupt from CLINT
    output              mie,
    output reg          meie,
    output reg          mtie,
    output reg          msie,
    output reg [31:0]   mip,
    
    // MRET interface
    input               mret,
    
    // Debug CSR interface
    input               dbg_mode,       // Current debug mode status
    input               dbg_mode_entry, // Debug mode entry (for saving DPC)
    input  [31:0]       dbg_entry_pc,  // PC to save in DPC when entering debug mode
    input  [2:0]        dbg_cause,     // Debug cause: 0=ebreak, 2=haltreq, 3=step, 4=resethaltreq
    input               dret,          // DRET instruction
    input  [1:0]        prv_mode,      // Current privilege mode (0=U, 1=S, 3=M)
    input		csr_instret_inc,
    output reg [31:0]   dpc,           // Debug PC (for DRET return)
    output [31:0]       dcsr_out       // DCSR output for ebreak checking
);

    // CSR registers
    reg  [31:0] mstatus;
    wire [31:0] misa = 32'h40001105;  // RV32IMAC;
    reg  [31:0] mscratch;
    reg  [31:0] mcause;
    reg  [31:0] mtval;
    reg  [31:0] mcycle;
    reg  [31:0] mcycleh;
    reg  [31:0] minstret;
    reg  [31:0] minstreth;
    wire [31:0] mvenderid = 32'd0;
    wire [31:0] marchid = 32'd0;
    wire [31:0] mimpid = 32'd0; 
    reg  [31:0] mhartid;
    
    // Debug CSR registers
    // DCSR fields:
    // [15:12] ebreakm/s/u: ebreak behavior in M/S/U mode (set to 0 for now)
    // [11]    stepie: step interrupt enable (0)
    // [10]    stopcount: stop counter increments (0 = counter continues)
    // [9]     stoptime: stop timer increments (0 = timer continues)
    // [8:6]   cause: debug cause (0=ebreak, 2=haltreq, 3=step, 4=resethaltreq)
    // [5]     0
    // [4]     mprven
    // [3]     nmip
    // [2]     step
    reg [4:0]  r_ebreak;
    reg        r_stepie;
    reg        r_stopcount;
    reg [2:0]  r_cause;
    reg        r_mprven;
    reg        r_nmip;
    reg        r_step;
    // dpc is declared as output reg in port list
    reg [31:0] dscratch0;
    reg [31:0] dscratch1;
    
    // MSTATUS fields
    assign mie = mstatus[3];

    reg [31:0] csr_wdata_i;
    
    // CSR read
    always @(*) begin
        case (csr_addr)
            `CSR_MSTATUS:  csr_rdata = mstatus;
            `CSR_MISA:     csr_rdata = misa;
            `CSR_MIE:      csr_rdata = {20'h0, meie, 3'h0, mtie, 3'h0, msie, 3'h0};
            `CSR_MTVEC:    csr_rdata = mtvec;
            `CSR_MSCRATCH: csr_rdata = mscratch;
            `CSR_MEPC:     csr_rdata = mepc;
            `CSR_MCAUSE:   csr_rdata = mcause;
            `CSR_MTVAL:    csr_rdata = mtval;
            `CSR_MIP: begin
                // MIP register format (per RISC-V spec):
                // Bits 31-12: Reserved (0)
                // Bit 11: MEIP (Machine External Interrupt Pending) - writable
                // Bits 10-8: Reserved (0)
                // Bit 7: MTIP (Machine Timer Interrupt Pending) - read-only from CLINT
                // Bits 6-4: Reserved (0)
                // Bit 3: MSIP (Machine Software Interrupt Pending) - read-only from CLINT
                // Bits 2-0: Reserved (0)
                csr_rdata = {20'h0,
                             mip[`MIP_MEI_BIT],  // Bit 11 (writable)
                             3'h0,
                             mip[`MIP_MTI_BIT],  // Bit 7 (read-only from CLINT)
                             3'h0,
                             mip[`MIP_MSI_BIT],  // Bit 3 (read-only from CLINT)
                             3'h0};
            end
            `CSR_MCYCLE:     csr_rdata = mcycle;
            `CSR_MCYCLEH:    csr_rdata = mcycleh;
            `CSR_MINSTRET:   csr_rdata = minstret;
	    `CSR_MINSTRETH:  csr_rdata = minstreth;
	    `CSR_MVENDERID:  csr_rdata = mvenderid;
	    `CSR_MARCHID:    csr_rdata = marchid;
	    `CSR_MIMPID:     csr_rdata = mimpid;
            `CSR_MHARTID:    csr_rdata = mhartid;
            `CSR_DCSR:       csr_rdata = dbg_mode ? dcsr_out : 32'h0;
            `CSR_DPC:        csr_rdata = dbg_mode ? dpc : 32'h0;
            `CSR_DSCRATCH0:  csr_rdata = dbg_mode ? dscratch0 : 32'h0;
            `CSR_DSCRATCH1:  csr_rdata = dbg_mode ? dscratch1 : 32'h0;
            default:         csr_rdata = 32'h0;
        endcase
    end
    always @(*) begin
        case (csr_op)
            2'b01:  // CSRRW
                csr_wdata_i = csr_wdata;
            2'b10:  // CSRRS
                csr_wdata_i = csr_rdata | csr_wdata;
            2'b11:  // CSRRC
                csr_wdata_i = csr_rdata & ~csr_wdata;
            default:
                csr_wdata_i = 'd0;
        endcase
    end
    // CSR write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus  <= 32'h0;
            meie     <= 1'b0;
            mtie     <= 1'b0;
            msie     <= 1'b0;
            mtvec    <= `CSR_MTVEC_HANDLER;
            mscratch <= 32'h0;
            mepc     <= 32'h0;
            mcause   <= 32'h0;
            mtval    <= 32'h0;
            mcycle   <= 32'h0;
            mcycleh  <= 32'h0;
            minstret <= 32'h0;
	    minstreth <= 32'h0;
            mhartid  <= 32'h0;
            mip      <= 32'h0;
        end else begin
            // Update counters
            mcycle  <= mcycle + 32'h1;
            mcycleh <= (mcycle == 32'hFFFF_FFFF) ? mcycleh + 32'd1 : mcycleh;
            minstret <= (csr_instret_inc) ? minstret + 32'd1 : minstret;
	        minstreth <= (minstret == 32'hFFFF_FFFF && csr_instret_inc) ? minstreth + 32'd1: minstreth;
            // Update MIP bits from CLINT (read-only bits per RISC-V spec)
            // Bit 3: MSIP (Machine Software Interrupt Pending) - read-only, reflects CLINT MSIP
            // Bit 7: MTIP (Machine Timer Interrupt Pending) - read-only, reflects CLINT timer interrupt
            mip[`MIP_MSI_BIT] <= clint_sft_irq;  // Bit 3
            mip[`MIP_MTI_BIT] <= clint_tmr_irq;  // Bit 7
            mip[`MIP_MEI_BIT] <= ext_irq;  	 // Bit 11
            // Handle traps
            if (trap) begin
                mstatus[7] <= mstatus[3];  // MPIE = MIE
                mstatus[3] <= 1'b0;        // MIE = 0
                mepc       <= trap_pc;
                mcause     <= trap_cause;
                mtval      <= trap_value;
            end
            
            // Handle MRET (restore MIE from MPIE)
            if (mret) begin
                mstatus[3] <= mstatus[7];  // MIE = MPIE
                mstatus[7] <= 1'b1;         // MPIE = 1 (set to allow nested interrupts)
            end
            
            // CSR write operations
            if (csr_we) begin
                case (csr_addr)
                    `CSR_MSTATUS: begin
                        mstatus <= csr_wdata_i;
                    end
                    `CSR_MIE: begin
                        meie <= csr_wdata_i[11];
                        mtie <= csr_wdata_i[7];
                        msie <= csr_wdata_i[3];
                    end
                    `CSR_MTVEC: begin
                        mtvec <= {csr_wdata_i[31:1], 1'b0};
                    end
                    `CSR_MSCRATCH: begin
                        mscratch <= csr_wdata_i;
                    end
                    `CSR_MEPC: begin
                        mepc <= {csr_wdata_i[31:1], 1'b0};
                    end
                    `CSR_MCAUSE: begin
                        mcause <= csr_wdata_i;
                    end
                    `CSR_MTVAL: begin
                        mtval <= csr_wdata_i;
                    end
                    `CSR_MIP: begin
                        // Only bit 11 (MEIP) is writable, bits 3 and 7 are read-only from CLINT
                        // Bits 3 and 7 are ignored on write (they come from CLINT)
                        mip[`MIP_MEI_BIT] <= csr_wdata_i[`MIP_MEI_BIT];  // Bit 11 (writable)
                        // Bits 3 and 7 are updated from CLINT, not from CSR write
                    end
                    `CSR_MCYCLE: begin
                        mcycle <= csr_wdata_i;
                    end
                    `CSR_MCYCLEH: begin
                        mcycleh <= csr_wdata_i;
                    end
                    `CSR_MINSTRET: begin
                        minstret <= csr_wdata_i;
                    end
                    `CSR_MINSTRETH: begin
                        minstreth <= csr_wdata_i;
                    end
                endcase
            end
        end
    end
    
    // Debug CSR register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all debug CSRs
            r_stepie <= 'd0;
            r_stopcount <= 'd0;
            r_cause <= 'd0;
            r_mprven <= 'd0;
            r_nmip <= 'd0;
            r_step <= 'd0;
            r_ebreak <= 'd0;
            dpc <= 32'h0;
            dscratch0 <= 32'h0;
            dscratch1 <= 32'h0;
        end else begin
            // Save DPC and update DCSR when entering debug mode
            // DPC should contain the PC of the instruction that was executing when debug_req was asserted
            dpc <= (dbg_mode_entry) ? {dbg_entry_pc[31:1], 1'b0} :  // Save PC, clear LSB (word-aligned)
                   (csr_we && csr_addr == `CSR_DPC && dbg_mode) ? {csr_wdata_i[31:1], 1'b0} :
                   dpc;
            
            // Update DCSR fields:
            // [31:28] xdebugver: Debug version (0x4 for 0.13)
            // [27:16] reserved
            // [15:12] ebreakm/s/u: ebreak behavior in M/S/U mode (set to 0 for now)
            // [11]    stepie: step interrupt enable (0)
            // [10]    stopcount: stop counter increments (0 = counter continues)
            // [9]     stoptime: stop timer increments (0 = timer continues)
            // [8:6]   cause: debug cause (0=ebreak, 2=haltreq, 3=step, 4=resethaltreq)
            // [5]     0
            // [4]     mprven
            // [3]     nmip
            // [2]     step
            // [1:0]   prv: previous privilege mode
            r_cause    <= (dbg_mode_entry) ? dbg_cause[2:0] : r_cause;  // cause (3 bits)
            r_ebreak   <= (csr_we && csr_addr == `CSR_DCSR && dbg_mode) ? csr_wdata_i[15:12] : r_ebreak;
            r_stepie   <= (csr_we && csr_addr == `CSR_DCSR && dbg_mode) ? csr_wdata_i[11] : r_stepie;
            r_stopcount <= (csr_we && csr_addr == `CSR_DCSR && dbg_mode) ? csr_wdata_i[10] : r_stopcount;
            r_mprven   <= (csr_we && csr_addr == `CSR_DCSR && dbg_mode) ? csr_wdata_i[4] : r_mprven;
            r_step     <= (csr_we && csr_addr == `CSR_DCSR && dbg_mode) ? csr_wdata_i[2] : r_step;
            dscratch0  <= (csr_we && csr_addr == `CSR_DSCRATCH0 && dbg_mode) ? csr_wdata_i : dscratch0;
            dscratch1  <= (csr_we && csr_addr == `CSR_DSCRATCH1 && dbg_mode) ? csr_wdata_i : dscratch1;
        end
    end
    
    // DCSR output for ebreak checking
    // DCSR fields:
    // [31:28] xdebugver: Debug version (0x4 for 0.13)
    // [27:16] reserved
    // [15:12] ebreakm/s/u: ebreak behavior in M/S/U mode (set to 0 for now)
    // [11]    stepie: step interrupt enable (0)
    // [10]    stopcount: stop counter increments (0 = counter continues)
    // [9]     stoptime: stop timer increments (0 = timer continues)
    // [8:6]   cause: debug cause (0=ebreak, 2=haltreq, 3=step, 4=resethaltreq)
    // [5]     0
    // [4]     mprven
    // [3]     nmip
    // [2]     step
    // [1:0]   prv: previous privilege mode

    assign dcsr_out[31:28] = 4'd4;
    assign dcsr_out[27:16] = 'd0;
    assign dcsr_out[15:12] = r_ebreak;
    assign dcsr_out[11]    = r_stepie;
    assign dcsr_out[10]    = 1'b1;
    assign dcsr_out[9]     = 1'b1;
    assign dcsr_out[8:6]   = r_cause;
    assign dcsr_out[5]     = 1'b0;
    assign dcsr_out[4]     = r_mprven;
    assign dcsr_out[3]     = r_nmip;
    assign dcsr_out[2]     = r_step;
    assign dcsr_out[1:0]   = 2'b11;
endmodule


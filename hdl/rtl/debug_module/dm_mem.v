// Debug Memory Module - APB Interface
// Implements debug memory regions accessible via APB bus
// Based on dm_mem.v reference, converted from ICB to APB interface

module dm_mem #(
    parameter HART_NUM = 1,
    parameter HART_ID_W = 1
) (
    input               clk,
    input               rst_n,
    
    // APB Slave Interface
    input               m_apb_psel,
    input               m_apb_penable,
    input  [31:0]       m_apb_paddr,
    input               m_apb_pwrite,
    input  [31:0]       m_apb_pwdata,
    output reg [31:0]   m_apb_prdata,
    output reg          m_apb_pready,
    output reg          m_apb_pslverr,
    
    // FSM interface
    input               fsm_cmd_valid,
    input  [7:0]        fsm_cmd_type,
    input  [23:0]        fsm_cmd_control,
    output              fsm_cmd_busy,
    output              fsm_cmd_error_wr,
    output [2:0]        fsm_cmd_error,
    
    // Data and program buffer inputs
    input  [31:0]       data0_i,
    output              data0_wr,
    input  [31:0]       data1_i,
    output              data1_wr,    
    input  [31:0]       progbuf0,
    input  [31:0]       progbuf1,
    input  [31:0]       progbuf2,
    input  [31:0]       progbuf3,
    input  [31:0]       progbuf4,
    input  [31:0]       progbuf5,
    input  [31:0]       progbuf6,
    input  [31:0]       progbuf7,
        
    // Hart control (multi-hart interface - arrays)
    input [HART_ID_W-1:0] hartsel_index,  // Which hart is selected
    input [HART_NUM-1:0]  resume_req,     // Resume request per hart
    input                  clear_resume_ack,
    output [HART_NUM-1:0] halted,         // Halted status per hart
    output [HART_NUM-1:0] resuming        // Resuming status per hart
);

    //----------------------------------------------------------------------------
    // Constants
    //----------------------------------------------------------------------------
    localparam ABS_ROM_NUM = 8;
    localparam HaltAddress = 12'h800;
    localparam ResumeAddress = 12'h804;
    localparam ExceptionAddress = 12'h808;
    localparam HaltedAddr    = 12'h100;
    localparam GoingAddr     = 12'h104;
    localparam ResumingAddr  = 12'h108;
    localparam ExceptionAddr = 12'h10C;
    localparam WhereToAddr   = 12'h300;
    localparam DataBaseAddr  = 12'h380;
    localparam AbstractCmdBaseAddr = 12'h310;
    localparam ProgBufBaseAddr = AbstractCmdBaseAddr + 4*ABS_ROM_NUM;
    localparam FLAG_BASE     = 12'h400;
    localparam FLAG_END      = 12'h7FF;
    
    localparam CMD_ACCREG = 8'd0;
    localparam CMD_QACC = 8'd1;
    localparam CMD_ACCMEM = 8'd2;
    localparam CSR_DSRATCH0 = 12'h7B2;
    localparam CSR_DSRATCH1 = 12'h7B3;
    localparam MaxAar = 3;
    
    // RISC-V Instruction Constants
    localparam [31:0] RISCV_NOP = 32'h00000013;      // ADDI x0, x0, 0
    localparam [31:0] RISCV_EBREAK = 32'h00100073;   // EBREAK
    
    //----------------------------------------------------------------------------
    // RISC-V Instruction Encoding Functions
    //----------------------------------------------------------------------------
    
    // JAL instruction: jal rd, offset
    // rd: destination register (5 bits)
    // offset: signed offset (21 bits, word-aligned)
    function [31:0] riscv_jal;
        input [4:0] rd;
        input [20:0] offset;
        begin
            riscv_jal = {offset[20], offset[10:1], offset[11], offset[19:12], rd, 7'b1101111};
        end
    endfunction
    
    // Load instruction: lw rd, offset(rs1)
    // size: 0=byte, 1=halfword, 2=word
    // rd: destination register (5 bits)
    // rs1: source register (5 bits)
    // offset: signed offset (12 bits)
    function [31:0] riscv_load;
        input [2:0] size;
        input [4:0] rd;
        input [4:0] rs1;
        input [11:0] offset;
        begin
            riscv_load = {offset[11:0], rs1, size, rd, 7'b0000011};
        end
    endfunction
    
    // Store instruction: sw rs2, offset(rs1)
    // size: 0=byte, 1=halfword, 2=word
    // rs2: source register (5 bits)
    // rs1: base register (5 bits)
    // offset: signed offset (12 bits)
    function [31:0] riscv_store;
        input [2:0] size;
        input [4:0] rs2;
        input [4:0] rs1;
        input [11:0] offset;
        begin
            riscv_store = {offset[11:5], rs2, rs1, size, offset[4:0], 7'b0100011};
        end
    endfunction
    
    // CSR Write instruction: csrrw rd, csr, rs1
    // rd: destination register (5 bits)
    // csr: CSR address (12 bits)
    // rs1: source register (5 bits)
    function [31:0] riscv_csrw;
        input [11:0] csr;
        input [4:0] rd;
        begin
            riscv_csrw = {csr, rd, 3'b001, 5'b00000, 7'b1110011};
        end
    endfunction
    
    // CSR Read instruction: csrr rd, csr
    // rd: destination register (5 bits)
    // csr: CSR address (12 bits)
    function [31:0] riscv_csrr;
        input [11:0] csr;
        input [4:0] rd;
        begin
            riscv_csrr = {csr, 5'b00000, 3'b010, rd, 7'b1110011};
        end
    endfunction
    
    //----------------------------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------------------------
    reg [HART_NUM-1:0] r_halted;
    reg [HART_NUM-1:0] r_resuming;
    wire [7:0] flag;
    reg [31:0] rd_flag_or;
    reg [31:0] fsm_rd_data;
    
    // Output assignments - per-hart arrays
    genvar h;
    generate
        for (h = 0; h < HART_NUM; h = h + 1) begin : gen_hart_outputs
            assign halted[h] = r_halted[h];
            assign resuming[h] = r_resuming[h];
        end
    endgenerate
    
    // Wires for selected hart's status (for FSM logic)
    wire r_halted_selected = r_halted[hartsel_index];
    wire r_resuming_selected = r_resuming[hartsel_index];
    wire resume_req_selected = resume_req[hartsel_index];
    
    //----------------------------------------------------------------------------
    // APB Interface Conversion
    //----------------------------------------------------------------------------
    wire apb_wr = m_apb_psel && m_apb_penable && m_apb_pwrite;
    wire apb_rd = m_apb_psel && m_apb_penable && !m_apb_pwrite;
    wire [11:0] apb_addr = m_apb_paddr[11:0];  // Lower 12 bits for debug memory address
    
    assign data0_wr = (apb_addr == DataBaseAddr) && apb_wr;
    assign data1_wr = (apb_addr == (DataBaseAddr + 4)) && apb_wr;
    //----------------------------------------------------------------------------
    // Debug ROM Selection
    //----------------------------------------------------------------------------
    wire [31:0] rom_o;
    wire sel_debug_rom = (apb_addr[11:8] == 4'h8);
    wire sel_halted_reg = (apb_addr == HaltedAddr);
    wire sel_resume_reg = (apb_addr == ResumingAddr);
    
    debug_rom_013 u_debug_rom(
        .addr_i(apb_addr[7:2]),
        .rdata_o(rom_o)
    );
    
    //----------------------------------------------------------------------------
    // FSM for Resume/Go
    //----------------------------------------------------------------------------
    localparam S_IDLE = 0;
    localparam S_RESUME = 1;
    localparam S_GO = 2;
    localparam S_CMDEXE = 3;
    reg [1:0] state, nstate;
    wire unsupported_command;
    
    assign fsm_cmd_busy = ~(state == S_IDLE);
    wire resume = (state == S_RESUME);
    wire go = (state == S_GO);
    wire going = (apb_addr == GoingAddr) && apb_wr;
    wire exception = (apb_addr == ExceptionAddr) && apb_wr;
    
    assign fsm_cmd_error_wr = exception || (unsupported_command && fsm_cmd_valid);
    assign fsm_cmd_error = exception ? 3'd3 : (unsupported_command ? 3'd2 : 3'd0);
    
    // Abstract command ROM - declare early so it can be used in fsm_rd_data
    wire [2:0] ctrl_aarsize = fsm_cmd_control[22:20];
    wire ctrl_aarpostincrement = fsm_cmd_control[19];
    wire ctrl_postexec = fsm_cmd_control[18];
    wire ctrl_transfer = fsm_cmd_control[17];
    wire ctrl_write = fsm_cmd_control[16];
    wire [15:0] ctrl_regno = fsm_cmd_control[15:0];
    reg [31:0] abstract_cmd [0:ABS_ROM_NUM-1];
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            state <= S_IDLE;
        else
            state <= nstate;
    end
    
    always @(*) begin
        case (state)
            default: begin
                if (fsm_cmd_valid && r_halted_selected && ~unsupported_command)
                    nstate = S_GO;
                else if (r_halted_selected == resume_req_selected && r_halted_selected && ~r_resuming_selected)
                    nstate = S_RESUME;
                else
                    nstate = S_IDLE;
            end
            S_RESUME: begin
                if (r_resuming_selected)
                    nstate = S_IDLE;
                else
                    nstate = S_RESUME;
            end
            S_GO: begin
                if (going)
                    nstate = S_CMDEXE;
                else
                    nstate = S_GO;
            end
            S_CMDEXE: begin
                if (sel_halted_reg && apb_wr)
                    nstate = S_IDLE;
                else
                    nstate = S_CMDEXE;
            end
        endcase
    end
    
    //----------------------------------------------------------------------------
    // Read Data Selection
    //----------------------------------------------------------------------------
    always @(*) begin
        rd_flag_or = {32{1'b0}};
        if (apb_addr[11:2] == (FLAG_BASE>>2))
            rd_flag_or = flag << (8 * 0);
    end
    
    always @(*) begin
        fsm_rd_data = {32{1'b0}};
        if (apb_rd) begin
            case (apb_addr[11:0])
                WhereToAddr: begin
                    if (resume_req_selected)
                        fsm_rd_data = riscv_jal(5'd0, (ResumeAddress - WhereToAddr));
                    if (fsm_cmd_busy) begin
                        if (fsm_cmd_type == CMD_ACCREG && ~fsm_cmd_control[17] && fsm_cmd_control[18])
                            fsm_rd_data = riscv_jal(5'd0, (ProgBufBaseAddr - WhereToAddr));
                        else
                            fsm_rd_data = riscv_jal(5'd0, (AbstractCmdBaseAddr - WhereToAddr));
                    end
                end
                DataBaseAddr:
                    fsm_rd_data = data0_i;
                DataBaseAddr + 4:
                    fsm_rd_data = data1_i;                    
                AbstractCmdBaseAddr:
                    fsm_rd_data = abstract_cmd[0];
                AbstractCmdBaseAddr + 4:
                    fsm_rd_data = abstract_cmd[1];
                AbstractCmdBaseAddr + 8:
                    fsm_rd_data = abstract_cmd[2];
                AbstractCmdBaseAddr + 12:
                    fsm_rd_data = abstract_cmd[3];
                AbstractCmdBaseAddr + 16:
                    fsm_rd_data = abstract_cmd[4];
                AbstractCmdBaseAddr + 20:
                    fsm_rd_data = abstract_cmd[5];
                AbstractCmdBaseAddr + 24:
                    fsm_rd_data = abstract_cmd[6];
                AbstractCmdBaseAddr + 28:
                    fsm_rd_data = abstract_cmd[7];
                ProgBufBaseAddr:
                    fsm_rd_data = progbuf0;
                ProgBufBaseAddr + 4:
                    fsm_rd_data = progbuf1;
                ProgBufBaseAddr + 8:
                    fsm_rd_data = progbuf2;
                ProgBufBaseAddr + 12:
                    fsm_rd_data = progbuf3;
                ProgBufBaseAddr + 16:
                    fsm_rd_data = progbuf4;
                ProgBufBaseAddr + 20:
                    fsm_rd_data = progbuf5;
                ProgBufBaseAddr + 24:
                    fsm_rd_data = progbuf6;
                ProgBufBaseAddr + 28:
                    fsm_rd_data = progbuf7;                                                                                
                default:
                    fsm_rd_data = {32{1'b0}};
            endcase
        end
    end
    
    //----------------------------------------------------------------------------
    // APB Read Response
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_apb_prdata <= {32{1'b0}};
            m_apb_pready <= 1'b0;
            m_apb_pslverr <= 1'b0;
        end else begin
            if (apb_rd) begin
                m_apb_prdata <= {32{sel_debug_rom}} & rom_o
                              | {32{sel_halted_reg}} & {{31{1'b0}}, r_halted_selected}
                              | rd_flag_or
                              | fsm_rd_data;
                m_apb_pready <= 1'b1;
                m_apb_pslverr <= 1'b0;
            end else if (apb_wr) begin
                m_apb_pready <= 1'b1;
                m_apb_pslverr <= 1'b0;
            end else begin
                m_apb_pready <= 1'b0;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Halted Register (per-hart, but only selected hart is updated)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            r_halted <= {HART_NUM{1'b0}};
        end else begin
            if (sel_halted_reg && apb_wr)
                r_halted[hartsel_index] <= 1'b1;
            else if (sel_resume_reg && apb_wr)
                r_halted[hartsel_index] <= 1'b0;
        end
    end
    
    //----------------------------------------------------------------------------
    // Resuming Register (per-hart, but only selected hart is updated)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            r_resuming <= {HART_NUM{1'b0}};
        end else begin
            if (clear_resume_ack)
                r_resuming[hartsel_index] <= 1'b0;
            else if (sel_resume_reg && apb_wr)
                r_resuming[hartsel_index] <= 1'b1;
        end
    end
    
    //----------------------------------------------------------------------------
    // Flag Register
    //----------------------------------------------------------------------------
    assign flag = {6'd0, resume, go};
    
    //----------------------------------------------------------------------------
    // Abstract Command ROM Generation
    //----------------------------------------------------------------------------
    always @(*) begin : Abstract_Command_ROM
        abstract_cmd[0] = RISCV_NOP;
        abstract_cmd[1] = RISCV_NOP;
        abstract_cmd[2] = RISCV_NOP;
        abstract_cmd[3] = RISCV_NOP;
        abstract_cmd[4] = RISCV_NOP;
        abstract_cmd[5] = RISCV_NOP;
        abstract_cmd[6] = RISCV_NOP;
        abstract_cmd[7] = RISCV_EBREAK;
        
        if (unsupported_command)
            abstract_cmd[0] = RISCV_EBREAK;
        else begin
            if (ctrl_transfer && ctrl_write) begin  // Write
                if (ctrl_regno[12]) begin  // GPRs/Floating point registers
                    if (ctrl_regno[5]) begin  // Floating point registers
                        abstract_cmd[1] = riscv_load(ctrl_aarsize, ctrl_regno[4:0], 5'd0, DataBaseAddr);
                    end else begin
                        abstract_cmd[1] = riscv_load(ctrl_aarsize, ctrl_regno[4:0], 5'd0, DataBaseAddr);
                    end
                end else begin  // CSRW
                    // store s0 in dscratch
                    abstract_cmd[1] = riscv_csrw(CSR_DSRATCH0, 5'd8);
                    // load from data register
                    abstract_cmd[2] = riscv_load(ctrl_aarsize, 5'd8, 5'd0, DataBaseAddr);
                    // and store it in the corresponding CSR
                    abstract_cmd[3] = riscv_csrw(ctrl_regno[11:0], 5'd8);
                    // restore s0 again from dscratch
                    abstract_cmd[4] = riscv_csrr(CSR_DSRATCH0, 5'd8);
                end
            end else if (ctrl_transfer && ~ctrl_write) begin  // Read
                if (ctrl_regno[12]) begin  // GPRs/Floating point registers
                    if (ctrl_regno[5]) begin  // Floating point registers
                        abstract_cmd[1] = riscv_store(ctrl_aarsize, ctrl_regno[4:0], 5'd0, DataBaseAddr);
                    end else begin
                        abstract_cmd[1] = riscv_store(ctrl_aarsize, ctrl_regno[4:0], 5'd0, DataBaseAddr);
                    end
                end else begin  // CSRR
                    // store s0 in dscratch
                    abstract_cmd[1] = riscv_csrw(CSR_DSRATCH0, 5'd8);
                    // read value from CSR into s0
                    abstract_cmd[2] = riscv_csrr(ctrl_regno[11:0], 5'd8);
                    // and store s0 into data section
                    abstract_cmd[3] = riscv_store(ctrl_aarsize, 5'd8, 5'd0, DataBaseAddr);
                    // restore s0 again from dscratch
                    abstract_cmd[4] = riscv_csrr(CSR_DSRATCH0, 5'd8);
                end
            end
            
            if (ctrl_postexec)  // issue a nop, we will automatically run into the program buffer
                abstract_cmd[7] = RISCV_NOP;
        end
    end
    
    assign unsupported_command = (fsm_cmd_type == CMD_ACCREG && (ctrl_regno[15:13] != 3'b000 || 
                                    ((ctrl_regno[15:12] == 4'b0001) && (|ctrl_regno[11:6])) ||
                                    ctrl_aarsize >= MaxAar)) ||
                                 (fsm_cmd_type != CMD_ACCREG);

endmodule


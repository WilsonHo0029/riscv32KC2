//=============================================================================
// RISC-V Instruction Decoder Module
//=============================================================================
// This module integrates all decode-stage functionality:
//   - Compressed instruction decoding (inlined from riscv_compressed)
//   - Instruction type decoding (inlined from riscv_instr_type_decoder)
//   - Immediate selection
//   - Control signal generation (inlined from riscv_control)
//
// All sub-module logic is inlined for a single cohesive decoder module.
//=============================================================================

`include "riscv_defines.v"

module riscv_decoder (
    // Inputs
    input  [31:0]       instruction,        // Instruction from IF/ID stage
    input  [31:0]       pc,                 // Program Counter for return address calculation
    
    // Instruction fields (decoded from instruction)
    output reg [4:0]    rd,                 // Destination register
    output reg [4:0]    rs1,                // Source register 1
    output reg [4:0]    rs2,                // Source register 2    
    // Immediate values
    output reg [31:0]   selected_imm,       // Selected immediate based on instruction type (for ALU operations)
    
    output              dec_jal,
    output              dec_bxx,
    output              dec_rv32,
    
    // ALU Control Signals
    output reg [3:0]    alu_op,             // ALU operation
    output reg          alu_src_a,          // ALU source A select (0: rs1_data, 1: PC)
    output reg          alu_src_b,          // ALU source B select (0: rs2_data, 1: immediate)
    
    // Register Control Signals
    output reg          reg_we,             // Register write enable
    output reg          reg_src,            // Register source (0: ALU, 1: Memory)
    
    // Memory Control Signals
    output reg          mem_req,            // Memory request
    output reg          mem_we,             // Memory write enable
    output reg [2:0]    mem_size,           // Memory size (000: byte, 001: half, 010: word)
    output reg          mem_sign_ext,       // Memory sign extend
    
    // Branch/Jump Control Signals
    output reg          branch,             // Branch instruction
    output reg [2:0]    branch_type,        // Branch type
    output reg          jump,               // Jump instruction (JAL/JALR)
    output reg          jump_save_ra,       // Jump save return address
    
    // CSR Control Signals
    output     [11:0]   csr_addr,           // CSR Address
    output              csr_imm,
    output reg          csr_we,             // CSR write enable
    output reg [1:0]    csr_op,             // CSR operation type
    
    // Multiplier/Divider Control Signals
    output reg          multdiv_req,        // Multiplier/Divider request
    output reg [2:0]    multdiv_op,         // Multiplier/Divider operation
    
    // Fence Instructions
    output reg          fence,              // Fence instruction
    output reg          fence_i,            // Fence.I instruction
    
    // Exception/Interrupt Control Signals
    output reg          ecall,              // Environment call
    output reg          ebreak,             // Environment break
    output reg          mret,               // Machine mode return
    output reg          dret,               // Debug mode return
    output reg          wfi,                // Wait for interrupt
    
    // Exception Flags
    output              illegal_inst        // Illegal instruction detected
);

    // Local parameters
    localparam [1:0] COMPRESSED_MASK = 2'b11;
    
    // Internal signals
    reg         compressed_valid;
    wire [11:0] funct12;               // Extracted from imm_i[11:0] for CSR instructions
    reg [6:0]   funct7;             // Function code 7 bits
    reg [2:0]   funct3;             // Function code 3 bits
    reg [6:0]   opcode;             // Instruction opcode
    // Internal immediate values (used internally for selection)
    reg [31:0]  imm_s;  // S-type immediate
    reg [31:0]  imm_u;  // U-type immediate
    reg [31:0]  imm_j;  // J-type immediate
    reg [31:0]  imm_b;  // B-type immediate
    reg [31:0]  imm_i;  // I-type immediate
    // Illegal instruction detection signals
    wire        illegal_inst_rv32;
    
    // Detect if instruction is compressed (low 2 bits != 11)
    wire is_compressed_inst = (instruction[1:0] != COMPRESSED_MASK);
    assign dec_rv32 = ~is_compressed_inst;

    assign dec_jal  = (opcode == `OP_JAL);
    assign dec_bxx  = (opcode == `OP_BRANCH); 
    //----------------------------------------------------------------------------
    // Compressed Instruction Field Extraction (16-bit to opcode, rd, rs1, rs2, imm, etc.)
    //----------------------------------------------------------------------------
    always @(*) begin
        // Default values
        opcode = 7'h0;
        rd = 5'h0;
        funct3 = 3'h0;
        rs1 = 5'h0;
        rs2 = 5'h0;
        funct7 = 7'h0;
        imm_i = 32'h0;
        imm_s = 32'h0;
        imm_b = 32'h0;
        imm_u = 32'h0;
        imm_j = 32'h0;
        compressed_valid = 1'b1;
        
        if (is_compressed_inst) begin
            // Direct field extraction from 16-bit compressed instruction
            case (instruction[1:0])
                2'b00: begin  // Quadrant 0
                    case (instruction[15:13])
                        3'b000: begin  // C.ADDI4SPN
                            if (instruction[12:5] == 8'b0) begin
                                compressed_valid = 1'b0;
                            end else begin
                                opcode = `OP_OP_IMM;
                                rd = {2'b01, instruction[4:2]};  // x8-x15
                                rs1 = 5'b00010;  // sp (x2)
                                funct3 = `F3_ADD;
                                // Extract immediate: {c[10:7], c[12:11], c[5], c[6], 00}
                                imm_i = {{22{1'b0}}, instruction[10:7], instruction[12:11], instruction[5], instruction[6], 2'b00};
                            end
                        end
                        3'b010: begin  // C.LW
                            opcode = `OP_LOAD;
                            rd = {2'b01, instruction[4:2]};  // x8-x15
                            rs1 = {2'b01, instruction[9:7]};  // x8-x15
                            funct3 = `F3_LW;
                            // Extract immediate: {c[5], c[12:10], c[6], 00}
                            imm_i = {{25{1'b0}}, instruction[5], instruction[12:10], instruction[6], 2'b00};
                        end
                        3'b110: begin  // C.SW
                            opcode = `OP_STORE;
                            rs1 = {2'b01, instruction[9:7]};  // x8-x15
                            rs2 = {2'b01, instruction[4:2]};  // x8-x15
                            funct3 = `F3_SW;
                            // Extract immediate: {c[5], c[12], c[11:10], c[6], 00}
                            imm_s = {{25{1'b0}}, instruction[5], instruction[12], instruction[11:10], instruction[6], 2'b00};
                        end
                        default: begin
                            compressed_valid = 1'b0;
                        end
                    endcase
                end
                2'b01: begin  // Quadrant 1
                    case (instruction[15:13])
                        3'b000: begin  // C.NOP / C.ADDI
                            if (instruction[11:7] == 5'b0) begin
                                // C.NOP - no operation
                                opcode = `OP_OP_IMM;
                            end else begin
                                opcode = `OP_OP_IMM;
                                rd = instruction[11:7];
                                rs1 = instruction[11:7];
                                funct3 = `F3_ADD;
                                // Extract immediate: sign-extend {c[12], c[6:2]}
                                imm_i = {{26{instruction[12]}}, instruction[12], instruction[6:2]};
                            end
                        end
                        3'b001: begin  // C.JAL
                            opcode = `OP_JAL;
                            rd = 5'b00001;  // x1
                            // Extract immediate: {{20{instr[12]}}, instr[12], instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0}
                            imm_j = {{20{instruction[12]}}, instruction[12], instruction[8], instruction[10:9], 
                                     instruction[6], instruction[7], instruction[2], instruction[11], 
                                     instruction[5:3], 1'b0};
                        end
                        3'b010: begin  // C.LI
                            opcode = `OP_OP_IMM;
                            rd = instruction[11:7];
                            rs1 = 5'b00000;  // x0
                            funct3 = `F3_ADD;
                            imm_i = {{26{instruction[12]}}, instruction[12], instruction[6:2]};
                        end
                        3'b011: begin  // C.LUI / C.ADDI16SP
                            if (instruction[11:7] == 5'b00010) begin  // C.ADDI16SP
                                if (instruction[12] == 1'b0 && instruction[6:2] == 5'b0) begin
                                    compressed_valid = 1'b0;
                                end else begin
                                    opcode = `OP_OP_IMM;
                                    rd = 5'b00010;  // sp
                                    rs1 = 5'b00010;  // sp
                                    funct3 = `F3_ADD;
                                    imm_i = {{22{instruction[12]}}, instruction[12], instruction[4:3], 
                                             instruction[5], instruction[2], instruction[6], 4'b0000};
                                end
                            end else begin  // C.LUI
                                if (instruction[11:7] == 5'b0 || (instruction[12] == 1'b0 && instruction[6:2] == 5'b0)) begin
                                    compressed_valid = 1'b0;
                                end else begin
                                    opcode = `OP_LUI;
                                    rd = instruction[11:7];
                                    imm_u = {{14{instruction[12]}}, instruction[12], instruction[6:2], 12'h0};
                                end
                            end
                        end
                        3'b100: begin  // C.MISC-ALU
                            case (instruction[11:10])
                                2'b00: begin  // C.SRLI
                                    if (instruction[12] == 1'b1) begin
                                        compressed_valid = 1'b0;
                                    end else begin
                                        opcode = `OP_OP_IMM;
                                        rd = {2'b01, instruction[9:7]};
                                        rs1 = {2'b01, instruction[9:7]};
                                        funct3 = `F3_SRL;
                                        imm_i = {27'h0, instruction[6:2]};
                                    end
                                end
                                2'b01: begin  // C.SRAI
                                    if (instruction[12] == 1'b1) begin
                                        compressed_valid = 1'b0;
                                    end else begin
                                        opcode = `OP_OP_IMM;
                                        rd = {2'b01, instruction[9:7]};
                                        rs1 = {2'b01, instruction[9:7]};
                                        funct3 = `F3_SRL;
                                        funct7 = 7'b0100000;
                                        imm_i = {27'h0, instruction[6:2]};
                                    end
                                end
                                2'b10: begin  // C.ANDI
                                    opcode = `OP_OP_IMM;
                                    rd = {2'b01, instruction[9:7]};
                                    rs1 = {2'b01, instruction[9:7]};
                                    funct3 = `F3_AND;
                                    imm_i = {{26{instruction[12]}}, instruction[12], instruction[6:2]};
                                end
                                2'b11: begin
                                    if (instruction[12] == 1'b1) begin
                                        compressed_valid = 1'b0;
                                    end else begin
                                        opcode = `OP_OP;
                                        rd = {2'b01, instruction[9:7]};
                                        rs1 = {2'b01, instruction[9:7]};
                                        rs2 = {2'b01, instruction[4:2]};
                                        case (instruction[6:5])
                                            2'b00: begin  // C.SUB
                                                funct3 = `F3_ADD;
                                                funct7 = 7'b0100000;
                                            end
                                            2'b01: begin  // C.XOR
                                                funct3 = `F3_XOR;
                                                funct7 = 7'b0000000;
                                            end
                                            2'b10: begin  // C.OR
                                                funct3 = `F3_OR;
                                                funct7 = 7'b0000000;
                                            end
                                            2'b11: begin  // C.AND
                                                funct3 = `F3_AND;
                                                funct7 = 7'b0000000;
                                            end
                                        endcase
                                    end
                                end
                            endcase
                        end
                        3'b101: begin  // C.J
                            opcode = `OP_JAL;
                            rd = 5'b00000;  // x0 (no save)
                            // Extract immediate: {{20{instr[12]}}, instr[12], instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0}
                            imm_j = {{20{instruction[12]}}, instruction[12], instruction[8], instruction[10:9], 
                                     instruction[6], instruction[7], instruction[2], instruction[11], 
                                     instruction[5:3], 1'b0};
                        end
                        3'b110: begin  // C.BEQZ
                            opcode = `OP_BRANCH;
                            rs1 = {2'b01, instruction[9:7]};
                            rs2 = 5'b00000;  // x0
                            funct3 = `F3_BEQ;
                            // Extract immediate: {{23{instr[12]}}, instr[12], instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0}
                            imm_b = {{23{instruction[12]}}, instruction[12], instruction[6:5], instruction[2], 
                                     instruction[11:10], instruction[4:3], 1'b0};
                        end
                        3'b111: begin  // C.BNEZ
                            opcode = `OP_BRANCH;
                            rs1 = {2'b01, instruction[9:7]};
                            rs2 = 5'b00000;  // x0
                            funct3 = `F3_BNE;
                            // Extract immediate: {{23{instr[12]}}, instr[12], instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0}
                            imm_b = {{23{instruction[12]}}, instruction[12], instruction[6:5], instruction[2], 
                                     instruction[11:10], instruction[4:3], 1'b0};
                        end
                    endcase
                end
                2'b10: begin  // Quadrant 2
                    case (instruction[15:13])
                        3'b000: begin  // C.SLLI
                            if (instruction[12] == 1'b1) begin
                                compressed_valid = 1'b0;
                            end else begin
                                opcode = `OP_OP_IMM;
                                rd = instruction[11:7];
                                rs1 = instruction[11:7];
                                funct3 = `F3_SLL;
                                imm_i = {27'h0, instruction[6:2]};
                            end
                        end
                        3'b010: begin  // C.LWSP
                            opcode = `OP_LOAD;
                            rd = instruction[11:7];
                            rs1 = 5'b00010;  // sp
                            funct3 = `F3_LW;
                            imm_i = {{24{1'b0}}, instruction[3:2], instruction[12], instruction[6:4], 2'b00};
                        end
                        3'b100: begin
                            if (instruction[12] == 1'b0 && instruction[6:2] == 5'b0) begin  // C.JR
                                opcode = `OP_JALR;
                                rd = 5'b00000;  // x0
                                rs1 = instruction[11:7];
                                funct3 = 3'b000;
                                imm_i = 32'h0;
                            end else if (instruction[12] == 1'b0) begin  // C.MV
                                opcode = `OP_OP;
                                rd = instruction[11:7];
                                rs1 = 5'b00000;  // x0
                                rs2 = instruction[6:2];
                                funct3 = `F3_ADD;
                                funct7 = 7'b0000000;
                            end else if (instruction[12] == 1'b1 && instruction[6:2] == 5'b0) begin
                                if (instruction[11:7] == 5'b0) begin // C.EBREAK
                                    opcode = `OP_SYSTEM;
                                    funct3 = `F3_PRIV;
                                    imm_i = 12'h001;
                                end else begin // C.JALR
                                    opcode = `OP_JALR;
                                    rd = 5'b00001;  // x1
                                    rs1 = instruction[11:7];
                                    funct3 = 3'b000;
                                    imm_i = 32'h0;
                                end
                            end else begin // C.ADD
                                opcode = `OP_OP;
                                rd = instruction[11:7];
                                rs1 = instruction[11:7];
                                rs2 = instruction[6:2];
                                funct3 = `F3_ADD;
                                funct7 = 7'b0000000;
                            end
                        end
                        3'b110: begin  // C.SWSP
                            opcode = `OP_STORE;
                            rs1 = 5'b00010;  // sp
                            rs2 = instruction[6:2];
                            funct3 = `F3_SW;
                            imm_s = {{24{1'b0}}, instruction[8:7], instruction[12], instruction[11:9], 2'b00};
                        end
                        default: begin
                            compressed_valid = 1'b0;
                        end
                    endcase
                end
                default: begin
                    compressed_valid = 1'b0;
                end
            endcase
        end else begin
            compressed_valid = 1'b0;
            //----------------------------------------------------------------------------
            // Standard 32-bit Instruction Field Extraction
            //----------------------------------------------------------------------------
            opcode = instruction[6:0];
            rd = instruction[11:7];
            funct3 = instruction[14:12];

            if (opcode == `OP_LUI)
                rs1 = 5'b00000;
            else
                rs1 = instruction[19:15];

            rs2 = instruction[24:20];
            funct7 = instruction[31:25];
            
            // I-type immediate
            imm_i = {{20{instruction[31]}}, instruction[31:20]};
            
            // S-type immediate
            imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            
            // B-type immediate
            imm_b = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            
            // U-type immediate
            imm_u = {instruction[31:12], 12'h0};
            
            // J-type immediate
            imm_j = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        end
    end
    
    // Extract funct12 for CSR instructions (from imm_i[11:0])
    assign funct12 = imm_i[11:0];
    assign csr_addr = imm_i[11:0];
    assign csr_imm = funct3[2];  // funct3[2]=1 for immediate variants
    //----------------------------------------------------------------------------
    // Immediate Selection
    //----------------------------------------------------------------------------
    always @(*) begin
        case (opcode)
            `OP_LUI, `OP_AUIPC: selected_imm = imm_u;
            `OP_JAL: selected_imm = imm_j;
            `OP_JALR, `OP_OP_IMM, `OP_LOAD: selected_imm = imm_i;
            `OP_STORE: selected_imm = imm_s;
            `OP_BRANCH: selected_imm = imm_b;
            default: selected_imm = imm_i;
        endcase
    end
    
    //----------------------------------------------------------------------------
    // Control Signal Generation (Inlined from riscv_control)
    //----------------------------------------------------------------------------
    always @(*) begin
        // Default values
        alu_op = `ALU_ADD;
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        reg_we = 1'b0;
        reg_src = 1'b0;
        mem_req = 1'b0;
        mem_we = 1'b0;
        mem_size = 3'b010;  // Word
        mem_sign_ext = 1'b1;
        branch = 1'b0;
        branch_type = 3'b000;
        jump = 1'b0;
        jump_save_ra = 1'b0;
        csr_we = 1'b0;
        csr_op = 2'b00;
        multdiv_req = 1'b0;
        multdiv_op = 3'b000;
        
        case (opcode)
            `OP_LUI: begin
                alu_op = `ALU_ADD;
                alu_src_a = 1'b0;  // Use rs1(x0)
                alu_src_b = 1'b1;  // Use immediate (U-type)
                reg_we = 1'b1;
            end
            
            `OP_AUIPC: begin
                alu_op = `ALU_ADD;
                alu_src_a = 1'b1;  // Use PC
                alu_src_b = 1'b1;  // Use immediate
                reg_we = 1'b1;
            end
            
            `OP_JAL: begin
                jump = 1'b1;
                jump_save_ra = 1'b1;
                alu_op = `ALU_ADD;
                alu_src_a = 1'b1;  // Use PC for jump target calculation
                alu_src_b = 1'b1;  // Use immediate (imm_j) for jump target calculation
                reg_we = 1'b1;
            end
            
            `OP_JALR: begin
                jump = 1'b1;
                jump_save_ra = 1'b1;
                alu_op = `ALU_ADD;
                alu_src_a = 1'b0;  // Use rs1
                alu_src_b = 1'b1;  // Use immediate
                reg_we = 1'b1;
            end
            
            `OP_BRANCH: begin
                branch = 1'b1;
                branch_type = funct3;
                alu_op = `ALU_SUB;
                alu_src_a = 1'b0;
                alu_src_b = 1'b0;
            end
            
            `OP_LOAD: begin
                mem_req = 1'b1;
                mem_we = 1'b0;
                mem_size = funct3[1:0];
                mem_sign_ext = (funct3[2] == 1'b0);
                alu_op = `ALU_ADD;
                alu_src_a = 1'b0;
                alu_src_b = 1'b1;
                reg_we = 1'b1;
                reg_src = 1'b1;  // Write from memory
            end
            
            `OP_STORE: begin
                mem_req = 1'b1;
                mem_we = 1'b1;
                mem_size = funct3[1:0];
                alu_op = `ALU_ADD;
                alu_src_a = 1'b0;
                alu_src_b = 1'b1;
            end
            
            `OP_OP_IMM: begin
                if (funct3 == `F3_SLL) begin
                    reg_we = 1'b1;
                    alu_src_a = 1'b0;
                    alu_src_b = 1'b1;
                    alu_op = `ALU_SLL;
                end else if (funct3 == `F3_SRL) begin
                    reg_we = 1'b1;
                    alu_src_a = 1'b0;
                    alu_src_b = 1'b1;
                    alu_op = (funct7[5] == 1'b1) ? `ALU_SRA : `ALU_SRL;
                end else begin
                    reg_we = 1'b1;
                    alu_src_a = 1'b0;
                    alu_src_b = 1'b1;
                    case (funct3)
                        `F3_ADD:  alu_op = `ALU_ADD;
                        `F3_SLT:  alu_op = `ALU_SLT;
                        `F3_SLTU: alu_op = `ALU_SLTU;
                        `F3_XOR:  alu_op = `ALU_XOR;
                        `F3_OR:   alu_op = `ALU_OR;
                        `F3_AND:  alu_op = `ALU_AND;
                        default:  alu_op = `ALU_ADD;
                    endcase
                end
            end
            
            `OP_OP: begin
                if (funct7[0] == 1'b1) begin
                    // M extension
                    reg_we = 1'b1;
                    multdiv_req = 1'b1;
                    multdiv_op = funct3;
                end else begin
                    // Standard ALU operations
                    reg_we = 1'b1;
                    alu_src_a = 1'b0;
                    alu_src_b = 1'b0;
                    case (funct3)
                        `F3_ADD:  alu_op = (funct7[5] == 1'b1) ? `ALU_SUB : `ALU_ADD;
                        `F3_SLL:  alu_op = `ALU_SLL;
                        `F3_SLT:  alu_op = `ALU_SLT;
                        `F3_SLTU: alu_op = `ALU_SLTU;
                        `F3_XOR:  alu_op = `ALU_XOR;
                        `F3_SRL:  alu_op = (funct7[5] == 1'b1) ? `ALU_SRA : `ALU_SRL;
                        `F3_OR:   alu_op = `ALU_OR;
                        `F3_AND:  alu_op = `ALU_AND;
                        default:  alu_op = `ALU_ADD;
                    endcase
                end
            end
            
            `OP_SYSTEM: begin
                if (funct3 != `F3_PRIV) begin
                    // CSR instructions
                    csr_we = 1'b1;
                    csr_op = funct3[1:0];
                    reg_we = 1'b1;
                end
            end
            
            default: begin end
        endcase
    end
    
    //----------------------------------------------------------------------------
    // System Control Signal Generation
    //----------------------------------------------------------------------------
    always @(*) begin
        // Default values
        fence = 1'b0;
        fence_i = 1'b0;
        ecall = 1'b0;
        ebreak = 1'b0;
        mret = 1'b0;
        dret = 1'b0;
        wfi = 1'b0;
        
        case (opcode)
            `OP_FENCE: begin
                if (funct3 == `F3_FENCEI) begin
                    fence_i = 1'b1;
                end else if (funct3 == `F3_FENCE) begin
                    fence = 1'b1;
                end
            end
            
            `OP_SYSTEM: begin
                if (funct3 == `F3_PRIV) begin
                    case (funct12)
                        `F12_ECALL:  ecall = 1'b1;
                        `F12_EBREAK: ebreak = 1'b1;
                        `F12_MRET:   mret = 1'b1;
                        `F12_WFI:    wfi = 1'b1;
                        `F12_DRET:   dret = 1'b1;
                        default: begin end
                    endcase
                end
            end
            
            default: begin end
        endcase
    end
    
    //----------------------------------------------------------------------------
    // Illegal Instruction Detection (Inlined from riscv_control)
    //----------------------------------------------------------------------------
    wire illegal_branch   = (opcode == `OP_BRANCH) && 
                             (funct3 == 3'b010 || funct3 == 3'b011);
    
    wire illegal_load     = (opcode == `OP_LOAD) && 
                             (funct3 == 3'b011 || funct3 == 3'b110 || funct3 == 3'b111);
    
    wire illegal_store    = (opcode == `OP_STORE) && 
                             (funct3 == 3'b011 || funct3 == 3'b100 || funct3 == 3'b101 || 
                              funct3 == 3'b110 || funct3 == 3'b111);
    
    wire illegal_fence    = (opcode == `OP_FENCE) && 
                             (funct3 != `F3_FENCE && funct3 != `F3_FENCEI);
    
    wire illegal_op_imm   = (opcode == `OP_OP_IMM) && (
                             (funct3 == `F3_SLL && funct7 != 7'b0000000) ||
                             (funct3 == `F3_SRL && funct7[6:1] != 6'b000000 && funct7[6:1] != 6'b010000) ||
                             (funct3 != `F3_SLL && funct3 != `F3_SRL && 
                              funct3 != `F3_ADD && funct3 != `F3_SLT && funct3 != `F3_SLTU &&
                              funct3 != `F3_XOR && funct3 != `F3_OR && funct3 != `F3_AND));
    
    wire op_is_m_ext      = (opcode == `OP_OP) && funct7[0];
    wire op_is_alu         = (opcode == `OP_OP) && !funct7[0];
    wire valid_alu_funct3 = (funct3 == `F3_ADD || funct3 == `F3_SLL || funct3 == `F3_SLT ||
                              funct3 == `F3_SLTU || funct3 == `F3_XOR || funct3 == `F3_SRL ||
                              funct3 == `F3_OR || funct3 == `F3_AND);
    wire valid_alu_funct7 = (funct7[6:1] == 6'b000000 || funct7[6:1] == 6'b010000);
    
    wire illegal_op       = (opcode == `OP_OP) && (
                             (op_is_m_ext && funct7[6:1] != 6'b000000) ||
                             (op_is_alu && (!valid_alu_funct7 || !valid_alu_funct3)));
    
    wire illegal_system   = (opcode == `OP_SYSTEM) && (
                             (funct3 == `F3_PRIV && 
                              funct12 != `F12_ECALL && funct12 != `F12_EBREAK && 
                              funct12 != `F12_MRET &&
                              funct12 != `F12_WFI && funct12 != `F12_DRET) ||
                             (funct3 != `F3_PRIV && funct3 == 3'b000));
    
    wire illegal_opcode   = !(opcode == `OP_LUI || opcode == `OP_AUIPC || opcode == `OP_JAL ||
                               opcode == `OP_JALR || opcode == `OP_BRANCH || opcode == `OP_LOAD ||
                               opcode == `OP_STORE || opcode == `OP_OP_IMM || opcode == `OP_OP ||
                               opcode == `OP_FENCE || opcode == `OP_SYSTEM);
    
    assign illegal_inst_rv32 = illegal_opcode || illegal_branch || illegal_load || illegal_store ||
                               illegal_op_imm || illegal_op || illegal_fence || illegal_system;
    
    // Illegal instruction detection: RV32 illegal OR compressed instruction invalid
    assign illegal_inst = is_compressed_inst ? !compressed_valid : illegal_inst_rv32;

endmodule

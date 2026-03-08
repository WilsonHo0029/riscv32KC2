// RISC-V Core Definitions
// Architecture: RV32IMC_Zicsr_Zifencei

`ifndef RISCV_DEFINES_V
`define RISCV_DEFINES_V

// Instruction opcodes
`define OP_LUI      7'b0110111
`define OP_AUIPC    7'b0010111
`define OP_JAL      7'b1101111
`define OP_JALR     7'b1100111
`define OP_BRANCH   7'b1100011
`define OP_LOAD     7'b0000011
`define OP_STORE    7'b0100011
`define OP_OP_IMM   7'b0010011
`define OP_OP       7'b0110011
`define OP_FENCE    7'b0001111
`define OP_SYSTEM   7'b1110011
`define OP_COMPRESSED 2'b00  // First 2 bits for compressed

// Compressed instruction formats
`define C0_QUAD0    2'b00
`define C0_QUAD1    2'b01
`define C0_QUAD2    2'b10

// Instruction formats (funct3)
`define F3_ADD      3'b000
`define F3_SLL      3'b001
`define F3_SLT      3'b010
`define F3_SLTU     3'b011
`define F3_XOR      3'b100
`define F3_SRL      3'b101
`define F3_OR       3'b110
`define F3_AND      3'b111

// Branch instructions (funct3)
`define F3_BEQ      3'b000
`define F3_BNE      3'b001
`define F3_BLT      3'b100
`define F3_BGE      3'b101
`define F3_BLTU     3'b110
`define F3_BGEU     3'b111

// Load instructions (funct3)
`define F3_LB       3'b000
`define F3_LH       3'b001
`define F3_LW       3'b010
`define F3_LBU      3'b100
`define F3_LHU      3'b101

// Store instructions (funct3)
`define F3_SB       3'b000
`define F3_SH       3'b001
`define F3_SW       3'b010

// CSR instructions (funct3)
`define F3_CSRRW    3'b001
`define F3_CSRRS    3'b010
`define F3_CSRRC    3'b011
`define F3_CSRRWI   3'b101
`define F3_CSRRSI   3'b110
`define F3_CSRRCI   3'b111

// System instructions
`define F3_PRIV     3'b000
`define F12_ECALL   12'h000
`define F12_EBREAK  12'h001
`define F12_MRET    12'h302
`define F12_URET    12'h002
`define F12_WFI     12'h105
`define F12_DRET    12'h7b2  // Debug Return (same encoding as DSCRATCH0 address)

// Fence instructions
`define F3_FENCE    3'b000
`define F3_FENCEI   3'b001

// ALU operations
`define ALU_ADD     4'b0000
`define ALU_SUB     4'b0001
`define ALU_SLL     4'b0010
`define ALU_SLT     4'b0011
`define ALU_SLTU    4'b0100
`define ALU_XOR     4'b0101
`define ALU_SRL     4'b0110
`define ALU_SRA     4'b0111
`define ALU_OR      4'b1000
`define ALU_AND     4'b1001

// MUL/DIV operations
`define MD_MUL      3'b000
`define MD_MULH     3'b001
`define MD_MULHSU   3'b010
`define MD_MULHU    3'b011
`define MD_DIV      3'b100
`define MD_DIVU     3'b101
`define MD_REM      3'b110
`define MD_REMU     3'b111


// CSR addresses
// Machine Trap Setup
`define CSR_MTVEC_HANDLER 32'h00001008
`define CSR_MSTATUS     12'h300
`define CSR_MISA        12'h301
`define CSR_MIE         12'h304
`define CSR_MTVEC       12'h305
// Machine Trap Handling
`define CSR_MSCRATCH    12'h340
`define CSR_MEPC        12'h341
`define CSR_MCAUSE      12'h342
`define CSR_MTVAL       12'h343
`define CSR_MIP         12'h344
// Machine Counter/Timers
`define CSR_MCYCLE      12'hB00
`define CSR_MCYCLEH     12'hB80
`define CSR_MINSTRET    12'hB02
`define CSR_MINSTRETH   12'hB82
// Machine Information Registers
`define CSR_MVENDERID   12'hF11
`define CSR_MARCHID	12'hF12
`define CSR_MIMPID	12'hF13
`define CSR_MHARTID     12'hF14

// Debug CSR addresses (RISC-V Debug Spec 0.13)
`define CSR_DCSR        12'h7b0  // Debug Control and Status Register
`define CSR_DPC         12'h7b1  // Debug Program Counter
`define CSR_DSCRATCH0   12'h7b2  // Debug Scratch Register 0
`define CSR_DSCRATCH1   12'h7b3  // Debug Scratch Register 1

// Exception causes (mcause values when interrupt=0)
`define EXC_INST_ADDR_MISALIGNED    32'h0
`define EXC_INST_ACCESS_FAULT       32'h1
`define EXC_ILLEGAL_INST            32'h2
`define EXC_BREAKPOINT              32'h3
`define EXC_LOAD_ADDR_MISALIGNED    32'h4
`define EXC_LOAD_ACCESS_FAULT       32'h5
`define EXC_STORE_ADDR_MISALIGNED   32'h6
`define EXC_STORE_ACCESS_FAULT      32'h7
`define EXC_ECALL_U                 32'h8
`define EXC_ECALL_S                 32'h9
`define EXC_ECALL_M                 32'hB
`define EXC_INST_PAGE_FAULT         32'hC
`define EXC_LOAD_PAGE_FAULT         32'hD
`define EXC_STORE_PAGE_FAULT        32'hF

// Interrupt causes (mcause values when interrupt=1, bit 31 set)
`define IRQ_SOFTWARE_M              32'h80000003
`define IRQ_TIMER_M                 32'h80000007
`define IRQ_EXTERNAL_M              32'h8000000B

// Interrupt bit positions in mip/mie registers
`define MIP_MSI_BIT                 3
`define MIP_MTI_BIT                 7
`define MIP_MEI_BIT                 11

// Memory access size constants
`define MEM_SIZE_BYTE               3'b000
`define MEM_SIZE_HALFWORD           3'b001
`define MEM_SIZE_WORD               3'b010

// Pipeline stages
`define STAGE_IF        3'b000
`define STAGE_ID        3'b001
`define STAGE_EX        3'b010
`define STAGE_MEM       3'b011
`define STAGE_WB        3'b100

// Debug module addresses (DMI)
`define DMI_DATA0       7'h04
`define DMI_DATA1       7'h05
`define DMI_DMCONTROL   7'h10
`define DMI_DMSTATUS    7'h11
`define DMI_HARTINFO    7'h12
`define DMI_ABSTRACTCS  7'h16
`define DMI_COMMAND     7'h17
`define DMI_ABSTRACTAUTO 7'h18
`define DMI_PROGBUF0    7'h20
`define DMI_PROGBUF1    7'h21
`define DMI_PROGBUF2    7'h22
`define DMI_PROGBUF3    7'h23
`define DMI_PROGBUF4    7'h24
`define DMI_PROGBUF5    7'h25
`define DMI_PROGBUF6    7'h26
`define DMI_PROGBUF7    7'h27
`define DMI_HALTSUM0    7'h40
//----
`define MULT_PIPELINE
`endif


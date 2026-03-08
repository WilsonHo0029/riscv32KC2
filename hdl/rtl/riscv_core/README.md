# ðŸ§  RISC-V Core Implementation (RV32IMC)

This directory contains the synthesizable RTL implementation of a high-performance RISC-V 32-bit core. The core is designed with a focus on efficiency and modularity, featuring a 2-stage pipeline and support for compressed instructions.

---

## 🚀 Architecture Overview

The core implements the **`RV32IMC_Zicsr_Zifencei`** instruction set architecture:

- **RV32I**: Base 32-bit integer ISA (42 instructions).
- **M Extension**: Hardware multiplier and divider (8 instructions).
- **C Extension**: Compressed instructions for high code density (26 instructions).
- **Zicsr**: Control and Status Register instructions (6 instructions).
- **Zifencei**: Instruction-fetch fence support.

### âš¡ Performance Features
- **2-Stage Pipeline:** Stage 1: IF/ID | Stage 2: EX/MEM/WB.
- **Early Jump Prediction:** Zero-cycle jump detection via mini-decoder to minimize branch penalties.
- **Zero-Latency Stalls:** Combinational stall logic for memory and mult/div operations.
- **Optimized Multiplier:** Radix-4 Booth Multiplier for balanced area and speed.
- **Radix-4 Divider:** Iterative divider processing 2 bits per cycle.

---

## 📂 Module Structure

### Core Components
| Module | Description |
| :--- | :--- |
| **`riscv_core.v`** | Top-level SoC integration wrapper. |
| **`riscv_pipeline.v`** | Integrated 2-stage pipeline controller. |
| **`riscv_if_stage.v`** | Stage 1: Instruction fetch and decode (IF/ID). |
| **`riscv_final_stage.v`** | Stage 2: Unified Execute/Memory/Writeback logic (EX/MEM/WB). |

### Functional Units
| Module | Description |
| :--- | :--- |
| **`riscv_alu.v`** | 32-bit Arithmetic Logic Unit. |
| **`riscv_multdiv.v`** | High-performance M-extension unit. |
| **`riscv_csr.v`** | Machine-mode Control and Status Registers. |
| **`riscv_regfile.v`** | 32-word GPR file with 2-read/1-write ports. |

---

## ðŸ“ Instruction Set Support

### RV32I Base Integer ISA
`LUI`, `AUIPC`, `JAL`, `JALR`, `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, `SW`, `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`, `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`, `FENCE`, `ECALL`, `EBREAK`, `MRET`, `WFI`.

### M Extension (Multiply/Divide)
`MUL`, `MULH`, `MULHSU`, `MULHU`, `DIV`, `DIVU`, `REM`, `REMU`.

### C Extension (Compressed)
Full support for RVC quadrants 0, 1, and 2, including:
`C.LW`, `C.SW`, `C.ADDI`, `C.JAL`, `C.LI`, `C.LUI`, `C.MV`, `C.ADD`, `C.J`, `C.BEQZ`, `C.BNEZ`, `C.SLLI`, `C.LWSP`, `C.SWSP`, `C.JR`, `C.JALR`.

---

## ðŸ› ï¸ Pipeline Details

### Stage 1: IF/ID (Fetch/Decode)
- Handles instruction fetch from AXI4 memory.
- **Mini-Decoder:** Detects jumps/branches early.
- **Next-PC Logic:** Prioritizes traps > MRET/DRET > Jump/Branch > Sequential.

### Stage 2: EX/MEM/WB (Execute/Memory/Writeback)
- **Execute:** ALU operations and branch resolution.
- **Memory:** Issued immediately on decode for lowest latency.
- **Writeback:** Final result selection and GPR update.

---

## ðŸ“‰ Timing & Performance

- **Target Frequency:** 50 MHz (FPGA).
- **Critical Path:** ~20ns (Logic levels: 23).
- **Optimization:** Routing delay contributes ~80% of total latency; further layout constraints recommended for high-speed targets.

---

## 📜 Related Documents
- [**Main Project README**](../../README.md)
- [**System Integration**](../riscv32KC2_system/README.md)
- [**Debug Interface**](../debug_module/README.md)
- [**Memory Map**](../Memory_Map.txt)



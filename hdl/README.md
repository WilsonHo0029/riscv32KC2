# RISC-V 32KC2 Hardware (HDL)

This directory contains the complete hardware description for the **RISC-V 32KC2** SoC, including the CPU core, bus infrastructure, peripherals, and verification environment.

## 📂 Folder Structure

- **[rtl/](./rtl/)**: Synthesizable Verilog RTL source code.
  - **[riscv_core/](./rtl/riscv_core/)**: 2-stage RISC-V pipeline implementation (Stage 1: IF/ID | Stage 2: EX/MEM/WB).
  - **[debug_module/](./rtl/debug_module/)**: RISC-V Debug Specification 0.13 compliance.
  - **[bus/](./rtl/bus/)**: AXI4 crossbar and protocol bridges.
  - **[peripheral/](./rtl/peripheral/)**: UART, GPIO, and Mixed-Signal interfaces.
  - **[ram/](./rtl/ram/)**: Memory models and controller wrappers.
  - **[riscv32KC2_system/](./rtl/riscv32KC2_system/)**: Top-level SoC integration.
- **[testbench/](./testbench/)**: Simulation and verification infrastructure.
- **[fpga/](./fpga/)**: FPGA-specific project files, constraints, and IP cores (Vivado).

## 🚀 Getting Started

### ðŸ› ï¸ Hardware Requirements
- **Simulator:** Verilator (recommended), ModelSim, or Vivado XSIM.
- **Synthesis:** Xilinx Vivado (2020.1 or later) for FPGA implementation.

### 🧪 Simulation
Navigate to the `testbench/` directory for detailed instructions on how to run simulations using the provided argument files (`riscv32KC2.args`).

```bash
cd testbench
iverilog -g2012 -f riscv32KC2.args -o system.vvp
vvp system.vvp
```

## 📜 Coding Standards
Hardware development follows the guidelines in `cursor/rules/verilog_coding_rules.md`. 
- **Verilog Version:** IEEE 1364-2001 (Verilog 2001) for maximum tool compatibility.
- **Clocking:** Synchronous designs with active-low resets.

---
*For software development and SDK, see the [software/](../software/) directory.*



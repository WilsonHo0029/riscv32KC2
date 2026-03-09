# RISC-V 32KC2 SoC Project



A simple 2-stage pipeline, full AXI4 interconnect, and comprehensive debug support. Designed for efficiency, modularity, and seamless integration into FPGA or ASIC workflows.

---

## 🌟 Project Highlights

- **Core Architecture:** `RV32IMC_Zicsr_Zifencei` (No Atomic 'A' extension).
- **Pipeline:** 2-Stage (Stage 1: IF/ID | Stage 2: EX/MEM/WB).
- **Memory System:** Multi-master AXI4 Interconnect with APB peripheral bridging.
- **Debug:** Fully compliant with RISC-V Debug Specification 0.13 (JTAG DTM).
- **Peripherals:** UART, GPIO, CLINT, PLIC.

---

## 📂 Project Structure

| Directory | Description |
| :--- | :--- |
| [**`hdl/rtl/riscv_core/`**](hdl/rtl/riscv_core/README.md) | CPU Core implementation (RV32IMC). |
| [**`hdl/rtl/debug_module/`**](hdl/rtl/debug_module/README.md) | Debug infrastructure (JTAG/DMI/DM). |
| [**`hdl/rtl/bus/`**](hdl/rtl/bus/README.md) | AXI4/APB Interconnect & Bridges. |
| [**`hdl/rtl/peripheral/`**](hdl/rtl/peripheral/README.md) | I/O Subsystem (UART, GPIO, ADC/DAC). |
| [**`hdl/rtl/riscv32KC2_system/`**](hdl/rtl/riscv32KC2_system/README.md) | System-level Top Integration. |
| **`software/`** | [Firmware SDK](software/framework/framework-riscv32KC2-sdk/README.md) and build tools. |
| **`docs/`** | Technical specifications and user guides. |

---

## 🛠️ Key Components

### 1. RISC-V Core (`RV32IMC`)
- **2-Stage Pipeline:** High-efficiency architecture (Stage 1: IF/ID | Stage 2: EX/MEM/WB).
- **Optimized Math:** Hardware acceleration via Radix-4 Booth Multiplier and Radix-4 Divider.
- **Branch Prediction:** Zero-cycle early jump prediction with hardware recovery.

### 2. Debug Infrastructure
- **JTAG Support:** Full hardware debugging via JTAG TAP.
- **Features:** Hardware breakpoints, single-stepping, and direct register/memory access.

### 3. System Interconnect
- **AXI4 Fabric:** High-bandwidth multi-master crossbar.
- **Peripheral Bridge:** Low-power APB bridge for I/O registers.

---

## Memory Map

| Range | Size | Component | Description |
| :--- | :--- | :--- | :--- |
| `0x0000_0800` - `0x0000_0FFF` | 2 KB | **Debug Module** | DMI Registers |
| `0x0000_1000` - `0x0000_7FFF` | 256 B | **Boot ROM** | Reset Entry Point |
| `0x0200_0000` - `0x0200_FFFF` | 64 KB | **CLINT** | Timer/Soft Interrupts |
| `0x0C00_0000` - `0x0C03_FFFF` | 4 MB | **PLIC** | Platform Interrupts |
| `0x1000_0000` - `0x1000_0FFF` | 4 KB | **UART** | Serial Console |
| `0x1000_2000` - `0x1000_2FFF` | 4 KB | **GPIO** | Digital I/O |
| `0x7000_0000` - `0x8FFF_FFFF` | 16 KB | **Instruction RAM** | Code Storage |
| `0x9000_0000` - `0xAFFF_FFFF` | 16 KB | **Data RAM** | Data Storage |

---

## Quick Start

### 📋 Prerequisites
- **Simulation:** Verilator, ModelSim, or Vivado XSim.
- **Toolchain:** RISC-V GNU Toolchain (`riscv32-unknown-elf-`).
- **Scripts:** Python 3.x for analysis tools.

### 🚀 Running Simulation
The top-level module is `riscv32KC2_system`. You can run the integrated testbench using:
```bash
# See hdl/testbench/README.md for detailed instructions
./scripts/run_sim.sh
```

### 💻 Software Development
Navigate to the [Software SDK](software/framework/framework-riscv32KC2-sdk/README.md) to start developing firmware.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

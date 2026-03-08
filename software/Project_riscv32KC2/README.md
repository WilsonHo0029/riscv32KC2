# 💻 RISC-V 32KC2 Firmware Project

This repository contains the baseline firmware and build environment for the RISC-V 32KC2 SoC, managed via **PlatformIO**. It provides a complete development flow from source compilation to JTAG-based debugging and hardware deployment.

---

## 🚀 Quick Start

Developed with flexibility in mind, this project supports standard RISC-V cross-compilation and OpenOCD debugging.

### 📋 Prerequisites
- **PlatformIO IDE** or CLI.
- **RISC-V Toolchain:** `riscv32-unknown-elf-gcc`.
- **OpenOCD:** Configured for the RISC-V 32KC2 Spec 0.13.

### ðŸ› ï¸ Common Commands
```bash
# Build the application
pio run

# Clean the build artifacts
pio run --target clean

# Upload to hardware via JTAG (OpenOCD)
pio run --target upload

# Start a GDB debugging session
pio debug
```

---

## 📂 Project Architecture

| File/Folder | Description |
| :--- | :--- |
| **`src/main.c`** | Application entry point and peripheral initialization. |
| **`src/start.S`** | Boot assembly: Stack setup, BSS clearing, and jump to main. |
| **`platformio.ini`** | Project configuration (board, framework, and upload settings). |
| **`linker.lds`** | Memory layout: Maps code to IRAM and data to DRAM. |
| **`openocd.cfg`** | JTAG configuration for FTDI adapters and RISC-V Spec 0.13. |

---

## ðŸ—ºï¸ Targeted Memory Map

The firmware is linked to target the following SoC memory regions:

- **Reset Entry:** `0x0000_1000` (Jumps to `0x7000_0000`).
- **Instruction RAM:** `0x7000_0000` (linked as `.text`).
- **Data RAM:** `0x9000_0000` (linked as `.data`, `.bss`, and `stack`).
- **Stack:** Placed at the top of Data RAM, growing downwards.

---

## 🔧 Debugging & Deployment

### JTAG Configuration
The project is pre-configured for **FTDI FT4232H** adapters. To use a different debugger (e.g., J-Link), update the `interface/` section in `openocd.cfg`.

### Serial Console
By default, the `main.c` initializes **UART 0** at **115200 8N1**. Connect a USB-to-UART bridge to the SoC UART pins and run:
```bash
pio device monitor
```

---

## 📜 RELATED DOCUMENTATION
- [**Root SoC README**](../../README.md)
- [**Hardware Specification**](../../hdl/rtl/riscv32KC2_system/README.md)
- [**SDK Documentation**](../framework/framework-riscv32KC2-sdk/README.md)




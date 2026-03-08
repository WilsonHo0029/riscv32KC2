# RISC-V 32KC2 SDK

## ðŸ“¦ Overview

The Software Development Kit (SDK) provides everything needed to build, debug, and deploy firmware for the RISC-V 32KC2 SoC. It includes a Board Support Package (BSP), peripheral drivers, and PlatformIO integration.

---

## ðŸ—ï¸ SDK Structure

- **`bsp/env/`**: Startup code (`start.S`), linker scripts (`linker.lds`), and OpenOCD configurations.
- **`bsp/include/metal/`**: Hardware Abstraction Layer (HAL) headers for UART, GPIO, and AD/DA.
- **`bsp/src/`**: Driver implementations for system peripherals.
- **`examples/`**: Ready-to-run code templates for ADC/DAC and UART.

---

## ðŸ§  Memory Map Summary

| Region | Address Range | Description |
| :--- | :--- | :--- |
| **Boot ROM** | `0x0000_1000` | Hardware entry point. |
| **I-RAM** | `0x7000_0000` | Code execution memory (16KB). |
| **D-RAM** | `0x9000_0000` | Data storage memory (16KB). |
| **UART** | `0x1000_0000` | Console I/O. |
| **GPIO** | `0x1000_2000` | Digital I/O. |

---

## ðŸ› ï¸ Getting Started

### 1. Installation
Copy the SDK folder into your PlatformIO packages directory or create a symbolic link:
```bash
# Windows example
mklink /D %HOMEPATH%\.platformio\packages\framework-riscv32KC2-sdk .
```

### 2. Project Config
Add the following to your `platformio.ini`:
```ini
[env:riscv32KC2]
platform = riscv32KC2
framework = riscv32KC2-sdk
```

---

## 📜 Documentation

Detailed API documentation for drivers can be found in the header files under `bsp/include/metal/`.



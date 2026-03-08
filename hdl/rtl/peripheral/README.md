# ðŸ”Œ Peripheral Subsystem

This directory contains the I/O hub for the RISC-V 32KC2 SoC. It integrates various low-speed communication and control peripherals via an **APB** (Advanced Peripheral Bus) fabric, bridged from the main system AXI4 interconnect.

---

## ðŸ—ï¸ Subsystem Architecture

The peripheral subsystem (`riscv32KC2_peripheral.v`) acts as a unified AXI4-Lite slave that encapsulates:
- **AXI-to-APB Bridge:** Protocol conversion for peripheral register access.
- **APB Decoder:** 16-way routing for internal peripheral selection.
- **Interrupt Aggregator:** Collects interrupt signals (UART, GPIO, etc.) for the CPU core.

---

## ðŸ› ï¸ Integrated Peripherals

### 1. UART Controller (`uart/`)
A lightweight serial interface for console I/O.
- **Features:** 16-byte TX FIFO, configurable baud rate (16-bit divisor), 8N1 format.
- **Base Address:** `0x1000_0000`

### 2. GPIO Controller (`gpio/`)
32-bit General Purpose I/O with comprehensive control.
- **Features:** 
  - Direction control, pull-up/pull-down config, 4-level drive strength.
  - Multi-mode interrupts (edge/level triggered).
  - Atomic set/clear/toggle registers for bitwise manipulation.
- **Base Address:** `0x1000_2000`

### 3. ADC/DAC Interface (`ad_da_if/`)
Mixed-signal interface for analog interaction.
- **ADC:** 12-bit resolution with configurable sample rates and offsets.
- **DAC:** 3-channel 16-bit output with precise clock timing control.
- **Base Address:** `0x1000_1000`

---

## ðŸ—ºï¸ Register Map Summary

| Peripheral | Base Address | Range | Description |
| :--- | :--- | :--- | :--- |
| **UART** | `0x1000_0000` | 4 KB | Serial console port. |
| **ADC/DAC** | `0x1000_1000` | 4 KB | Analog subsystem control. |
| **GPIO** | `0x1000_2000` | 4 KB | 32-bit digital I/O pins. |

---

## 📂 File Directory

| Module | Location | Description |
| :--- | :--- | :--- |
| `riscv32KC2_peripheral.v` | Root | Subsystem top-level wrapper. |
| `apb_uart.v` | `uart/` | APB-compliant UART core. |
| `apb_gpio.v` | `gpio/` | 32-bit GPIO controller with interrupts. |
| `apb_ad_da_if.v` | `ad_da_if/` | Unified ADC/DAC interface wrapper. |

---

## 📜 Related Documents
- [**Main Project README**](../../README.md)
- [**Bus Infrastructure**](../bus/README.md)
- [**System Integration**](../riscv32KC2_system/README.md)
- [**Memory Map**](../Memory_Map.txt)



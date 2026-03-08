# ðŸ”Ž RISC-V Debug Module (Spec 0.13)

This directory contains the complete debug infrastructure for the RISC-V KC32 SoC, fully compliant with **RISC-V Debug Specification 0.13**. It enables external debuggers (via JTAG) to control the CPU, access registers, and perform memory operations.

---

## ðŸ› ï¸ Architecture & Components

The debug system is composed of three primary layers:

### 1. JTAG Debug Transport Module (`riscv_jtag_dtm.v`)
Bridges physical JTAG pins to the internal Debug Module Interface (DMI).
- **TAP Controller:** Full 16-state JTAG TAP implementation.
- **Registers:** IDCODE, DTMCS, and DMI access.
- **Clock Domain:** Operates in the `TCK` domain with robust CDC to the system clock.

### 2. Debug Module (DM) (`riscv_debug_module.v`)
The core logic for hardware orchestration.
- **Hart Management:** State control for Halt, Resume, and Single-Step.
- **Abstract Commands:** "Access Register" and "Access Memory" support.
- **Program Buffer:** 8-word buffer for executing custom instruction sequences in Debug Mode.

### 3. Integrated Debug Block (`riscv_debug_block.v`)
A high-level wrapper that integrates the DTM and DM with the SoC fabric.
- **Bus Interface:** APB Slave interface for memory access via the debugger.
- **Control Interface:** Multi-hart `debug_req` and `debug_mode` signal arrays.

---

## âš¡ Key Features

- **Full Compliance:** Implements RISC-V Debug Spec 0.13.
- **Multi-Hart Support:** Scalable architecture via the `HART_NUM` parameter.
- **Fast Memory Access:** Direct system bus access via an integrated APB bridge.
- **Debug ROM:** Internal ROM (`debug_rom_013.v`) containing standard entry/exit handlers.
- **Hardware Breakpoints:** Support for triggering Debug Mode via the `ebreak` instruction.

---

## 📂 File Directory

| File | Description |
| :--- | :--- |
| `riscv_jtag_dtm.v` | JTAG TAP and DTM implementation. |
| `riscv_debug_module.v` | Core Debug Module (DM) logic. |
| `riscv_debug_block.v` | Top-level integration of DTM + DM. |
| `dm_mem.v` | Internal memory/buffer logic for the DM. |
| `debug_rom_013.v` | Hardware ROM for debug exception handling. |
| `debug_apb_bridge.v` | Bridge for memory-mapped access to DMI. |

---

## 📜 Related Documents
- [**Main Project README**](../../README.md)
- [**Core Implementation**](../riscv_core/README.md)
- [**System Integration**](../riscv32KC2_system/README.md)
- [**Memory Map**](../Memory_Map.txt)


# ðŸ› ï¸ Miscellaneous Utilities & Math Modules

This directory contains essential utility modules, optimized arithmetic implementations, and Clock Domain Crossing (CDC) logic used throughout the RISC-V 32KC2 SoC.

---

## ðŸ§® Optimized Arithmetic Modules

These modules provide hardware acceleration for the RISC-V **M-Extension** (Multiply/Divide).

### 1. Booth Multipliers
Optimized combinational multipliers using Booth's Algorithm to reduce partial products and improve timing.
- **Radix-4 Multipliers (`booth_mult_r4.v`, `booth_mult_r4_b.v`):**
  - High-performance behavioral and structural implementations.
  - Reduces partial products by 50% vs. standard multipliers.
- **Radix-8 Multiplier (`booth_mult_r8.v`):**
  - Further reduces partial products by 75%, processing 4 bits per stage. Requires pre-calculation of 3x multiplicand.

### 2. Integer Dividers
Sequential, multi-cycle dividers with RISC-V compliant exception handling.
- **Radix-4 Divider (`div_r4.v`):** High-efficiency divider calculating **2 quotient bits per cycle**.
- **Radix-2 Divider (`div_r2.v`):** Standard restorer calculating **1 quotient bit per cycle**.
- **Features:** Robust handling of divide-by-zero and signed overflow conditions.

---

## ðŸš¥ Clock Domain Crossing (CDC)

Robust synchronization modules for interfacing logic across different clock domains (e.g., JTAG TCK to System Clock).
- **`async_buf_cdc.v`**: Asynchronous buffer with full CDC support.
- **`buf_cdc_tx.v` / `buf_cdc_rx.v`**: Specialized transmitter/receiver synchronization buffers.

---

## ðŸ“¦ General Utilities

- **`sync_fifo.v`**: Highly configurable synchronous FIFO for data buffering.
- **`sirv_sim_ram.v`**: Behavioral RAM model specifically for simulation and verification.

---

## 📜 Related Documents
- [**Main Project README**](../../README.md)
- [**Core Implementation**](../riscv_core/README.md)


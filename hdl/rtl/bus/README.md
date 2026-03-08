# ðŸš System Interconnect & Bus Infrastructure

This directory contains the essential bus fabric for the RISC-V 32KC2 SoC. It implements a high-performance **AXI4** interconnect and an **APB** peripheral subsystem, providing seamless communication between the CPU core, memory, and I/O peripherals.

---

## ðŸ—ï¸ Architecture Overview

The system employs a hierarchical bus topology designed for balanced throughput and low-power peripheral access:

1.  **AXI4 Backbone:** A multi-master, multi-slave interconnect (`riscv32KC2_bus.v`) that handles high-speed traffic (Instruction Fetch, Data Access, and DMA).
2.  **AXI-to-APB Bridge:** A protocol converter (`axi2apb_bridge.v`) that translates AXI4-Lite transactions into simpler APB cycles for I/O registers.
3.  **APB Subsystem:** A routed peripheral bus (`apb_decoder.v`) governing low-speed devices like UART and GPIO.

---

## ðŸ› ï¸ Core Bus Modules

### 1. System Interconnect (`riscv32KC2_bus.v`)
The central switch fabric of the SoC.
- **Protocol:** Full AXI4 (supports burst transactions, byte enables).
- **Topology:** Multi-master / Multi-slave with fair arbitration.
- **Routing:** Intelligent address-based transaction steering.

### 2. AXI-to-APB Bridge (`axi2apb_bridge.v`)
Enables the CPU to communicate with low-complexity peripherals.
- Converts AXI4-Lite read/write requests to synchronous APB cycles.
- Supports byte strobes (`PSTRB`) for flexible register access.

### 3. APB Decoder (`apb_decoder.v`)
A 1-to-16 address decoder for the peripheral bus.
- **Routing:** Maps a single APB master to up to 16 slave devices.
- **Configuration:** Fully parameterizable base addresses and ranges.

### 4. AXI4 Mux/Demux Logic
High-performance routing components for the AXI4 fabric:
- **`axi_lite_mux.v`**: Combines multiple master streams (N-to-1) with priority arbitration.
- **`axi_lite_demux.v`**: Routes a single master to multiple slaves (1-to-N) with transaction tracking.
- **Note:** These modules support **Full AXI4** (bursts/IDs), despite the legacy "lite" naming.

---

## 📂 File Directory

| Module | Description |
| :--- | :--- |
| `riscv32KC2_bus.v` | Central AXI4 interconnect core. |
| `axi2apb_bridge.v` | AXI-to-APB protocol converter. |
| `apb_decoder.v` | APB peripheral address router. |
| `axi_lite_mux2.v` | 2-to-1 AXI4 multiplexer with FIFO tracking. |
| `axi_fifo.v` | Transaction buffer for CDC and timing closure. |
| `read_req_to_axi.v`| Stage 1 (IF/ID) to AXI transaction bridge. |

---

## 📜 Related Documents
- [**Main Project README**](../../README.md)
- [**Core Implementation**](../riscv_core/README.md)
- [**Peripheral Subsystem**](../peripheral/README.md)
- [**Memory Map**](../Memory_Map.txt)



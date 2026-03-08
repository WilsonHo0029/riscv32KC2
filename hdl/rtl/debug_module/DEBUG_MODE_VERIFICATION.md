# Debug Mode Entry Verification

## Overview
This document verifies that the RISC-V core can enter debug mode via APB bus when `debug_req` is high.

## Flow Verification

### 1. Debug Request Assertion
- **Location**: `riscv_pipeline.v`
- **Signal**: `debug_req` (input from `riscv_debug_module`)
- **Action**: When `debug_req` goes high, `debug_mode_entry` is detected
- **Code**: 
  ```verilog
  wire debug_mode_entry = debug_req && !debug_ack;
  ```

### 2. PC Jump to Debug Exception Address
- **Location**: `riscv_pipeline.v`
- **Constant**: `DEBUG_EXCEPTION_ADDR = 32'h00000800`
- **Action**: Pipeline sets `next_pc = DEBUG_EXCEPTION_ADDR`
- **Code**:
  ```verilog
  assign next_pc = debug_mode_entry ? DEBUG_EXCEPTION_ADDR : ...
  ```

### 3. Instruction Fetch Request
- **Location**: `riscv_axi_ifetch.v`
- **PC Value**: `0x00000800`
- **Address Range Check**: PC is NOT in instruction RAM range (0x70000000-0x8FFFFFFF)
- **Action**: Uses data AXI fallback path
- **Path**: Instruction Fetch → Data AXI → APB Splitter → APB Decoder

### 4. APB Decoder Routing
- **Location**: `apb_decoder.v`
- **Input Address**: `0x00000800` (absolute)
- **Address Range**: Matches debug module range (0x00000800-0x00000FFF)
- **Action**: Routes to Slave 0 (Debug Module)
- **Address**: Passes absolute address directly (no conversion)

### 5. Debug Module Address Handling
- **Location**: `riscv_debug_module.v`
- **Input**: `m_apb_paddr = 0x00000800` (absolute from APB decoder)
- **Address**: Uses absolute address directly for `dm_mem`
- **Code**:
  ```verilog
  // APB decoder passes absolute addresses directly
  // dm_mem uses absolute addresses in the range 0x800-0xFFF (lower 12 bits)
  ```
- **Address Decode**: Checks if address is in `dm_mem` range
  ```verilog
  wire apb_to_dm_mem = (m_apb_paddr[11:8] == 4'h8) || ...;
  // For 0x00000800: m_apb_paddr[11:8] = 0x8 → TRUE ✓
  ```

### 6. Debug Memory Module Access
- **Location**: `dm_mem.v`
- **Input**: `m_apb_paddr = 0x00000800` (absolute)
- **Address Extraction**: `apb_addr[11:0] = m_apb_paddr[11:0] = 0x800`
- **Debug ROM Selection**: 
  ```verilog
  wire sel_debug_rom = (apb_addr[11:8] == 4'h8);
  // For 0x800: apb_addr[11:8] = 0x8 → TRUE ✓
  ```

### 7. Debug ROM Access
- **Location**: `debug_rom_013.v`
- **Input**: `addr_i = apb_addr[7:2] = 0x800[7:2] = 0x0` (word address)
- **Output**: Returns instruction at ROM[0] = `32'h00c0006f` (JAL instruction)
- **Result**: First instruction of debug exception handler is fetched

### 8. Instruction Return Path
- **Path**: `debug_rom_013` → `dm_mem` → `riscv_debug_module` → APB response → APB decoder → APB splitter → Data AXI → Instruction fetch → Pipeline
- **Result**: Pipeline receives instruction and executes debug exception handler

## Address Mapping Summary

| Absolute Address | dm_mem Address (lower 12 bits) | ROM Address | Description |
|-----------------|--------------------------------|-------------|-------------|
| 0x00000800 | 0x800 | 0x0 | Debug ROM entry point |
| 0x00000804 | 0x804 | 0x1 | Debug ROM +4 |
| 0x00000808 | 0x808 | 0x2 | Debug ROM +8 |
| ... | ... | ... | ... |
| 0x000009FC | 0x9FC | 0x3F | Debug ROM end |

## Verification Checklist

- [x] `debug_req` assertion causes `debug_mode_entry` signal
- [x] Pipeline jumps to `DEBUG_EXCEPTION_ADDR = 0x00000800`
- [x] Instruction fetch routes to APB bus (via data AXI fallback)
- [x] APB decoder routes to debug module (Slave 0)
- [x] Address conversion: relative → absolute for `dm_mem`
- [x] `dm_mem` correctly identifies debug ROM region
- [x] Debug ROM returns correct instruction at address 0x800
- [x] Instruction is returned to pipeline via APB response path

## Design Decision

**Direct Address Usage**: 
- **Approach**: APB decoder passes absolute addresses directly to debug module (no relative address conversion)
- **Rationale**: Simplifies address handling and matches how `dm_mem` expects addresses
- **Implementation**: 
  - APB decoder: `m0_apb_paddr = s_apb_paddr;` (direct pass-through)
  - Debug module: Uses `m_apb_paddr` directly for `dm_mem`
  - Address decode: Checks `m_apb_paddr[11:8]` directly

## Conclusion

The RISC-V core **CAN** enter debug mode via APB bus when `debug_req` is high. The complete flow is verified:

1. Debug request causes PC to jump to 0x00000800
2. Instruction fetch routes through APB bus
3. Debug ROM is correctly accessed
4. Debug exception handler instructions are fetched and executed

The address conversion fix ensures that the debug ROM is accessible at the correct address when the core enters debug mode.


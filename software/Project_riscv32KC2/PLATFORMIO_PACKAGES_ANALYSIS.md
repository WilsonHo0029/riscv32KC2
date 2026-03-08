# PlatformIO Packages Analysis

Analysis of available PlatformIO packages in `C:\Users\wilson\.platformio\packages`

## Overview

This document provides a comprehensive analysis of the PlatformIO packages available for the AI RISC-V KC32 project.

## Available Toolchains

### 1. toolchain-riscv32KC2
- **Version**: 11.2.0
- **Description**: RISC-V GCC toolchain
- **Location**: `C:\Users\wilson\.platformio\packages\toolchain-riscv32KC2`
- **Architecture**: riscv32-unknown-elf
- **GCC Version**: 11.2.0
- **Tools Available**:
  - `riscv32-unknown-elf-gcc.exe` - C/C++ compiler
  - `riscv32-unknown-elf-g++.exe` - C++ compiler
  - `riscv32-unknown-elf-as.exe` - Assembler
  - `riscv32-unknown-elf-ld.exe` - Linker
  - `riscv32-unknown-elf-objcopy.exe` - Object file converter
  - `riscv32-unknown-elf-objdump.exe` - Object file dumper
  - `riscv32-unknown-elf-gdb.exe` - Debugger
  - `riscv32-unknown-elf-size.exe` - Size utility
  - `riscv32-unknown-elf-strip.exe` - Strip utility
- **Status**: âœ… Recommended for AI RISC-V KC32 projects

### 2. toolchain-riscv
- **Version**: 1.130200.2
- **Description**: GNU toolchain for RISC-V, including GCC
- **Location**: `C:\Users\wilson\.platformio\packages\toolchain-riscv`
- **Repository**: https://github.com/riscv/riscv-gnu-toolchain
- **Status**: âœ… Generic RISC-V toolchain (alternative option)

### 3. toolchain-riscv64
- **Description**: RISC-V 64-bit toolchain
- **Status**: âš ï¸ Not applicable for 32-bit RV32IMC architecture

### 4. toolchain-riscv-pulp
- **Description**: PULP platform specific RISC-V toolchain
- **Status**: âš ï¸ Not applicable for this project

### 5. toolchain-gccarmnoneeabi
- **Description**: ARM Cortex-M toolchain
- **Status**: âŒ Not applicable (ARM, not RISC-V)

## Available Frameworks

### 1. framework-riscv32KC2-sdk â­ PRIMARY
- **Version**: 0.0.0
- **Description**: AI RISC-V KC32 Software Development Kit
- **Location**: `C:\Users\wilson\.platformio\packages\framework-riscv32KC2-sdk`
- **Status**: âœ… **Currently used in project**
- **Components**:
  - BSP (Board Support Package)
  - Metal HAL (Hardware Abstraction Layer)
  - UART, GPIO, Timer, I2C, SPI drivers
  - Startup code and linker scripts
- **Key Files**:
  - `bsp/include/metal/*.h` - Metal HAL headers
  - `bsp/src/*.c` - Metal HAL implementations
  - `bsp/env/riscv32KC2/` - Board-specific configurations
  - `bsp/env/riscv32KC2/linker.lds` - Linker script
  - `bsp/env/riscv32KC2/openocd.cfg` - OpenOCD configurations
  - `bsp/env/start.S` - Startup assembly

### 2. Alternative Framework Variants
- **Description**: Other RISC-V SDK variants recorded for reference.
- **Status**: âš ï¸ Generic or variant SDKs.

### 4. framework-cva6_64-sdk
- **Description**: CVA6 64-bit RISC-V SDK
- **Status**: âš ï¸ 64-bit architecture, not applicable

### 5. framework-cva6_2_64-sdk
- **Description**: CVA6 v2 64-bit RISC-V SDK
- **Status**: âš ï¸ 64-bit architecture, not applicable

### 6. framework-pulp-sdk
- **Description**: PULP platform SDK
- **Status**: âš ï¸ Different platform

### 7. framework-arduinoststm32
- **Description**: Arduino framework for STM32
- **Status**: âŒ Not applicable (ARM/Arduino)

## Debug Tools

### 1. tool-openocd-riscv â­ PRIMARY
- **Version**: 0.10.1
- **Description**: Open On-Chip Debugger with RISC-V support
- **Location**: `C:\Users\wilson\.platformio\packages\tool-openocd-riscv`
- **Repository**: https://github.com/riscv-mcu/riscv-openocd
- **Status**: âœ… **Currently used in project**
- **Executable**: `bin/openocd.exe`
- **Features**:
  - RISC-V Debug Specification support
  - JTAG interface support
  - GDB server
  - Flash programming

### 2. tool-openocd-nuclei
- **Description**: OpenOCD with Nuclei support
- **Status**: âš ï¸ Nuclei-specific variant

### 3. tool-openocd-riscv
- **Description**: Generic RISC-V OpenOCD
- **Status**: âœ… Alternative option

### 4. tool-jlink
- **Description**: SEGGER J-Link debugger tools
- **Status**: âœ… Alternative debugger (if using J-Link hardware)

## Build Tools

### 1. tool-scons
- **Description**: SCons build system
- **Status**: âœ… Used by PlatformIO for building

## Package Structure Analysis

### Framework-riscv32KC2-sdk Structure

```
framework-riscv32KC2-sdk/
â”œâ”€â”€ bsp/
â”‚   â”œâ”€â”€ env/
â”‚   â”‚   â”œâ”€â”€ riscv32KC2/        # Board configuration
â”‚   â”‚   â”‚   â”œâ”€â”€ linker.lds       # Linker script
â”‚   â”‚   â”‚   â”œâ”€â”€ openocd.cfg      # OpenOCD config
â”‚   â”‚   â”‚   â”œâ”€â”€ settings.mk      # Build settings
â”‚   â”‚   â”‚   â””â”€â”€ riscv32KC2.cfg # Board config
â”‚   â”‚   â”œâ”€â”€ common.mk            # Common build rules
â”‚   â”‚   â”œâ”€â”€ start.S              # Startup code
â”‚   â”‚   â”œâ”€â”€ init.c               # Initialization
â”‚   â”‚   â””â”€â”€ sirv_printf.c        # Printf implementation
â”‚   â”œâ”€â”€ include/
â”‚   â”‚   â”œâ”€â”€ metal/               # Metal HAL headers
â”‚   â”‚   â”‚   â”œâ”€â”€ uart.h
â”‚   â”‚   â”‚   â”œâ”€â”€ gpio.h
â”‚   â”‚   â”‚   â”œâ”€â”€ timer.h
â”‚   â”‚   â”‚   â”œâ”€â”€ i2c.h
â”‚   â”‚   â”‚   â”œâ”€â”€ spi.h
â”‚   â”‚   â”‚   â””â”€â”€ ...
â”‚   â”‚   â”œâ”€â”€ encoding.h           # RISC-V CSR encoding
â”‚   â”‚   â””â”€â”€ platform.h
â”‚   â””â”€â”€ src/                     # Metal HAL implementations
â”‚       â”œâ”€â”€ uart.c
â”‚       â”œâ”€â”€ gpio.c
â”‚       â””â”€â”€ ...
â”œâ”€â”€ package.json
â””â”€â”€ SConscript                   # SCons build script
```

## Linker Scripts Available

From `framework-riscv32KC2-sdk/bsp/env/riscv32KC2/`:

1. **link_itcm.lds** - ITCM (Instruction Tightly Coupled Memory) layout
   - ITCM: 0x80000000, 32KB
   - RAM: 0x90000000, 2KB

2. **link_flash.lds** - Flash-based layout

3. **link_flashxip.lds** - Flash Execute-In-Place layout

4. **link_itcm_me.lds** - ITCM with Memory Extension

5. **link_mtp.lds** - MTP (Multi-Time Programmable) layout

**Note**: Our project uses a custom `linker.lds` adapted for:
- Instruction RAM: 0x80000000 (512 MB)
- Data RAM: 0x90000000 (512 MB)

## OpenOCD Configurations Available

From `framework-riscv32KC2-sdk/bsp/env/riscv32KC2/`:

1. **openocd.cfg** - Default configuration
2. **openocd_ftdi.cfg** - FTDI adapter configuration
3. **openocd_olimex.cfg** - Olimex adapter configuration
4. **openocd_me.cfg** - Memory Extension configuration
5. **openocd_flash.cfg** - Flash programming configuration

**Note**: Our project uses a custom `openocd.cfg` configured for:
- FTDI FT4232H adapter
- RISC-V Debug Specification 0.13
- AI RISC-V KC32 memory map

## Recommendations

### For AI RISC-V KC32 Project:

1. **Toolchain**: âœ… `toolchain-riscv32KC2` (GCC 11.2.0)
   - Already configured and tested
   - Optimized for AI RISC-V KC32 architecture
   - Supports RV32IMC

2. **Framework**: âœ… `framework-riscv32KC2-sdk`
   - Provides Metal HAL
   - Includes UART, GPIO, Timer drivers
   - Startup code compatible with RISC-V

3. **Debug Tool**: âœ… `tool-openocd-riscv`
   - RISC-V Debug support
   - Compatible with Debug Spec 0.13
   - JTAG interface support

4. **Platform**: âœ… `riscv32KC2` platform
   - Uses `toolchain-riscv32KC2`
   - Uses `framework-riscv32KC2-sdk`
   - Board: `riscv32KC2`

## Current Project Configuration

```ini
[env:riscv32KC2]
platform = riscv32KC2
board = riscv32KC2
framework = riscv32KC2-sdk
board_build.ldscript = linker.lds
```

**Status**: âœ… Configuration is optimal for the project

## Alternative Configurations

If needed, alternative configurations:

### Option 1: Generic RISC-V Toolchain
```ini
platform_packages = 
    toolchain-riscv@^1.130200.2
build_flags = 
    -march=rv32imc
    -mabi=ilp32
```

### Option 2: J-Link Debugger
```ini
debug_tool = jlink
debug_server = 
    ${platformio_packages_dir}/tool-jlink/JLinkGDBServer.exe
```

## Package Dependencies

Current project dependencies:
- âœ… `toolchain-riscv32KC2`
- âœ… `framework-riscv32KC2-sdk`
- âœ… `tool-openocd-riscv`
- âœ… `tool-scons` (via PlatformIO build system)

## Summary

The PlatformIO packages directory contains all necessary tools for the AI RISC-V KC32 project:

- âœ… **Toolchain**: toolchain-riscv32KC2 (GCC 11.2.0)
- âœ… **Framework**: framework-riscv32KC2-sdk (Metal HAL)
- âœ… **Debugger**: tool-openocd-riscv (OpenOCD)
- âœ… **Build System**: tool-scons

The current project configuration (`platformio.ini`) correctly references these packages through the `riscv32KC2` platform, which automatically resolves the dependencies.

## Notes

1. The `riscv32KC2` platform must be installed in PlatformIO.

2. The project uses custom linker script (`linker.lds`) and OpenOCD config (`openocd.cfg`) adapted for the AI RISC-V KC32 memory map.

3. All Metal HAL drivers from `framework-riscv32KC2-sdk` are available for use in the project.



# Custom Platform and Framework Summary

## Overview

This project includes a custom PlatformIO platform (`riscv32KC2`) and framework (`framework-riscv32KC2-sdk`) designed specifically for the AI RISC-V KC32 System.

## Structure

```
Project_riscv32KC2/
â”œâ”€â”€ platform/                          # Custom PlatformIO platform
â”‚   â””â”€â”€ riscv32KC2/
â”‚       â”œâ”€â”€ platform.json              # Platform definition
â”‚       â”œâ”€â”€ platform.py                # Platform Python script
â”‚       â”œâ”€â”€ boards/
â”‚       â”‚   â””â”€â”€ riscv32KC2.json     # Board definition
â”‚       â””â”€â”€ builder/
â”‚           â””â”€â”€ frameworks/
â”‚               â”œâ”€â”€ _bare.py           # Bare-metal framework base
â”‚               â””â”€â”€ riscv32KC2-sdk.py # Framework builder script
â”‚
â”œâ”€â”€ framework/                         # Custom Framework SDK
â”‚   â””â”€â”€ framework-riscv32KC2-sdk/
â”‚       â”œâ”€â”€ package.json               # Framework package definition
â”‚       â”œâ”€â”€ bsp/                       # Board Support Package
â”‚       â”‚   â”œâ”€â”€ env/                   # Environment/startup code
â”‚       â”‚   â”‚   â”œâ”€â”€ riscv32KC2/      # Board-specific configs
â”‚       â”‚   â”‚   â”‚   â”œâ”€â”€ linker.lds    # Linker script
â”‚       â”‚   â”‚   â”‚   â”œâ”€â”€ ftdi.cfg      # FTDI OpenOCD config
â”‚       â”‚   â”‚   â”‚   â”œâ”€â”€ jlink.cfg     # J-Link OpenOCD config
â”‚       â”‚   â”‚   â”‚   â””â”€â”€ riscv32KC2.cfg # Target config
â”‚       â”‚   â”‚   â”œâ”€â”€ start.S           # Startup assembly
â”‚       â”‚   â”‚   â””â”€â”€ init.c            # Initialization code
â”‚       â”‚   â”œâ”€â”€ include/               # Header files
â”‚       â”‚   â”‚   â”œâ”€â”€ encoding.h        # RISC-V CSR encoding
â”‚       â”‚   â”‚   â”œâ”€â”€ platform.h        # Platform configuration
â”‚       â”‚   â”‚   â””â”€â”€ metal/            # Metal HAL headers
â”‚       â”‚   â”‚       â””â”€â”€ uart.h        # UART driver header
â”‚       â”‚   â””â”€â”€ src/                  # Source files
â”‚       â”‚       â””â”€â”€ uart.c            # UART driver implementation
â”‚       â””â”€â”€ README.md                  # Framework documentation
â”‚
â”œâ”€â”€ src/                               # Project source code
â”‚   â”œâ”€â”€ main.c                        # Main application
â”‚   â””â”€â”€ start.S                       # Project startup (optional)
â”‚
â”œâ”€â”€ platformio.ini                     # PlatformIO configuration
â”œâ”€â”€ linker.lds                        # Project linker script
â”œâ”€â”€ openocd.cfg                       # Project OpenOCD config
â”œâ”€â”€ README.md                         # Project documentation
â”œâ”€â”€ INSTALLATION.md                   # Installation guide
â””â”€â”€ PLATFORMIO_PACKAGES_ANALYSIS.md   # Packages analysis
```

## Key Features

### Platform (`riscv32KC2`)

- **Name**: riscv32KC2
- **Version**: 0.1.0
- **Architecture**: RV32IMC_Zicsr_Zifencei
- **Toolchain**: RISC-V GCC (11.2.0)
- **Debug Tool**: OpenOCD (RISC-V supported)

### Framework (`framework-riscv32KC2-sdk`)

- **Name**: framework-riscv32KC2-sdk
- **Version**: 0.1.0
- **Memory Map**:
  - Instruction RAM: 0x80000000 - 0x9FFFFFFF (512 MB)
  - Data RAM: 0x90000000 - 0xAFFFFFFF (512 MB)
- **Features**:
  - Metal HAL (Hardware Abstraction Layer)
  - UART driver support
  - Startup code and initialization
  - Linker scripts for memory layout
  - OpenOCD debug configurations

## Installation

See `INSTALLATION.md` for detailed installation instructions.

Quick installation:

1. Copy platform to `~/.platformio/platforms/riscv32KC2`
2. Copy framework to `~/.platformio/packages/framework-riscv32KC2-sdk`
3. Build project: `pio run`

## Usage

The project is configured in `platformio.ini`:

```ini
[env:riscv32KC2]
platform = riscv32KC2
board = riscv32KC2
framework = riscv32KC2-sdk
```


## Extending the Framework

To add new drivers or features:

1. **Add Header**: Create header in `framework/framework-riscv32KC2-sdk/bsp/include/metal/`
2. **Add Implementation**: Create source in `framework/framework-riscv32KC2-sdk/bsp/src/`
3. **Update Build**: The framework builder will automatically include new files
4. **Rebuild**: Run `pio run --target clean` then `pio run`

## Files Reference

### Platform Files

- `platform/riscv32KC2/platform.json` - Platform metadata and package dependencies
- `platform/riscv32KC2/platform.py` - Platform Python script for dynamic board configuration
- `platform/riscv32KC2/boards/riscv32KC2.json` - Board definition with build parameters
- `platform/riscv32KC2/builder/frameworks/_bare.py` - Base framework flags
- `platform/riscv32KC2/builder/frameworks/riscv32KC2-sdk.py` - Framework builder script

### Framework Files

- `framework/framework-riscv32KC2-sdk/package.json` - Framework package metadata
- `framework/framework-riscv32KC2-sdk/bsp/env/start.S` - Startup assembly code
- `framework/framework-riscv32KC2-sdk/bsp/env/init.c` - C initialization code
- `framework/framework-riscv32KC2-sdk/bsp/env/riscv32KC2/linker.lds` - Linker script
- `framework/framework-riscv32KC2-sdk/bsp/env/riscv32KC2/*.cfg` - OpenOCD configurations
- `framework/framework-riscv32KC2-sdk/bsp/include/encoding.h` - RISC-V CSR definitions
- `framework/framework-riscv32KC2-sdk/bsp/include/platform.h` - Platform configuration
- `framework/framework-riscv32KC2-sdk/bsp/include/metal/uart.h` - UART HAL header
- `framework/framework-riscv32KC2-sdk/bsp/src/uart.c` - UART driver implementation

## Next Steps

1. Install the platform and framework (see INSTALLATION.md)
2. Build the project: `pio run`
3. Configure OpenOCD for your JTAG adapter
4. Start developing your application!

## Support

For issues or questions:
- Review the README.md files
- Check INSTALLATION.md for troubleshooting
- Review PLATFORMIO_PACKAGES_ANALYSIS.md for package information



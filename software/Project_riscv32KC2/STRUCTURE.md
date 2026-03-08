# Project Structure

This document describes the organization of the AI RISC-V KC32 software project.

## Directory Structure

```
software/
â”œâ”€â”€ framework/                          # Framework SDK (shared)
â”‚   â””â”€â”€ framework-riscv32KC2-sdk/
â”‚       â”œâ”€â”€ bsp/                       # Board Support Package
â”‚       â”‚   â”œâ”€â”€ env/                   # Environment/startup code
â”‚       â”‚   â”œâ”€â”€ include/               # Header files
â”‚       â”‚   â””â”€â”€ src/                   # Source files
â”‚       â””â”€â”€ package.json
â”‚
â”œâ”€â”€ platform/                          # PlatformIO platform (shared)
â”‚   â””â”€â”€ riscv32KC2/
â”‚       â”œâ”€â”€ boards/                    # Board definitions
â”‚       â”œâ”€â”€ builder/                   # Build scripts
â”‚       â”œâ”€â”€ platform.json              # Platform definition
â”‚       â””â”€â”€ platform.py               # Platform Python script
â”‚
â””â”€â”€ Project_riscv32KC2/              # Main project directory
    â”œâ”€â”€ src/                           # Project source code
    â”‚   â”œâ”€â”€ main.c                     # Main application
    â”‚   â””â”€â”€ start.S                    # Project startup (optional)
    â”œâ”€â”€ build/                         # Build output directory
    â”œâ”€â”€ platformio.ini                 # PlatformIO configuration
    â”œâ”€â”€ linker.lds                     # Linker script
    â”œâ”€â”€ openocd.cfg                    # OpenOCD configuration
    â”œâ”€â”€ compile_manual.bat             # Manual compilation script
    â”œâ”€â”€ build.bat                      # Build script
    â””â”€â”€ README.md                      # Project documentation
```

## Key Directories

### `software/framework/`
Contains the framework SDK that can be shared across multiple projects:
- **Location**: `software/framework/framework-riscv32KC2-sdk/`
- **Purpose**: Provides BSP, drivers, and startup code
- **Usage**: Referenced by projects via relative path `../framework/framework-riscv32KC2-sdk`

### `software/platform/`
Contains the PlatformIO platform definition:
- **Location**: `software/platform/riscv32KC2/`
- **Purpose**: Defines the platform for PlatformIO
- **Usage**: Installed to `~/.platformio/platforms/riscv32KC2` for PlatformIO use

### `software/Project_riscv32KC2/`
The main project directory:
- **Location**: `software/Project_riscv32KC2/`
- **Purpose**: Contains project-specific source code and configuration
- **Build Output**: `build/` directory

## Path References

### In `compile_manual.bat`
- Framework path: `%~dp0..\framework\framework-riscv32KC2-sdk`
  - `%~dp0` = Project directory (`software/Project_riscv32KC2/`)
  - `..\framework` = Goes up to `software/` then into `framework/`

### In `platformio.ini`
- Platform: `riscv32KC2` (installed to PlatformIO platforms directory)
- Framework: `riscv32KC2-sdk` (installed to PlatformIO packages directory)

## Benefits of This Structure

1. **Shared Resources**: Framework and platform can be reused by multiple projects
2. **Clean Separation**: Project code is separate from framework/platform code
3. **Easy Updates**: Update framework/platform once, affects all projects
4. **Standard Layout**: Follows common embedded project organization

## Adding New Projects

To create a new project:

1. Create new directory: `software/Project_new_name/`
2. Copy `platformio.ini` and modify project name
3. Create `src/` directory with your source files
4. Framework and platform are already available at `../framework/` and `../platform/`

## Installation

When installing for PlatformIO:

1. Copy `software/platform/riscv32KC2/` â†’ `~/.platformio/platforms/riscv32KC2`
2. Copy `software/framework/framework-riscv32KC2-sdk/` â†’ `~/.platformio/packages/framework-riscv32KC2-sdk`

See `INSTALLATION.md` for detailed instructions.











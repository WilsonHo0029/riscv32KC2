# Installation Guide for AI RISC-V KC32 Platform and Framework

This guide explains how to install the custom PlatformIO platform and framework for the AI RISC-V KC32 System.

## Prerequisites

- PlatformIO IDE or CLI installed
- Python 3.x
- Git (optional)

## Installation Steps

### Step 1: Install the Platform

Copy the platform directory to PlatformIO's platforms directory:

**Windows:**
```powershell
# Navigate to software directory
cd software

# Copy platform to PlatformIO directory
xcopy /E /I platform\riscv32KC2 C:\Users\<your_username>\.platformio\platforms\riscv32KC2
```

**Linux/Mac:**
```bash
# Navigate to software directory
cd software

# Copy platform to PlatformIO directory
cp -r platform/riscv32KC2 ~/.platformio/platforms/riscv32KC2
```

### Step 2: Install the Framework

Copy the framework directory to PlatformIO's packages directory:

**Windows:**
```powershell
# From software directory, copy framework to PlatformIO directory
xcopy /E /I framework\framework-riscv32KC2-sdk C:\Users\<your_username>\.platformio\packages\framework-riscv32KC2-sdk
```

**Linux/Mac:**
```bash
# From software directory, copy framework to PlatformIO directory
cp -r framework/framework-riscv32KC2-sdk ~/.platformio/packages/framework-riscv32KC2-sdk
```

### Step 3: Verify Installation

Check that PlatformIO recognizes the platform:

```bash
pio platform list | grep riscv32KC2
```

You should see:
```
riscv32KC2                   0.1.0
```

### Step 4: Update Project Configuration

Your `platformio.ini` should already be configured:

```ini
[env:riscv32KC2]
platform = riscv32KC2
board = riscv32KC2
framework = riscv32KC2-sdk
```

### Step 5: Build the Project

```bash
cd software/Project_riscv32KC2
pio run
```

## Alternative: Using Local Framework (Development)

If you're actively developing the framework, you can reference it locally without copying:

```ini
[env:riscv32KC2]
platform = riscv32KC2
board = riscv32KC2
framework = riscv32KC2-sdk
platform_packages = 
    framework-riscv32KC2-sdk = file://../framework/framework-riscv32KC2-sdk
```

## Troubleshooting

### Platform Not Found

If PlatformIO doesn't recognize the platform:

1. Verify the platform directory structure:
   ```
   .platformio/platforms/riscv32KC2/
   â”œâ”€â”€ platform.json
   â”œâ”€â”€ platform.py
   â”œâ”€â”€ boards/
   â””â”€â”€ builder/
   ```

2. Check `platform.json` syntax is valid JSON

3. Restart PlatformIO IDE or run `pio platform update`

### Framework Not Found

If the framework is not found:

1. Verify the framework directory exists:
   ```
   .platformio/packages/framework-riscv32KC2-sdk/
   â”œâ”€â”€ package.json
   â””â”€â”€ bsp/
   ```

2. Check `package.json` syntax

3. Try cleaning and rebuilding:
   ```bash
   pio run --target clean
   pio run
   ```

### Build Errors

If you encounter build errors:

1. Ensure `toolchain-riscv32KC2` is installed:
   ```bash
   pio platform install riscv32KC2
   ```

2. Check that all required files exist:
   - `bsp/env/start.S`
   - `bsp/env/init.c`
   - `bsp/include/encoding.h`
   - `bsp/include/platform.h`

3. Verify linker script path in `platformio.ini`

## Uninstallation

To remove the platform and framework:

**Windows:**
```powershell
rmdir /S C:\Users\<your_username>\.platformio\platforms\riscv32KC2
rmdir /S C:\Users\<your_username>\.platformio\packages\framework-riscv32KC2-sdk
```

**Linux/Mac:**
```bash
rm -rf ~/.platformio/platforms/riscv32KC2
rm -rf ~/.platformio/packages/framework-riscv32KC2-sdk
```

## Next Steps

After installation:

1. Review the project README.md
2. Build the example project
3. Configure OpenOCD for your JTAG adapter
4. Start developing!



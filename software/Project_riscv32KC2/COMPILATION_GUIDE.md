# Compilation Guide for AI RISC-V KC32 Project

This guide explains how to compile the `main.c` file for the AI RISC-V KC32 System.

## Method 1: Using PlatformIO (Recommended)

### Prerequisites
- PlatformIO IDE (VS Code extension) or PlatformIO Core installed
- Platform and framework installed (see INSTALLATION.md)

### Steps

1. **Open the project in PlatformIO**:
   ```bash
   cd software/Project_riscv32KC2
   ```

2. **Build the project**:
   ```bash
   pio run
   ```
   
   Or if using PlatformIO IDE:
   - Click the "Build" button in the PlatformIO toolbar
   - Or use the command palette: `PlatformIO: Build`

3. **Check output**:
   - Compiled binary: `.pio/build/riscv32KC2/firmware.elf`
   - Binary file: `.pio/build/riscv32KC2/firmware.bin`
   - Hex file: `.pio/build/riscv32KC2/firmware.hex`

### Troubleshooting PlatformIO

If PlatformIO is not found:

1. **Install PlatformIO Core**:
   ```bash
   pip install platformio
   ```

2. **Or install PlatformIO IDE**:
   - VS Code: Install "PlatformIO IDE" extension
   - Atom: Install "platformio-ide" package

3. **Verify installation**:
   ```bash
   pio --version
   ```

## Method 2: Manual Compilation (Alternative)

If PlatformIO is not available, you can compile manually using the GCC toolchain.

### Prerequisites
- RISC-V GCC toolchain installed
- Toolchain location: `C:\Users\wilson\.platformio\packages\toolchain-riscv32KC2\bin`

### Quick Build (Using Script)

1. **Run the build script**:
   ```bash
   compile_manual.bat
   ```

   This will:
   - Compile all source files
   - Link them together
   - Generate ELF, BIN, HEX, and disassembly files

### Manual Build Steps

If you prefer to compile manually:

1. **Set environment variables**:
   ```batch
set TOOLCHAIN=C:\Users\wilson\.platformio\packages\toolchain-riscv\bin
set PREFIX=%TOOLCHAIN%\riscv-none-elf-
   set FRAMEWORK=%~dp0framework\framework-riscv32KC2-sdk
   ```

2. **Compile startup code**:
   ```batch
   %PREFIX%gcc.exe -march=rv32imc -mabi=ilp32 -mcmodel=medany -c %FRAMEWORK%\bsp\env\start.S -o start.o
   ```

3. **Compile initialization**:
   ```batch
   %PREFIX%gcc.exe -march=rv32imc -mabi=ilp32 -mcmodel=medany -I%FRAMEWORK%\bsp\include -c %FRAMEWORK%\bsp\env\init.c -o init.o
   ```

4. **Compile UART driver**:
   ```batch
   %PREFIX%gcc.exe -march=rv32imc -mabi=ilp32 -mcmodel=medany -I%FRAMEWORK%\bsp\include -c %FRAMEWORK%\bsp\src\uart.c -o uart.o
   ```

5. **Compile main.c**:
   ```batch
   %PREFIX%gcc.exe -march=rv32imc -mabi=ilp32 -mcmodel=medany -I%FRAMEWORK%\bsp\include -Isrc -c src\main.c -o main.o
   ```

6. **Link everything**:
   ```batch
   %PREFIX%gcc.exe -march=rv32imc -mabi=ilp32 -mcmodel=medany -Tlinker.lds -nostartfiles --specs=nano.specs --specs=nosys.specs -Wl,--gc-sections -o firmware.elf start.o init.o uart.o main.o
   ```

7. **Generate binary**:
   ```batch
   %PREFIX%objcopy.exe -O binary firmware.elf firmware.bin
   %PREFIX%objcopy.exe -O ihex firmware.elf firmware.hex
   ```

## Method 3: Using Build Scripts

### Windows

1. **Quick build**:
   ```batch
   build.bat
   ```
   This script will try PlatformIO first, then fall back to manual compilation.

2. **Manual build**:
   ```batch
   compile_manual.bat
   ```
   This script compiles using the GCC toolchain directly.

## Common Compilation Issues

### Issue 1: "Platform not found"

**Solution**: Install the platform first (see INSTALLATION.md)
```bash
# Copy platform to PlatformIO directory
xcopy /E /I platform\riscv32KC2 %USERPROFILE%\.platformio\platforms\riscv32KC2
```

### Issue 2: "Framework not found"

**Solution**: Install the framework
```bash
# Copy framework to PlatformIO directory
xcopy /E /I framework\framework-riscv32KC2-sdk %USERPROFILE%\.platformio\packages\framework-riscv32KC2-sdk
```

### Issue 3: "Toolchain not found"

**Solution**: The toolchain should be auto-installed by PlatformIO. If not:
```bash
pio platform install riscv32KC2
```

### Issue 4: Missing header files

**Error**: `fatal error: metal/uart.h: No such file or directory`

**Solution**: Ensure the framework is installed and include paths are correct:
- Framework should be at: `%USERPROFILE%\.platformio\packages\framework-riscv32KC2-sdk`
- Or update `platformio.ini` to use local framework path

### Issue 5: Linker errors

**Error**: `undefined reference to 'metal_get_uart'`

**Solution**: Ensure UART driver is compiled and linked:
- Check that `uart.c` is being compiled
- Verify linker script includes all necessary sections

## Compiler Flags Explained

- `-march=rv32imc`: Target RISC-V 32-bit with I, M, C extensions
- `-mabi=ilp32`: Use 32-bit integer, long, and pointer ABI
- `-mcmodel=medany`: Medium code model (for position-independent code)
- `-ffunction-sections`: Place each function in its own section
- `-fdata-sections`: Place each data item in its own section
- `-Wl,--gc-sections`: Remove unused sections during linking
- `-nostartfiles`: Don't use standard startup files (we provide our own)
- `--specs=nano.specs`: Use newlib-nano (smaller library)
- `--specs=nosys.specs`: No system calls (bare metal)

## Output Files

After successful compilation:

- **firmware.elf**: ELF executable (for debugging)
- **firmware.bin**: Raw binary (for flashing)
- **firmware.hex**: Intel HEX format (for flashing)
- **firmware.dis**: Disassembly listing (for analysis)

## Next Steps

After compilation:

1. **Upload to target**: Use OpenOCD or your debugger
2. **Debug**: Use GDB with OpenOCD
3. **Monitor**: Use serial monitor to see UART output

## Getting Help

If you encounter issues:

1. Check `INSTALLATION.md` for platform/framework setup
2. Review `PLATFORMIO_PACKAGES_ANALYSIS.md` for package information
3. Check build output for specific error messages
4. Verify all paths are correct



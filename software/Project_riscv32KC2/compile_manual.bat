@echo off
setlocal enabledelayedexpansion
REM Manual compilation script for AI RISC-V KC32
REM Uses GCC toolchain directly without PlatformIO

echo ========================================
echo Manual Compilation Script
echo RISC-V 32KC2 Project
echo ========================================
echo.

REM Set toolchain path
set TOOLCHAIN_DIR=C:\Users\Bisma\.platformio\packages\toolchain-riscv\bin
set TOOLCHAIN_PREFIX=%TOOLCHAIN_DIR%\riscv-none-elf-

REM Set framework path (relative to software folder)
set FRAMEWORK_DIR=%~dp0..\framework\framework-riscv32KC2-sdk
set LIBWRAP_DIR=%FRAMEWORK_DIR%\bsp\libwrap

REM Check if toolchain exists
if not exist "%TOOLCHAIN_PREFIX%gcc.exe" (
    echo ERROR: Toolchain not found at %TOOLCHAIN_DIR%
    echo Please install the toolchain or update TOOLCHAIN_DIR in this script
    pause
    exit /b 1
)

echo Toolchain found: %TOOLCHAIN_DIR%
echo Framework: %FRAMEWORK_DIR%
echo Libwrap: %LIBWRAP_DIR%
echo.

REM Create build directory
if not exist "build" mkdir build
if not exist "build\obj" mkdir build\obj

REM Compiler flags - match hardware architecture (removed 'a' for atomic)
set CFLAGS=-march=rv32imc_zicsr_zifencei -mabi=ilp32 -mcmodel=medany -ffunction-sections -fdata-sections -Wall -Wextra -Os -g
set CFLAGS=%CFLAGS% -fno-builtin-printf -fno-builtin-malloc

REM Add include directories - recursively find all subdirectories in bsp\include
echo Adding include directories...
set CFLAGS=%CFLAGS% -I"%FRAMEWORK_DIR%\bsp\include"
for /d /r "%FRAMEWORK_DIR%\bsp\include" %%d in (*) do (
    set CFLAGS=!CFLAGS! -I"%%d"
)
set CFLAGS=%CFLAGS% -I"%FRAMEWORK_DIR%\bsp\env"
set CFLAGS=%CFLAGS% -I"%~dp0src" -I"%~dp0include"

set ASFLAGS=%CFLAGS%

REM Linker flags - must match CFLAGS architecture
set LDFLAGS=-march=rv32imc_zicsr_zifencei -mabi=ilp32 -mcmodel=medany -T"%~dp0linker.lds"
set LDFLAGS=%LDFLAGS% -nostartfiles --specs=nano.specs --specs=nosys.specs
set LDFLAGS=%LDFLAGS% -Wl,--gc-sections -Wl,--wrap=scanf -Wl,--wrap=malloc -Wl,--wrap=printf
set LDFLAGS=%LDFLAGS% -Wl,--check-sections -u _isatty -u _write

echo Compiling startup code...
"%TOOLCHAIN_PREFIX%gcc.exe" %ASFLAGS% -c "%FRAMEWORK_DIR%\bsp\env\start.S" -o "build\obj\start.o"
if %ERRORLEVEL% NEQ 0 goto :error

echo Compiling trap entry code...
"%TOOLCHAIN_PREFIX%gcc.exe" %ASFLAGS% -c "%FRAMEWORK_DIR%\bsp\env\entry.S" -o "build\obj\entry.o"
if %ERRORLEVEL% NEQ 0 goto :error

REM Compile all .c files in bsp\env directory
echo Compiling framework environment files...
for %%f in ("%FRAMEWORK_DIR%\bsp\env\*.c") do (
    echo   Compiling %%~nxf...
    "%TOOLCHAIN_PREFIX%gcc.exe" %CFLAGS% -c "%%f" -o "build\obj\%%~nf.o"
    if !ERRORLEVEL! NEQ 0 goto :error
)

REM Compile all .c files in bsp\src directory
echo Compiling framework source files...
for %%f in ("%FRAMEWORK_DIR%\bsp\src\*.c") do (
    echo   Compiling %%~nxf...
    "%TOOLCHAIN_PREFIX%gcc.exe" %CFLAGS% -c "%%f" -o "build\obj\%%~nf.o"
    if !ERRORLEVEL! NEQ 0 goto :error
)

REM Compile all .c files in libwrap subdirectories
echo Compiling libwrap files...
for /r "%LIBWRAP_DIR%" %%f in (*.c) do (
    echo   Compiling %%~nxf...
    "%TOOLCHAIN_PREFIX%gcc.exe" %CFLAGS% -c "%%f" -o "build\obj\%%~nf.o"
    if !ERRORLEVEL! NEQ 0 goto :error
)

REM Compile all .c files in project src directory
echo Compiling project source files...
for %%f in ("%~dp0src\*.c") do (
    echo   Compiling %%~nxf...
    "%TOOLCHAIN_PREFIX%gcc.exe" %CFLAGS% -c "%%f" -o "build\obj\%%~nf.o"
    if !ERRORLEVEL! NEQ 0 goto :error
)

echo Linking...
REM Collect all object files for linking (start.o and entry.o first, then all others)
set OBJ_FILES=build\obj\start.o build\obj\entry.o
for %%f in (build\obj\*.o) do (
    set "fname=%%f"
    if /i not "!fname!"=="build\obj\start.o" if /i not "!fname!"=="build\obj\entry.o" (
        set OBJ_FILES=!OBJ_FILES! %%f
    )
)
"%TOOLCHAIN_PREFIX%gcc.exe" %LDFLAGS% -o "build\firmware.elf" %OBJ_FILES%
if %ERRORLEVEL% NEQ 0 goto :error

echo.
echo ========================================
echo Build successful!
echo Output: build\firmware.elf
echo ========================================
echo.

REM Generate additional files
echo Generating binary...
"%TOOLCHAIN_PREFIX%objcopy.exe" -O binary "build\firmware.elf" "build\firmware.bin"

echo Generating hex...
"%TOOLCHAIN_PREFIX%objcopy.exe" -O ihex "build\firmware.elf" "build\firmware.hex"

echo Generating disassembly...
"%TOOLCHAIN_PREFIX%objdump.exe" -d "build\firmware.elf" > "build\firmware.dis"

echo Generating size information...
"%TOOLCHAIN_PREFIX%size.exe" "build\firmware.elf"

REM Generate Verilog and dump files using tools from software\tools
set TOOLS_DIR=%~dp0..\tools
if exist "%TOOLS_DIR%\objcopy.exe" (
    REM Create firmware_output directory
    if not exist "firmware_output" mkdir firmware_output
    
    echo Generating firmware.verilog...
    "%TOOLS_DIR%\objcopy.exe" -O verilog "build\firmware.elf" "firmware_output\firmware.verilog"
    
    echo Generating firmware.dump...
    "%TOOLS_DIR%\objdump.exe" -S "build\firmware.elf" > "firmware_output\firmware.dump"
    
    REM Process verilog file to replace @any_address with @0 and rename to riscv32KC2_instr.verilog
    echo Processing firmware.verilog - replacing address with @0...
    if exist firmware_output\firmware.verilog (
        powershell -ExecutionPolicy Bypass -Command "$content = Get-Content firmware_output\firmware.verilog -Raw; $content = $content -replace '@[0-9a-fA-F]','@0'; Set-Content -Path firmware_output\riscv32KC2_instr.verilog -Value $content -NoNewline"
    )
    
    echo Verilog and dump files generated successfully in firmware_output!
) else (
    echo Warning: Tools not found at %TOOLS_DIR%, skipping Verilog/dump generation
    echo Run conv_firmware.bat manually after build to generate these files
)

echo.
echo Build complete! Files generated:
dir /b build\*.elf build\*.bin build\*.hex 2>nul
if exist firmware_output\firmware.verilog echo   firmware_output\firmware.verilog
if exist firmware_output\firmware.dump echo   firmware_output\firmware.dump
if exist firmware_output\riscv32KC2_instr.verilog echo   firmware_output\riscv32KC2_instr.verilog

goto :end

:error
echo.
echo ========================================
echo BUILD FAILED!
echo ========================================
echo.
pause
exit /b 1

:end
pause

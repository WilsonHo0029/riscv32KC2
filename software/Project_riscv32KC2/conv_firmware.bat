@echo off
REM Convert firmware.elf to firmware.dump and riscv32KC2_instr.verilog
REM Uses objcopy.exe and objdump.exe from software\tools

echo ========================================
echo Converting firmware to Verilog format
echo ========================================
echo.

REM Set tools path
set TOOLS_DIR=%~dp0..\tools

REM Check if tools exist
if not exist "%TOOLS_DIR%\objcopy.exe" (
    echo ERROR: objcopy.exe not found at %TOOLS_DIR%
    pause
    exit /b 1
)

if not exist "%TOOLS_DIR%\objdump.exe" (
    echo ERROR: objdump.exe not found at %TOOLS_DIR%
    pause
    exit /b 1
)

REM Check if firmware.elf exists
if not exist "build\firmware.elf" (
    echo ERROR: build\firmware.elf not found
    echo Please compile the project first using compile_manual.bat
    pause
    exit /b 1
)

REM Create firmware_output directory
if not exist "firmware_output" mkdir firmware_output

REM Generate temporary firmware.verilog for processing
echo Generating temporary firmware.verilog...
"%TOOLS_DIR%\objcopy.exe" -O verilog build\firmware.elf firmware_output\firmware.verilog
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to generate firmware.verilog
    pause
    exit /b 1
)

echo Generating firmware.dump...
"%TOOLS_DIR%\objdump.exe" -S build\firmware.elf > firmware_output\firmware.dump
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to generate firmware.dump
    pause
    exit /b 1
)

REM Process verilog file to replace any @address with @0 and rename to riscv32KC2_instr.verilog
echo Processing firmware.verilog (replacing address prefix with @0)...
powershell -ExecutionPolicy Bypass -Command "$content = Get-Content firmware_output\firmware.verilog -Raw; $content = $content -replace '@[0-9a-fA-F]','@0'; Set-Content -Path firmware_output\riscv32KC2_instr.verilog -Value $content -NoNewline"

REM Delete temporary firmware.verilog file
if exist firmware_output\firmware.verilog del firmware_output\firmware.verilog

echo.
echo ========================================
echo Conversion successful!
echo ========================================
echo.
echo Generated files in firmware_output\:
echo   - firmware.dump
echo   - riscv32KC2_instr.verilog
echo.

pause

@echo off
REM PlatformIO Compilation Script for AI RISC-V KC32
REM Uses the main.py builder to compile the project

echo ========================================
echo PlatformIO Compilation Script
echo AI RISC-V KC32 Project
echo ========================================
echo.

REM Get the script directory
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%
set PLATFORM_DIR=%SCRIPT_DIR%..\platform\riscv32KC2

REM Check if PlatformIO is available
set PIO_CMD=
if exist "%USERPROFILE%\.platformio\penv\Scripts\pio.exe" (
    set PIO_CMD=%USERPROFILE%\.platformio\penv\Scripts\pio.exe
    echo Found PlatformIO Core at: %PIO_CMD%
) else if exist "%USERPROFILE%\.platformio\penv\Scripts\platformio.exe" (
    set PIO_CMD=%USERPROFILE%\.platformio\penv\Scripts\platformio.exe
    echo Found PlatformIO Core at: %PIO_CMD%
) else (
    REM Try to find pio in PATH
    where pio >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        set PIO_CMD=pio
        echo Found PlatformIO in PATH
    ) else (
        echo ERROR: PlatformIO not found!
        echo.
        echo Please install PlatformIO Core or add it to your PATH.
        echo You can install it from: https://platformio.org/install/cli
        echo.
        echo Alternatively, use compile_manual.bat for manual compilation.
        pause
        exit /b 1
    )
)

echo.
echo Project Directory: %PROJECT_DIR%
echo Platform Directory: %PLATFORM_DIR%
echo.

REM Change to project directory
cd /d "%PROJECT_DIR%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Cannot change to project directory
    pause
    exit /b 1
)

REM Check if platform directory exists
if not exist "%PLATFORM_DIR%" (
    echo ERROR: Platform directory not found at: %PLATFORM_DIR%
    pause
    exit /b 1
)

REM Check if main.py exists
if not exist "%PLATFORM_DIR%\builder\main.py" (
    echo ERROR: main.py builder not found at: %PLATFORM_DIR%\builder\main.py
    pause
    exit /b 1
)

echo ========================================
echo Using Local Platform and Framework
echo ========================================
echo.
echo Platform: Using local platform from platformio.ini
echo Framework: Using local framework from platform_packages
echo.
echo NOTE: PlatformIO will use local files directly (no installation)
echo.

echo ========================================
echo Building Project
echo ========================================
echo.

REM Build the project
echo Running: %PIO_CMD% run
echo.
"%PIO_CMD%" run
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo BUILD FAILED!
    echo ========================================
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build Successful!
echo ========================================
echo.

REM Show size information
echo Running size command...
"%PIO_CMD%" run -t size
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Size command failed, but build was successful
)

echo.
echo ========================================
echo Build Output Files
echo ========================================
echo.

REM Check for output files
set BUILD_DIR=.pio\build\riscv32KC2
if exist "%BUILD_DIR%\firmware.elf" (
    echo   ELF: %BUILD_DIR%\firmware.elf
)
if exist "%BUILD_DIR%\firmware.hex" (
    echo   HEX: %BUILD_DIR%\firmware.hex
)
if exist "%BUILD_DIR%\firmware.bin" (
    echo   BIN: %BUILD_DIR%\firmware.bin
)
if exist "%BUILD_DIR%\firmware.verilog" (
    echo   Verilog: %BUILD_DIR%\firmware.verilog
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo To upload firmware, run:
echo   %PIO_CMD% run -t upload
echo.
echo To clean build files, run:
echo   %PIO_CMD% run -t clean
echo.

pause



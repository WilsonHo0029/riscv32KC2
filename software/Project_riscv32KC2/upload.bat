@echo off
setlocal enabledelayedexpansion
REM Upload script for RISC-V 32KC2 Project
REM Uses OpenOCD to upload firmware.elf via JTAG
REM Based on platformio.ini upload_command

echo ========================================
echo RISC-V 32KC2 Upload Script
echo ========================================
echo.

REM Set script directory
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%

REM Default interface
set INTERFACE=ftdi

REM Parse arguments
:args_loop
if "%~1"=="" goto :args_done
if /i "%~1"=="-i" (
    set INTERFACE=%~2
    shift
    shift
    goto :args_loop
)
shift
goto :args_loop
:args_done

REM Check if firmware.elf exists
set FIRMWARE_ELF=%PROJECT_DIR%build\firmware.elf
if not exist "%FIRMWARE_ELF%" (
    echo ERROR: firmware.elf not found at %FIRMWARE_ELF%
    echo Please build the project first using build.bat or compile_manual.bat
    echo.
    pause
    exit /b 1
)

echo Firmware found: %FIRMWARE_ELF%
echo.

REM Try to find OpenOCD
set OPENOCD_EXE=

REM First, try PlatformIO packages (most common location)
set PIO_PACKAGES_DIR=%USERPROFILE%\.platformio\packages
set OPENOCD_PIO=%PIO_PACKAGES_DIR%\tool-openocd\bin\openocd.exe
if exist "%OPENOCD_PIO%" (
    set OPENOCD_EXE=%OPENOCD_PIO%
    echo Found OpenOCD at: %OPENOCD_EXE%
    goto :found_openocd
)

REM Try other common PlatformIO OpenOCD locations
for %%d in (tool-openocd tool-openocd-riscv) do (
    set TEST_PATH=%PIO_PACKAGES_DIR%\%%d\bin\openocd.exe
    if exist "!TEST_PATH!" (
        set OPENOCD_EXE=!TEST_PATH!
        echo Found OpenOCD at: !OPENOCD_EXE!
        goto :found_openocd
    )
)

REM Try system OpenOCD
where openocd >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set OPENOCD_EXE=openocd
    echo Found OpenOCD in PATH
    goto :found_openocd
)

REM Try common installation locations
set OPENOCD_PATHS[0]=C:\Program Files\OpenOCD\bin\openocd.exe
set OPENOCD_PATHS[1]=C:\OpenOCD\bin\openocd.exe
set OPENOCD_PATHS[2]=%USERPROFILE%\OpenOCD\bin\openocd.exe

for %%p in ("%OPENOCD_PATHS[0]%" "%OPENOCD_PATHS[1]%" "%OPENOCD_PATHS[2]%") do (
    if exist %%p (
        set OPENOCD_EXE=%%p
        echo Found OpenOCD at: %%p
        goto :found_openocd
    )
)

echo.
echo ERROR: OpenOCD not found!
echo.
echo Please install OpenOCD or ensure it's in your PATH.
echo.
echo Options:
echo 1. Install via PlatformIO (recommended): platformio will install it automatically
echo 2. Install OpenOCD manually: https://openocd.org/pages/getting-openocd.html
echo 3. Add OpenOCD to your system PATH
echo.
pause
exit /b 1

:found_openocd
echo.

REM Set config file based on interface
if /i "!INTERFACE!"=="jlink" (
    set OPENOCD_CFG=%PROJECT_DIR%openocd_jlink.cfg
) else if /i "!INTERFACE!"=="ftdi" (
    set OPENOCD_CFG=%PROJECT_DIR%openocd_ftdi.cfg
) else (
    set OPENOCD_CFG=%PROJECT_DIR%openocd.cfg
)

if not exist "%OPENOCD_CFG%" (
    echo ERROR: OpenOCD config file not found at %OPENOCD_CFG%
    echo.
    pause
    exit /b 1
)

echo OpenOCD config: %OPENOCD_CFG%
echo.

REM Convert Windows paths to forward slashes for OpenOCD
REM OpenOCD on Windows requires forward slashes in paths
set "OPENOCD_CFG_FORWARD=!OPENOCD_CFG:\=/!"
set "FIRMWARE_ELF_FORWARD=!FIRMWARE_ELF:\=/!"

echo ========================================
echo Starting firmware upload...
echo ========================================
echo.
echo Using firmware: %FIRMWARE_ELF_FORWARD%
echo.

REM Execute OpenOCD with upload commands
REM Note: Core internal IRAM starts at 0x80000000 according to RTL checks.

"%OPENOCD_EXE%" ^
    -f "%OPENOCD_CFG_FORWARD%" ^
	-c "reset halt" ^
    -c "load_image \"%FIRMWARE_ELF_FORWARD%\"" ^
    -c "verify_image \"%FIRMWARE_ELF_FORWARD%\"" ^
    -c "resume 0x80000000" ^
    -c "shutdown"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo UPLOAD FAILED!
    echo ========================================
    echo.
    echo Possible issues:
    echo - JTAG adapter not connected
    echo - Wrong adapter configuration in !OPENOCD_CFG!
    echo - Target not powered on
    echo - OpenOCD configuration error
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Upload successful!
echo Firmware loaded and execution resumed at 0x80000000
echo ========================================
echo.
pause

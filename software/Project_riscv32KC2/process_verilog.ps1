# PowerShell script to process firmware.verilog
# Replaces @8 with @0 (for instruction memory address) and saves as riscv32KC2_instr.verilog

$content = Get-Content firmware.verilog -Raw
$content = $content -replace '@8','@0'
Set-Content -Path riscv32KC2_instr.verilog -Value $content -NoNewline



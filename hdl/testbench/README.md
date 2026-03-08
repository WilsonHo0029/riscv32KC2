# Testbench for riscv32KC2_system

## Overview

This testbench provides basic testing infrastructure for the `riscv32KC2_system` module.

## Files

- `tb_riscv32KC2_system.v` - Main testbench module
- `riscv32KC2.args` - Simulation arguments file (for use with simulators)

## Usage

### Simulation with Verilator

Using the args file:
```bash
verilator --cc --exe --build -j 0 -Wall -f riscv32KC2.args
```

Or manually:
```bash
verilator --cc --exe --build -j 0 -Wall \
    -I../rtl/riscv_core \
    -I../rtl/debug_module \
    -I../rtl/bus \
    -I../rtl/ram \
    -I../rtl/misc \
    -I../rtl/riscv32KC2_system \
    tb_riscv32KC2_system.v \
    ../rtl/riscv32KC2_system/*.v \
    ../rtl/riscv_core/*.v \
    ../rtl/debug_module/*.v \
    ../rtl/bus/*.v \
    ../rtl/ram/*.v \
    ../rtl/misc/*.v
```

### Simulation with ModelSim/QuestaSim

Using the args file:
```tcl
# Read args file and compile
do riscv32KC2.args
# Or manually process the args file
```

Or manually:
```tcl
# Compile files
vlog -work work +incdir+../rtl/riscv_core \
     +incdir+../rtl/debug_module \
     +incdir+../rtl/bus \
     +incdir+../rtl/ram \
     +incdir+../rtl/misc \
     +incdir+../rtl/riscv32KC2_system \
     ../rtl/riscv_core/*.v \
     ../rtl/debug_module/*.v \
     ../rtl/bus/*.v \
     ../rtl/ram/*.v \
     ../rtl/misc/*.v \
     ../rtl/riscv32KC2_system/*.v \
     tb_riscv32KC2_system.v

# Run simulation
vsim -voptargs=+acc work.tb_riscv32KC2_system
run -all
```

### Simulation with Icarus Verilog

Using the args file:
```bash
iverilog -g2012 -f riscv32KC2.args -o tb_riscv32KC2_system.vvp
vvp tb_riscv32KC2_system.vvp
```

Or manually:
```bash
iverilog -g2012 \
    -I../rtl/riscv_core \
    -I../rtl/debug_module \
    -I../rtl/bus \
    -I../rtl/ram \
    -I../rtl/misc \
    -I../rtl/riscv32KC2_system \
    -o tb_riscv32KC2_system.vvp \
    ../rtl/riscv_core/*.v \
    ../rtl/debug_module/*.v \
    ../rtl/bus/*.v \
    ../rtl/ram/*.v \
    ../rtl/misc/*.v \
    ../rtl/riscv32KC2_system/*.v \
    tb_riscv32KC2_system.v

vvp tb_riscv32KC2_system.vvp
```

## Testbench Features

### Clock Generation
- System clock: 100MHz (10ns period)
- JTAG clock: 10MHz (100ns period)

### Reset Generation
- Active low reset (sys_rst_n)
- Reset pulse: 100ns
- Reset release delay: 100ns after assertion

### Signal Monitoring
- Basic signal monitoring for reset and JTAG
- Can be expanded to monitor internal signals

### Waveform Output
- VCD file: `tb_riscv32KC2_system.vcd`
- Can be viewed with GTKWave or other waveform viewers

## Test Program

The testbench includes a simple test program:
- `ADDI x1, x0, 5` - Load immediate value 5 into register x1
- `ADD x2, x1, x1` - Add x1 to x1, store in x2
- `SW x2, 0(x0)` - Store x2 to address 0
- `LW x3, 0(x0)` - Load from address 0 into x3
- `JAL x0, 0` - Infinite loop (branch to self)

## Future Enhancements

For a complete testbench, consider adding:

1. **Memory Initialization**
   - Load instruction memory through debug interface
   - Initialize data memory if needed

2. **Instruction Execution Monitoring**
   - Monitor PC value
   - Check register file contents
   - Verify memory contents

3. **Debug Interface Testing**
   - JTAG protocol implementation
   - Debug commands (halt, resume, step)
   - Register and memory access through debug interface

4. **Bus Transaction Monitoring**
   - Monitor AXI transactions
   - Monitor APB transactions
   - Verify address routing

5. **Self-Checking Tests**
   - Compare actual vs expected results
   - Assertion-based verification
   - Automatic pass/fail reporting

## Notes

- The current testbench is a basic framework
- Memory initialization requires access to internal signals or debug interface
- For production use, implement proper memory loading mechanisms
- Consider using SystemVerilog for more advanced verification features

## Related Documentation

- See `../README.md` for a high-level overview of the HDL directory
- See `../rtl/riscv_core/README.md` for core implementation details
- See `../rtl/riscv32KC2_system/README.md` for system integration details
- See `../../VERILOG_CODE_ANALYSIS.md` for code quality analysis




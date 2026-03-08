transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../ipstatic" "+incdir+E:/Xilinx/2025.2/Vivado/data/rsb/busdef" "+incdir+../../../../riscv32KC2.gen/sources_1/ip/riscv32KC2_fpga_pll_1" -l xpm -l xil_defaultlib \
"E:/Xilinx/2025.2/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  -incr \
"E:/Xilinx/2025.2/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../ipstatic" "+incdir+E:/Xilinx/2025.2/Vivado/data/rsb/busdef" "+incdir+../../../../riscv32KC2.gen/sources_1/ip/riscv32KC2_fpga_pll_1" -l xpm -l xil_defaultlib \
"../../../../riscv32KC2.gen/sources_1/ip/riscv32KC2_fpga_pll_1/riscv32KC2_fpga_pll_clk_wiz.v" \
"../../../../riscv32KC2.gen/sources_1/ip/riscv32KC2_fpga_pll_1/riscv32KC2_fpga_pll.v" \

vlog -work xil_defaultlib \
"glbl.v"


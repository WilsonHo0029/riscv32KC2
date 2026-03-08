vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../ipstatic" "+incdir+E:/Xilinx/2025.2/Vivado/data/rsb/busdef" "+incdir+../../../../riscv32KC2.gen/sources_1/ip/riscv32KC2_fpga_pll_1" \
"E:/Xilinx/2025.2/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm  -93  \
"E:/Xilinx/2025.2/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../ipstatic" "+incdir+E:/Xilinx/2025.2/Vivado/data/rsb/busdef" "+incdir+../../../../riscv32KC2.gen/sources_1/ip/riscv32KC2_fpga_pll_1" \
"../../../../riscv32KC2.gen/sources_1/ip/riscv32KC2_fpga_pll_1/riscv32KC2_fpga_pll_clk_wiz.v" \
"../../../../riscv32KC2.gen/sources_1/ip/riscv32KC2_fpga_pll_1/riscv32KC2_fpga_pll.v" \

vlog -work xil_defaultlib \
"glbl.v"


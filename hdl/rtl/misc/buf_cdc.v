module buf_cdc#(
  parameter DW = 32
)(
	input  clk,
	input  rst_n,
// TX
	
// RX

);

buf_cdc_tx
(
	.DW(DW)
)u_tx(
  input  i_vld, 
  output i_rdy, 
  input  [DW-1:0] i_dat,

  output o_vld, 
  input  o_rdy_a, 
  output [DW-1:0] o_dat,

  input  clk,
  input  rst_n 
);

buf_cdc_rx# (
  .DW(DW)
)u_rx(
  input  i_vld_a, 
  output i_rdy, 
  input  [DW-1:0] i_dat,
  output o_vld, 
  input  o_rdy, 
  output [DW-1:0] o_dat,

  input  clk,
  input  rst_n 

);


endmodule
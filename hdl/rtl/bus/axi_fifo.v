module axi_fifo#(
	parameter DW = 4
)(
	input	clk,
	input	rst_n,
	
	input	[DW-1:0] data_i,
	input	push_i,
	output	empty_o,
	
	output	[DW-1:0] data_o,
	input	pop_i

);

reg [DW-1:0] data;
reg 	     empty;
assign data_o = data;
assign empty_o = empty;

always@(posedge clk or negedge rst_n)
	if(~rst_n) begin
		data <= {DW{1'b0}};
		empty <= 1'b1;
	end
	else begin
		if(push_i & empty) begin
			data <= data_i;
			empty <= 1'b0;
		end
		else if(pop_i & ~empty) begin
			data <= {DW{1'b0}};
			empty <= 1'b1;
		end
	end
endmodule

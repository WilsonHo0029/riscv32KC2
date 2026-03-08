//----------------------------------------------------------------------------------
//          File name       : uart_rxd_model.v
//          Description     : uart receive Logic
//
//
// Revision History:
// ==================================================================================
// Rev		Date				Author		Note
// ==================================================================================
// 1.0.0		2023.09.13		Wilson Ho
// ==================================================================================
`timescale 1ps/1ps
module uart_rxd_model #(
	parameter BAUD_RATE = 115200	
)(
   input rxd,
   output reg [7:0] rxd_data
);
parameter [63:0] BAUD_RATE_PERIOD = (10**12)/BAUD_RATE;
parameter [63:0] SAMPLE_PERIOD = BAUD_RATE_PERIOD>>3; // div8
parameter IDLE = 0;
parameter RX_DATA = 1;
parameter STOP = 2;
reg [3:0] cnt;
reg [1:0] state;
reg [7:0] shf_data;
reg [2:0] sample_cnt;
reg uart_rstn;
reg uart_clk;
reg rxd_p;
reg trigger;
initial
begin
	uart_clk = 1'b0;
	forever #(SAMPLE_PERIOD/2)uart_clk = ~uart_clk;
end
initial
begin
	uart_rstn = 1'b1;
	#10000    uart_rstn = 1'b0;
	#10000    uart_rstn = 1'b1;
end
wire rxd_fall = rxd_p & ~rxd;
wire sample_en = (sample_cnt == 3'd4);
always@(posedge uart_clk) begin
	rxd_p <= rxd;
	if(rxd_fall)
		trigger <= 1'b1;
	else if(state == RX_DATA) 
		trigger <= 1'b0;
end
always@(posedge uart_clk, negedge uart_rstn) begin
	if(~uart_rstn)
		sample_cnt <= 3'd0;
	else if(state == IDLE & rxd_fall)
		sample_cnt <= 3'd0;
	else
		sample_cnt <= sample_cnt + 3'd1;
end
always @(negedge uart_rstn or posedge uart_clk) begin
	if(!uart_rstn) begin
		state <= IDLE;
		cnt <= 4'd0;
		shf_data <= 8'b0;
		rxd_data <= 8'b0;
	end
	else begin
		case(state)
			default : begin
				cnt <= 4'd0;
				if(sample_cnt == 4'd7 && trigger == 1'b1) begin
					state <= RX_DATA;
				end
			end
			RX_DATA : begin
				if(sample_en) begin
					shf_data <= {rxd, shf_data[7:1]};	
					cnt <= cnt + 1'd1;
				end				
				if(cnt == 4'd8) begin
					state <= STOP;
				end
			end
			STOP : begin
				rxd_data <= shf_data;	
				if(rxd) begin
					state <= IDLE;		
					$fwrite(32'h80000002, "%c", shf_data);	
				end
			end
		endcase
	end 
end
endmodule



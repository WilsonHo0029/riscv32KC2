
`ifndef JTAG_TASK
//`timescale 1ps/1ps  // timeunit ps
`define JTAG_PERIOD 100000 //100 ns 
`define abits = 5;
`define JTAG_TASK
task init_jtag_signals;
begin
        trst_n = 1'b0;
	tms = 1'b1;
	tck = 1'b0;
	tdi = 1'b0;
	#10;
	trst_n = 1'b1;
end
endtask

task jtag_set_signals;
input tms_in;
input tdi_in;
output tdo_out;
begin
	tms = tms_in;
	tck = 1'b0;
	tdi = tdi_in;
	#(`JTAG_PERIOD/2);
	tck = 1'b1;
	tdo_out = tdo;
	#(`JTAG_PERIOD/2);	
	tck = 1'b0;
end
endtask

task jtag_reset;
reg dummy;
begin
	repeat(8) begin
		jtag_set_signals(1'b1, 1'b0, dummy);
	end
	jtag_set_signals(1'b0, 1'b0, dummy); // run test idle
end
endtask

task jtag_get_DR;
input [31:0] len;
input [63:0] data_in;
output [63:0] data;
integer i;
reg tmp;
reg dummy;
begin
	data = 64'd0;
	i=0;
	jtag_set_signals(1'b0, 1'b0, dummy); // run test idle
	jtag_set_signals(1'b1, 1'b0, dummy); // select DR scan
	jtag_set_signals(1'b0, 1'b0, dummy); // capture DR
	jtag_set_signals(1'b0, 1'b0, dummy); // shift DR
	repeat(len) begin
		if(i == (len-1))
			jtag_set_signals(1'b1, data_in[0], tmp); // exit 1 DR
		else
			jtag_set_signals(1'b0, data_in[0], tmp); // shift DR
		data[i] = tmp;	
		i = i + 1;
		data_in = {1'b0, data_in[63:1]};
	end
	jtag_set_signals(1'b1, 1'b0, dummy); // update DR
	repeat(8) begin
		jtag_set_signals(1'b0, 1'b0, dummy); // run test idle
	end
end
endtask

task jtag_set_IR;
input [31:0] len;
input [63:0] data_in;
integer i;
reg tmp;
reg dummy;
begin
	i=0;
	jtag_set_signals(1'b0, 1'b0, dummy); // run test idle
	jtag_set_signals(1'b1, 1'b0, dummy); // select DR scan
	jtag_set_signals(1'b1, 1'b0, dummy); // select IR scan
	jtag_set_signals(1'b0, 1'b0, dummy); // capture IR
	jtag_set_signals(1'b0, 1'b0, dummy); // shift IR
	repeat(len) begin
		if(i == (len-1))
			jtag_set_signals(1'b1, data_in[0], tmp); // exit 1 IR
		else
			jtag_set_signals(1'b0, data_in[0], tmp); // shift IR
		i = i + 1;
		data_in = {1'b0, data_in[63:1]};
	end
	jtag_set_signals(1'b1, 1'b0, dummy); // update IR
	repeat(8) begin
		jtag_set_signals(1'b0, 1'b0, dummy); // run test idle
	end
end
endtask

task jtag_read_IDCODE;
output [31:0] id;
begin
	jtag_set_IR(5, 64'd1);
	jtag_get_DR(32, 0, id);
end
endtask

task jtag_read_DTMCS;
input  [63:0] data_in;
output [31:0] data;
begin
	jtag_set_IR(5, 64'h0000_0000_0000_0010);
	jtag_get_DR(32, data_in, data);
end
endtask

task jtag_read_DTM;
input  [31:0] addr;
input  [33:0] data_in;
output [63:0] data;
reg [63:0] tmp;
begin
	tmp = 0;
	tmp[1:0] = 2'b01;
	tmp[35:2]= data_in;
	tmp[40:36] = addr[5-1:0];
	jtag_set_IR(5, 64'h0000_0000_0000_0011);
	jtag_get_DR(41, tmp, data);
	#10000;
	jtag_get_DR(41, tmp, data);
	tmp = 0;
	tmp[31:0] = data[33:2];
	data[31:0] = tmp[31:0];
end
endtask

task jtag_read_DTM_013;
input  [31:0] addr;
input  [31:0] data_in;
output [63:0] data;
reg [63:0] tmp;
begin
	tmp = 0;
	tmp[1:0] = 2'b01;
	tmp[33:2]= data_in;
	tmp[40:34] = addr[7-1:0];
	jtag_set_IR(5, 64'h0000_0000_0000_0011);
	jtag_get_DR(41, tmp, data);
	#10000;
	jtag_get_DR(41, tmp, data);
	tmp = 0;
	tmp[31:0] = data[33:2];
	data[31:0] = tmp[31:0];
end
endtask

task jtag_write_DTM;
input  [31:0] addr;
input  [33:0] data_in;
reg [63:0] tmp;
reg [63:0] dummy;
begin
	tmp[1:0] = 2'b10;
	tmp[35:2]= data_in;
	tmp[40:36] = addr[5-1:0];
	jtag_set_IR(5, 64'h0000_0000_0000_0011);
	jtag_get_DR(41, tmp, dummy);
end
endtask

task jtag_write_DTM_013;
input  [31:0] addr;
input  [31:0] data_in;
reg [63:0] tmp;
reg [63:0] dummy;
begin
	tmp[1:0] = 2'b10;
	tmp[33:2]= data_in;
	tmp[40:34] = addr[7-1:0];
	jtag_set_IR(5, 64'h0000_0000_0000_0011);
	jtag_get_DR(41, tmp, dummy);
end
endtask

task jtag_dtm_active_013;
reg [31:0] tmp;
begin
	tmp = 0;
	tmp[0] = 1'b1;
	jtag_write_DTM_013(32'h10, tmp);
end
endtask


task jtag_hart_sel_013;
input  [19:0] hart_id;
reg [31:0] tmp;
begin
	tmp = 0;
	tmp[0] = 1'b1;
	tmp[15:6] = hart_id[19:10];
	tmp[25:16] = hart_id[9:0];
	//tmp[28] = 1'b1;
	jtag_write_DTM_013(32'h10, tmp);
end
endtask

task jtag_read_dmstatus_013;
output  [63:0] data;
begin
	data = 0;
	jtag_read_DTM_013(32'h11, 0, data[31:0]);
end
endtask

task jtag_hart_set_haltreq_013; //set_haltreq
input  [19:0] hart_id;
reg [31:0] tmp;
begin
	tmp = 0;
	tmp[0] = 1'b1;
	tmp[15:6] = hart_id[19:10];
	tmp[25:16] = hart_id[9:0];
        tmp[31] = 1'b1;
	jtag_write_DTM_013(32'h10, tmp);
end
endtask

task jtag_hart_clear_haltreq_013; //set_haltreq
input  [19:0] hart_id;
reg [31:0] tmp;
begin
	tmp = 0;
	tmp[0] = 1'b1;
	tmp[15:6] = hart_id[19:10];
	tmp[25:16] = hart_id[9:0];
        tmp[31] = 1'b0;
	jtag_write_DTM_013(32'h10, tmp);
end
endtask

task jtag_hart_resume_013; //
input  [19:0] hart_id;
reg [31:0] tmp;
begin
	tmp = 0;
	tmp[0] = 1'b1;
	tmp[15:6] = hart_id[19:10];
	tmp[25:16] = hart_id[9:0];
        tmp[30] = 1'b1;
        tmp[31] = 1'b0;
	jtag_write_DTM_013(32'h10, tmp);
end
endtask



task jtag_write_sys_bus;
input  [31:0] addr;
input  [31:0] data;
input  [9:0]  hart_id;
reg    [33:0] tmp;
reg    [31:0] i;
begin
	tmp = 0;
	tmp[32] = 1'b1;
	i=0;	
	if(data[11] == 1'b1 && data[31:12] == 24'hFFFFF) begin
		tmp[19:0] = 20'h0_0793;	// ADDI rs1=zero, rd=r15 
		tmp[31:20] = data[11:0]; 
		jtag_write_DTM(i, tmp);
		i = i +1;
	end
	else begin
		tmp[11:0] = 12'h7b7; // LUI r15 for data
		tmp[31:12] = data[31:12] + {23'd0, data[11]};
		jtag_write_DTM(i, tmp);
		i = i +1;
		tmp[19:0] = 20'h7_8793;	// ADDI
		tmp[31:20] = data[11:0]; // Result = data
		jtag_write_DTM(i, tmp);
		i = i +1;
	end
	if(addr[11] == 1'b1 && addr[31:12] == 24'hFFFFF) begin
		tmp[6:0] = 7'b0100011; // SW instr
		tmp[11:7] = addr[4:0];
		tmp[14:12] = 3'b010;
		tmp[19:15] = 5'h0E;//rs1:a4
		tmp[24:20] = 5'h00;//rs2:zero
		tmp[31:25] = addr[11:5];
		jtag_write_DTM(i, tmp);
		i = i +1;
	end
	else begin
		tmp[11:0] = 12'h737; // LUI r14 for addr
		tmp[31:12] = addr[31:12] + {23'd0, addr[11]};
		jtag_write_DTM(i, tmp);
		i = i +1;
		tmp[6:0] = 7'b0100011; // SW instr
		tmp[11:7] = addr[4:0];
		tmp[14:12] = 3'b010;
		tmp[19:15] = 5'h0E;//rs1:a4
		tmp[24:20] = 5'h0F;//rs2:a5
		tmp[31:25] = addr[11:5];
		jtag_write_DTM(i, tmp);
		i = i +1;
	end
	tmp[31:0] = 32'h3FC0_006F;
	jtag_write_DTM(i, tmp);	//EXIT to 0x804
	tmp = 34'd0;
	tmp[11:2] = hart_id;
	tmp[32] = 1'b1;
	tmp[33] = 1'b1;
	jtag_write_DTM(32'h10, tmp);	
end
endtask

task jtag_write_set_addr_sba_64_013;
input  [63:0] addr;
input 	      auto;
input	      read;
reg [31:0] tmp;
begin
	tmp = 0;
	tmp[19:17] = 3'd3;
	tmp[16] = auto;
	tmp[15] = read;
	jtag_write_DTM_013(32'h38, tmp);
	jtag_write_DTM_013(32'h3a, addr[63:32]);
	jtag_write_DTM_013(32'h39, addr[31:0]);
end
endtask

task jtag_write_set_data_sba_64_013;
input  [63:0] data;
begin
	jtag_write_DTM_013(32'h3d, data[63:32]);
	jtag_write_DTM_013(32'h3c, data[31:0]);
end
endtask

task jtag_write_sys_bus_sba_64_013;
input  [63:0] addr;
input  [63:0] data;
begin
	jtag_write_set_addr_sba_64_013(addr, 1'b0, 1'b0);
	jtag_write_set_data_sba_64_013(data);
end
endtask


task jtag_read_sys_bus;
input  [31:0] addr;
output  [31:0] data;
input  [9:0]  hart_id;
reg    [33:0] tmp;
reg    [31:0] i;
begin
	tmp = 0;
	tmp[32] = 1'b1;
	i=0;	
	if(addr[11] == 1'b1 && addr[31:12] == 24'hFFFFF) begin
		tmp[6:0] = 7'b0000011; // LW instr
		tmp[11:7] = 5'hD;//rd=a3
		tmp[14:12] = 3'b010;//
		tmp[19:15] = 5'h0;//rs1:zero
		tmp[31:20] = addr[11:0];
		jtag_write_DTM(i, tmp);
		i = i +1;
	end
	else begin
		tmp[11:0] = 12'h737; // LUI r14 for addr
		tmp[31:12] = addr[31:12] + {23'd0, addr[11]};
		jtag_write_DTM(i, tmp);
		i = i +1;
		tmp[6:0] = 7'b0000011; // LW instr
		tmp[11:7] = 5'hD;//rd=a3
		tmp[14:12] = 3'b010;//
		tmp[19:15] = 5'hE;//rs1:a4
		tmp[31:20] = addr[11:0];
		jtag_write_DTM(i, tmp);
		i = i +1;
	end
	tmp[6:0] = 7'b0100011; // SW instr
	tmp[11:7] = 5'h14; // 0x418
	tmp[14:12] = 3'b010;
	tmp[19:15] = 5'h00;//rs1:zero
	tmp[24:20] = 5'h0D;//rs2:a3
	tmp[31:25] = 6'h20; //0x41C
	jtag_write_DTM(i, tmp);
	i = i +1;
	tmp[31:0] = 32'h3FC0_006F;
	jtag_write_DTM(i, tmp);	//EXIT to 0x804
	tmp = 34'd0;
	tmp[11:2] = hart_id;
	tmp[32] = 1'b1;
	tmp[33] = 1'b1;
	jtag_write_DTM(32'h10, tmp);	
	#500000;
	jtag_read_DTM(32'h05,0, data);
	$display("Address 0x%h Data 0x%h\n", addr[31:0], data[31:0]);
end
endtask

task jtag_read_data_sba_64_013;
output  [63:0] data;
begin
	jtag_read_DTM_013(32'h3d, 0, data[63:32]);
	jtag_read_DTM_013(32'h3c, 0, data[31:0]);
end
endtask

task jtag_read_sys_bus_sba_64_013;
input  [63:0] addr;
output  [63:0] data;
begin
	jtag_write_set_addr_sba_64_013(addr, 1'b0, 1'b1);
	jtag_read_data_sba_64_013(data);
	jtag_write_set_addr_sba_64_013(addr, 1'b0, 1'b0);
	jtag_read_data_sba_64_013(data);
	//jtag_write_set_auto_addr_sba_64_013(addr, 1'b0);
	//jtag_read_data_sba_64_013(data);
end
endtask


task jtag_read_csr;
input  [31:0] addr;
output  [31:0] data;
input  [9:0]  hart_id;
reg    [33:0] tmp;
reg    [31:0] i;
begin
	tmp = 0;
	tmp[32] = 1'b1;
	i=0;	
	tmp[6:0] = 7'b1110011; // CSRR instr
	tmp[11:7] = 5'hD;//rd=a3
	tmp[14:12] = 3'b010;//
	tmp[19:15] = 5'h0;//rs1:zero
	tmp[31:20] = addr[11:0];
	jtag_write_DTM(i, tmp);
	i = i +1;
	
	tmp[6:0] = 7'b0100011; // SW instr
	tmp[11:7] = 5'h14; // 0x418
	tmp[14:12] = 3'b010;
	tmp[19:15] = 5'h00;//rs1:zero
	tmp[24:20] = 5'h0D;//rs2:a3
	tmp[31:25] = 6'h20; //0x41C
	jtag_write_DTM(i, tmp);
	i = i +1;
	tmp[31:0] = 32'h3FC0_006F;
	jtag_write_DTM(i, tmp);	//EXIT to 0x804
	tmp = 34'd0;
	tmp[11:2] = hart_id;
	tmp[32] = 1'b1;
	tmp[33] = 1'b1;
	jtag_write_DTM(32'h10, tmp);	
	jtag_read_DTM(32'h05,0, data);
	$display("CSR Address 0x%h Data 0x%h\n", addr[11:0], data[31:0]);
end
endtask

task jtag_write_csr;
input  [31:0] addr;
input  [31:0] data;
input  [9:0]  hart_id;
reg    [33:0] tmp;
reg    [31:0] i;
begin
	tmp = 0;
	tmp[32] = 1'b1;
	i=0;	
	if(data[11] == 1'b1 && data[31:12] == 24'hFFFFF) begin
		tmp[6:0] = 7'h13; // ADDI 
		tmp[11:7] = 5'h1c; // rd	
		tmp[14:12] = 3'b000;
		tmp[19:15] = 5'h0;
		tmp[31:20] = data[11:0]; 
		jtag_write_DTM(i, tmp);
		i = i +1;
	end
	else begin
		tmp[6:0] = 7'h37; // LUI 
		tmp[11:7] = 5'h1c; // rd
		tmp[31:12] = data[31:12] + {23'd0, data[11]};
		jtag_write_DTM(i, tmp);
		i = i +1;
		tmp[6:0] = 7'h13; // ADDI 
		tmp[11:7] = 5'h1c; // rd	
		tmp[14:12] = 3'b000;
		tmp[19:15] = 5'h1c;
		tmp[31:20] = data[11:0]; // Result = data
		jtag_write_DTM(i, tmp);
		i = i +1;
	end

	tmp[6:0] = 7'b1110011; // CSRW instr
	tmp[11:7] = 5'h0;//
	tmp[14:12] = 3'b001;//
	tmp[19:15] = 5'h1c;//rs1:t3
	tmp[31:20] = addr[11:0];
	jtag_write_DTM(i, tmp);
	i = i +1;
	
	tmp[31:0] = 32'h3FC0_006F;
	jtag_write_DTM(i, tmp);	//EXIT to 0x804
	tmp = 34'd0;
	tmp[11:2] = hart_id;
	tmp[32] = 1'b1;
	tmp[33] = 1'b1;
	jtag_write_DTM(32'h10, tmp);
end
endtask

task jtag_write_csr_013;
input  [11:0] csr;
input  [63:0] data;
reg [31:0] tmp;
begin
	jtag_write_DTM_013(32'h04, data[31:0]);
	jtag_write_DTM_013(32'h05, data[63:32]);
	tmp[11:0] = csr;
	tmp[15:12] = 4'd0;
	tmp[16] = 1'b1;
	tmp[17] = 1'b1;
	tmp[18] = 1'b0;
	tmp[19] = 1'b0;
	tmp[22:20] = 3'd2;
	tmp[23] = 0;
	tmp[31:24] = 0;
	jtag_write_DTM_013(32'h17, tmp);
end
endtask

task jtag_write_sysbus_013;
input  [31:0] addr;
input  [31:0] data;
reg [31:0] tmp;
begin
	jtag_write_DTM_013(32'h20, 32'h00942023);
	jtag_write_DTM_013(32'h21, 32'h00100073);
	jtag_write_DTM_013(32'h04, addr[31:0]);
	tmp[15:0] = 16'h1008;
	tmp[16] = 1'b1; //write
	tmp[17] = 1'b1;
	tmp[18] = 1'b0;
	tmp[19] = 1'b0;
	tmp[22:20] = 3'd2;
	tmp[23] = 0;
	tmp[31:24] = 0;
	jtag_write_DTM_013(32'h17, tmp);
	jtag_write_DTM_013(32'h04, data[31:0]);
	tmp[15:0] = 16'h1009;
	tmp[16] = 1'b1;
	tmp[17] = 1'b1;
	tmp[18] = 1'b1; // post-exc
	tmp[19] = 1'b0;
	tmp[22:20] = 3'd2;
	tmp[23] = 0;
	tmp[31:24] = 0;
	jtag_write_DTM_013(32'h17, tmp);	
end
endtask

task jtag_set_riscv_regs;
input  [5:0] rd;
input  [31:0] data;
input  [9:0]  hart_id;
reg    [33:0] tmp;
reg    [31:0] i;
begin
	tmp = 0;
	tmp[32] = 1'b1;
	i=0;	
	if(data[11] == 1'b1 && data[31:12] == 24'hFFFFF) begin
		tmp[6:0] = 7'h13; // ADDI 
		tmp[11:7] = rd; // rd	
		tmp[14:12] = 3'b000;
		tmp[19:15] = 5'd0;	 
		tmp[31:20] = data[11:0]; 
		jtag_write_DTM(i, tmp);
		i = i +1;
	end
	else begin
		tmp[6:0] = 7'h37; // LUI 
		tmp[11:7] = rd; // rd
		tmp[31:12] = data[31:12] + {23'd0, data[11]};
		jtag_write_DTM(i, tmp);
		i = i +1;
		tmp[6:0] = 7'h13; // ADDI 
		tmp[11:7] = rd; // rd	
		tmp[14:12] = 3'b000;
		tmp[19:15] = rd;
		tmp[31:20] = data[11:0]; // Result = data
		jtag_write_DTM(i, tmp);
		i = i +1;
	end
	tmp[31:0] = 32'h3FC0_006F;
	jtag_write_DTM(i, tmp);	//EXIT to 0x804
	tmp = 34'd0;
	tmp[11:2] = hart_id;
	tmp[32] = 1'b1;
	tmp[33] = 1'b1;
	jtag_write_DTM(32'h10, tmp);	
end
endtask

task jtag_set_riscv_regs_013;
input  [5:0] rd;
input  [63:0] data;
reg [31:0] tmp;
begin
	jtag_write_DTM_013(32'h04, data[31:0]);
	jtag_write_DTM_013(32'h05, data[63:32]);
	tmp[5:0] = rd;
	tmp[11:6] = 0;
	tmp[15:12] = 4'd1;
	tmp[16] = 1'b1;
	tmp[17] = 1'b1;
	tmp[18] = 1'b0;
	tmp[19] = 1'b0;
	tmp[22:20] = 3'd2;
	tmp[23] = 0;
	tmp[31:24] = 0;
	jtag_write_DTM_013(32'h17, tmp);
end
endtask

task jtag_rd_riscv_regs;
input  [5:0] rs;
output  [31:0] data;
input  [9:0]  hart_id;
reg    [33:0] tmp;
reg    [31:0] i;
begin
	tmp = 0;
	tmp[32] = 1'b1;
	i=0;	
	tmp[6:0] = 7'b0100011; // SW instr
	tmp[11:7] = 5'h14; // 0x414
	tmp[14:12] = 3'b010;
	tmp[19:15] = 5'h00;//rs1:zero
	tmp[24:20] = rs;//rs2:a3
	tmp[31:25] = 6'h20; 
	jtag_write_DTM(i, tmp);
	i = i +1;
	tmp[31:0] = 32'h3FC0_006F;
	jtag_write_DTM(i, tmp);	//EXIT to 0x804
	tmp = 34'd0;
	tmp[11:2] = hart_id;
	tmp[32] = 1'b1;
	tmp[33] = 1'b1;
	jtag_write_DTM(32'h10, tmp);	
	jtag_read_DTM(32'h05,0, data);
	$display("R%d Data 0x%h\n", rs[5:0], data[31:0]);
end
endtask


task jtag_enter_debug_mode;
input  [9:0]  hart_id;
begin
	jtag_write_csr(32'h0000_07b0, 32'h0000_0008, hart_id);	
end
endtask

task jtag_enter_halt_mode;
input  [9:0]  hart_id;
begin
	jtag_write_sys_bus(32'h0000_010C, {22'd0 ,hart_id}, hart_id);	
end
endtask

task jtag_set_pc;
input [31:0] pc;
input  [9:0]  hart_id;
begin
	jtag_write_csr(32'h0000_07b1, pc, hart_id);	
end
endtask

task jtag_set_pc_013; 
input  [63:0] pc;
begin
	jtag_write_csr_013(32'h0000_07b1, pc);
end
endtask

task jtag_exit_debug_mode;
input  [9:0]  hart_id;
begin
	jtag_write_csr(32'h0000_07b0, 32'h0000_0000, hart_id);	
end
endtask

task jtag_switch_hart_id;
input  [9:0]  hart_id;
reg    [33:0] tmp;
begin
	tmp = 34'd0;
	tmp[11:2] = hart_id;
	tmp[32] = 1'b1;
	tmp[33] = 1'b0;
	jtag_write_DTM(32'h10, tmp);
end
endtask

task jtag_write_test;
input  [9:0]  hart_id;
input  [33:0] slot0;
input  [33:0] slot1;
input  [33:0] slot2;
input  [33:0] slot3;
input  [33:0] slot4;
input  [33:0] slot5;
input  [33:0] slot6;
reg    [33:0] tmp;
reg    [31:0] i;
begin

	jtag_write_DTM(0, slot0);	//EXIT to 0x804
	jtag_write_DTM(1, slot1);	//EXIT to 0x804
	jtag_write_DTM(2, slot2);	//EXIT to 0x804
	jtag_write_DTM(3, slot3);	//EXIT to 0x804
	jtag_write_DTM(4, slot4);	//EXIT to 0x804
	jtag_write_DTM(5, slot5);	//EXIT to 0x804
	jtag_write_DTM(6, slot6);	//EXIT to 0x804

	tmp = 34'd0;
	tmp[11:2] = hart_id;
	tmp[32] = 1'b1;
	tmp[33] = 1'b1;
	jtag_write_DTM(32'h10, tmp);	
	#500000;
end
endtask
`endif


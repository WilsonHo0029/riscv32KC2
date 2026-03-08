module riscv_fetch_pc_unit #(
    parameter RESET_PC = 32'h0000_1000
) (	
    input               clk, 
    input               rst_n,
    input  [31:0]       next_pc1,
    input               pc1_sel,
    input               instr_rv32,
    input               flush,
    input               stall,
    input               ifu_ready,
    output reg [31:0]   fetch_addr,
    output reg [31:0]   pc,
    input  [31:0]       pc_incr,
    output [31:0]       pc_ra,
    output              ifetch_rvalid,
    input               instr_rvalid,
    input  [31:0]       instr_i,
    output reg [31:0]   instr_o,
    output              fetch_rvalid
);
reg  [31:0]      buf_instr;
reg             instr_cnt;
wire            fetch_done;
reg  [1:0]       s_instr_state, ns_instr_state;
localparam      S_INSTR_00  = 2'b00;
localparam      S_INSTR_01  = 2'b01;
localparam      S_INSTR_11  = 2'b10;
reg             s_fetch_2op;
wire [31:0]      next_pc           = (pc1_sel)?next_pc1: pc + pc_incr;
wire [31:0]      next_fetch_addr   = fetch_addr + 32'd4;
assign          pc_ra = pc + pc_incr;
wire            w_instr_rvalid    = instr_rvalid;

reg             r_stop_fetch_update_1P;
wire            clear_prefetch    = flush | pc1_sel;
wire            issue_rv32c       = fetch_done & ~instr_rv32;
wire            issue_rv32        = fetch_done & instr_rv32;
wire            stop_fetch_update = ((s_instr_state == S_INSTR_01) & issue_rv32c) & ~stall & ~clear_prefetch;
assign ifetch_rvalid              =  ~stall & ~((s_instr_state == S_INSTR_01) & issue_rv32c) & ~clear_prefetch;
assign fetch_rvalid               = fetch_done & ~stall;
assign fetch_done = (((~s_fetch_2op) & w_instr_rvalid) |
                     ((s_fetch_2op) & w_instr_rvalid & instr_cnt)) | r_stop_fetch_update_1P;
 
always@(posedge clk or negedge rst_n)
    if(~rst_n)
        s_fetch_2op <= 1'b0;
    else begin
        if(clear_prefetch)
           s_fetch_2op <= next_pc[1];
        else if(stall)
           s_fetch_2op <= pc[1];
        else if(s_fetch_2op & fetch_done)
           s_fetch_2op <= 1'b0;
    end
always@(posedge clk)
    if(clear_prefetch)
        buf_instr <= 32'd0;
    else if(w_instr_rvalid)
        buf_instr <= instr_i;
        
always@(posedge clk or negedge rst_n)
    if(~rst_n) begin
       instr_cnt <= 1'b0;
       r_stop_fetch_update_1P <= 1'b0;
    end
    else begin
        if(clear_prefetch | stall)
            instr_cnt <= 1'b0;
        else if(s_fetch_2op & w_instr_rvalid)
            instr_cnt <= 1'b1;
                
       r_stop_fetch_update_1P <= stop_fetch_update;
    end   
always@(posedge clk or negedge rst_n)
    if(~rst_n) begin
        fetch_addr <= RESET_PC;
    end
    else begin
        if(clear_prefetch) begin
            fetch_addr <= {next_pc[31:2], 2'b00};
        end
       else if(stall) begin
            fetch_addr <= pc;
         end
       else if(stop_fetch_update) begin
            fetch_addr <= fetch_addr;     
        end
        else if(ifu_ready) begin
            fetch_addr <= next_fetch_addr;
		end	
    end
wire            pc_update = flush || ( (fetch_done) & ~stall);   
always@(posedge clk or negedge rst_n)
    if(~rst_n) begin
        pc <= RESET_PC;
    end
    else begin
        if(pc_update) begin
            pc <= next_pc;
        end
        
    end
    

        
always@(posedge clk or negedge rst_n)
    if(~rst_n)
        s_instr_state <= S_INSTR_00;
    else
        if(clear_prefetch) begin
            s_instr_state <= next_pc[1] ? S_INSTR_01 : S_INSTR_00;
        end
        else if(stall) begin
            s_instr_state <= pc[1] ? S_INSTR_01 : S_INSTR_00;
        end
        else if(pc_update)begin
            s_instr_state <= ns_instr_state;
        end

always@(*)
    case(s_instr_state)
        S_INSTR_00:
            if(issue_rv32c)
                ns_instr_state = S_INSTR_01;
            else
                ns_instr_state = S_INSTR_00;
        S_INSTR_01:
            if(issue_rv32c)
                ns_instr_state = S_INSTR_11;
            else
                ns_instr_state = S_INSTR_01;
        S_INSTR_11:
            if(issue_rv32c)
               ns_instr_state = S_INSTR_01;
            else if(issue_rv32)
               ns_instr_state = S_INSTR_00;
            else
               ns_instr_state = S_INSTR_11;
         default:
               ns_instr_state = S_INSTR_00;
    endcase     
    
always@(*)
    case(s_instr_state)
        S_INSTR_00:
            instr_o = instr_i;
        S_INSTR_01:
            instr_o = {instr_i[15:0], buf_instr[31:16]};
        S_INSTR_11:
            instr_o = buf_instr;
        default:
            instr_o = instr_i;
    endcase           


endmodule
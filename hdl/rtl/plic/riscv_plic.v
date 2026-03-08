module riscv_plic #(
    parameter HART_NUM = 1,
    parameter PLIC_PRIO_WIDTH = 3,
    parameter PLIC_NUM = 52
)(
    input                    clk,
    input                    rst_n,

    input  [23:0]            plic_addr,
    input                     wr_en,
    input  [31:0]             wdata,
    output [31:0]             rdata,

    input  [PLIC_NUM-1:0]     ext_irq,
    output [HART_NUM-1:0]     irq
);
    localparam PLIC_PEND_ARRAY = (((PLIC_NUM-1)/32) + 1);
    localparam PLIC_NUM_LOG2    = $clog2(PLIC_NUM);
    //localparam PLIC_PRIO_REMAIN_WIDTH = 32 - PLIC_PRIO_WIDTH;
    
    //----------------Memory Map
    localparam INT_PRIORITY_BASE  = 24'd0;
    localparam INT_PENDING_BASE   = 24'h1000;
    localparam INT_ENABLE_BASE    = 24'h2000;
    localparam INT_THRESHOLD_BASE = 24'h20_0000;
    localparam INT_CLAIM_BASE     = 24'h20_0004;

    reg  [PLIC_PRIO_WIDTH-1:0]     irq_priority [1:PLIC_NUM-1];
    wire [PLIC_PRIO_WIDTH*PLIC_NUM-1:0] irq_priority_flat;
    wire [PLIC_NUM-1:0]            irq_pending;
    reg  [PLIC_NUM-1:0]            irq_enable [0:HART_NUM-1];
    reg  [PLIC_PRIO_WIDTH-1:0]     irq_throd [0:HART_NUM-1];
    wire [HART_NUM-1:0]            irq_notifcation_o;
    wire [PLIC_NUM_LOG2-1:0]       irq_id_o [0:HART_NUM-1];
    wire [32-1:0]                  rsp_irq_priority_plic [0:PLIC_NUM-1];
    wire [32-1:0]                  rsp_irq_throd_hart [0:HART_NUM-1];
    wire [32-1:0]                  rsp_irq_id_hart [0:HART_NUM-1];
    wire [32-1:0]                  rsp_irq_enable_hart [0:PLIC_PEND_ARRAY*HART_NUM-1];
    wire [32-1:0]                  rsp_irq_pending_plic [0:PLIC_PEND_ARRAY-1];
    reg  [32-1:0]                  rsp_irq_priority;
    reg  [32-1:0]                  rsp_irq_throd;
    reg  [32-1:0]                  rsp_irq_enable;
    reg  [32-1:0]                  rsp_irq_id;
    reg  [32-1:0]                  rsp_irq_pending;
    wire [HART_NUM-1:0]             rd_claim_sel;
    wire [HART_NUM-1:0]             wr_claim_sel;
    
    assign rdata = rsp_irq_priority | rsp_irq_throd | rsp_irq_enable | rsp_irq_id | rsp_irq_pending;
    assign irq   = irq_notifcation_o;
    
    genvar i, j;
    
    assign rsp_irq_priority_plic[0]              = {{PLIC_PRIO_WIDTH}{1'b0}};
    assign irq_priority_flat[PLIC_PRIO_WIDTH-1:0] = {{PLIC_PRIO_WIDTH}{1'b0}};
    generate begin
        for (i=1; i<PLIC_NUM; i=i+1) begin: PLIC_PRIORITY
            assign rsp_irq_priority_plic[i] = (plic_addr == (INT_PRIORITY_BASE + i*24'd4)) ? {{(32 - PLIC_PRIO_WIDTH){1'b0}}, irq_priority[i]} : {32{1'b0}};
            always @(posedge clk, negedge rst_n) begin
                if (~rst_n)
                    irq_priority[i] <= {PLIC_PRIO_WIDTH{1'b0}};
                else
                    irq_priority[i] <= ((plic_addr == (INT_PRIORITY_BASE + i*24'd4)) & wr_en) ?
                                      wdata[PLIC_PRIO_WIDTH-1:0] : irq_priority[i];
            end
            assign irq_priority_flat[(i+1)*PLIC_PRIO_WIDTH-1:i*PLIC_PRIO_WIDTH] = irq_priority[i];
        end
        
        for (i=0; i<HART_NUM; i=i+1) begin: THRESHOLD
            assign rsp_irq_throd_hart[i] = (plic_addr == (INT_THRESHOLD_BASE + i*24'h1000)) ? {{(32 - PLIC_PRIO_WIDTH){1'b0}}, irq_throd[i]} : {32{1'b0}};
            always @(posedge clk, negedge rst_n) begin
                if (~rst_n)
                    irq_throd[i] <= {PLIC_PRIO_WIDTH{1'b0}};
                else
                    irq_throd[i] <= ((plic_addr == (INT_THRESHOLD_BASE + i*24'h1000)) & wr_en) ?
                                    wdata[PLIC_PRIO_WIDTH-1:0] : irq_throd[i];
            end
        end
        
        for (i=0; i<HART_NUM; i=i+1) begin: ENABLE
            for (j=0; j<PLIC_PEND_ARRAY; j=j+1) begin
                if (j == (PLIC_PEND_ARRAY-1)) begin
                    assign rsp_irq_enable_hart[i*PLIC_PEND_ARRAY + j] = (plic_addr == (INT_ENABLE_BASE + i*24'h80 + j*24'd4)) ?
                                                                        {{(32-(PLIC_NUM-j*32)){1'b0}}, irq_enable[i][PLIC_NUM-1:j*32]} : {32{1'b0}};
                    always @(posedge clk, negedge rst_n) begin
                        if (~rst_n)
                            irq_enable[i][PLIC_NUM-1:j*32] <= {(PLIC_NUM-j*32){1'b0}};
                        else
                            irq_enable[i][PLIC_NUM-1:j*32] <= ((plic_addr == (INT_ENABLE_BASE + i*24'h80 + j*24'd4)) & wr_en) ?
                                                              wdata[PLIC_NUM-32*j-1:0] : irq_enable[i][PLIC_NUM-1:j*32];
                    end
                end
                else begin
                    assign rsp_irq_enable_hart[i*PLIC_PEND_ARRAY + j] = (plic_addr == (INT_ENABLE_BASE + i*24'h80 + j*24'd4)) ?
                                                                       irq_enable[i][(j+1)*32:j*32] : {32{1'b0}};
                    always @(posedge clk, negedge rst_n) begin
                        if (~rst_n)
                            irq_enable[i][(j+1)*32-1:j*32] <= {32{1'b0}};
                        else
                            irq_enable[i][(j+1)*32-1:j*32] <= ((plic_addr == (INT_ENABLE_BASE + i*24'h80 + j*24'd4)) & wr_en) ?
                                                              wdata : irq_enable[i][(j+1)*32-1:j*32];
                    end
                end
            end
        end
        
        for (i=0; i<HART_NUM; i=i+1) begin: CLAIM
            assign rd_claim_sel[i]     = (plic_addr == (INT_CLAIM_BASE + i*24'h1000));
            assign wr_claim_sel[i]     = (plic_addr == (INT_CLAIM_BASE + i*24'h1000) & wr_en);
            assign rsp_irq_id_hart[i]  = rd_claim_sel[i] ? {{(32-PLIC_NUM_LOG2){1'b0}}, irq_id_o[i]} : 32'd0;
        end

        for (j=0; j<PLIC_PEND_ARRAY; j=j+1) begin: PENDING_BIT
            if (j == (PLIC_PEND_ARRAY-1)) begin
                assign rsp_irq_pending_plic[j] = (plic_addr == (INT_PENDING_BASE + j*24'd4)) ?
                                                 {{(32-(PLIC_NUM-j*32)){1'b0}}, irq_pending[PLIC_NUM-1:j*32]} : {32{1'b0}};
            end
            else begin
                assign rsp_irq_pending_plic[j] = (plic_addr == (INT_PENDING_BASE + j*24'd4)) ?
                                                   irq_pending[(j+1)*32-1:j*32] : {32{1'b0}};
            end
        end
    end
    endgenerate 

    integer k;
    
    always @(*) begin
        rsp_irq_priority = {32{1'b0}};
        for (k=0; k<PLIC_NUM; k=k+1) begin
            rsp_irq_priority = rsp_irq_priority | rsp_irq_priority_plic[k];
        end
    end

    always @(*) begin
        rsp_irq_throd = {32{1'b0}};
        rsp_irq_id    = {32{1'b0}};
        for (k=0; k<HART_NUM; k=k+1) begin
            rsp_irq_throd = rsp_irq_throd | rsp_irq_throd_hart[k];
            rsp_irq_id    = rsp_irq_id | rsp_irq_id_hart[k];
        end
    end

    always @(*) begin
        rsp_irq_enable = {32{1'b0}};
        for (k=0; k<HART_NUM*PLIC_PEND_ARRAY; k=k+1) begin
            rsp_irq_enable = rsp_irq_enable | rsp_irq_enable_hart[k];
        end
    end

    always @(*) begin
        rsp_irq_pending = {32{1'b0}};
        for (k=0; k<PLIC_PEND_ARRAY; k=k+1) begin
            rsp_irq_pending = rsp_irq_pending | rsp_irq_pending_plic[k];
        end
    end
    //-----------------------------------------
    //------Gateways---------------------------
    wire [PLIC_NUM-1:0] irq_req;
    reg  [PLIC_NUM-1:0]  irq_claim, irq_complete;
    
    plic_Gateways #(
        .PLIC_NUM(PLIC_NUM)
    ) u_gateway (
        .clk         (clk),
        .rst_n       (rst_n),
        .irq_src     (ext_irq),
        .irq_claim   (irq_claim),
        .irq_complete(irq_complete),
        .irq_pending (irq_pending),
        .irq_req     (irq_req)
    );
    
    //--------------------------------------------
    //---------Plic Core---------------------------
    reg [PLIC_NUM_LOG2-1:0] claim_index_hart[0:HART_NUM-1];
    reg [PLIC_NUM_LOG2-1:0] complete_index_hart[0:HART_NUM-1];
    reg [PLIC_NUM_LOG2-1:0] claim_index, complete_index;
    
    generate begin
        for (i=0; i<HART_NUM; i=i+1) begin
            always @(*) begin
                claim_index_hart[i]     = {PLIC_NUM_LOG2{1'b0}};
                complete_index_hart[i]  = {PLIC_NUM_LOG2{1'b0}};
                if (irq_id_o[i] != {PLIC_NUM_LOG2{1'b0}} & rd_claim_sel[i])
                    claim_index_hart[i] = irq_id_o[i];
                if (wdata[PLIC_NUM_LOG2:0] != {PLIC_NUM_LOG2{1'b0}} & wr_claim_sel[i])
                    complete_index_hart[i] = wdata[PLIC_NUM_LOG2:0];
            end
        end
    end
    endgenerate
    
    always @(*) begin
        claim_index    = {PLIC_NUM_LOG2{1'b0}};
        complete_index = {PLIC_NUM_LOG2{1'b0}};
        for (k=0; k<HART_NUM; k=k+1) begin
            claim_index    = claim_index | claim_index_hart[k];
            complete_index = complete_index | complete_index_hart[k];
        end
    end

    always @(*) begin: CLAIM_COMPLETE_DEMUX
        irq_claim    = {PLIC_NUM{1'b0}};
        irq_complete = {PLIC_NUM{1'b0}};
        for (k=1; k<PLIC_NUM; k=k+1) begin
            irq_claim[k]    = (k == claim_index);
            irq_complete[k] = (k == complete_index);
        end
    end
    
    //-------Plic Target
    generate begin
        for (i=0; i<HART_NUM; i=i+1) begin : Target
            plic_target #(
                .PLIC_NUM       (PLIC_NUM),
                .PLIC_NUM_LOG2  ($clog2(PLIC_NUM)),
                .PLIC_PRIO_WIDTH(PLIC_PRIO_WIDTH)
            ) u_plic_target (
                .irq_pending (irq_pending),
                .irq_priority(irq_priority_flat),
                .irq_enable  (irq_enable[i]),
                .irq_throd   (irq_throd[i]),
                .irq_o       (irq_notifcation_o[i]),
                .irq_id      (irq_id_o[i])
            );
        end
    end
    endgenerate

//-----------------------------------------



endmodule

module plic_Gateways #(
    parameter PLIC_NUM = 52
)(
    input                    clk,
    input                    rst_n,
    input  [PLIC_NUM-1:0]    irq_src,
    input  [PLIC_NUM-1:0]    irq_claim,
    input  [PLIC_NUM-1:0]    irq_complete,
    output reg [PLIC_NUM-1:0] irq_pending,
    output      [PLIC_NUM-1:0] irq_req
);
    genvar i;
    reg [PLIC_NUM-1:0] irq_active;
    
    assign irq_req = irq_src & ~irq_active;
    
    generate begin
        for (i=0; i<PLIC_NUM; i=i+1) begin: ACTIVE
            always @(posedge clk, negedge rst_n) begin
                if (~rst_n)
                    irq_active[i] <= 1'b0;
                else
                    if (irq_complete[i])
                        irq_active[i] <= 1'b0;
                    else if (irq_src[i] & ~irq_active[i])
                        irq_active[i] <= 1'b1;
            end
        end
        
        for (i=0; i<PLIC_NUM; i=i+1) begin: PENDING
            always @(posedge clk, negedge rst_n) begin
                if (~rst_n)
                    irq_pending[i] <= 1'b0;
                else
                    if (irq_claim[i])
                        irq_pending[i] <= 1'b0;
                    else if (irq_src[i] & ~irq_active[i] & ~irq_pending[i])
                        irq_pending[i] <= 1'b1;
            end
        end
    end
    endgenerate

endmodule

module plic_target #(
    parameter PLIC_NUM       = 52,
    parameter PLIC_NUM_LOG2  = 6,
    parameter PLIC_PRIO_WIDTH = 3
)(
    input  [PLIC_NUM-1:0]                    irq_pending,
    input  [PLIC_PRIO_WIDTH*PLIC_NUM-1:0]    irq_priority,
    input  [PLIC_NUM-1:0]                    irq_enable,
    input  [PLIC_PRIO_WIDTH-1:0]             irq_throd,
    output                                    irq_o,
    output [PLIC_NUM_LOG2-1:0]                irq_id
);
    // Binary Search
    localparam IRQ_ARRAY_SIZE = 2**PLIC_NUM_LOG2;
    reg  [PLIC_PRIO_WIDTH*IRQ_ARRAY_SIZE-1:0] init_irq_priority_array;
    reg  [PLIC_NUM_LOG2*IRQ_ARRAY_SIZE-1:0]   init_irq_id_array;
    wire [PLIC_PRIO_WIDTH-1:0]                max_irq_priority;
    wire [PLIC_NUM_LOG2-1:0]                   max_irq_id;
    wire [PLIC_NUM-1:0]                        irq_valid = irq_enable & irq_pending;
    
    assign irq_o = (max_irq_priority > irq_throd);
    assign irq_id = (max_irq_priority > irq_throd) ? max_irq_id : {PLIC_NUM_LOG2{1'b0}};
    
    genvar i;
    generate begin
        for (i=0; i<IRQ_ARRAY_SIZE; i=i+1) begin
            always @(*) begin
                init_irq_id_array[(i+1)*PLIC_NUM_LOG2-1: i*PLIC_NUM_LOG2] = i;
                if (i >= PLIC_NUM) begin
                    init_irq_priority_array[(i+1)*PLIC_PRIO_WIDTH-1:i*PLIC_PRIO_WIDTH] = {PLIC_PRIO_WIDTH{1'b0}};
                end
                else begin
                    init_irq_priority_array[(i+1)*PLIC_PRIO_WIDTH-1:i*PLIC_PRIO_WIDTH] = irq_valid[i] ? irq_priority[(i+1)*PLIC_PRIO_WIDTH-1:i*PLIC_PRIO_WIDTH] : {PLIC_PRIO_WIDTH{1'b0}};
                end
            end
        end
    end
    endgenerate
    
    plic_target_binary_search #(
        .ARRAY_SIZE     (IRQ_ARRAY_SIZE),
        .PLIC_PRIO_WIDTH(PLIC_PRIO_WIDTH),
        .PLIC_ID_WIDTH  (PLIC_NUM_LOG2)
    ) u_plic_binary_search (
        .irq_array_id_i      (init_irq_id_array),
        .irq_array_priority_i(init_irq_priority_array),
        .irq_array_id_o      (max_irq_id),
        .irq_array_priority_o(max_irq_priority)
    );
endmodule

module plic_target_binary_search #(
    parameter ARRAY_SIZE     = 32,
    parameter PLIC_PRIO_WIDTH = 3,
    parameter PLIC_ID_WIDTH  = 3
)(
    input  [PLIC_ID_WIDTH*ARRAY_SIZE-1:0]    irq_array_id_i,
    input  [PLIC_PRIO_WIDTH*ARRAY_SIZE-1:0]   irq_array_priority_i,
    output [PLIC_ID_WIDTH-1:0]                irq_array_id_o,
    output [PLIC_PRIO_WIDTH-1:0]              irq_array_priority_o
);
    reg  [PLIC_ID_WIDTH*(ARRAY_SIZE/2)-1:0]   irq_array_id_o_pre;
    reg  [PLIC_PRIO_WIDTH*(ARRAY_SIZE/2)-1:0] irq_array_priority_o_pre;
    wire [(ARRAY_SIZE/2)-1:0]                  irq_array_priority_gt;
    genvar i;
    
    generate begin
        // find the Max
        for (i=0; i<ARRAY_SIZE/2; i=i+1) begin
            assign irq_array_priority_gt[i] = (irq_array_priority_i[(2*i+1)*PLIC_PRIO_WIDTH-1: 2*i*PLIC_PRIO_WIDTH] >
                                               irq_array_priority_i[(2*i+2)*PLIC_PRIO_WIDTH-1: (2*i+1)*PLIC_PRIO_WIDTH]);
            always @(*) begin
                irq_array_id_o_pre[(i+1)*PLIC_ID_WIDTH-1: i*PLIC_ID_WIDTH] = (irq_array_priority_gt[i]) ?
                    irq_array_id_i[(2*i+1)*PLIC_ID_WIDTH-1: 2*i*PLIC_ID_WIDTH] : irq_array_id_i[(2*i+2)*PLIC_ID_WIDTH-1: (2*i+1)*PLIC_ID_WIDTH];
                irq_array_priority_o_pre[(i+1)*PLIC_PRIO_WIDTH-1: i*PLIC_PRIO_WIDTH] = (irq_array_priority_gt[i]) ?
                    irq_array_priority_i[(2*i+1)*PLIC_PRIO_WIDTH-1: 2*i*PLIC_PRIO_WIDTH] : irq_array_priority_i[(2*i+2)*PLIC_PRIO_WIDTH-1: (2*i+1)*PLIC_PRIO_WIDTH];
            end
        end
        
        if (ARRAY_SIZE == 2) begin: ENDBLK
            assign irq_array_id_o       = irq_array_id_o_pre;
            assign irq_array_priority_o = irq_array_priority_o_pre;
        end
        else begin
            plic_target_binary_search #(
                .ARRAY_SIZE     (ARRAY_SIZE/2),
                .PLIC_PRIO_WIDTH(PLIC_PRIO_WIDTH),
                .PLIC_ID_WIDTH  (PLIC_ID_WIDTH)
            ) u_plic_recursive (
                .irq_array_id_i      (irq_array_id_o_pre),
                .irq_array_priority_i(irq_array_priority_o_pre),
                .irq_array_id_o      (irq_array_id_o),
                .irq_array_priority_o(irq_array_priority_o)
            );
        end
    end
    endgenerate

endmodule
module axi_lite_mux2#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NumSlv     = 2
)(
    input                               clk,
    input                               rst_n,

    // Write Address Channel
    input  [NumSlv*ADDR_WIDTH-1:0]      s_axi_awaddr,
    input  [NumSlv*8-1:0]               s_axi_awlen,
    input  [NumSlv*3-1:0]               s_axi_awsize,
    input  [NumSlv*2-1:0]               s_axi_awburst,
    input  [NumSlv-1:0]                 s_axi_awvalid,
    output [NumSlv-1:0]                 s_axi_awready,

    // Write Data Channel
    input  [NumSlv*DATA_WIDTH-1:0]      s_axi_wdata,
    input  [NumSlv*(DATA_WIDTH/8)-1:0]  s_axi_wstrb,
    input  [NumSlv-1:0]                 s_axi_wlast,
    input  [NumSlv-1:0]                 s_axi_wvalid,
    output [NumSlv-1:0]                 s_axi_wready,

    // Write Response Channel
    output [NumSlv*2-1:0]               s_axi_bresp,
    output [NumSlv-1:0]                 s_axi_bvalid,
    input  [NumSlv-1:0]                 s_axi_bready,

    // Read Address Channel
    input  [NumSlv*ADDR_WIDTH-1:0]      s_axi_araddr,
    input  [NumSlv*8-1:0]               s_axi_arlen,
    input  [NumSlv*3-1:0]               s_axi_arsize,
    input  [NumSlv*2-1:0]               s_axi_arburst,
    input  [NumSlv-1:0]                 s_axi_arvalid,
    output reg [NumSlv-1:0]             s_axi_arready,

    // Read Data Channel
    output [NumSlv*DATA_WIDTH-1:0]      s_axi_rdata,
    output [NumSlv*2-1:0]               s_axi_rresp,
    output [NumSlv-1:0]                 s_axi_rlast,
    output [NumSlv-1:0]                 s_axi_rvalid,
    input  [NumSlv-1:0]                 s_axi_rready,

 // Master interface
    // Write Address Channel
    output [ADDR_WIDTH-1:0]             m_axi_awaddr,
    output [7:0]                        m_axi_awlen,
    output [2:0]                        m_axi_awsize,
    output [1:0]                        m_axi_awburst,
    output                              m_axi_awvalid,
    input                               m_axi_awready,

    // Write Data Channel
    output [DATA_WIDTH-1:0]             m_axi_wdata,
    output [(DATA_WIDTH/8)-1:0]         m_axi_wstrb,
    output                              m_axi_wlast,
    output                              m_axi_wvalid,
    input                               m_axi_wready,

    // Write Response Channel
    input  [1:0]                        m_axi_bresp,
    input                               m_axi_bvalid,
    output                              m_axi_bready,

    // Read Address Channel
    output reg [ADDR_WIDTH-1:0]         m_axi_araddr,
    output reg [7:0]                    m_axi_arlen,
    output reg [2:0]                    m_axi_arsize,
    output reg [1:0]                    m_axi_arburst,
    output reg                          m_axi_arvalid,
    input                               m_axi_arready,

    // Read Data Channel
    input  [DATA_WIDTH-1:0]             m_axi_rdata,
    input  [1:0]                        m_axi_rresp,
    input                               m_axi_rlast,
    input                               m_axi_rvalid,
    output                              m_axi_rready
);

    reg [$clog2(NumSlv)-1:0]            idx;
    reg [NumSlv-1:0]                    idx_bit;
    reg                                 rd_fifo_push;
    wire                                rd_fifo_pop;
    wire                                rd_empty;
    wire [$clog2(NumSlv)-1:0]           idx_rd;
    wire [NumSlv-1:0]                   idx_bit_rd;

    assign s_axi_rdata  = {NumSlv{m_axi_rdata}};
    assign s_axi_rresp  = {NumSlv{m_axi_rresp}};
    assign s_axi_rlast  = {NumSlv{m_axi_rlast}};
    assign s_axi_rvalid = idx_bit_rd & {NumSlv{m_axi_rvalid}};
    assign m_axi_rready = ~rd_empty;

    integer i;

    always @(*) begin
        m_axi_araddr  = 0;
        m_axi_arlen   = 0;
        m_axi_arsize  = 0;
        m_axi_arburst = 0;
        m_axi_arvalid = 0;
        rd_fifo_push  = 1'b0;
        idx_bit       = 0;
        idx           = 0;
        s_axi_arready = {NumSlv{1'b0}};

        if (s_axi_arvalid[0]) begin
            m_axi_araddr  = s_axi_araddr[ADDR_WIDTH-1:0];
            m_axi_arlen   = s_axi_arlen[7:0];
            m_axi_arsize  = s_axi_arsize[2:0];
            m_axi_arburst = s_axi_arburst[1:0];
            m_axi_arvalid = 1'b1;
        end else if (s_axi_arvalid[1]) begin
            m_axi_araddr  = s_axi_araddr[(1+1)*ADDR_WIDTH-1:ADDR_WIDTH];
            m_axi_arlen   = s_axi_arlen[15:8];
            m_axi_arsize  = s_axi_arsize[5:3];
            m_axi_arburst = s_axi_arburst[3:2];
            m_axi_arvalid = 1'b1;
        end

        if (m_axi_arready & s_axi_arvalid[0] & rd_empty) begin
            s_axi_arready = 2'b01;
            idx           = 0;
            idx_bit[0]    = 1'b1;
            rd_fifo_push  = rd_empty;
        end else if (m_axi_arready & s_axi_arvalid[1] & rd_empty) begin
            s_axi_arready = 2'b10;
            idx           = 1;
            idx_bit[1]    = 1'b1;
            rd_fifo_push  = rd_empty;
        end
    end

    assign rd_fifo_pop = ~rd_empty & s_axi_rready[idx_rd] & m_axi_rvalid;

    axi_fifo #(
        .DW(NumSlv + $clog2(NumSlv))
    ) u_fifo_r (
        .clk     (clk),
        .rst_n   (rst_n),
        .data_i  ({idx_bit, idx}),
        .push_i  (rd_fifo_push),
        .empty_o (rd_empty),
        .data_o  ({idx_bit_rd, idx_rd}),
        .pop_i   (rd_fifo_pop)
    );

endmodule

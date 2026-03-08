// APB Decoder/Splitter (16-Way)
// Routes single APB master to 16 APB slaves
// Each slave has a fixed size of 0x1000 (4KB)

module apb_decoder #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BASE_ADDR  = 32'h10000000
)(
    input               clk,
    input               rst_n,
    
    // APB Slave Interface (from Bridge)
    input  [ADDR_WIDTH-1:0] s_apb_paddr,
    input               s_apb_psel,
    input               s_apb_penable,
    input               s_apb_pwrite,
    input  [DATA_WIDTH-1:0] s_apb_pwdata,
    input  [3:0]        s_apb_pstrb,
    output [DATA_WIDTH-1:0] s_apb_prdata,
    output              s_apb_pready,
    output              s_apb_pslverr,
    
    // APB Master Interface 0
    output [ADDR_WIDTH-1:0] m0_apb_paddr,
    output                  m0_apb_psel,
    output                  m0_apb_penable,
    output                  m0_apb_pwrite,
    output [DATA_WIDTH-1:0] m0_apb_pwdata,
    output [3:0]            m0_apb_pstrb,
    input  [DATA_WIDTH-1:0] m0_apb_prdata,
    input                   m0_apb_pready,
    input                   m0_apb_pslverr,

    // APB Master Interface 1
    output [ADDR_WIDTH-1:0] m1_apb_paddr,
    output                  m1_apb_psel,
    output                  m1_apb_penable,
    output                  m1_apb_pwrite,
    output [DATA_WIDTH-1:0] m1_apb_pwdata,
    output [3:0]            m1_apb_pstrb,
    input  [DATA_WIDTH-1:0] m1_apb_prdata,
    input                   m1_apb_pready,
    input                   m1_apb_pslverr,

    // APB Master Interface 2
    output [ADDR_WIDTH-1:0] m2_apb_paddr,
    output                  m2_apb_psel,
    output                  m2_apb_penable,
    output                  m2_apb_pwrite,
    output [DATA_WIDTH-1:0] m2_apb_pwdata,
    output [3:0]            m2_apb_pstrb,
    input  [DATA_WIDTH-1:0] m2_apb_prdata,
    input                   m2_apb_pready,
    input                   m2_apb_pslverr,

    // APB Master Interface 3
    output [ADDR_WIDTH-1:0] m3_apb_paddr,
    output                  m3_apb_psel,
    output                  m3_apb_penable,
    output                  m3_apb_pwrite,
    output [DATA_WIDTH-1:0] m3_apb_pwdata,
    output [3:0]            m3_apb_pstrb,
    input  [DATA_WIDTH-1:0] m3_apb_prdata,
    input                   m3_apb_pready,
    input                   m3_apb_pslverr,

    // APB Master Interface 4
    output [ADDR_WIDTH-1:0] m4_apb_paddr,
    output                  m4_apb_psel,
    output                  m4_apb_penable,
    output                  m4_apb_pwrite,
    output [DATA_WIDTH-1:0] m4_apb_pwdata,
    output [3:0]            m4_apb_pstrb,
    input  [DATA_WIDTH-1:0] m4_apb_prdata,
    input                   m4_apb_pready,
    input                   m4_apb_pslverr,

    // APB Master Interface 5
    output [ADDR_WIDTH-1:0] m5_apb_paddr,
    output                  m5_apb_psel,
    output                  m5_apb_penable,
    output                  m5_apb_pwrite,
    output [DATA_WIDTH-1:0] m5_apb_pwdata,
    output [3:0]            m5_apb_pstrb,
    input  [DATA_WIDTH-1:0] m5_apb_prdata,
    input                   m5_apb_pready,
    input                   m5_apb_pslverr,

    // APB Master Interface 6
    output [ADDR_WIDTH-1:0] m6_apb_paddr,
    output                  m6_apb_psel,
    output                  m6_apb_penable,
    output                  m6_apb_pwrite,
    output [DATA_WIDTH-1:0] m6_apb_pwdata,
    output [3:0]            m6_apb_pstrb,
    input  [DATA_WIDTH-1:0] m6_apb_prdata,
    input                   m6_apb_pready,
    input                   m6_apb_pslverr,

    // APB Master Interface 7
    output [ADDR_WIDTH-1:0] m7_apb_paddr,
    output                  m7_apb_psel,
    output                  m7_apb_penable,
    output                  m7_apb_pwrite,
    output [DATA_WIDTH-1:0] m7_apb_pwdata,
    output [3:0]            m7_apb_pstrb,
    input  [DATA_WIDTH-1:0] m7_apb_prdata,
    input                   m7_apb_pready,
    input                   m7_apb_pslverr,

    // APB Master Interface 8
    output [ADDR_WIDTH-1:0] m8_apb_paddr,
    output                  m8_apb_psel,
    output                  m8_apb_penable,
    output                  m8_apb_pwrite,
    output [DATA_WIDTH-1:0] m8_apb_pwdata,
    output [3:0]            m8_apb_pstrb,
    input  [DATA_WIDTH-1:0] m8_apb_prdata,
    input                   m8_apb_pready,
    input                   m8_apb_pslverr,

    // APB Master Interface 9
    output [ADDR_WIDTH-1:0] m9_apb_paddr,
    output                  m9_apb_psel,
    output                  m9_apb_penable,
    output                  m9_apb_pwrite,
    output [DATA_WIDTH-1:0] m9_apb_pwdata,
    output [3:0]            m9_apb_pstrb,
    input  [DATA_WIDTH-1:0] m9_apb_prdata,
    input                   m9_apb_pready,
    input                   m9_apb_pslverr,

    // APB Master Interface 10
    output [ADDR_WIDTH-1:0] m10_apb_paddr,
    output                  m10_apb_psel,
    output                  m10_apb_penable,
    output                  m10_apb_pwrite,
    output [DATA_WIDTH-1:0] m10_apb_pwdata,
    output [3:0]            m10_apb_pstrb,
    input  [DATA_WIDTH-1:0] m10_apb_prdata,
    input                   m10_apb_pready,
    input                   m10_apb_pslverr,

    // APB Master Interface 11
    output [ADDR_WIDTH-1:0] m11_apb_paddr,
    output                  m11_apb_psel,
    output                  m11_apb_penable,
    output                  m11_apb_pwrite,
    output [DATA_WIDTH-1:0] m11_apb_pwdata,
    output [3:0]            m11_apb_pstrb,
    input  [DATA_WIDTH-1:0] m11_apb_prdata,
    input                   m11_apb_pready,
    input                   m11_apb_pslverr,

    // APB Master Interface 12
    output [ADDR_WIDTH-1:0] m12_apb_paddr,
    output                  m12_apb_psel,
    output                  m12_apb_penable,
    output                  m12_apb_pwrite,
    output [DATA_WIDTH-1:0] m12_apb_pwdata,
    output [3:0]            m12_apb_pstrb,
    input  [DATA_WIDTH-1:0] m12_apb_prdata,
    input                   m12_apb_pready,
    input                   m12_apb_pslverr,

    // APB Master Interface 13
    output [ADDR_WIDTH-1:0] m13_apb_paddr,
    output                  m13_apb_psel,
    output                  m13_apb_penable,
    output                  m13_apb_pwrite,
    output [DATA_WIDTH-1:0] m13_apb_pwdata,
    output [3:0]            m13_apb_pstrb,
    input  [DATA_WIDTH-1:0] m13_apb_prdata,
    input                   m13_apb_pready,
    input                   m13_apb_pslverr,

    // APB Master Interface 14
    output [ADDR_WIDTH-1:0] m14_apb_paddr,
    output                  m14_apb_psel,
    output                  m14_apb_penable,
    output                  m14_apb_pwrite,
    output [DATA_WIDTH-1:0] m14_apb_pwdata,
    output [3:0]            m14_apb_pstrb,
    input  [DATA_WIDTH-1:0] m14_apb_prdata,
    input                   m14_apb_pready,
    input                   m14_apb_pslverr,

    // APB Master Interface 15
    output [ADDR_WIDTH-1:0] m15_apb_paddr,
    output                  m15_apb_psel,
    output                  m15_apb_penable,
    output                  m15_apb_pwrite,
    output [DATA_WIDTH-1:0] m15_apb_pwdata,
    output [3:0]            m15_apb_pstrb,
    input  [DATA_WIDTH-1:0] m15_apb_prdata,
    input                   m15_apb_pready,
    input                   m15_apb_pslverr
);

    // Decoding logic
    wire [3:0] sel = s_apb_paddr[15:12]; // 4KB slot based on address bit 12
    wire in_range = (s_apb_paddr[31:16] == BASE_ADDR[31:16]); // Match base address

    // Port 0 Assignments
    assign m0_apb_paddr   = s_apb_paddr;
    assign m0_apb_penable = s_apb_penable;
    assign m0_apb_pwrite  = s_apb_pwrite;
    assign m0_apb_pwdata  = s_apb_pwdata;
    assign m0_apb_pstrb   = s_apb_pstrb;
    assign m0_apb_psel    = s_apb_psel && in_range && (sel == 4'h0);

    // Port 1 Assignments
    assign m1_apb_paddr   = s_apb_paddr;
    assign m1_apb_penable = s_apb_penable;
    assign m1_apb_pwrite  = s_apb_pwrite;
    assign m1_apb_pwdata  = s_apb_pwdata;
    assign m1_apb_pstrb   = s_apb_pstrb;
    assign m1_apb_psel    = s_apb_psel && in_range && (sel == 4'h1);

    // Port 2 Assignments
    assign m2_apb_paddr   = s_apb_paddr;
    assign m2_apb_penable = s_apb_penable;
    assign m2_apb_pwrite  = s_apb_pwrite;
    assign m2_apb_pwdata  = s_apb_pwdata;
    assign m2_apb_pstrb   = s_apb_pstrb;
    assign m2_apb_psel    = s_apb_psel && in_range && (sel == 4'h2);

    // Port 3 Assignments
    assign m3_apb_paddr   = s_apb_paddr;
    assign m3_apb_penable = s_apb_penable;
    assign m3_apb_pwrite  = s_apb_pwrite;
    assign m3_apb_pwdata  = s_apb_pwdata;
    assign m3_apb_pstrb   = s_apb_pstrb;
    assign m3_apb_psel    = s_apb_psel && in_range && (sel == 4'h3);

    // Port 4 Assignments
    assign m4_apb_paddr   = s_apb_paddr;
    assign m4_apb_penable = s_apb_penable;
    assign m4_apb_pwrite  = s_apb_pwrite;
    assign m4_apb_pwdata  = s_apb_pwdata;
    assign m4_apb_pstrb   = s_apb_pstrb;
    assign m4_apb_psel    = s_apb_psel && in_range && (sel == 4'h4);

    // Port 5 Assignments
    assign m5_apb_paddr   = s_apb_paddr;
    assign m5_apb_penable = s_apb_penable;
    assign m5_apb_pwrite  = s_apb_pwrite;
    assign m5_apb_pwdata  = s_apb_pwdata;
    assign m5_apb_pstrb   = s_apb_pstrb;
    assign m5_apb_psel    = s_apb_psel && in_range && (sel == 4'h5);

    // Port 6 Assignments
    assign m6_apb_paddr   = s_apb_paddr;
    assign m6_apb_penable = s_apb_penable;
    assign m6_apb_pwrite  = s_apb_pwrite;
    assign m6_apb_pwdata  = s_apb_pwdata;
    assign m6_apb_pstrb   = s_apb_pstrb;
    assign m6_apb_psel    = s_apb_psel && in_range && (sel == 4'h6);

    // Port 7 Assignments
    assign m7_apb_paddr   = s_apb_paddr;
    assign m7_apb_penable = s_apb_penable;
    assign m7_apb_pwrite  = s_apb_pwrite;
    assign m7_apb_pwdata  = s_apb_pwdata;
    assign m7_apb_pstrb   = s_apb_pstrb;
    assign m7_apb_psel    = s_apb_psel && in_range && (sel == 4'h7);

    // Port 8 Assignments
    assign m8_apb_paddr   = s_apb_paddr;
    assign m8_apb_penable = s_apb_penable;
    assign m8_apb_pwrite  = s_apb_pwrite;
    assign m8_apb_pwdata  = s_apb_pwdata;
    assign m8_apb_pstrb   = s_apb_pstrb;
    assign m8_apb_psel    = s_apb_psel && in_range && (sel == 4'h8);

    // Port 9 Assignments
    assign m9_apb_paddr   = s_apb_paddr;
    assign m9_apb_penable = s_apb_penable;
    assign m9_apb_pwrite  = s_apb_pwrite;
    assign m9_apb_pwdata  = s_apb_pwdata;
    assign m9_apb_pstrb   = s_apb_pstrb;
    assign m9_apb_psel    = s_apb_psel && in_range && (sel == 4'h9);

    // Port 10 Assignments
    assign m10_apb_paddr   = s_apb_paddr;
    assign m10_apb_penable = s_apb_penable;
    assign m10_apb_pwrite  = s_apb_pwrite;
    assign m10_apb_pwdata  = s_apb_pwdata;
    assign m10_apb_pstrb   = s_apb_pstrb;
    assign m10_apb_psel    = s_apb_psel && in_range && (sel == 4'ha);

    // Port 11 Assignments
    assign m11_apb_paddr   = s_apb_paddr;
    assign m11_apb_penable = s_apb_penable;
    assign m11_apb_pwrite  = s_apb_pwrite;
    assign m11_apb_pwdata  = s_apb_pwdata;
    assign m11_apb_pstrb   = s_apb_pstrb;
    assign m11_apb_psel    = s_apb_psel && in_range && (sel == 4'hb);

    // Port 12 Assignments
    assign m12_apb_paddr   = s_apb_paddr;
    assign m12_apb_penable = s_apb_penable;
    assign m12_apb_pwrite  = s_apb_pwrite;
    assign m12_apb_pwdata  = s_apb_pwdata;
    assign m12_apb_pstrb   = s_apb_pstrb;
    assign m12_apb_psel    = s_apb_psel && in_range && (sel == 4'hc);

    // Port 13 Assignments
    assign m13_apb_paddr   = s_apb_paddr;
    assign m13_apb_penable = s_apb_penable;
    assign m13_apb_pwrite  = s_apb_pwrite;
    assign m13_apb_pwdata  = s_apb_pwdata;
    assign m13_apb_pstrb   = s_apb_pstrb;
    assign m13_apb_psel    = s_apb_psel && in_range && (sel == 4'hd);

    // Port 14 Assignments
    assign m14_apb_paddr   = s_apb_paddr;
    assign m14_apb_penable = s_apb_penable;
    assign m14_apb_pwrite  = s_apb_pwrite;
    assign m14_apb_pwdata  = s_apb_pwdata;
    assign m14_apb_pstrb   = s_apb_pstrb;
    assign m14_apb_psel    = s_apb_psel && in_range && (sel == 4'he);

    // Port 15 Assignments
    assign m15_apb_paddr   = s_apb_paddr;
    assign m15_apb_penable = s_apb_penable;
    assign m15_apb_pwrite  = s_apb_pwrite;
    assign m15_apb_pwdata  = s_apb_pwdata;
    assign m15_apb_pstrb   = s_apb_pstrb;
    assign m15_apb_psel    = s_apb_psel && in_range && (sel == 4'hf);

    // Mux response back to master
    reg [DATA_WIDTH-1:0] mux_prdata;
    reg                  mux_pready;
    reg                  mux_pslverr;

    always @(*) begin
        case (sel)
            4'h0: begin
                mux_prdata = m0_apb_prdata;
                mux_pready = m0_apb_pready;
                mux_pslverr = m0_apb_pslverr;
            end
            4'h1: begin
                mux_prdata = m1_apb_prdata;
                mux_pready = m1_apb_pready;
                mux_pslverr = m1_apb_pslverr;
            end
            4'h2: begin
                mux_prdata = m2_apb_prdata;
                mux_pready = m2_apb_pready;
                mux_pslverr = m2_apb_pslverr;
            end
            4'h3: begin
                mux_prdata = m3_apb_prdata;
                mux_pready = m3_apb_pready;
                mux_pslverr = m3_apb_pslverr;
            end
            4'h4: begin
                mux_prdata = m4_apb_prdata;
                mux_pready = m4_apb_pready;
                mux_pslverr = m4_apb_pslverr;
            end
            4'h5: begin
                mux_prdata = m5_apb_prdata;
                mux_pready = m5_apb_pready;
                mux_pslverr = m5_apb_pslverr;
            end
            4'h6: begin
                mux_prdata = m6_apb_prdata;
                mux_pready = m6_apb_pready;
                mux_pslverr = m6_apb_pslverr;
            end
            4'h7: begin
                mux_prdata = m7_apb_prdata;
                mux_pready = m7_apb_pready;
                mux_pslverr = m7_apb_pslverr;
            end
            4'h8: begin
                mux_prdata = m8_apb_prdata;
                mux_pready = m8_apb_pready;
                mux_pslverr = m8_apb_pslverr;
            end
            4'h9: begin
                mux_prdata = m9_apb_prdata;
                mux_pready = m9_apb_pready;
                mux_pslverr = m9_apb_pslverr;
            end
            4'ha: begin
                mux_prdata = m10_apb_prdata;
                mux_pready = m10_apb_pready;
                mux_pslverr = m10_apb_pslverr;
            end
            4'hb: begin
                mux_prdata = m11_apb_prdata;
                mux_pready = m11_apb_pready;
                mux_pslverr = m11_apb_pslverr;
            end
            4'hc: begin
                mux_prdata = m12_apb_prdata;
                mux_pready = m12_apb_pready;
                mux_pslverr = m12_apb_pslverr;
            end
            4'hd: begin
                mux_prdata = m13_apb_prdata;
                mux_pready = m13_apb_pready;
                mux_pslverr = m13_apb_pslverr;
            end
            4'he: begin
                mux_prdata = m14_apb_prdata;
                mux_pready = m14_apb_pready;
                mux_pslverr = m14_apb_pslverr;
            end
            4'hf: begin
                mux_prdata = m15_apb_prdata;
                mux_pready = m15_apb_pready;
                mux_pslverr = m15_apb_pslverr;
            end
        endcase
    end

    assign s_apb_prdata  = in_range ? mux_prdata  : {DATA_WIDTH{1'b0}};
    assign s_apb_pready  = in_range ? mux_pready  : 1'b1;
    assign s_apb_pslverr = in_range ? mux_pslverr : 1'b1;

endmodule

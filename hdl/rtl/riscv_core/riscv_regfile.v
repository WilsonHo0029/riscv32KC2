// RISC-V Register File
// 32x32 bit registers (x0-x31)
// x0 is hardwired to zero

module riscv_regfile (
    input               clk,
    input               rst_n,
    
    // Read port 1
    input  [4:0]        rs1_addr,
    output [31:0]       rs1_data,
    
    // Read port 2
    input  [4:0]        rs2_addr,
    output [31:0]       rs2_data,
    
    // Write port
    input               we,
    input  [4:0]        wr_addr,
    input  [31:0]       wr_data
);

    //----------------------------------------------------------------------------
    // Constants
    //----------------------------------------------------------------------------
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 5;
    localparam REG_COUNT = 32;
    localparam REG_X0_ADDR = {ADDR_WIDTH{1'b0}};  // x0 register address (hardwired to zero)

    //----------------------------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------------------------
    // Register file storage
    wire [DATA_WIDTH-1:0] regfile [0:REG_COUNT-1];
    reg [DATA_WIDTH-1:0] ra;
    reg [DATA_WIDTH-1:0] sp;
    reg [DATA_WIDTH-1:0] gp;
    reg [DATA_WIDTH-1:0] tp;
    reg [DATA_WIDTH-1:0] t0;
    reg [DATA_WIDTH-1:0] t1;
    reg [DATA_WIDTH-1:0] t2;
    reg [DATA_WIDTH-1:0] s0;
    reg [DATA_WIDTH-1:0] s1;
    reg [DATA_WIDTH-1:0] a0;
    reg [DATA_WIDTH-1:0] a1;
    reg [DATA_WIDTH-1:0] a2;
    reg [DATA_WIDTH-1:0] a3;
    reg [DATA_WIDTH-1:0] a4;
    reg [DATA_WIDTH-1:0] a5;
    reg [DATA_WIDTH-1:0] a6;
    reg [DATA_WIDTH-1:0] a7;
    reg [DATA_WIDTH-1:0] s2;
    reg [DATA_WIDTH-1:0] s3;
    reg [DATA_WIDTH-1:0] s4;
    reg [DATA_WIDTH-1:0] s5;
    reg [DATA_WIDTH-1:0] s6;
    reg [DATA_WIDTH-1:0] s7;
    reg [DATA_WIDTH-1:0] s8;
    reg [DATA_WIDTH-1:0] s9;
    reg [DATA_WIDTH-1:0] s10;
    reg [DATA_WIDTH-1:0] s11;
    reg [DATA_WIDTH-1:0] t3;
    reg [DATA_WIDTH-1:0] t4;
    reg [DATA_WIDTH-1:0] t5;
    reg [DATA_WIDTH-1:0] t6;
    assign rs1_data = regfile[rs1_addr];
    assign rs2_data = regfile[rs2_addr];
    
    //----------------------------------------------------------------------------
    // Synchronous Write Logic
    //----------------------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ra  <= {DATA_WIDTH{1'b0}};
            sp  <= {DATA_WIDTH{1'b0}};
            gp  <= {DATA_WIDTH{1'b0}};
            tp  <= {DATA_WIDTH{1'b0}};
            t0  <= {DATA_WIDTH{1'b0}};
            t1  <= {DATA_WIDTH{1'b0}};
            t2  <= {DATA_WIDTH{1'b0}};
            s0  <= {DATA_WIDTH{1'b0}};
            s1  <= {DATA_WIDTH{1'b0}};
            a0  <= {DATA_WIDTH{1'b0}};
            a1  <= {DATA_WIDTH{1'b0}};
            a2  <= {DATA_WIDTH{1'b0}};
            a3  <= {DATA_WIDTH{1'b0}};
            a4  <= {DATA_WIDTH{1'b0}};
            a5  <= {DATA_WIDTH{1'b0}};
            a6  <= {DATA_WIDTH{1'b0}};
            a7  <= {DATA_WIDTH{1'b0}};
            s2  <= {DATA_WIDTH{1'b0}};
            s3  <= {DATA_WIDTH{1'b0}};
            s4  <= {DATA_WIDTH{1'b0}};
            s5  <= {DATA_WIDTH{1'b0}};
            s6  <= {DATA_WIDTH{1'b0}};
            s7  <= {DATA_WIDTH{1'b0}};
            s8  <= {DATA_WIDTH{1'b0}};
            s9  <= {DATA_WIDTH{1'b0}};
            s10 <= {DATA_WIDTH{1'b0}};
            s11 <= {DATA_WIDTH{1'b0}};
            t3  <= {DATA_WIDTH{1'b0}};
            t4  <= {DATA_WIDTH{1'b0}};
            t5  <= {DATA_WIDTH{1'b0}};
            t6  <= {DATA_WIDTH{1'b0}};
        end else begin
            ra  <= (we && (wr_addr == 5'd1))  ? wr_data : ra;
            sp  <= (we && (wr_addr == 5'd2))  ? wr_data : sp;
            gp  <= (we && (wr_addr == 5'd3))  ? wr_data : gp;
            tp  <= (we && (wr_addr == 5'd4))  ? wr_data : tp;
            t0  <= (we && (wr_addr == 5'd5))  ? wr_data : t0;
            t1  <= (we && (wr_addr == 5'd6))  ? wr_data : t1;
            t2  <= (we && (wr_addr == 5'd7))  ? wr_data : t2;
            s0  <= (we && (wr_addr == 5'd8))  ? wr_data : s0;
            s1  <= (we && (wr_addr == 5'd9))  ? wr_data : s1;
            a0  <= (we && (wr_addr == 5'd10)) ? wr_data : a0;
            a1  <= (we && (wr_addr == 5'd11)) ? wr_data : a1;
            a2  <= (we && (wr_addr == 5'd12)) ? wr_data : a2;
            a3  <= (we && (wr_addr == 5'd13)) ? wr_data : a3;
            a4  <= (we && (wr_addr == 5'd14)) ? wr_data : a4;
            a5  <= (we && (wr_addr == 5'd15)) ? wr_data : a5;
            a6  <= (we && (wr_addr == 5'd16)) ? wr_data : a6;
            a7  <= (we && (wr_addr == 5'd17)) ? wr_data : a7;
            s2  <= (we && (wr_addr == 5'd18)) ? wr_data : s2;
            s3  <= (we && (wr_addr == 5'd19)) ? wr_data : s3;
            s4  <= (we && (wr_addr == 5'd20)) ? wr_data : s4;
            s5  <= (we && (wr_addr == 5'd21)) ? wr_data : s5;
            s6  <= (we && (wr_addr == 5'd22)) ? wr_data : s6;
            s7  <= (we && (wr_addr == 5'd23)) ? wr_data : s7;
            s8  <= (we && (wr_addr == 5'd24)) ? wr_data : s8;
            s9  <= (we && (wr_addr == 5'd25)) ? wr_data : s9;
            s10 <= (we && (wr_addr == 5'd26)) ? wr_data : s10;
            s11 <= (we && (wr_addr == 5'd27)) ? wr_data : s11;
            t3  <= (we && (wr_addr == 5'd28)) ? wr_data : t3;
            t4  <= (we && (wr_addr == 5'd29)) ? wr_data : t4;
            t5  <= (we && (wr_addr == 5'd30)) ? wr_data : t5;
            t6  <= (we && (wr_addr == 5'd31)) ? wr_data : t6;
        end
    end

    assign regfile[0]  = {DATA_WIDTH{1'b0}};
    assign regfile[1]  = ra;
    assign regfile[2]  = sp;
    assign regfile[3]  = gp;
    assign regfile[4]  = tp;
    assign regfile[5]  = t0;
    assign regfile[6]  = t1;
    assign regfile[7]  = t2;
    assign regfile[8]  = s0;
    assign regfile[9]  = s1;
    assign regfile[10] = a0;
    assign regfile[11] = a1;
    assign regfile[12] = a2;
    assign regfile[13] = a3;
    assign regfile[14] = a4;
    assign regfile[15] = a5;
    assign regfile[16] = a6;
    assign regfile[17] = a7;
    assign regfile[18] = s2;
    assign regfile[19] = s3;
    assign regfile[20] = s4;
    assign regfile[21] = s5;
    assign regfile[22] = s6;
    assign regfile[23] = s7;
    assign regfile[24] = s8;
    assign regfile[25] = s9;
    assign regfile[26] = s10;
    assign regfile[27] = s11;
    assign regfile[28] = t3;
    assign regfile[29] = t4;
    assign regfile[30] = t5;
    assign regfile[31] = t6;

endmodule


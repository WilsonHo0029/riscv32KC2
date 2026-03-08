// Debug ROM for RISC-V Debug Specification 0.13
// Contains instructions executed when hart enters debug mode

module debug_rom_013(
    input       [5:0]   addr_i,
    output      [31:0]  rdata_o
);

    wire [31:0] rom [0:63];
    
    assign rdata_o = rom[addr_i];
    
    assign rom[0]  = 32'h00c0006f;
    assign rom[1]  = 32'h07c0006f;
    assign rom[2]  = 32'h04c0006f;
    assign rom[3]  = 32'h0ff0000f;
    assign rom[4]  = 32'h7b241073;
    assign rom[5]  = 32'h7b351073;
    assign rom[6]  = 32'h00000517;
    assign rom[7]  = 32'h00c55513;
    assign rom[8]  = 32'h00c51513;
    assign rom[9]  = 32'hf1402473;
    assign rom[10] = 32'h10852023;
    assign rom[11] = 32'h00a40433;
    assign rom[12] = 32'h40044403;
    assign rom[13] = 32'h00147413;
    assign rom[14] = 32'h02041c63;
    assign rom[15] = 32'hf1402473;
    assign rom[16] = 32'h00a40433;
    assign rom[17] = 32'h40044403;
    assign rom[18] = 32'h00247413;
    assign rom[19] = 32'hfa041ce3;
    assign rom[20] = 32'hfd5ff06f;
    assign rom[21] = 32'h00000517;
    assign rom[22] = 32'h00c55513;
    assign rom[23] = 32'h00c51513;
    assign rom[24] = 32'h10052623;
    assign rom[25] = 32'h7b302573;
    assign rom[26] = 32'h7b202473;
    assign rom[27] = 32'h00100073;
    assign rom[28] = 32'h10052223;
    assign rom[29] = 32'h7b302573;
    assign rom[30] = 32'h7b202473;
    assign rom[31] = 32'ha85ff06f;
    assign rom[32] = 32'hf1402473;
    assign rom[33] = 32'h10852423;
    assign rom[34] = 32'h7b302573;
    assign rom[35] = 32'h7b202473;
    assign rom[36] = 32'h7b200073;
    assign rom[37] = 32'h00000000;
    
    // Fill remaining entries with NOP
    genvar i;
    generate
        for (i = 38; i < 64; i = i + 1) begin : gen_rom_nop
            assign rom[i] = 32'h00000013;  // NOP
        end
    endgenerate

endmodule


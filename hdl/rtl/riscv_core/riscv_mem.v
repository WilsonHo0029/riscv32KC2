//=============================================================================
// RISC-V Memory Operations Module (MEM Stage)
//=============================================================================
// This module encapsulates all memory-related operations for Stage 2:
//   - Load/Store operations
//   - Address misalignment detection
//   - Memory interface control (address, data, byte enable)
//   - Memory read data sign extension
//=============================================================================

`include "riscv_defines.v"

module riscv_mem (
    // Clock and Reset
    input               clk,
    input               rst_n,
    
    // Pipeline Control
    input               if_id_valid,        // Instruction valid in decode stage
    
    // Memory Address (from Execution Unit)
    input  [31:0]       alu_mem_addr,         // Memory address from ALU
    
    // Register File Data (for store operations)
    input  [31:0]       rs1_data,           // Source register 1 (address for memory operations)
    input  [31:0]       rs2_data,           // Source register 2 (write data for stores)
    
    // Control Signals (from Decode Stage)
    input               ctrl_mem_req,       // Memory request
    input               ctrl_mem_we,        // Memory write enable
    input  [2:0]        ctrl_mem_size,      // Memory size (000: byte, 001: half, 010: word)
    input               ctrl_mem_sign_ext,  // Memory sign extend
    
    // External Memory Interface (to AXI4/Data Bus)
    output reg          mem_req,            // Memory access request (Load/Store)
    output reg          mem_we,             // Memory write enable
    output [31:0]       mem_addr,           // Memory address
    output reg [31:0]   mem_wdata,          // Memory write data
    output reg [3:0]    mem_be,             // Memory byte enable
    input  [31:0]       mem_rdata,          // Memory read data
    input               mem_ready,          // Memory ready signal
    input               mem_rvalid,         // Read data valid signal
    
    // Memory Operation Results
    output reg [31:0]   mem_result,         // Memory read result (sign-extended)
    
    // Pipeline Control Outputs
    output              mem_pending,        // Memory operation pending (combinational)
    
    // Exception Outputs
    output              exception_load_addr_misaligned,   // Load address misalignment
    output              exception_store_addr_misaligned   // Store address misalignment
);

    //----------------------------------------------------------------------------
    // Constants
    //----------------------------------------------------------------------------
    // Memory alignment constants
    localparam [1:0]  WORD_ALIGNED     = 2'b00;
    localparam        HALFWORD_ALIGNED = 1'b0;
    
    

    
    //----------------------------------------------------------------------------
    // Helper Functions
    //----------------------------------------------------------------------------
    // Generate memory byte enable based on memory size
    function [3:0] get_mem_byte_enable;
        input [2:0] mem_size;
        input [1:0] addr_lsb;
        begin
            case (mem_size)
                `MEM_SIZE_BYTE: begin
                    case (addr_lsb)
                        2'b00: get_mem_byte_enable = 4'b0001;
                        2'b01: get_mem_byte_enable = 4'b0010;
                        2'b10: get_mem_byte_enable = 4'b0100;
                        2'b11: get_mem_byte_enable = 4'b1000;
                    endcase
                end
                `MEM_SIZE_HALFWORD: begin
                    case (addr_lsb[1])
                        1'b0: get_mem_byte_enable = 4'b0011;  // Address aligned to 0x0 or 0x2
                        1'b1: get_mem_byte_enable = 4'b1100;  // Address aligned to 0x2 or 0x3
                    endcase
                end
                `MEM_SIZE_WORD: begin
                    get_mem_byte_enable = 4'b1111;
                end
                default: get_mem_byte_enable = 4'b1111;
            endcase
        end
    endfunction
    
    // Sign-extend memory read data based on size
    function [31:0] sign_extend_mem_data;
        input [31:0] mem_data;
        input [2:0]  mem_size;
        input        sign_ext;
        input [1:0]  addr_lsb;
        begin
            case (mem_size)
                `MEM_SIZE_BYTE: begin
                    case (addr_lsb)
                        2'b00: sign_extend_mem_data = sign_ext ? 
                            {{24{mem_data[7]}}, mem_data[7:0]} : 
                            {{24{1'b0}}, mem_data[7:0]};
                        2'b01: sign_extend_mem_data = sign_ext ? 
                            {{24{mem_data[15]}}, mem_data[15:8]} : 
                            {{24{1'b0}}, mem_data[15:8]};
                        2'b10: sign_extend_mem_data = sign_ext ? 
                            {{24{mem_data[23]}}, mem_data[23:16]} : 
                            {{24{1'b0}}, mem_data[23:16]};
                        2'b11: sign_extend_mem_data = sign_ext ? 
                            {{24{mem_data[31]}}, mem_data[31:24]} : 
                            {{24{1'b0}}, mem_data[31:24]};
                    endcase
                end
                `MEM_SIZE_HALFWORD: begin
                    case (addr_lsb[1])
                        1'b0: sign_extend_mem_data = sign_ext ? 
                            {{16{mem_data[15]}}, mem_data[15:0]} : 
                            {{16{1'b0}}, mem_data[15:0]};
                        1'b1: sign_extend_mem_data = sign_ext ? 
                            {{16{mem_data[31]}}, mem_data[31:16]} : 
                            {{16{1'b0}}, mem_data[31:16]};
                    endcase
                end
                `MEM_SIZE_WORD: begin
                    sign_extend_mem_data = mem_data;
                end
                default: sign_extend_mem_data = mem_data;
            endcase
        end
    endfunction
    
    //----------------------------------------------------------------------------
    // Memory Interface Control
    //----------------------------------------------------------------------------
    // Memory request generation: Asserted when instruction requires memory access
    // and instruction is valid in decode stage. Request remains active until
    // operation completes (handled by pipeline stall logic).
    // AMO operations override normal memory control signals. 
    wire        mem_access_active = ctrl_mem_req && if_id_valid;
    wire        mem_rd_req = mem_access_active & !ctrl_mem_we;
    wire        mem_wr_req = mem_access_active & ctrl_mem_we;
    reg         s_wait_rvalid;
    assign mem_addr = alu_mem_addr;

    always @(*) begin
        mem_we = ctrl_mem_we;
        // Align write data based on address and size
        case (ctrl_mem_size)
            `MEM_SIZE_BYTE: begin
                case (alu_mem_addr[1:0])
                    2'b00: mem_wdata = rs2_data;
                    2'b01: mem_wdata = rs2_data << 8;
                    2'b10: mem_wdata = rs2_data << 16;
                    2'b11: mem_wdata = rs2_data << 24;
                endcase
            end
            `MEM_SIZE_HALFWORD: begin
                case (alu_mem_addr[1])
                    1'b0: mem_wdata = rs2_data;
                    1'b1: mem_wdata = rs2_data << 16;
                endcase
            end
            `MEM_SIZE_WORD: begin
                mem_wdata = rs2_data;
            end
            default: mem_wdata = rs2_data;
        endcase
        mem_be = get_mem_byte_enable(ctrl_mem_size, alu_mem_addr[1:0]);
    end

    always @(*) begin
        //if (mem_rd_req & mem_ready & ~s_wait_rvalid)
        if (mem_rd_req & ~s_wait_rvalid)
            mem_req <= 1'b1;
      //  else if (mem_wr_req & mem_ready)
        else if (mem_wr_req)
            mem_req <= 1'b1;
        else
            mem_req <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            s_wait_rvalid <= 1'b0;
        else if (s_wait_rvalid & mem_rvalid)
            s_wait_rvalid <= 1'b0;            
        else if (mem_rd_req & ~s_wait_rvalid)
            s_wait_rvalid <= 1'b1;
    end
    //----------------------------------------------------------------------------
    // Memory Read Data Processing
    //----------------------------------------------------------------------------
    // Process memory read data: Sign-extend based on memory size and sign extension
    // control signal. Only process when load operation completes (mem_rvalid = 1).
    
    always @(*) begin
        if (s_wait_rvalid & mem_rvalid) begin
            // Load operation complete: Sign-extend result
            mem_result = sign_extend_mem_data(mem_rdata, ctrl_mem_size, ctrl_mem_sign_ext, alu_mem_addr[1:0]);
        end else begin
            mem_result = {32{1'b0}};
        end
    end
    
    //----------------------------------------------------------------------------
    // Pipeline Control: Pending Operation Detection
    //----------------------------------------------------------------------------
    //   - Zero latency: Updates immediately based on current instruction state
    assign mem_pending = ctrl_mem_req && if_id_valid && 
                         ((!ctrl_mem_we && !mem_rvalid) || (ctrl_mem_we && !mem_ready));
    

    //----------------------------------------------------------------------------
    // Address Misalignment Detection
    //----------------------------------------------------------------------------
    wire        mem_access_word;
    wire        mem_access_halfword;
    wire        addr_word_misaligned;
    wire        addr_halfword_misaligned;
    
    assign mem_access_word          = (ctrl_mem_size == `MEM_SIZE_WORD);
    assign mem_access_halfword      = (ctrl_mem_size == `MEM_SIZE_HALFWORD);
    assign addr_word_misaligned     = (alu_mem_addr[1:0] != WORD_ALIGNED);
    assign addr_halfword_misaligned = (alu_mem_addr[0] != HALFWORD_ALIGNED);
    
    assign exception_load_addr_misaligned  = mem_rd_req & mem_ready & ~s_wait_rvalid & 
                                             ((mem_access_word && addr_word_misaligned) ||
                                              (mem_access_halfword && addr_halfword_misaligned));
    assign exception_store_addr_misaligned = mem_wr_req & mem_ready & 
                                             ((mem_access_word && addr_word_misaligned) ||
                                              (mem_access_halfword && addr_halfword_misaligned));

endmodule


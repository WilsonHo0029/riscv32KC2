// RISC-V Debug Module (Debug Specification 0.13)
// Implements Debug Module with DMI (Debug Module Interface)
// Supports multi-hart configuration
`ifndef RISCV_DEFINES_V
`include "riscv_defines.v"
`endif

module riscv_debug_module #(
    parameter HART_NUM = 1,        // Number of harts supported
    parameter HART_ID_W = 1        // Hart ID width ($clog2(HART_NUM))
)(
    input               clk,
    input               rst_n,
    
    // JTAG Clock and Reset (for CDC)
    input               tck,        // JTAG test clock
    input               trst_n,     // JTAG test reset (optional, active low)
    
    // DMI (Debug Module Interface) - TCK domain (from DTM)
    input               dmi_req_valid_tck,
    output              dmi_req_ready_tck,
    input  [6:0]        dmi_req_addr_tck,
    input  [1:0]        dmi_req_op_tck,      // 00: NOP, 01: READ, 10: WRITE
    input  [31:0]       dmi_req_data_tck,
    output              dmi_resp_valid_tck,
    input               dmi_resp_ready_tck,
    output [31:0]       dmi_resp_data_tck,
    output [1:0]        dmi_resp_resp_tck,   // 00: OK, 01: FAILED, 10: UNSUPPORTED
    
    // Hart control interface (multi-hart)
    output reg [HART_NUM-1:0] debug_req,       // Halt request per hart
    input  [HART_NUM-1:0]     debug_mode,      // Debug mode per hart (hart is in debug mode)
    output reg		      ndmreset,
    // APB Slave Interface (for dm_mem access)
    input               m_apb_psel,
    input               m_apb_penable,
    input  [31:0]       m_apb_paddr,
    input               m_apb_pwrite,
    input  [31:0]       m_apb_pwdata,
    output reg [31:0]   m_apb_prdata,
    output reg          m_apb_pready,
    output reg          m_apb_pslverr
);

    //----------------------------------------------------------------------------
    // Constants
    //----------------------------------------------------------------------------
    
    // DMI Operation Codes
    localparam [1:0] DMI_OP_NOP   = 2'b00;
    localparam [1:0] DMI_OP_READ  = 2'b01;
    localparam [1:0] DMI_OP_WRITE = 2'b10;
    
    // DMI Response Codes
    localparam [1:0] DMI_RESP_OK          = 2'b00;
    localparam [1:0] DMI_RESP_FAILED      = 2'b01;
    localparam [1:0] DMI_RESP_UNSUPPORTED = 2'b10;
    
    // Register Initialization Values
    localparam [31:0] DMSTATUS_INIT   = 32'h00002000;  // version = 0.13
    localparam [31:0] HARTINFO_INIT   = 32'h00000004;  // datasize = 4, dataaddr = 0

    // Command Field Constants
    localparam [7:0] CMD_TYPE_ACCESS_REG = 8'h0;
    localparam [2:0] CMD_REG_TYPE_GPR    = 3'b000;
    localparam [2:0] CMD_ERROR_UNSUPPORTED = 3'h2;
    localparam [2:0] CMD_ERROR_BUSY = 3'd1;  // CMD_BUSY error code
    localparam [31:0] RISCV_NOP = 32'h00000013;      // ADDI x0, x0, 0
    // Register Field Constants
    localparam [3:0] DMSTATUS_VERSION = 4'b0010;  // version = 0.13
    localparam [4:0] ABSTRACTCS_PROGBUFSIZE = 5'd8;  // progbufsize (4 instructions)
    localparam [3:0] ABSTRACTCS_DATACOUNT = 4'd2;  // datacount
    // Data Width Constants
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 7;
    localparam OP_WIDTH = 2;
    localparam RESP_WIDTH = 2;
    localparam PROGBUF_SIZE = 8;
    
    //----------------------------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------------------------
    // Debug Module registers (combinational - assigned via assign statements)
    wire [DATA_WIDTH-1:0] dmcontrol;
    wire [DATA_WIDTH-1:0] dmstatus;
    reg [DATA_WIDTH-1:0] hartinfo;
    wire [DATA_WIDTH-1:0] abstractcs;
    wire [DATA_WIDTH-1:0] command;
    wire [DATA_WIDTH-1:0] abstractauto;
    reg [DATA_WIDTH-1:0] data0;
    reg [DATA_WIDTH-1:0] data1;
    reg [DATA_WIDTH-1:0] progbuf [0:PROGBUF_SIZE-1];
    
    // Hart selection and state (multi-hart)
    reg [19:0] hartsel;  // Hart selection register (20 bits per spec)
    wire [HART_ID_W-1:0] hartsel_index;  // Index into hart arrays
    
    // Hart state (per-hart arrays)
    wire [HART_NUM-1:0] halted;
    wire [HART_NUM-1:0] resuming;
    wire [HART_NUM-1:0] resuming_ack;  // Acknowledge from hart when resuming completes
    reg  [HART_NUM-1:0] halt_req;  // Halt request register
    reg  [HART_NUM-1:0] resume_req;  // Resume request register
    reg  [HART_NUM-1:0] havereset;  // Per-hart reset tracking
    
    // Debug Module control state
    reg dm_active;
    //reg ndmreset;
    
    // Extract hartsel index (only use lower bits needed for indexing)
    assign hartsel_index = hartsel[HART_ID_W-1:0];
  
    
    // Abstract command handling
    reg [7:0] abs_cmdtype;
    reg [23:0] abs_control;
    reg abs_command_valid;
    wire fsm_cmd_busy;  // Abstract command FSM busy signal
    reg [2:0] r_fsm_cmd_error;
    
    // Auto-execute registers
    reg [7:0] autoexecprogbuf;
    reg autoexecdata;
    
    // DMI request handling registers (CLK domain) - declared before CDC section
    reg dmi_resp_valid_reg;
    reg [DATA_WIDTH-1:0] dmi_resp_data_reg;
    reg [RESP_WIDTH-1:0] dmi_resp_resp_reg;
    
    //----------------------------------------------------------------------------
    // Clock Domain Crossing (CDC) for DMI Interface
    //----------------------------------------------------------------------------
    // Request Path: TCK -> CLK (using buf_cdc_rx, clocked by CLK)
    // Format: {addr[40:34], data[33:2], op[1:0]}
    wire [40:0] dmi_req_dat_tck;
    wire [40:0] dmi_req_dat_clk;
    wire dmi_req_valid_clk;
    wire dmi_req_ready_clk;
    
    // Pack request data according to RISC-V Debug Spec 0.13: {addr, data, op}
    assign dmi_req_dat_tck = {dmi_req_addr_tck, dmi_req_data_tck, dmi_req_op_tck};
    
    buf_cdc_rx #(
        .DW(41)   // 7-bit addr + 32-bit data + 2-bit op
    ) u_dmi_req_cdc (
        // Async input (from TCK domain)
        .i_vld_a(dmi_req_valid_tck),
        .i_rdy(dmi_req_ready_tck),
        .i_dat(dmi_req_dat_tck),
        
        // Clocked output (CLK domain)
        .o_vld(dmi_req_valid_clk),
        .o_rdy(dmi_req_ready_clk),
        .o_dat(dmi_req_dat_clk),
        
        // Clock and reset (CLK domain)
        .clk(clk),
        .rst_n(rst_n)
    );
    
    // Unpack request data (CLK domain)
    // Format: {addr[40:34], data[33:2], op[1:0]}
    wire [6:0]  dmi_req_addr;
    wire [1:0]  dmi_req_op;
    wire [31:0] dmi_req_data;
    assign dmi_req_addr = dmi_req_dat_clk[40:34];
    assign dmi_req_data = dmi_req_dat_clk[33:2];
    assign dmi_req_op = dmi_req_dat_clk[1:0];
    
    // Request operation signals
    wire dtm_req_rd = (dmi_req_op == DMI_OP_READ) & dmi_req_valid_clk;
    wire dtm_req_wr = (dmi_req_op == DMI_OP_WRITE) & dmi_req_valid_clk;
    wire dtm_req_rd_or_wr = ((dmi_req_op == DMI_OP_WRITE) | (dmi_req_op == DMI_OP_READ)) & dmi_req_valid_clk;
    
    // Clear resume acknowledge logic (declared after DMI signals)
    wire clear_resume_ack = ~resume_req[hartsel_index] & 
                            ((dmi_req_addr == `DMI_DMCONTROL) & dtm_req_wr) & 
                            dmi_req_data[30];
    
    // Response Path: CLK -> TCK (using buf_cdc_tx, clocked by CLK)
    wire [33:0] dmi_resp_dat_clk;
    wire dmi_resp_valid_clk;
    wire dmi_resp_ready_clk;
    
    assign dmi_resp_dat_clk = {dmi_resp_data_reg, dmi_resp_resp_reg};
    
    buf_cdc_tx #(
        .DW(34)   // 32-bit data + 2-bit resp
    ) u_dmi_resp_cdc (
        // Clocked input (from CLK domain)
        .i_vld(dmi_resp_valid_reg),
        .i_rdy(dmi_resp_ready_clk),
        .i_dat(dmi_resp_dat_clk),
        
        // Async output (to TCK domain)
        .o_vld(dmi_resp_valid_tck),
        .o_rdy_a(dmi_resp_ready_tck),
        .o_dat({dmi_resp_data_tck, dmi_resp_resp_tck}),
        
        // Clock and reset (CLK domain)
        .clk(clk),
        .rst_n(rst_n)
    );
    
    //----------------------------------------------------------------------------
    // Register Field Assignments
    //----------------------------------------------------------------------------
    // DMCONTROL register fields
    assign dmcontrol[31:27] = {5{1'b0}};
    assign dmcontrol[26] = 1'b0;  // hasel (not supported)
    assign dmcontrol[25:16] = hartsel[9:0];   // hartsel[9:0]
    assign dmcontrol[15:6] = hartsel[19:10];  // hartsel[19:10]
    assign dmcontrol[5:2] = {4{1'b0}};
    assign dmcontrol[1] = ndmreset;
    assign dmcontrol[0] = dm_active;
    
    // DMSTATUS register fields (multi-hart aware)
    assign dmstatus[31:23] = {9{1'b0}};
    assign dmstatus[22] = 1'b0;  // impebreak
    assign dmstatus[21:20] = {2{1'b0}};
    assign dmstatus[19] = &havereset[HART_NUM-1:0];  // allhavereset (all harts have reset)
    assign dmstatus[18] = |havereset[HART_NUM-1:0];  // anyhavereset (any hart has reset)
    assign dmstatus[17] = resuming_ack[hartsel_index];  // allresumeack
    assign dmstatus[16] = resuming_ack[hartsel_index];  // anyresumeack
    assign dmstatus[15] = (hartsel > (HART_NUM-1));  // allnonexistent (selected hart doesn't exist)
    assign dmstatus[14] = (hartsel > (HART_NUM-1));  // anynonexistent
    assign dmstatus[13] = 1'b0;  // allunavail
    assign dmstatus[12] = 1'b0;  // anyunavail
    assign dmstatus[11] = ~halted[hartsel_index];  // allrunning
    assign dmstatus[10] = ~halted[hartsel_index];  // anyrunning
    assign dmstatus[9] = halted[hartsel_index];  // allhalted
    assign dmstatus[8] = halted[hartsel_index];  // anyhalted
    assign dmstatus[7] = 1'b1;  // authenticated
    assign dmstatus[6] = 1'b0;  // authbusy
    assign dmstatus[5] = 1'b0;  // hasresethaltreq
    assign dmstatus[4] = 1'b0;  // confstrptrvalid
    assign dmstatus[3:0] = DMSTATUS_VERSION;  // version
    
    // ABSTRACTCS register fields
    assign abstractcs[31:29] = {3{1'b0}};
    assign abstractcs[28:24] = ABSTRACTCS_PROGBUFSIZE;  // progbufsize (4 instructions)
    assign abstractcs[23:13] = {11{1'b0}};
    assign abstractcs[12] = fsm_cmd_busy;  // busy
    assign abstractcs[11] = 1'b0;
    assign abstractcs[10:8] = r_fsm_cmd_error;  // cmderr
    assign abstractcs[7:4] = {4{1'b0}};
    assign abstractcs[3:0] = ABSTRACTCS_DATACOUNT;  // datacount
    
    // COMMAND register fields
    assign command[31:24] = abs_cmdtype;
    assign command[23:0] = abs_control;
    
    // ABSTRACTAUTO register fields
    assign abstractauto[31:24] = {8{1'b0}};
    assign abstractauto[23:16] = autoexecprogbuf;
    assign abstractauto[15:12] = {4{1'b0}};
    assign abstractauto[11:1] = {11{1'b0}};
    assign abstractauto[0] = autoexecdata;
    
    //----------------------------------------------------------------------------
    // Response Data Selection (Combinational)
    //----------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] dtm_resp_bits_data;
    wire [RESP_WIDTH-1:0] dtm_resp_bits_resp;
    
    always @(*) begin
        case (dmi_req_addr)
            `DMI_DATA0:        dtm_resp_bits_data = data0;
            `DMI_DMCONTROL:    dtm_resp_bits_data = dmcontrol;
            `DMI_DMSTATUS:     dtm_resp_bits_data = dmstatus;
            `DMI_HARTINFO:     dtm_resp_bits_data = hartinfo;
            `DMI_ABSTRACTCS:   dtm_resp_bits_data = abstractcs;
            `DMI_COMMAND:      dtm_resp_bits_data = command;
            `DMI_ABSTRACTAUTO: dtm_resp_bits_data = abstractauto;
            `DMI_DATA1:        dtm_resp_bits_data = data1;
            `DMI_PROGBUF0:     dtm_resp_bits_data = progbuf[0];
            `DMI_PROGBUF1:     dtm_resp_bits_data = progbuf[1];
            `DMI_PROGBUF2:     dtm_resp_bits_data = progbuf[2];
            `DMI_PROGBUF3:     dtm_resp_bits_data = progbuf[3];
            `DMI_PROGBUF4:     dtm_resp_bits_data = progbuf[4];
            `DMI_PROGBUF5:     dtm_resp_bits_data = progbuf[5];
            `DMI_PROGBUF6:     dtm_resp_bits_data = progbuf[6];
            `DMI_PROGBUF7:     dtm_resp_bits_data = progbuf[7];
            default:           dtm_resp_bits_data = {DATA_WIDTH{1'b0}};
        endcase
    end
    
    assign dtm_resp_bits_resp = DMI_RESP_OK;  // Can be modified based on error conditions
    
    //----------------------------------------------------------------------------
    // Ready Signal Logic
    //----------------------------------------------------------------------------
    wire i_dtm_req_condi = 1'b1;  // Condition for accepting requests
    // Ready is combinational: ready when condition is met and response is ready
    assign dmi_req_ready_clk = i_dtm_req_condi & dmi_resp_ready_clk;
    
    // fsm_cmd_busy: Abstract command FSM is busy when executing
    wire fsm_cmd_busy_dm_mem;
    assign fsm_cmd_busy = fsm_cmd_busy_dm_mem;
    
    // FSM interface signals for dm_mem (internal)
    wire fsm_cmd_valid;
    wire [7:0] fsm_cmd_type;
    wire [23:0] fsm_cmd_control;
    wire fsm_cmd_error_wr;
    wire [2:0] fsm_cmd_error;
    wire data0_wr_from_dm_mem;
    wire data1_wr_from_dm_mem;
    assign fsm_cmd_valid = abs_command_valid;
    assign fsm_cmd_type = abs_cmdtype;
    assign fsm_cmd_control = abs_control;
    
    //----------------------------------------------------------------------------
    // Write Addresses That Consider Busy
    //----------------------------------------------------------------------------
    wire wr_addr_consider_busy = (dmi_req_addr == `DMI_DATA0) || 
                                  (dmi_req_addr == `DMI_COMMAND) || 
                                  (dmi_req_addr == `DMI_ABSTRACTAUTO) || 
                                  (dmi_req_addr == `DMI_PROGBUF0) ||
                                  (dmi_req_addr == `DMI_PROGBUF1) || 
                                  (dmi_req_addr == `DMI_PROGBUF2) ||
                                  (dmi_req_addr == `DMI_PROGBUF3) || 
                                  (dmi_req_addr == `DMI_PROGBUF4) ||
                                  (dmi_req_addr == `DMI_PROGBUF5) || 
                                  (dmi_req_addr == `DMI_PROGBUF6) ||
                                  (dmi_req_addr == `DMI_PROGBUF7);
    
    //----------------------------------------------------------------------------
    // DMI Response Signals (separate always block)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dmi_resp_valid_reg <= 1'b0;
            dmi_resp_data_reg <= {DATA_WIDTH{1'b0}};
            dmi_resp_resp_reg <= DMI_RESP_OK;
        end else begin
            // Clear response when accepted by CDC
            if (dmi_resp_valid_reg && dmi_resp_ready_clk) begin
                dmi_resp_valid_reg <= 1'b0;
            end
            // Set response when request is accepted
            else if (dmi_req_valid_clk && dmi_req_ready_clk) begin
                dmi_resp_data_reg <= dtm_resp_bits_data;
                dmi_resp_resp_reg <= dtm_resp_bits_resp;
                dmi_resp_valid_reg <= 1'b1;
            end
            // Default: clear valid if no request
            else begin
                dmi_resp_valid_reg <= 1'b0;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Abstract Command Signals (separate always block)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_cmdtype <= {8{1'b0}};
            abs_control <= {24{1'b0}};
            abs_command_valid <= 1'b0;
        end else begin
            if (~dm_active) begin
                abs_cmdtype <= {8{1'b0}};
                abs_control <= {24{1'b0}};
                abs_command_valid <= 1'b0;
            end else begin
                if (dmi_req_addr == `DMI_DATA0) begin
                    abs_command_valid <= dtm_req_rd_or_wr & ~fsm_cmd_busy & autoexecdata;
                end
                // Auto-execute: Trigger command when PROGBUF registers are accessed and autoexecprogbuf is enabled
                else if (dmi_req_addr == `DMI_PROGBUF0) begin
                    abs_command_valid <= dtm_req_rd_or_wr & ~fsm_cmd_busy & autoexecprogbuf[0];
                end
                else if (dmi_req_addr == `DMI_PROGBUF1) begin
                    abs_command_valid <= dtm_req_rd_or_wr & ~fsm_cmd_busy & autoexecprogbuf[1];
                end
                else if (dmi_req_addr == `DMI_PROGBUF2) begin
                    abs_command_valid <= dtm_req_rd_or_wr & ~fsm_cmd_busy & autoexecprogbuf[2];
                end
                else if (dmi_req_addr == `DMI_PROGBUF3) begin
                    abs_command_valid <= dtm_req_rd_or_wr & ~fsm_cmd_busy & autoexecprogbuf[3];
                end
                else if (dmi_req_addr == `DMI_PROGBUF4) begin
                    abs_command_valid <= dtm_req_rd_or_wr & ~fsm_cmd_busy & autoexecprogbuf[4];
                end
                else if (dmi_req_addr == `DMI_PROGBUF5) begin
                    abs_command_valid <= dtm_req_rd_or_wr & ~fsm_cmd_busy & autoexecprogbuf[5];
                end
                else if (dmi_req_addr == `DMI_PROGBUF6) begin
                    abs_command_valid <= dtm_req_rd_or_wr & ~fsm_cmd_busy & autoexecprogbuf[6];
                end
                else if (dmi_req_addr == `DMI_PROGBUF7) begin
                    abs_command_valid <= dtm_req_rd_or_wr & ~fsm_cmd_busy & autoexecprogbuf[7];
                end
                // Direct COMMAND register write
                else begin
                    abs_command_valid <= (dmi_req_addr == `DMI_COMMAND) & dtm_req_wr & ~fsm_cmd_busy;
                end

                // Update command type and control when COMMAND register is written
                abs_cmdtype <= ((dmi_req_addr == `DMI_COMMAND) & dtm_req_wr) ? dmi_req_data[31:24] : abs_cmdtype;
                abs_control <= ((dmi_req_addr == `DMI_COMMAND) & dtm_req_wr) ? dmi_req_data[23:0] : abs_control;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Abstract Command Error Register (separate always block)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_fsm_cmd_error <= {3{1'b0}};
        end else begin
            if (~dm_active) begin
                r_fsm_cmd_error <= {3{1'b0}};
            end else begin
                // Handle ABSTRACTCS error clearing
                if ((dmi_req_addr == `DMI_ABSTRACTCS) & dtm_req_wr) begin
                    if (~fsm_cmd_busy) begin
                        r_fsm_cmd_error <= ~dmi_req_data[10:8] & r_fsm_cmd_error;
                    end else if (r_fsm_cmd_error == {3{1'b0}}) begin
                        r_fsm_cmd_error <= CMD_ERROR_BUSY;  // CMD_BUSY
                    end
                end
                // Handle busy error when writing to registers that require not busy
                else if (wr_addr_consider_busy & dtm_req_wr) begin
                    if (r_fsm_cmd_error == {3{1'b0}} && fsm_cmd_busy == 1'b1) begin
                        r_fsm_cmd_error <= CMD_ERROR_BUSY;  // CMD_BUSY
                    end
                end
                // Handle error from FSM (dm_mem)
                else if (fsm_cmd_error_wr) begin
                    r_fsm_cmd_error <= fsm_cmd_error;
                end
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // DATA0 and DATA1 Registers (separate always block)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data0 <= {DATA_WIDTH{1'b0}};
            data1 <= {DATA_WIDTH{1'b0}};
        end else begin
            // Handle data0 write from dm_mem
            // When dm_mem detects APB write to DataBaseAddr (0x380), it asserts data0_wr
            // We write the APB write data to data0
            data0 <= (~dm_active) ? {DATA_WIDTH{1'b0}} :
                     (data0_wr_from_dm_mem) ? m_apb_pwdata :
                     ((dmi_req_addr == `DMI_DATA0) & dtm_req_wr) ? dmi_req_data :
                     data0;
            
            // Handle DATA1 writes
            data1 <= (~dm_active) ? {DATA_WIDTH{1'b0}} :
                     (data1_wr_from_dm_mem) ? m_apb_pwdata :
                     ((dmi_req_addr == `DMI_DATA1) & dtm_req_wr) ? dmi_req_data :
                     data1;
        end
    end
    
    //----------------------------------------------------------------------------
    // Main Control Logic
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debug_req <= {HART_NUM{1'b0}};
            dm_active <= 1'b0;
            ndmreset <= 1'b0;
            havereset <= {HART_NUM{1'b1}};  // Initially set for all harts
            halt_req <= {HART_NUM{1'b0}};
            resume_req <= {HART_NUM{1'b0}};
            hartsel <= {20{1'b0}};
            autoexecprogbuf <= {8{1'b0}};
            autoexecdata <= 1'b0;
            hartinfo <= HARTINFO_INIT;
        end else begin
            // DMCONTROL register handling
            if (~dm_active) begin
                debug_req <= {HART_NUM{1'b0}};
                halt_req <= {HART_NUM{1'b0}};
                resume_req <= {HART_NUM{1'b0}};
                ndmreset <= 1'b0;
                hartsel <= {20{1'b0}};
            end
            
            // Update dm_active
            dm_active <= ((dmi_req_addr == `DMI_DMCONTROL) & dtm_req_wr) ? dmi_req_data[0] : dm_active;
            
            // Handle DMCONTROL writes (multi-hart)
            if ((dmi_req_addr == `DMI_DMCONTROL) & dtm_req_wr & dm_active) begin
                // Update hartsel
                hartsel <= {dmi_req_data[15:6], dmi_req_data[25:16]};
                
                // Update ndmreset
                ndmreset <= dmi_req_data[1];
                
                if (dmi_req_data[1]) begin  // ndmreset
                    debug_req <= {HART_NUM{1'b0}};
                    halt_req <= {HART_NUM{1'b0}};
                    havereset <= {HART_NUM{1'b1}};
                end else if (dmi_req_data[31]) begin  // haltreq (bit 31)
                    // Halt selected hart
                    halt_req[hartsel_index] <= 1'b1;
                    debug_req[hartsel_index] <= 1'b1;
                end else begin
                    // Clear halt request for selected hart
                    halt_req[hartsel_index] <= 1'b0;
                    debug_req[hartsel_index] <= 1'b0;
                    // Handle resume request
                    if (dmi_req_data[30]) begin  // resumereq (bit 30)
                        if (halted[hartsel_index]) begin
                            resume_req[hartsel_index] <= 1'b1;
                        end
                    end
                end
            end
            
            // Handle havereset (per-hart)
            if ((dmi_req_addr == `DMI_DMCONTROL) & dtm_req_wr & dmi_req_data[28]) begin
                // Clear havereset for selected hart
                havereset[hartsel_index] <= 1'b0;
            end else if (ndmreset) begin
                havereset <= {HART_NUM{1'b1}};
            end
            
            // Handle resume acknowledge (per-hart)
            if (resume_req[hartsel_index] && resuming_ack[hartsel_index]) begin
                // Clear resume request when acknowledged
                resume_req[hartsel_index] <= 1'b0;
            end
            
            // Handle ABSTRACTAUTO
            autoexecprogbuf <= ((dmi_req_addr == `DMI_ABSTRACTAUTO) & dtm_req_wr & ~fsm_cmd_busy) ? dmi_req_data[23:16] : autoexecprogbuf;
            autoexecdata <= ((dmi_req_addr == `DMI_ABSTRACTAUTO) & dtm_req_wr & ~fsm_cmd_busy) ? dmi_req_data[0] : autoexecdata;
            
            // Update debug_req based on halt_req (per-hart)
            debug_req <= halt_req;
        end
    end
    
    //----------------------------------------------------------------------------
    // PROGBUF Registers (separate always block)
    //----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize all progbuf registers to NOP
            progbuf[0] <= RISCV_NOP;
            progbuf[1] <= RISCV_NOP;
            progbuf[2] <= RISCV_NOP;
            progbuf[3] <= RISCV_NOP;
            progbuf[4] <= RISCV_NOP;
            progbuf[5] <= RISCV_NOP;
            progbuf[6] <= RISCV_NOP;
            progbuf[7] <= RISCV_NOP;
        end else begin
            // Handle PROGBUF writes
            progbuf[0] <= (dtm_req_wr & ~fsm_cmd_busy & (dmi_req_addr == `DMI_PROGBUF0)) ? dmi_req_data : progbuf[0];
            progbuf[1] <= (dtm_req_wr & ~fsm_cmd_busy & (dmi_req_addr == `DMI_PROGBUF1)) ? dmi_req_data : progbuf[1];
            progbuf[2] <= (dtm_req_wr & ~fsm_cmd_busy & (dmi_req_addr == `DMI_PROGBUF2)) ? dmi_req_data : progbuf[2];
            progbuf[3] <= (dtm_req_wr & ~fsm_cmd_busy & (dmi_req_addr == `DMI_PROGBUF3)) ? dmi_req_data : progbuf[3];
            progbuf[4] <= (dtm_req_wr & ~fsm_cmd_busy & (dmi_req_addr == `DMI_PROGBUF4)) ? dmi_req_data : progbuf[4];
            progbuf[5] <= (dtm_req_wr & ~fsm_cmd_busy & (dmi_req_addr == `DMI_PROGBUF5)) ? dmi_req_data : progbuf[5];
            progbuf[6] <= (dtm_req_wr & ~fsm_cmd_busy & (dmi_req_addr == `DMI_PROGBUF6)) ? dmi_req_data : progbuf[6];
            progbuf[7] <= (dtm_req_wr & ~fsm_cmd_busy & (dmi_req_addr == `DMI_PROGBUF7)) ? dmi_req_data : progbuf[7];
        end
    end
    
    //----------------------------------------------------------------------------
    // Debug Memory Module (dm_mem) - Integrated APB Interface
    //----------------------------------------------------------------------------
    wire [31:0] dm_mem_prdata;
    wire        dm_mem_pready;
    wire        dm_mem_pslverr;
    
    // APB decoder passes absolute addresses directly (no conversion)
    // dm_mem uses absolute addresses in the range 0x000-0xFFF (lower 12 bits)
    // APB address decode for dm_mem (debug memory regions: 0x000-0xFFF absolute)
    wire apb_to_dm_mem = (m_apb_paddr[11:8] == 4'h1) ||  // Halted/Resuming (0x100-0x10C)
                         (m_apb_paddr[11:8] == 4'h3) ||  // WhereTo/AbstractCmd/ProgBuf/DataBase (0x300-0x37F)
                         (m_apb_paddr[11:8] == 4'h4) ||  // Flags (0x400-0x4FF)
                         (m_apb_paddr[11:8] == 4'h5) ||  // Flags (0x500-0x5FF)
                         (m_apb_paddr[11:8] == 4'h6) ||  // Flags (0x600-0x6FF)
                         (m_apb_paddr[11:8] == 4'h7) ||  // Flags (0x700-0x7FF)
                         (m_apb_paddr[11:8] == 4'h8) ||  // Debug ROM (0x800-0x9FF)
                         (m_apb_paddr[11:8] == 4'h9) ||  // Reserved (0x900-0x9FF)
                         (m_apb_paddr[11:8] == 4'hA) ||  // Reserved (0xA00-0xAFF)
                         (m_apb_paddr[11:8] == 4'hB) ||  // Reserved (0xB00-0xBFF)
                         (m_apb_paddr[11:8] == 4'hC) ||  // Flags (0xC00-0xCFF)
                         (m_apb_paddr[11:8] == 4'hD) ||  // Flags (0xD00-0xDFF)
                         (m_apb_paddr[11:8] == 4'hE) ||  // Flags (0xE00-0xEFF)
                         (m_apb_paddr[11:8] == 4'hF);    // Flags (0xF00-0xFFF)
    
    dm_mem #(
        .HART_NUM(HART_NUM),
        .HART_ID_W(HART_ID_W)
    ) u_dm_mem (
        .clk(clk),
        .rst_n(rst_n),
        
        // APB Slave Interface
        .m_apb_psel(m_apb_psel && apb_to_dm_mem),
        .m_apb_penable(m_apb_penable),
        .m_apb_paddr(m_apb_paddr),  // Use absolute address directly
        .m_apb_pwrite(m_apb_pwrite),
        .m_apb_pwdata(m_apb_pwdata),
        .m_apb_prdata(dm_mem_prdata),
        .m_apb_pready(dm_mem_pready),
        .m_apb_pslverr(dm_mem_pslverr),
        
        // FSM interface
        .fsm_cmd_valid(fsm_cmd_valid),
        .fsm_cmd_type(fsm_cmd_type),
        .fsm_cmd_control(fsm_cmd_control),
        .fsm_cmd_busy(fsm_cmd_busy_dm_mem),
        .fsm_cmd_error_wr(fsm_cmd_error_wr),
        .fsm_cmd_error(fsm_cmd_error),
        
        // Data and program buffer
        .data0_i(data0),
        .data0_wr(data0_wr_from_dm_mem),
        .data1_i(data1),
        .data1_wr(data1_wr_from_dm_mem),        
        .progbuf0(progbuf[0]),
        .progbuf1(progbuf[1]),
        .progbuf2(progbuf[2]),
        .progbuf3(progbuf[3]),
        .progbuf4(progbuf[4]),
        .progbuf5(progbuf[5]),
        .progbuf6(progbuf[6]),
        .progbuf7(progbuf[7]),
                
        // Hart control (multi-hart arrays)
        .hartsel_index(hartsel_index),
        .resume_req(resume_req),
        .clear_resume_ack(clear_resume_ack),
        .halted(halted),
        .resuming(resuming_ack)
    );
    
    //----------------------------------------------------------------------------
    // APB Response Multiplexing
    //----------------------------------------------------------------------------
    // Route APB responses from dm_mem
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_apb_prdata <= {32{1'b0}};
            m_apb_pready <= 1'b0;
            m_apb_pslverr <= 1'b0;
        end else begin
            if (m_apb_penable && m_apb_psel) begin
                if (apb_to_dm_mem) begin
                    // Debug memory region - use dm_mem response
                    if (!m_apb_pwrite) begin
                        m_apb_prdata <= dm_mem_prdata;
                    end
                    m_apb_pready <= dm_mem_pready;
                    m_apb_pslverr <= dm_mem_pslverr;
                end else begin
                    // Other addresses - not handled by debug module
                    m_apb_prdata <= {32{1'b0}};
                    m_apb_pready <= 1'b1;
                    m_apb_pslverr <= 1'b1;  // Error for unsupported addresses
                end
            end else begin
                m_apb_pready <= 1'b0;
            end
        end
    end

endmodule



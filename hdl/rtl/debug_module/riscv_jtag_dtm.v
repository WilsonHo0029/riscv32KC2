// RISC-V JTAG Debug Transport Module (DTM)
// Implements JTAG-to-DMI bridge for RISC-V Debug Specification 0.13
// This module bridges between JTAG interface and DMI (Debug Module Interface)
//
// Features:
//   - Full JTAG TAP controller implementation
//   - DTMCS (DTM Control and Status) register
//   - DMI register for accessing Debug Module registers
//   - IDCODE register for device identification
//   - Supports READ, WRITE, and NOP DMI operations
//
// JTAG Instructions:
//   - IR_IDCODE (0x01): Read device IDCODE
//   - IR_DTMCS (0x10): Access DTM Control and Status register
//   - IR_DMI (0x11): Access DMI (Debug Module Interface)
//   - IR_BYPASS (0x1F): Bypass instruction

module riscv_jtag_dtm (
    // JTAG Interface (external)
    input               tck,        // JTAG test clock
    input               tms,        // JTAG test mode select
    input               tdi,        // JTAG test data input
    output reg          tdo,        // JTAG test data output
    input               trst_n,     // JTAG test reset (optional, active low)
    
    // DMI Interface (to Debug Module) - TCK domain
    output              dmi_req_valid,
    input               dmi_req_ready,
    output [6:0]        dmi_req_addr,
    output [1:0]        dmi_req_op,     // 00: NOP, 01: READ, 10: WRITE
    output [31:0]       dmi_req_data,
    input               dmi_resp_valid,
    output              dmi_resp_ready,
    input  [31:0]       dmi_resp_data,
    input  [1:0]        dmi_resp_resp   // 00: OK, 01: FAILED, 10: UNSUPPORTED
);

    // JTAG TAP State Machine States
    localparam TEST_LOGIC_RESET = 4'h0;
    localparam RUN_TEST_IDLE    = 4'h1;
    localparam SELECT_DR_SCAN   = 4'h2;
    localparam CAPTURE_DR       = 4'h3;
    localparam SHIFT_DR         = 4'h4;
    localparam EXIT1_DR         = 4'h5;
    localparam PAUSE_DR         = 4'h6;
    localparam EXIT2_DR         = 4'h7;
    localparam UPDATE_DR        = 4'h8;
    localparam SELECT_IR_SCAN   = 4'h9;
    localparam CAPTURE_IR       = 4'ha;
    localparam SHIFT_IR         = 4'hb;
    localparam EXIT1_IR         = 4'hc;
    localparam PAUSE_IR         = 4'hd;
    localparam EXIT2_IR         = 4'he;
    localparam UPDATE_IR        = 4'hf;

    // JTAG Instruction Codes
    localparam [4:0] IR_BYPASS    = 5'h1f;
    localparam [4:0] IR_IDCODE    = 5'h01;
    localparam [4:0] IR_DTMCS     = 5'h10;
    localparam [4:0] IR_DMI       = 5'h11;

    //----------------------------------------------------------------------------
    // Constants
    //----------------------------------------------------------------------------
    localparam IR_BITS = 5;
    localparam DBUS_REG_BITS = 41;  // 7-bit addr + 2-bit op + 32-bit data
    localparam SHIFT_REG_BITS = DBUS_REG_BITS;  // Use same size for shift register
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 7;
    localparam OP_WIDTH = 2;
    localparam RESP_WIDTH = 2;
    
    // DMI Operation Codes
    localparam [1:0] DMI_OP_NOP   = 2'b00;
    localparam [1:0] DMI_OP_READ  = 2'b01;
    localparam [1:0] DMI_OP_WRITE = 2'b10;
    
    // DMI Response Codes
    localparam [1:0] DMI_RESP_OK          = 2'b00;
    localparam [1:0] DMI_RESP_FAILED      = 2'b01;
    localparam [1:0] DMI_RESP_UNSUPPORTED = 2'b10;
    
    // DTMCS Register Constants
    localparam [31:0] DTMCS_INIT_VALUE = 32'h01000701;  // version=0x1, abits=7, dmistat=0, idle=0, dmireset=0, version=0x1
    localparam [2:0] DBUS_IDLE_CYCLES_VALUE = 3'h5;
    localparam [6:0] DEBUG_ADDR_BITS_VALUE = 7'd7;
    localparam [3:0] DEBUG_VERSION_VALUE = 4'h1;
    
    
    // TAP State Machine - single always block
    reg [3:0] tap_state;
    
    // Instruction Register (5 bits)
    reg [4:0] ir;
    
    // Single shift register for both IR and DR operations
    reg [SHIFT_REG_BITS-1:0] shift_reg;
    
    // Data Registers
    wire [31:0] idcode_reg;          // 32-bit IDCODE register (constant value)
    reg [31:0] dtmcs_reg;            // 32-bit DTMCS register
    reg [DBUS_REG_BITS-1:0] dmi_reg; // 41-bit DMI register
    
    // DMI control signals
    reg dmi_req_valid_reg;
    reg dmi_busy_reg;
    reg sticky_busy_reg;
    reg sticky_nonzero_resp_reg;
    reg skip_op_reg;      // Skip op because we're busy
    reg downgrade_op_reg;  // Downgrade op because prev. op failed
    
    // Internal DMI signals (TCK domain)
    wire dmi_req_ready_tck;
    wire dmi_resp_valid_tck;
    wire dmi_resp_ready_tck;      // Ready to accept response (from CDC o_rdy input)
    wire dmi_resp_ready_tck_int;  // Internal ready signal from buf_cdc_rx i_rdy output
    wire [33:0] dmi_resp_dat_tck;  // Packed response: data[31:0] + resp[1:0]
    
    //----------------------------------------------------------------------------
    // Internal Signals
    //----------------------------------------------------------------------------
    // IDCODE register (constant value)
    // [31:28] - version
    // [27:12] - part number
    // [11:1]  - manufacturer id
    // [0]     - always 1
    assign idcode_reg[31:28] = 4'd1; // 0.13
    assign idcode_reg[27:12] = 16'h0001;
    assign idcode_reg[11:1]  = 11'h3FF; 
    assign idcode_reg[0] = 1'b1;
    
    // DTMCS register fields
    wire [1:0] dbus_status;
    wire [2:0] dbus_idle_cycles;
    wire [31:0] dtminfo;
    wire dbus_reset;
    
    assign dbus_idle_cycles = DBUS_IDLE_CYCLES_VALUE;
    assign dbus_status = {sticky_nonzero_resp_reg, sticky_nonzero_resp_reg | sticky_busy_reg};
    assign dbus_reset = shift_reg[16];
    
    assign dtminfo = {{14{1'b0}},
                      1'b0,  // dmihardreset
                      1'b0,  // dmireset (write-only)
                      1'b0,
                      dbus_idle_cycles,
                      dbus_status,
                      DEBUG_ADDR_BITS_VALUE,
                      DEBUG_VERSION_VALUE};
    
    // Busy and nonzero response detection (only valid during CAPTURE_DR)
    wire busy;
    wire nonzero_resp;
    assign busy = (dmi_busy_reg & ~dmi_resp_valid_tck) | sticky_busy_reg;
    assign nonzero_resp = (dmi_resp_valid_tck ? |dmi_resp_dat_tck[1:0] : 1'b0) | sticky_nonzero_resp_reg;
    
    // Response data packing/unpacking
    wire [33:0] dmi_resp_dat_packed;
    assign dmi_resp_dat_packed = {dmi_resp_data, dmi_resp_resp};
    
    // Busy and non-busy response formats
    wire [DBUS_REG_BITS-1:0] busy_response;
    wire [DBUS_REG_BITS-1:0] nonbusy_response;
    
    assign busy_response = {{(DBUS_REG_BITS-RESP_WIDTH){1'b0}}, {RESP_WIDTH{1'b1}}};  // All-ones for busy
    assign nonbusy_response = {dmi_reg[40:34],  // Retain address bits
                               dmi_resp_dat_tck[33:2],  // Data from response
                               dmi_resp_dat_tck[1:0]};  // Response status
    
    //----------------------------------------------------------------------------
    // JTAG TAP State Machine
    //----------------------------------------------------------------------------
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            tap_state <= TEST_LOGIC_RESET;
        end else begin
            case (tap_state)
                TEST_LOGIC_RESET: tap_state <= tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
                RUN_TEST_IDLE:    tap_state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                SELECT_DR_SCAN:   tap_state <= tms ? SELECT_IR_SCAN : CAPTURE_DR;
                CAPTURE_DR:       tap_state <= tms ? EXIT1_DR : SHIFT_DR;
                SHIFT_DR:         tap_state <= tms ? EXIT1_DR : SHIFT_DR;
                EXIT1_DR:         tap_state <= tms ? UPDATE_DR : PAUSE_DR;
                PAUSE_DR:         tap_state <= tms ? EXIT2_DR : PAUSE_DR;
                EXIT2_DR:         tap_state <= tms ? UPDATE_DR : SHIFT_DR;
                UPDATE_DR:        tap_state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                SELECT_IR_SCAN:   tap_state <= tms ? TEST_LOGIC_RESET : CAPTURE_IR;
                CAPTURE_IR:       tap_state <= tms ? EXIT1_IR : SHIFT_IR;
                SHIFT_IR:         tap_state <= tms ? EXIT1_IR : SHIFT_IR;
                EXIT1_IR:         tap_state <= tms ? UPDATE_IR : PAUSE_IR;
                PAUSE_IR:         tap_state <= tms ? EXIT2_IR : PAUSE_IR;
                EXIT2_IR:         tap_state <= tms ? UPDATE_IR : SHIFT_IR;
                UPDATE_IR:        tap_state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                default:          tap_state <= TEST_LOGIC_RESET;
            endcase
        end
    end
    
    //----------------------------------------------------------------------------
    // Shift Register - handles both IR and DR
    //----------------------------------------------------------------------------
    always @(posedge tck) begin
        case (tap_state)
            CAPTURE_IR: begin
                // JTAG spec: IR capture must end with 'b01
                shift_reg <= {{(SHIFT_REG_BITS-1){1'b0}}, 1'b1};
            end
            SHIFT_IR: begin
                shift_reg <= {{(SHIFT_REG_BITS-IR_BITS){1'b0}}, tdi, shift_reg[IR_BITS-1:1]};
            end
            CAPTURE_DR: begin
                case (ir)
                    IR_BYPASS:     shift_reg <= {(SHIFT_REG_BITS){1'b0}};
                    IR_IDCODE:     shift_reg <= {{(SHIFT_REG_BITS-32){1'b0}}, idcode_reg};
                    IR_DTMCS:      shift_reg <= {{(SHIFT_REG_BITS-32){1'b0}}, dtminfo};
                    IR_DMI:        shift_reg <= busy ? busy_response : nonbusy_response;
                    default:       shift_reg <= {(SHIFT_REG_BITS){1'b0}};  // BYPASS
                endcase
            end
            SHIFT_DR: begin
                case (ir)
                    IR_BYPASS:     shift_reg <= {{(SHIFT_REG_BITS-1){1'b0}}, tdi};
                    IR_IDCODE:     shift_reg <= {{(SHIFT_REG_BITS-32){1'b0}}, tdi, shift_reg[31:1]};
                    IR_DTMCS:      shift_reg <= {{(SHIFT_REG_BITS-32){1'b0}}, tdi, shift_reg[31:1]};
                    IR_DMI:        shift_reg <= {tdi, shift_reg[SHIFT_REG_BITS-1:1]};
                    default:       shift_reg <= {{(SHIFT_REG_BITS-1){1'b0}}, tdi};  // BYPASS
                endcase
            end
        endcase
    end
    
    //----------------------------------------------------------------------------
    // Instruction Register Update (on negedge TCK)
    //----------------------------------------------------------------------------
    always @(negedge tck or negedge trst_n) begin
        if (!trst_n) begin
            ir <= IR_IDCODE;
        end else if (tap_state == TEST_LOGIC_RESET) begin
            ir <= IR_IDCODE;
        end else if (tap_state == UPDATE_IR) begin
            ir <= shift_reg[IR_BITS-1:0];
        end
    end
    
    //----------------------------------------------------------------------------
    // Busy Register
    //----------------------------------------------------------------------------
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            dmi_busy_reg <= 1'b0;
        end else begin
            if (dmi_req_valid_reg) begin
                dmi_busy_reg <= 1'b1;
            end else if (dmi_resp_valid_tck && dmi_resp_ready_tck) begin
                dmi_busy_reg <= 1'b0;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    // Skip/Downgrade Logic and Sticky Flags
    //----------------------------------------------------------------------------
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            skip_op_reg <= 1'b0;
            downgrade_op_reg <= 1'b0;
            sticky_busy_reg <= 1'b0;
            sticky_nonzero_resp_reg <= 1'b0;
        end else if (ir == IR_DMI) begin
            case (tap_state)
                CAPTURE_DR: begin
                    skip_op_reg <= busy;
                    downgrade_op_reg <= (~busy & nonzero_resp);
                    sticky_busy_reg <= busy;
                    sticky_nonzero_resp_reg <= nonzero_resp;
                end
                UPDATE_DR: begin
                    skip_op_reg <= 1'b0;
                    downgrade_op_reg <= 1'b0;
                end
            endcase
        end else if (ir == IR_DTMCS) begin
            case (tap_state)
                UPDATE_DR: begin
                    if (dbus_reset) begin
                        sticky_nonzero_resp_reg <= 1'b0;
                        sticky_busy_reg <= 1'b0;
                    end
                end
            endcase
        end
    end
    
    //----------------------------------------------------------------------------
    // DMI Register and Request Valid
    //----------------------------------------------------------------------------
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            dmi_reg <= {(DBUS_REG_BITS){1'b0}};
            dmi_req_valid_reg <= 1'b0;
            dtmcs_reg <= DTMCS_INIT_VALUE;
        end else if (tap_state == UPDATE_DR) begin
            if (ir == IR_DTMCS) begin
                dtmcs_reg <= shift_reg[31:0];
                end else if (ir == IR_DMI) begin
                if (skip_op_reg) begin
                    // Do nothing - skip operation
                end else if (downgrade_op_reg) begin
                    // Downgrade to NOP
                    dmi_reg <= {(DBUS_REG_BITS){1'b0}};
                    dmi_req_valid_reg <= 1'b1;
                end else begin
                    dmi_reg <= shift_reg[DBUS_REG_BITS-1:0];
                    dmi_req_valid_reg <= 1'b1;
                end
            end
        end else if (dmi_req_ready_tck) begin
            dmi_req_valid_reg <= 1'b0;
        end
    end
    
    //----------------------------------------------------------------------------
    // Clock Domain Crossing (CDC) for DMI Interface
    //----------------------------------------------------------------------------
    // Request Path: TCK -> Debug Module (using buf_cdc_tx)
    wire [40:0] dmi_req_dat_out;
    
    buf_cdc_tx #(
        .DW(41)   // 7-bit addr + 2-bit op + 32-bit data
    ) u_jtag2debug_cdc_tx (
        // Clocked input (from TCK domain)
        .i_vld(dmi_req_valid_reg),
        .i_rdy(dmi_req_ready_tck),
        .i_dat(dmi_reg),
        
        // Async output (to Debug Module)
        .o_vld(dmi_req_valid),
        .o_rdy_a(dmi_req_ready),
        .o_dat(dmi_req_dat_out),
        
        .clk(tck),
        .rst_n(trst_n)
    );
    
    // Unpack request data (module outputs)
    // Format: {addr[40:34], data[33:2], op[1:0]}
    assign dmi_req_addr = dmi_req_dat_out[40:34];
    assign dmi_req_data = dmi_req_dat_out[33:2];
    assign dmi_req_op = dmi_req_dat_out[1:0];
    
    // Response Path: Debug Module -> TCK (using buf_cdc_rx)
    // Ready to accept response only during CAPTURE_DR when processing DMI
    assign dmi_resp_ready_tck = (tap_state == CAPTURE_DR) && (ir == IR_DMI);
    
    buf_cdc_rx #(
        .DW(34)   // 32-bit data + 2-bit resp
    ) u_jtag2debug_cdc_rx (
        // Async input (from Debug Module)
        .i_vld_a(dmi_resp_valid),
        .i_rdy(dmi_resp_ready_tck_int),  // Output: ready from async side (4-phase handshake)
        .i_dat(dmi_resp_dat_packed),
        
        // Clocked output (to TCK domain)
        .o_vld(dmi_resp_valid_tck),
        .o_rdy(dmi_resp_ready_tck),  // Input: ready to accept on sync side
        .o_dat(dmi_resp_dat_tck),
        
        .clk(tck),
        .rst_n(trst_n)
    );
    
    // Connect CDC RX ready output to module output
    assign dmi_resp_ready = dmi_resp_ready_tck_int;
    
    //----------------------------------------------------------------------------
    // TDO Output (on negedge TCK)
    //----------------------------------------------------------------------------
    always @(negedge tck or negedge trst_n) begin
        if (!trst_n) begin
            tdo <= 1'b0;
        end else begin
            case (tap_state)
                SHIFT_IR, SHIFT_DR: begin
                    tdo <= shift_reg[0];
                end
                default: begin
                    tdo <= 1'b0;
                end
            endcase
        end
    end

endmodule

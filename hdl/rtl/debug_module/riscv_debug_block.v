// RISC-V Debug Block - Top Level
// Integrates JTAG DTM and Debug Module
// Provides complete debug infrastructure for RISC-V core
// Supports multi-hart configuration

module riscv_debug_block #(
    parameter HART_NUM = 1,        // Number of harts supported
    parameter HART_ID_W = 1        // Hart ID width ($clog2(HART_NUM))
)(
    // System Clock and Reset
    input               clk,            // System clock (for Debug Module)
    input               rst_n,          // System reset (active low)
    
    // JTAG Interface (external debugger connection)
    input               tck,            // JTAG test clock
    input               tms,            // JTAG test mode select
    input               tdi,            // JTAG test data input
    output              tdo,            // JTAG test data output
    input               trst_n,         // JTAG test reset (optional, active low)
    
    // Hart Control Interface (to/from RISC-V core) - multi-hart
    output [HART_NUM-1:0] debug_req,      // Debug halt request per hart
    input  [HART_NUM-1:0] debug_mode,     // Debug mode per hart
    output		  ndmreset,
    // APB Slave Interface (from APB decoder)
    input  [31:0]       m_apb_paddr,
    input               m_apb_psel,
    input               m_apb_penable,
    input               m_apb_pwrite,
    input  [31:0]       m_apb_pwdata,
    input  [3:0]        m_apb_pstrb,
    output reg [31:0]   m_apb_prdata,
    output reg          m_apb_pready,
    output reg          m_apb_pslverr
);

    // DMI signals (TCK domain) - CDC is now handled inside Debug Module
    wire               dmi_req_valid_tck;
    wire               dmi_req_ready_tck;
    wire [6:0]         dmi_req_addr_tck;
    wire [1:0]         dmi_req_op_tck;
    wire [31:0]        dmi_req_data_tck;
    wire               dmi_resp_valid_tck;
    wire               dmi_resp_ready_tck;
    wire [31:0]        dmi_resp_data_tck;
    wire [1:0]         dmi_resp_resp_tck;
    
    // APB response signals (from riscv_debug_module)
    wire [31:0]        apb_prdata;
    wire               apb_pready;
    wire               apb_pslverr;

    // Instantiate JTAG Debug Transport Module (DTM) - TCK domain
    riscv_jtag_dtm u_jtag_dtm (
        // JTAG Interface
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .trst_n(trst_n),
        
        // DMI Interface (TCK domain)
        .dmi_req_valid(dmi_req_valid_tck),
        .dmi_req_ready(dmi_req_ready_tck),
        .dmi_req_addr(dmi_req_addr_tck),
        .dmi_req_op(dmi_req_op_tck),
        .dmi_req_data(dmi_req_data_tck),
        .dmi_resp_valid(dmi_resp_valid_tck),
        .dmi_resp_ready(dmi_resp_ready_tck),
        .dmi_resp_data(dmi_resp_data_tck),
        .dmi_resp_resp(dmi_resp_resp_tck)
    );


    // Instantiate Debug Module - CLK domain
    // Debug Module handles CDC internally using buf_cdc_rx and buf_cdc_tx
    riscv_debug_module #(
        .HART_NUM(HART_NUM),
        .HART_ID_W(HART_ID_W)
    ) u_debug_module (
        // System Clock and Reset
        .clk(clk),
        .rst_n(rst_n),
        
        // JTAG Clock and Reset (for CDC)
        .tck(tck),
        .trst_n(trst_n),
        
        // DMI Interface (TCK domain - from DTM)
        .dmi_req_valid_tck(dmi_req_valid_tck),
        .dmi_req_ready_tck(dmi_req_ready_tck),
        .dmi_req_addr_tck(dmi_req_addr_tck),
        .dmi_req_op_tck(dmi_req_op_tck),
        .dmi_req_data_tck(dmi_req_data_tck),
        .dmi_resp_valid_tck(dmi_resp_valid_tck),
        .dmi_resp_ready_tck(dmi_resp_ready_tck),
        .dmi_resp_data_tck(dmi_resp_data_tck),
        .dmi_resp_resp_tck(dmi_resp_resp_tck),
        
        // Hart Control Interface (to/from RISC-V core) - multi-hart
        .debug_req(debug_req),
        .debug_mode(debug_mode),
        .ndmreset(ndmreset),
        // APB Slave Interface (for dm_mem access)
        .m_apb_psel(m_apb_psel),
        .m_apb_penable(m_apb_penable),
        .m_apb_paddr(m_apb_paddr),
        .m_apb_pwrite(m_apb_pwrite),
        .m_apb_pwdata(m_apb_pwdata),
        .m_apb_prdata(apb_prdata),
        .m_apb_pready(apb_pready),
        .m_apb_pslverr(apb_pslverr)
    );
    
    //----------------------------------------------------------------------------
    // APB Response Assignment
    //----------------------------------------------------------------------------
    // Assign wire outputs to reg outputs
    always @(*) begin
        m_apb_prdata = apb_prdata;
        m_apb_pready = apb_pready;
        m_apb_pslverr = apb_pslverr;
    end

endmodule


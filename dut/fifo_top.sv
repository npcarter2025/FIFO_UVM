//-----------------------------------------------------------------------------
// Module: fifo_top
// Description: Top-level wrapper integrating FIFO core with register interface
//-----------------------------------------------------------------------------

module fifo_top #(
    parameter DEPTH     = 16,
    parameter WIDTH     = 8,
    parameter ADDR_W    = 8,
    parameter DATA_W    = 32
)(
    input  logic                clk,
    input  logic                rst_n,

    //-------------------------------------------------------------------------
    // Register Bus Interface
    //-------------------------------------------------------------------------
    input  logic [ADDR_W-1:0]   reg_addr,
    input  logic [DATA_W-1:0]   reg_wdata,
    output logic [DATA_W-1:0]   reg_rdata,
    input  logic                reg_wen,
    input  logic                reg_ren,
    output logic                reg_ready,

    //-------------------------------------------------------------------------
    // FIFO Data Interface
    //-------------------------------------------------------------------------
    input  bit                  is_write,
    input  logic                sel,

    // Write port
    input  logic                w_enable,
    input  logic [WIDTH-1:0]    w_data,
    output logic                w_ready,

    // Read port
    output logic                r_enable,
    output logic [WIDTH-1:0]    r_data,
    input  logic                r_ready
);

    //-------------------------------------------------------------------------
    // Internal Signals - Register to FIFO Core
    //-------------------------------------------------------------------------
    logic                       fifo_enable;
    logic                       fifo_clear;
    logic [$clog2(DEPTH):0]     almost_full_thresh;

    // Status signals from FIFO core to registers
    logic                       fifo_empty;
    logic                       fifo_full;
    logic [$clog2(DEPTH):0]     fifo_count;
    logic                       fifo_overflow;
    logic                       fifo_underflow;

    //-------------------------------------------------------------------------
    // Register Module Instance
    //-------------------------------------------------------------------------
    fifo_regs #(
        .DEPTH   (DEPTH),
        .WIDTH   (WIDTH),
        .ADDR_W  (ADDR_W),
        .DATA_W  (DATA_W)
    ) u_fifo_regs (
        .clk                (clk),
        .rst_n              (rst_n),

        // Bus interface
        .addr               (reg_addr),
        .wdata              (reg_wdata),
        .rdata              (reg_rdata),
        .wen                (reg_wen),
        .ren                (reg_ren),
        .ready              (reg_ready),

        // Control outputs to FIFO core
        .fifo_enable        (fifo_enable),
        .fifo_clear         (fifo_clear),
        .almost_full_thresh (almost_full_thresh),

        // Status inputs from FIFO core
        .fifo_empty         (fifo_empty),
        .fifo_full          (fifo_full),
        .fifo_count         (fifo_count),
        .fifo_overflow      (fifo_overflow),
        .fifo_underflow     (fifo_underflow)
    );

    //-------------------------------------------------------------------------
    // FIFO Core Instance
    //-------------------------------------------------------------------------
    fifo_core #(
        .DEPTH  (DEPTH),
        .WIDTH  (WIDTH)
    ) u_fifo_core (
        .clk                (clk),
        .rst_n              (rst_n),

        // Control inputs from register module
        .fifo_enable        (fifo_enable),
        .fifo_clear         (fifo_clear),
        .almost_full_thresh (almost_full_thresh),

        // Status outputs to register module
        .fifo_empty         (fifo_empty),
        .fifo_full          (fifo_full),
        .fifo_count         (fifo_count),
        .fifo_overflow      (fifo_overflow),
        .fifo_underflow     (fifo_underflow),

        // Data interface
        .is_write           (is_write),
        .sel                (sel),
        .w_enable           (w_enable),
        .w_data             (w_data),
        .w_ready            (w_ready),
        .r_enable           (r_enable),
        .r_data             (r_data),
        .r_ready            (r_ready)
    );

endmodule

//-----------------------------------------------------------------------------
// Interface: reg_if
// Description: Register bus interface for UVM testbench
//-----------------------------------------------------------------------------

interface reg_if #(
    parameter ADDR_W = 8,
    parameter DATA_W = 32
)(
    input logic clk,
    input logic rst_n
);

    // Register bus signals (initialized to avoid X during reset)
    logic [ADDR_W-1:0]  addr  = '0;
    logic [DATA_W-1:0]  wdata = '0;
    logic [DATA_W-1:0]  rdata;
    logic               wen   = 1'b0;
    logic               ren   = 1'b0;
    logic               ready;

    //-------------------------------------------------------------------------
    // Clocking Blocks
    //-------------------------------------------------------------------------

    // Driver clocking block
    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;
        output addr, wdata, wen, ren;
        input  rdata, ready;
    endclocking

    // Monitor clocking block
    clocking mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input addr, wdata, wen, ren, rdata, ready;
    endclocking

    //-------------------------------------------------------------------------
    // Modports
    //-------------------------------------------------------------------------

    modport DRV (clocking drv_cb, input clk, input rst_n);
    modport MON (clocking mon_cb, input clk, input rst_n);

    //-------------------------------------------------------------------------
    // Assertions (optional, for protocol checking)
    //-------------------------------------------------------------------------

    // No simultaneous read and write
    property no_simultaneous_rw;
        @(posedge clk) disable iff (!rst_n)
        !(wen && ren);
    endproperty
    assert property (no_simultaneous_rw)
        else $error("REG_IF: Simultaneous read and write detected!");

endinterface

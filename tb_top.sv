`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import fifo_pkg::*;


    parameter WIDTH = 8;
    parameter DEPTH = 16;


    logic clk;
    logic rst;


    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end

    // Reset generation
    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    end


    fifo_if #(.WIDTH(WIDTH), .DEPTH(DEPTH)) vif (clk, rst);


    fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .clk        (clk),
        .rst        (rst),
        .is_write   (vif.is_write),
        .sel        (vif.sel),
        .w_enable   (vif.w_enable),
        .w_data     (vif.w_data),
        .w_ready    (vif.w_ready),
        .r_enable   (vif.r_enable),
        .r_data     (vif.r_data),
        .r_ready    (vif.r_ready)
    );

    // UVM test startup
    initial begin
        // Pass interface to UVM config database
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", vif);

        // Dump waveforms
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);

        // Run the test
        run_test("fifo_test");
    end

endmodule

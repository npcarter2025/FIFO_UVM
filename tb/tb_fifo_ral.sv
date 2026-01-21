//-----------------------------------------------------------------------------
// Testbench: tb_fifo_ral
// Description: UVM testbench with RAL integration for FIFO with registers
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_fifo_ral;

    //-------------------------------------------------------------------------
    // Import packages
    //-------------------------------------------------------------------------
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import reg_pkg::*;
    import fifo_ral_pkg::*;
    import fifo_ral_test_pkg::*;

    //-------------------------------------------------------------------------
    // Parameters
    //-------------------------------------------------------------------------
    parameter DEPTH  = 16;
    parameter WIDTH  = 8;
    parameter ADDR_W = 8;
    parameter DATA_W = 32;

    //-------------------------------------------------------------------------
    // Clock and Reset
    //-------------------------------------------------------------------------
    logic clk;
    logic rst_n;
    logic rst;  // Active-high reset for fifo_if compatibility

    // Clock generation - 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        rst_n = 0;
        rst   = 1;
        repeat(10) @(posedge clk);
        rst_n = 1;
        rst   = 0;
        `uvm_info("TB", "Reset released", UVM_LOW)
    end

    //-------------------------------------------------------------------------
    // Interface Instantiation
    //-------------------------------------------------------------------------
    
    // Register bus interface
    reg_if #(.ADDR_W(ADDR_W), .DATA_W(DATA_W)) reg_vif (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // FIFO data interface
    fifo_if #(.WIDTH(WIDTH), .DEPTH(DEPTH)) fifo_vif (
        .clk (clk),
        .rst (rst)
    );

    //-------------------------------------------------------------------------
    // DUT Instantiation - fifo_top with register interface
    //-------------------------------------------------------------------------
    fifo_top #(
        .DEPTH   (DEPTH),
        .WIDTH   (WIDTH),
        .ADDR_W  (ADDR_W),
        .DATA_W  (DATA_W)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),

        // Register bus interface
        .reg_addr   (reg_vif.addr),
        .reg_wdata  (reg_vif.wdata),
        .reg_rdata  (reg_vif.rdata),
        .reg_wen    (reg_vif.wen),
        .reg_ren    (reg_vif.ren),
        .reg_ready  (reg_vif.ready),

        // FIFO data interface
        .is_write   (fifo_vif.is_write),
        .sel        (fifo_vif.sel),
        .w_enable   (fifo_vif.w_enable),
        .w_data     (fifo_vif.w_data),
        .w_ready    (fifo_vif.w_ready),
        .r_enable   (fifo_vif.r_enable),
        .r_data     (fifo_vif.r_data),
        .r_ready    (fifo_vif.r_ready)
    );

    //-------------------------------------------------------------------------
    // UVM Configuration and Test Start
    //-------------------------------------------------------------------------
    initial begin
        // Register interfaces in config_db
        
        // Register interface for reg_agent
        uvm_config_db#(virtual reg_if)::set(null, "uvm_test_top.env.reg_agt.*", "vif", reg_vif);
        
        // FIFO interface for fifo_agent
        uvm_config_db#(virtual fifo_if)::set(null, "uvm_test_top.env.fifo_agt.*", "vif", fifo_vif);
        
        // Also set with wildcard for flexibility
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", fifo_vif);

        // Start UVM test
        run_test();
    end

    //-------------------------------------------------------------------------
    // Waveform Dump
    //-------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_fifo_ral.vcd");
        $dumpvars(0, tb_fifo_ral);
    end

    //-------------------------------------------------------------------------
    // Timeout
    //-------------------------------------------------------------------------
    initial begin
        #100000ns;
        `uvm_fatal("TB", "Test timeout!")
    end

endmodule

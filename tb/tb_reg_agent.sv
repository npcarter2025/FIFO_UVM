//-----------------------------------------------------------------------------
// Testbench: tb_reg_agent
// Description: UVM testbench for register agent verification
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

// Import packages
import uvm_pkg::*;
`include "uvm_macros.svh"

import reg_pkg::*;
`include "reg_test.sv"

module tb_reg_agent;

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

    // Clock generation - 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        rst_n = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        `uvm_info("TB", "Reset released", UVM_LOW)
    end

    //-------------------------------------------------------------------------
    // Interface Instantiation
    //-------------------------------------------------------------------------
    reg_if #(.ADDR_W(ADDR_W), .DATA_W(DATA_W)) reg_vif (
        .clk   (clk),
        .rst_n (rst_n)
    );

    //-------------------------------------------------------------------------
    // DUT Instantiation
    //-------------------------------------------------------------------------
    // FIFO data interface signals (directly connected for now)
    logic               fifo_sel;
    bit                 fifo_is_write;
    logic               fifo_w_enable;
    logic [WIDTH-1:0]   fifo_w_data;
    logic               fifo_w_ready;
    logic               fifo_r_enable;
    logic [WIDTH-1:0]   fifo_r_data;
    logic               fifo_r_ready;

    // Initialize FIFO data signals (not used in register-only test)
    initial begin
        fifo_sel      = 1'b1;
        fifo_is_write = 1'b0;
        fifo_w_enable = 1'b0;
        fifo_w_data   = '0;
        fifo_r_ready  = 1'b0;
    end

    fifo_top #(
        .DEPTH   (DEPTH),
        .WIDTH   (WIDTH),
        .ADDR_W  (ADDR_W),
        .DATA_W  (DATA_W)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),

        // Register bus (from interface)
        .reg_addr   (reg_vif.addr),
        .reg_wdata  (reg_vif.wdata),
        .reg_rdata  (reg_vif.rdata),
        .reg_wen    (reg_vif.wen),
        .reg_ren    (reg_vif.ren),
        .reg_ready  (reg_vif.ready),

        // FIFO data interface
        .is_write   (fifo_is_write),
        .sel        (fifo_sel),
        .w_enable   (fifo_w_enable),
        .w_data     (fifo_w_data),
        .w_ready    (fifo_w_ready),
        .r_enable   (fifo_r_enable),
        .r_data     (fifo_r_data),
        .r_ready    (fifo_r_ready)
    );

    //-------------------------------------------------------------------------
    // UVM Configuration and Test Start
    //-------------------------------------------------------------------------
    initial begin
        // Register the interface in config_db
        uvm_config_db#(virtual reg_if)::set(null, "uvm_test_top.env.reg_agt.*", "vif", reg_vif);

        // Start UVM test
        run_test();
    end

    //-------------------------------------------------------------------------
    // Waveform Dump
    //-------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_reg_agent.vcd");
        $dumpvars(0, tb_reg_agent);
    end

    //-------------------------------------------------------------------------
    // Timeout
    //-------------------------------------------------------------------------
    initial begin
        #50000ns;
        `uvm_fatal("TB", "Test timeout!")
    end

endmodule

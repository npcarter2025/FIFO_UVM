//-----------------------------------------------------------------------------
// Testbench: tb_fifo_regs
// Description: Simple directed test for FIFO register interface (non-UVM)
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_fifo_regs;

    //-------------------------------------------------------------------------
    // Parameters
    //-------------------------------------------------------------------------
    parameter DEPTH  = 16;
    parameter WIDTH  = 8;
    parameter ADDR_W = 8;
    parameter DATA_W = 32;

    // Register addresses
    localparam ADDR_CTRL   = 8'h00;
    localparam ADDR_STATUS = 8'h04;
    localparam ADDR_THRESH = 8'h08;

    //-------------------------------------------------------------------------
    // DUT Signals
    //-------------------------------------------------------------------------
    logic                clk;
    logic                rst_n;

    // Register bus
    logic [ADDR_W-1:0]   reg_addr;
    logic [DATA_W-1:0]   reg_wdata;
    logic [DATA_W-1:0]   reg_rdata;
    logic                reg_wen;
    logic                reg_ren;
    logic                reg_ready;

    // FIFO data interface
    bit                  is_write;
    logic                sel;
    logic                w_enable;
    logic [WIDTH-1:0]    w_data;
    logic                w_ready;
    logic                r_enable;
    logic [WIDTH-1:0]    r_data;
    logic                r_ready;

    //-------------------------------------------------------------------------
    // Test Status
    //-------------------------------------------------------------------------
    int test_pass = 0;
    int test_fail = 0;

    //-------------------------------------------------------------------------
    // DUT Instantiation
    //-------------------------------------------------------------------------
    fifo_top #(
        .DEPTH   (DEPTH),
        .WIDTH   (WIDTH),
        .ADDR_W  (ADDR_W),
        .DATA_W  (DATA_W)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .reg_addr   (reg_addr),
        .reg_wdata  (reg_wdata),
        .reg_rdata  (reg_rdata),
        .reg_wen    (reg_wen),
        .reg_ren    (reg_ren),
        .reg_ready  (reg_ready),
        .is_write   (is_write),
        .sel        (sel),
        .w_enable   (w_enable),
        .w_data     (w_data),
        .w_ready    (w_ready),
        .r_enable   (r_enable),
        .r_data     (r_data),
        .r_ready    (r_ready)
    );

    //-------------------------------------------------------------------------
    // Clock Generation
    //-------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;  // 100MHz clock

    //-------------------------------------------------------------------------
    // Helper Tasks
    //-------------------------------------------------------------------------

    // Write to register
    task automatic reg_write(input [ADDR_W-1:0] addr, input [DATA_W-1:0] data);
        @(posedge clk);
        reg_addr  <= addr;
        reg_wdata <= data;
        reg_wen   <= 1'b1;
        reg_ren   <= 1'b0;
        @(posedge clk);
        reg_wen   <= 1'b0;
        @(posedge clk);
    endtask

    // Read from register
    task automatic reg_read(input [ADDR_W-1:0] addr, output [DATA_W-1:0] data);
        @(posedge clk);
        reg_addr <= addr;
        reg_wen  <= 1'b0;
        reg_ren  <= 1'b1;
        @(posedge clk);
        data = reg_rdata;
        reg_ren  <= 1'b0;
        @(posedge clk);
    endtask

    // Write data to FIFO
    task automatic fifo_write(input [WIDTH-1:0] data);
        // Wait for FIFO to be ready first
        sel      <= 1'b1;
        is_write <= 1'b1;
        w_data   <= data;
        w_enable <= 1'b0;
        @(posedge clk);
        while (!w_ready) @(posedge clk);
        // Assert w_enable for exactly one cycle when ready
        w_enable <= 1'b1;
        @(posedge clk);
        w_enable <= 1'b0;
    endtask

    // Read data from FIFO
    task automatic fifo_read(output [WIDTH-1:0] data);
        // Wait for FIFO to have data first
        sel      <= 1'b1;
        is_write <= 1'b0;
        r_ready  <= 1'b0;
        @(posedge clk);
        while (!r_enable) @(posedge clk);
        // Assert r_ready for exactly one cycle when data available
        r_ready  <= 1'b1;
        @(posedge clk);
        data = r_data;
        r_ready  <= 1'b0;
    endtask

    // Check and report
    task automatic check(input string name, input [DATA_W-1:0] expected, input [DATA_W-1:0] actual);
        if (expected === actual) begin
            $display("[PASS] %s: Expected=0x%08h, Actual=0x%08h", name, expected, actual);
            test_pass++;
        end else begin
            $display("[FAIL] %s: Expected=0x%08h, Actual=0x%08h", name, expected, actual);
            test_fail++;
        end
    endtask

    //-------------------------------------------------------------------------
    // Main Test Sequence
    //-------------------------------------------------------------------------
    initial begin
        logic [DATA_W-1:0] read_data;
        logic [WIDTH-1:0]  fifo_data;

        // Initialize
        $display("\n========================================");
        $display("  FIFO Register Interface Test");
        $display("========================================\n");

        rst_n     = 0;
        reg_addr  = 0;
        reg_wdata = 0;
        reg_wen   = 0;
        reg_ren   = 0;
        sel       = 0;
        is_write  = 0;
        w_enable  = 0;
        w_data    = 0;
        r_ready   = 0;

        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        //---------------------------------------------------------------------
        // Test 1: Read default register values after reset
        //---------------------------------------------------------------------
        $display("\n--- Test 1: Default Register Values ---");

        reg_read(ADDR_CTRL, read_data);
        check("CTRL default", 32'h0, read_data);

        reg_read(ADDR_STATUS, read_data);
        check("STATUS default (FIFO empty)", 32'h00000001, read_data);  // Empty bit set

        reg_read(ADDR_THRESH, read_data);
        check("THRESH default", DEPTH-1, read_data);

        //---------------------------------------------------------------------
        // Test 2: Write and read back CTRL register
        //---------------------------------------------------------------------
        $display("\n--- Test 2: CTRL Register Write/Read ---");

        reg_write(ADDR_CTRL, 32'h00000001);  // Enable FIFO
        reg_read(ADDR_CTRL, read_data);
        check("CTRL enable bit", 32'h00000001, read_data);

        //---------------------------------------------------------------------
        // Test 3: Write and read back THRESH register
        //---------------------------------------------------------------------
        $display("\n--- Test 3: THRESH Register Write/Read ---");

        reg_write(ADDR_THRESH, 32'h0000000A);  // Set threshold to 10
        reg_read(ADDR_THRESH, read_data);
        check("THRESH value", 32'h0000000A, read_data[$clog2(DEPTH):0]);

        //---------------------------------------------------------------------
        // Test 4: FIFO operations with enable
        //---------------------------------------------------------------------
        $display("\n--- Test 4: FIFO Operations with Enable ---");

        // Make sure FIFO is enabled
        reg_write(ADDR_CTRL, 32'h00000001);

        // Write some data to FIFO
        for (int i = 0; i < 5; i++) begin
            fifo_write(i + 8'hA0);
        end

        // Check status - should show count = 5, not empty, not full
        reg_read(ADDR_STATUS, read_data);
        $display("STATUS after 5 writes: 0x%08h", read_data);
        check("STATUS empty bit cleared", 1'b0, read_data[0]);
        check("STATUS full bit cleared", 1'b0, read_data[1]);
        check("STATUS count", 5, read_data[15:8]);

        // Read back data
        for (int i = 0; i < 5; i++) begin
            fifo_read(fifo_data);
            check($sformatf("FIFO read data[%0d]", i), i + 8'hA0, fifo_data);
        end

        // Check status - should be empty again
        reg_read(ADDR_STATUS, read_data);
        check("STATUS empty after reads", 1'b1, read_data[0]);

        //---------------------------------------------------------------------
        // Test 5: FIFO Clear via CTRL register
        //---------------------------------------------------------------------
        $display("\n--- Test 5: FIFO Clear via CTRL ---");

        // Write more data
        for (int i = 0; i < 8; i++) begin
            fifo_write(i + 8'hB0);
        end

        // Verify count
        reg_read(ADDR_STATUS, read_data);
        check("STATUS count before clear", 8, read_data[15:8]);

        // Clear FIFO by writing to CTRL.CLEAR bit
        reg_write(ADDR_CTRL, 32'h00000003);  // Enable + Clear

        // CLEAR bit should self-clear
        reg_read(ADDR_CTRL, read_data);
        check("CTRL.CLEAR self-cleared", 32'h00000001, read_data);  // Only enable bit remains

        // FIFO should be empty
        reg_read(ADDR_STATUS, read_data);
        check("STATUS empty after clear", 1'b1, read_data[0]);
        check("STATUS count after clear", 0, read_data[15:8]);

        //---------------------------------------------------------------------
        // Test 6: Almost Full Threshold
        //---------------------------------------------------------------------
        $display("\n--- Test 6: Almost Full Threshold ---");

        // Set threshold to 4
        reg_write(ADDR_THRESH, 32'h00000004);

        // Write 3 entries - should not be almost full
        for (int i = 0; i < 3; i++) begin
            fifo_write(i);
        end
        reg_read(ADDR_STATUS, read_data);
        check("ALMOST_FULL not set (count=3, thresh=4)", 1'b0, read_data[2]);

        // Write 1 more - should be almost full (count = 4 >= thresh)
        fifo_write(8'hFF);
        reg_read(ADDR_STATUS, read_data);
        check("ALMOST_FULL set (count=4, thresh=4)", 1'b1, read_data[2]);

        // Clear FIFO for next test
        reg_write(ADDR_CTRL, 32'h00000003);
        repeat(2) @(posedge clk);

        //---------------------------------------------------------------------
        // Test 7: FIFO disabled - operations blocked
        //---------------------------------------------------------------------
        $display("\n--- Test 7: FIFO Disabled ---");

        // Disable FIFO
        reg_write(ADDR_CTRL, 32'h00000000);

        // Try to write - should not change count
        sel      <= 1'b1;
        is_write <= 1'b1;
        w_enable <= 1'b1;
        w_data   <= 8'hDE;
        repeat(3) @(posedge clk);
        w_enable <= 1'b0;

        reg_read(ADDR_STATUS, read_data);
        check("COUNT unchanged when disabled", 0, read_data[15:8]);

        // Re-enable for proper cleanup
        reg_write(ADDR_CTRL, 32'h00000001);

        //---------------------------------------------------------------------
        // Test Summary
        //---------------------------------------------------------------------
        $display("\n========================================");
        $display("  Test Summary");
        $display("========================================");
        $display("  PASSED: %0d", test_pass);
        $display("  FAILED: %0d", test_fail);
        $display("========================================\n");

        if (test_fail == 0) begin
            $display("*** ALL TESTS PASSED ***\n");
        end else begin
            $display("*** SOME TESTS FAILED ***\n");
        end

        $finish;
    end

    //-------------------------------------------------------------------------
    // Timeout
    //-------------------------------------------------------------------------
    initial begin
        #10000;
        $display("\n[ERROR] Test timeout!\n");
        $finish;
    end

    //-------------------------------------------------------------------------
    // Waveform Dump
    //-------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_fifo_regs.vcd");
        $dumpvars(0, tb_fifo_regs);
    end

endmodule

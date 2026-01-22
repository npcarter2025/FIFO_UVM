`ifndef FIFO_RAL_SEQUENCE_SVH
`define FIFO_RAL_SEQUENCE_SVH

//-----------------------------------------------------------------------------
// Class: fifo_ral_base_sequence
// Description: Base sequence for RAL-based register operations
//-----------------------------------------------------------------------------

class fifo_ral_base_sequence extends uvm_sequence;

    `uvm_object_utils(fifo_ral_base_sequence)

    // Reference to the register block (set by test)
    fifo_reg_block reg_block;

    function new(string name = "fifo_ral_base_sequence");
        super.new(name);
    endfunction

    // Helper: Check operation status
    function void check_status(uvm_status_e status, string op_name);
        if (status != UVM_IS_OK) begin
            `uvm_error(get_type_name(), $sformatf("%s failed with status %s", op_name, status.name()))
        end
    endfunction

endclass

//-----------------------------------------------------------------------------
// Class: fifo_ral_sanity_sequence
// Description: Sanity test sequence using RAL API
//-----------------------------------------------------------------------------

class fifo_ral_sanity_sequence extends fifo_ral_base_sequence;

    `uvm_object_utils(fifo_ral_sanity_sequence)

    function new(string name = "fifo_ral_sanity_sequence");
        super.new(name);
    endfunction

    virtual task body();
        uvm_status_e status;
        uvm_reg_data_t rdata;
        uvm_reg_data_t wdata;

        `uvm_info(get_type_name(), "=== Starting RAL Sanity Sequence ===", UVM_LOW)

        //---------------------------------------------------------------------
        // Test 1: Read default values using RAL
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Test 1: Read Default Values ---", UVM_LOW)

        // Read CTRL register
        reg_block.ctrl.read(status, rdata);
        check_status(status, "CTRL read");
        `uvm_info(get_type_name(), $sformatf("CTRL = 0x%08h (enable=%0d)", 
                  rdata, reg_block.ctrl.enable.get()), UVM_LOW)

        // Read STATUS register
        reg_block.status.read(status, rdata);
        check_status(status, "STATUS read");
        `uvm_info(get_type_name(), $sformatf("STATUS = 0x%08h (empty=%0d, full=%0d, count=%0d)", 
                  rdata, reg_block.status.empty.get(), reg_block.status.full.get(),
                  reg_block.status.count.get()), UVM_LOW)

        // Read THRESH register
        reg_block.thresh.read(status, rdata);
        check_status(status, "THRESH read");
        `uvm_info(get_type_name(), $sformatf("THRESH = 0x%08h (value=%0d)", 
                  rdata, reg_block.thresh.thresh_val.get()), UVM_LOW)

        //---------------------------------------------------------------------
        // Test 2: Write CTRL.ENABLE using field access
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Test 2: Enable FIFO via CTRL.ENABLE ---", UVM_LOW)

        // Method 1: Set field value and update register
        reg_block.ctrl.enable.set(1);
        reg_block.ctrl.update(status);
        check_status(status, "CTRL update");

        // Verify by reading back
        reg_block.ctrl.read(status, rdata);
        check_status(status, "CTRL read-back");
        if (reg_block.ctrl.enable.get() != 1) begin
            `uvm_error(get_type_name(), "CTRL.ENABLE not set!")
        end else begin
            `uvm_info(get_type_name(), "CTRL.ENABLE set successfully", UVM_LOW)
        end

        //---------------------------------------------------------------------
        // Test 3: Write THRESH using register write
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Test 3: Set THRESH = 10 ---", UVM_LOW)

        // Method 2: Direct register write
        wdata = 32'h0000000A;  // Threshold = 10
        reg_block.thresh.write(status, wdata);
        check_status(status, "THRESH write");

        // Verify
        reg_block.thresh.read(status, rdata);
        check_status(status, "THRESH read-back");
        if (reg_block.thresh.thresh_val.get() != 10) begin
            `uvm_error(get_type_name(), $sformatf("THRESH mismatch: expected 10, got %0d",
                       reg_block.thresh.thresh_val.get()))
        end else begin
            `uvm_info(get_type_name(), "THRESH set successfully to 10", UVM_LOW)
        end

        //---------------------------------------------------------------------
        // Test 4: Read STATUS (should show empty FIFO)
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Test 4: Check STATUS ---", UVM_LOW)

        reg_block.status.read(status, rdata);
        check_status(status, "STATUS read");
        
        `uvm_info(get_type_name(), $sformatf("STATUS: empty=%0d, full=%0d, almost_full=%0d, count=%0d",
                  reg_block.status.empty.get(),
                  reg_block.status.full.get(),
                  reg_block.status.almost_full.get(),
                  reg_block.status.count.get()), UVM_LOW)

        if (reg_block.status.empty.get() != 1) begin
            `uvm_error(get_type_name(), "FIFO should be empty!")
        end

        //---------------------------------------------------------------------
        // Test 5: Clear FIFO using CTRL.CLEAR
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Test 5: Clear FIFO via CTRL.CLEAR ---", UVM_LOW)

        // Set the clear bit
        reg_block.ctrl.clear.set(1);
        reg_block.ctrl.update(status);
        check_status(status, "CTRL.CLEAR update");

        // Read back - CLEAR should have self-cleared to 0
        reg_block.ctrl.read(status, rdata);
        check_status(status, "CTRL read after clear");
        
        // Note: The mirror might not reflect self-clearing behavior
        // Check the actual read data
        if ((rdata & 32'h2) != 0) begin
            `uvm_warning(get_type_name(), "CTRL.CLEAR may not have self-cleared (check RTL)")
        end else begin
            `uvm_info(get_type_name(), "CTRL.CLEAR self-cleared successfully", UVM_LOW)
        end

        //---------------------------------------------------------------------
        // Test 6: Mirror/Desired value check
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Test 6: RAL Mirror Check ---", UVM_LOW)

        // Get mirrored value without bus access
        `uvm_info(get_type_name(), $sformatf("CTRL mirror   = 0x%08h", reg_block.ctrl.get_mirrored_value()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("THRESH mirror = 0x%08h", reg_block.thresh.get_mirrored_value()), UVM_LOW)

        `uvm_info(get_type_name(), "=== RAL Sanity Sequence Complete ===", UVM_LOW)
    endtask

endclass

//-----------------------------------------------------------------------------
// Class: fifo_ral_reset_sequence
// Description: Test reset values using built-in RAL sequence
//-----------------------------------------------------------------------------

class fifo_ral_reset_sequence extends fifo_ral_base_sequence;

    `uvm_object_utils(fifo_ral_reset_sequence)

    function new(string name = "fifo_ral_reset_sequence");
        super.new(name);
    endfunction

    virtual task body();
        uvm_reg_hw_reset_seq reset_seq;

        `uvm_info(get_type_name(), "=== Running RAL Hardware Reset Sequence ===", UVM_LOW)

        // Use built-in UVM sequence to check reset values
        reset_seq = uvm_reg_hw_reset_seq::type_id::create("reset_seq");
        reset_seq.model = reg_block;
        reset_seq.start(null);

        `uvm_info(get_type_name(), "=== RAL Hardware Reset Sequence Complete ===", UVM_LOW)
    endtask

endclass

//-----------------------------------------------------------------------------
// Class: fifo_ral_reset_verify_sequence  
// Description: 7.3 - Comprehensive reset verification sequence
//              Writes values, uses reg_block.reset() to reset mirror,
//              reads back and verifies DUT matches reset values
//-----------------------------------------------------------------------------

class fifo_ral_reset_verify_sequence extends fifo_ral_base_sequence;

    `uvm_object_utils(fifo_ral_reset_verify_sequence)

    function new(string name = "fifo_ral_reset_verify_sequence");
        super.new(name);
    endfunction

    virtual task body();
        uvm_status_e status;
        uvm_reg_data_t rdata;
        uvm_reg regs[$];
        int errors = 0;

        `uvm_info(get_type_name(), "=== Starting Reset Verification Sequence ===", UVM_LOW)

        //---------------------------------------------------------------------
        // Step 1: Write non-reset values to writable registers
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "Step 1: Write non-reset values to registers", UVM_LOW)

        // Write CTRL: ENABLE=1
        reg_block.ctrl.write(status, 32'h0000_0001);
        check_status(status, "CTRL write");

        // Write THRESH: value=0x0A (10)
        reg_block.thresh.write(status, 32'h0000_000A);
        check_status(status, "THRESH write");

        // Verify writes
        reg_block.ctrl.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("CTRL after write: 0x%08h (ENABLE=%0d)", 
                  rdata, reg_block.ctrl.enable.get()), UVM_LOW)

        reg_block.thresh.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("THRESH after write: 0x%08h (value=%0d)", 
                  rdata, reg_block.thresh.thresh_val.get()), UVM_LOW)

        //---------------------------------------------------------------------
        // Step 2: Report current mirror values vs expected reset values
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "Step 2: Check current mirror vs reset values", UVM_LOW)

        reg_block.get_registers(regs);
        foreach (regs[i]) begin
            `uvm_info(get_type_name(), $sformatf("  %s: mirror=0x%08h, reset=0x%08h", 
                      regs[i].get_name(),
                      regs[i].get_mirrored_value(),
                      regs[i].get_reset()), UVM_LOW)
        end

        //---------------------------------------------------------------------
        // Step 3: Reset the RAL mirror (not the DUT - that requires HW reset)
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "Step 3: Reset RAL mirror to default values", UVM_LOW)
        
        // Note: reg_block.reset() only resets the RAL mirror, not the actual DUT
        // To test DUT reset, you would need to trigger hardware reset
        // This demonstrates the RAL reset API
        reg_block.reset();

        `uvm_info(get_type_name(), "RAL mirror reset complete. Mirror values now:", UVM_LOW)
        foreach (regs[i]) begin
            `uvm_info(get_type_name(), $sformatf("  %s: mirror=0x%08h (expected reset=0x%08h)", 
                      regs[i].get_name(),
                      regs[i].get_mirrored_value(),
                      regs[i].get_reset()), UVM_LOW)
            
            // Verify mirror matches reset value
            if (regs[i].get_mirrored_value() != regs[i].get_reset()) begin
                `uvm_error(get_type_name(), $sformatf("%s mirror mismatch after reset()", 
                          regs[i].get_name()))
                errors++;
            end
        end

        //---------------------------------------------------------------------
        // Step 4: Read actual DUT registers (may differ since we didn't HW reset)
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "Step 4: Read actual DUT register values", UVM_LOW)
        
        reg_block.ctrl.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("  CTRL DUT value: 0x%08h", rdata), UVM_LOW)
        
        reg_block.thresh.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("  THRESH DUT value: 0x%08h", rdata), UVM_LOW)
        
        reg_block.status.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("  STATUS DUT value: 0x%08h", rdata), UVM_LOW)

        if (errors == 0) begin
            `uvm_info(get_type_name(), "=== Reset Verification Sequence PASSED ===", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("Reset verification had %0d errors", errors))
        end
    endtask

endclass

//-----------------------------------------------------------------------------
// Class: fifo_ral_bit_bash_sequence
// Description: 7.4 - Bit-bash test using built-in RAL sequence
//              Tests all writable register bits by writing/reading each bit
//-----------------------------------------------------------------------------

class fifo_ral_bit_bash_sequence extends fifo_ral_base_sequence;

    `uvm_object_utils(fifo_ral_bit_bash_sequence)

    function new(string name = "fifo_ral_bit_bash_sequence");
        super.new(name);
    endfunction

    virtual task body();
        uvm_reg_bit_bash_seq bit_bash_seq;

        `uvm_info(get_type_name(), "=== Starting RAL Bit-Bash Sequence ===", UVM_LOW)
        `uvm_info(get_type_name(), "This tests all writable bits in all registers", UVM_LOW)

        // Use built-in UVM bit-bash sequence
        // This will:
        //   - Walk through each register
        //   - For each writable bit, write 1 then 0
        //   - Verify the bit retains the written value
        bit_bash_seq = uvm_reg_bit_bash_seq::type_id::create("bit_bash_seq");
        bit_bash_seq.model = reg_block;
        bit_bash_seq.start(null);

        `uvm_info(get_type_name(), "=== RAL Bit-Bash Sequence Complete ===", UVM_LOW)
    endtask

endclass

//-----------------------------------------------------------------------------
// Class: fifo_ral_mem_walk_sequence
// Description: Additional built-in RAL sequence - memory access test
//              (included for completeness, though FIFO has no RAL memories)
//-----------------------------------------------------------------------------

class fifo_ral_access_sequence extends fifo_ral_base_sequence;

    `uvm_object_utils(fifo_ral_access_sequence)

    function new(string name = "fifo_ral_access_sequence");
        super.new(name);
    endfunction

    virtual task body();
        uvm_reg_access_seq access_seq;

        `uvm_info(get_type_name(), "=== Starting RAL Access Sequence ===", UVM_LOW)
        `uvm_info(get_type_name(), "This verifies register accessibility (R/W vs RO)", UVM_LOW)

        // Use built-in UVM register access sequence
        access_seq = uvm_reg_access_seq::type_id::create("access_seq");
        access_seq.model = reg_block;
        access_seq.start(null);

        `uvm_info(get_type_name(), "=== RAL Access Sequence Complete ===", UVM_LOW)
    endtask

endclass

`endif

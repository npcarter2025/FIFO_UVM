`ifndef FIFO_CONFIG_THEN_WRITE_SEQUENCE_SVH
`define FIFO_CONFIG_THEN_WRITE_SEQUENCE_SVH

//-----------------------------------------------------------------------------
// Class: fifo_config_then_write_sequence
// Description: Virtual sequence that:
//   1. Configures FIFO (enable, set threshold)
//   2. Writes data to FIFO
//   3. Verifies STATUS register (almost_full flag)
//
// This demonstrates sequential coordination between register and data agents.
//-----------------------------------------------------------------------------

class fifo_config_then_write_sequence extends fifo_virtual_base_sequence;

    `uvm_object_utils(fifo_config_then_write_sequence)

    // Configuration
    rand bit [7:0] threshold;
    rand int       num_writes;

    constraint reasonable_c {
        threshold inside {[2:14]};
        num_writes inside {[1:16]};
    }

    function new(string name = "fifo_config_then_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit empty, full, almost_full;
        bit [7:0] count;

        `uvm_info(get_type_name(), "=== Starting Config-Then-Write Sequence ===", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("threshold=%0d, num_writes=%0d", threshold, num_writes), UVM_LOW)

        //---------------------------------------------------------------------
        // Step 1: Configure FIFO via registers
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Step 1: Configure FIFO ---", UVM_LOW)
        
        // Enable FIFO
        enable_fifo();
        
        // Set almost-full threshold
        set_threshold(threshold);
        
        // Clear FIFO to start fresh
        clear_fifo();

        // Verify configuration
        read_status(empty, full, almost_full, count);
        if (!empty) begin
            `uvm_error(get_type_name(), "FIFO should be empty after clear!")
        end

        //---------------------------------------------------------------------
        // Step 2: Write data to FIFO via data agent
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Step 2: Write Data to FIFO ---", UVM_LOW)
        
        write_fifo_items(num_writes);

        //---------------------------------------------------------------------
        // Step 3: Verify STATUS via registers
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Step 3: Verify STATUS ---", UVM_LOW)
        
        read_status(empty, full, almost_full, count);

        // Check count
        if (count != num_writes) begin
            `uvm_error(get_type_name(), $sformatf("Count mismatch: expected %0d, got %0d", num_writes, count))
        end else begin
            `uvm_info(get_type_name(), $sformatf("Count verified: %0d", count), UVM_LOW)
        end

        // Check almost_full flag
        if (num_writes >= threshold) begin
            if (!almost_full) begin
                `uvm_error(get_type_name(), $sformatf("ALMOST_FULL should be set (count=%0d >= thresh=%0d)", count, threshold))
            end else begin
                `uvm_info(get_type_name(), "ALMOST_FULL flag correctly set", UVM_LOW)
            end
        end else begin
            if (almost_full) begin
                `uvm_error(get_type_name(), $sformatf("ALMOST_FULL should NOT be set (count=%0d < thresh=%0d)", count, threshold))
            end else begin
                `uvm_info(get_type_name(), "ALMOST_FULL flag correctly cleared", UVM_LOW)
            end
        end

        // Check empty/full
        if (empty) begin
            `uvm_error(get_type_name(), "FIFO should not be empty after writes!")
        end

        `uvm_info(get_type_name(), "=== Config-Then-Write Sequence Complete ===", UVM_LOW)
    endtask

endclass

//-----------------------------------------------------------------------------
// Class: fifo_threshold_sweep_sequence
// Description: Sweeps through different threshold values and verifies behavior
//-----------------------------------------------------------------------------

class fifo_threshold_sweep_sequence extends fifo_virtual_base_sequence;

    `uvm_object_utils(fifo_threshold_sweep_sequence)

    function new(string name = "fifo_threshold_sweep_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit empty, full, almost_full;
        bit [7:0] count;
        int thresholds[] = '{4, 8, 12};

        `uvm_info(get_type_name(), "=== Starting Threshold Sweep Sequence ===", UVM_LOW)

        // Enable FIFO once
        enable_fifo();

        foreach (thresholds[i]) begin
            int thresh = thresholds[i];
            
            `uvm_info(get_type_name(), $sformatf("--- Testing threshold = %0d ---", thresh), UVM_LOW)
            
            // Clear and set new threshold
            clear_fifo();
            set_threshold(thresh);

            // Write up to threshold and check ALMOST_FULL transitions
            for (int w = 1; w <= thresh + 2 && w <= 16; w++) begin
                write_fifo_items(1, w);  // Write one item at a time
                read_status(empty, full, almost_full, count);
                
                if (w >= thresh && !almost_full) begin
                    `uvm_error(get_type_name(), $sformatf("ALMOST_FULL should be set at count=%0d, thresh=%0d", w, thresh))
                end else if (w < thresh && almost_full) begin
                    `uvm_error(get_type_name(), $sformatf("ALMOST_FULL should NOT be set at count=%0d, thresh=%0d", w, thresh))
                end
            end

            `uvm_info(get_type_name(), $sformatf("Threshold %0d test complete", thresh), UVM_LOW)
        end

        `uvm_info(get_type_name(), "=== Threshold Sweep Sequence Complete ===", UVM_LOW)
    endtask

endclass

`endif

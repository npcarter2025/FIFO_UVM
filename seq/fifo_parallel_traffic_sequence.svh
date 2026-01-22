`ifndef FIFO_PARALLEL_TRAFFIC_SEQUENCE_SVH
`define FIFO_PARALLEL_TRAFFIC_SEQUENCE_SVH

//-----------------------------------------------------------------------------
// Class: fifo_parallel_traffic_sequence
// Description: Virtual sequence that runs register and data traffic in parallel
//              using fork/join to demonstrate concurrent agent coordination.
//-----------------------------------------------------------------------------

class fifo_parallel_traffic_sequence extends fifo_virtual_base_sequence;

    `uvm_object_utils(fifo_parallel_traffic_sequence)

    function new(string name = "fifo_parallel_traffic_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit empty, full, almost_full;
        bit [7:0] count;

        `uvm_info(get_type_name(), "=== Starting Parallel Traffic Sequence ===", UVM_LOW)

        //---------------------------------------------------------------------
        // Initial Setup
        //---------------------------------------------------------------------
        enable_fifo();
        set_threshold(8);
        clear_fifo();

        //---------------------------------------------------------------------
        // Parallel Traffic: Register polling while data writes
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Starting parallel traffic ---", UVM_LOW)

        fork
            // Thread 1: Write data to FIFO
            begin
                `uvm_info(get_type_name(), "[DATA] Starting FIFO writes", UVM_MEDIUM)
                for (int i = 0; i < 10; i++) begin
                    fifo_item item = fifo_item::type_id::create("item");
                    start_item(item, -1, fifo_sqr);
                    item.op = 1;  // Write
                    item.w_data = 8'hD0 + i;
                    finish_item(item);
                    `uvm_info(get_type_name(), $sformatf("[DATA] Wrote item %0d", i), UVM_MEDIUM)
                end
                `uvm_info(get_type_name(), "[DATA] FIFO writes complete", UVM_MEDIUM)
            end

            // Thread 2: Periodically poll STATUS register
            begin
                `uvm_info(get_type_name(), "[REGS] Starting STATUS polling", UVM_MEDIUM)
                for (int poll = 0; poll < 5; poll++) begin
                    // Small delay between polls
                    #50ns;
                    
                    // Read status
                    read_status(empty, full, almost_full, count);
                    `uvm_info(get_type_name(), $sformatf("[REGS] Poll %0d: count=%0d, almost_full=%0d", 
                              poll, count, almost_full), UVM_MEDIUM)
                end
                `uvm_info(get_type_name(), "[REGS] STATUS polling complete", UVM_MEDIUM)
            end
        join

        //---------------------------------------------------------------------
        // Final Status Check
        //---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- Final status check ---", UVM_LOW)
        read_status(empty, full, almost_full, count);
        
        if (count != 10) begin
            `uvm_error(get_type_name(), $sformatf("Expected count=10, got %0d", count))
        end
        if (!almost_full) begin
            `uvm_error(get_type_name(), "ALMOST_FULL should be set (count=10, thresh=8)")
        end

        `uvm_info(get_type_name(), "=== Parallel Traffic Sequence Complete ===", UVM_LOW)
    endtask

endclass

//-----------------------------------------------------------------------------
// Class: fifo_write_read_interleaved_sequence
// Description: Interleaves write and read operations while monitoring status
//-----------------------------------------------------------------------------

class fifo_write_read_interleaved_sequence extends fifo_virtual_base_sequence;

    `uvm_object_utils(fifo_write_read_interleaved_sequence)

    function new(string name = "fifo_write_read_interleaved_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit empty, full, almost_full;
        bit [7:0] count;
        int expected_count;

        `uvm_info(get_type_name(), "=== Starting Write-Read Interleaved Sequence ===", UVM_LOW)

        // Setup
        enable_fifo();
        set_threshold(5);
        clear_fifo();
        expected_count = 0;

        // Pattern: Write 3, Read 1, Write 2, Read 2, etc.
        `uvm_info(get_type_name(), "--- Write 3 items ---", UVM_LOW)
        write_fifo_items(3, 8'h10);
        expected_count += 3;
        read_status(empty, full, almost_full, count);
        check_count(expected_count, count);

        `uvm_info(get_type_name(), "--- Read 1 item ---", UVM_LOW)
        read_fifo_items(1);
        expected_count -= 1;
        read_status(empty, full, almost_full, count);
        check_count(expected_count, count);

        `uvm_info(get_type_name(), "--- Write 4 items ---", UVM_LOW)
        write_fifo_items(4, 8'h20);
        expected_count += 4;
        read_status(empty, full, almost_full, count);
        check_count(expected_count, count);
        
        // Check almost_full (count=6 >= thresh=5)
        if (!almost_full) begin
            `uvm_error(get_type_name(), "ALMOST_FULL should be set")
        end

        `uvm_info(get_type_name(), "--- Read 3 items ---", UVM_LOW)
        read_fifo_items(3);
        expected_count -= 3;
        read_status(empty, full, almost_full, count);
        check_count(expected_count, count);

        // Check almost_full cleared (count=3 < thresh=5)
        if (almost_full) begin
            `uvm_error(get_type_name(), "ALMOST_FULL should be cleared")
        end

        // Drain FIFO
        `uvm_info(get_type_name(), "--- Drain remaining items ---", UVM_LOW)
        read_fifo_items(expected_count);
        expected_count = 0;
        read_status(empty, full, almost_full, count);
        check_count(expected_count, count);

        if (!empty) begin
            `uvm_error(get_type_name(), "FIFO should be empty")
        end

        `uvm_info(get_type_name(), "=== Write-Read Interleaved Sequence Complete ===", UVM_LOW)
    endtask

    function void check_count(int expected, int actual);
        if (expected != actual) begin
            `uvm_error(get_type_name(), $sformatf("Count mismatch: expected %0d, got %0d", expected, actual))
        end else begin
            `uvm_info(get_type_name(), $sformatf("Count verified: %0d", actual), UVM_MEDIUM)
        end
    endfunction

endclass

`endif

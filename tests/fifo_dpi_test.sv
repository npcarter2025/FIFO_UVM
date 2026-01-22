//-----------------------------------------------------------------------------
// File: fifo_dpi_test.sv
// Description: UVM tests demonstrating DPI-C integration
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// DPI-C Test Base Class
//-----------------------------------------------------------------------------

class fifo_dpi_base_test extends fifo_virtual_base_test;

    `uvm_component_utils(fifo_dpi_base_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        // Override scoreboard factory to use DPI version
        fifo_scoreboard::type_id::set_type_override(
            fifo_dpi_scoreboard::type_id::get());
        
        super.build_phase(phase);
        
        `uvm_info(get_type_name(), "Using DPI-C scoreboard with C reference model", UVM_LOW)
    endfunction

endclass

//-----------------------------------------------------------------------------
// DPI-C Basic Test
// Runs standard sequences with DPI-C scoreboard
//-----------------------------------------------------------------------------

class fifo_dpi_basic_test extends fifo_dpi_base_test;

    `uvm_component_utils(fifo_dpi_basic_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        fifo_config_then_write_sequence seq;
        
        `uvm_info(get_type_name(), "=== Running DPI-C Basic Test ===", UVM_LOW)
        `uvm_info(get_type_name(), "Testing FIFO operations with C reference model", UVM_LOW)
        
        seq = fifo_config_then_write_sequence::type_id::create("seq");
        seq.threshold = 8;
        seq.num_writes = 12;
        seq.start(env.v_sqr);
        
        // Report C model state
        `uvm_info(get_type_name(), $sformatf("C Model final count: %0d", c_fifo_count()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("C Model is_empty: %0d", c_fifo_is_empty()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("C Model is_full: %0d", c_fifo_is_full()), UVM_LOW)
    endtask

endclass

//-----------------------------------------------------------------------------
// DPI-C Pattern Test
// Tests C utility functions for pattern generation
//-----------------------------------------------------------------------------

class fifo_dpi_pattern_test extends fifo_dpi_base_test;

    `uvm_component_utils(fifo_dpi_pattern_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        byte pattern[16];
        byte checksum;
        
        `uvm_info(get_type_name(), "=== Running DPI-C Pattern Test ===", UVM_LOW)
        
        // Initialize random seed
        c_seed_random(42);  // Fixed seed for reproducibility
        
        // Test incrementing pattern
        c_generate_incrementing(pattern, 16, 8'hA0);
        `uvm_info(get_type_name(), "Incrementing pattern from 0xA0:", UVM_LOW)
        for (int i = 0; i < 16; i++) begin
            `uvm_info(get_type_name(), $sformatf("  [%0d] = 0x%02h", i, pattern[i]), UVM_MEDIUM)
        end
        checksum = c_calculate_checksum(pattern, 16);
        `uvm_info(get_type_name(), $sformatf("  Checksum: 0x%02h", checksum), UVM_LOW)
        
        // Test walking ones pattern
        c_generate_walking_ones(pattern, 8);
        `uvm_info(get_type_name(), "Walking ones pattern:", UVM_LOW)
        for (int i = 0; i < 8; i++) begin
            `uvm_info(get_type_name(), $sformatf("  [%0d] = 0x%02h", i, pattern[i]), UVM_MEDIUM)
        end
        
        // Test alternating pattern
        c_generate_alternating(pattern, 8);
        `uvm_info(get_type_name(), "Alternating pattern:", UVM_LOW)
        for (int i = 0; i < 8; i++) begin
            `uvm_info(get_type_name(), $sformatf("  [%0d] = 0x%02h", i, pattern[i]), UVM_MEDIUM)
        end
        
        // Test random bytes
        `uvm_info(get_type_name(), "Random bytes:", UVM_LOW)
        for (int i = 0; i < 5; i++) begin
            `uvm_info(get_type_name(), $sformatf("  Random[%0d] = 0x%02h", i, c_random_byte()), UVM_LOW)
        end
        
        // Test random range
        `uvm_info(get_type_name(), "Random range [10, 20]:", UVM_LOW)
        for (int i = 0; i < 5; i++) begin
            `uvm_info(get_type_name(), $sformatf("  Random[%0d] = %0d", i, c_random_range(10, 20)), UVM_LOW)
        end
        
        `uvm_info(get_type_name(), "=== DPI-C Pattern Test Complete ===", UVM_LOW)
    endtask

endclass

//-----------------------------------------------------------------------------
// DPI-C Full Test
// Comprehensive test of all DPI-C functionality
//-----------------------------------------------------------------------------

class fifo_dpi_full_test extends fifo_dpi_base_test;

    `uvm_component_utils(fifo_dpi_full_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        fifo_config_then_write_sequence     config_seq;
        fifo_write_read_interleaved_sequence interleaved_seq;
        
        `uvm_info(get_type_name(), "=== Running DPI-C Full Test ===", UVM_LOW)
        
        // Initialize C model explicitly (redundant but demonstrates API)
        c_fifo_init(16);
        `uvm_info(get_type_name(), "C Model initialized", UVM_LOW)
        
        // Test 1: Config and write
        `uvm_info(get_type_name(), "--- Test 1: Config-Then-Write with C Model ---", UVM_LOW)
        config_seq = fifo_config_then_write_sequence::type_id::create("config_seq");
        config_seq.threshold = 6;
        config_seq.num_writes = 10;
        config_seq.start(env.v_sqr);
        
        // Check C model state
        `uvm_info(get_type_name(), $sformatf("After config_seq: C count=%0d, almost_full(6)=%0d", 
                  c_fifo_count(), c_fifo_almost_full(6)), UVM_LOW)
        
        #100ns;
        
        // Test 2: Interleaved operations
        `uvm_info(get_type_name(), "--- Test 2: Interleaved Operations with C Model ---", UVM_LOW)
        interleaved_seq = fifo_write_read_interleaved_sequence::type_id::create("interleaved_seq");
        interleaved_seq.start(env.v_sqr);
        
        // Final C model state
        `uvm_info(get_type_name(), "--- Final C Model State ---", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Count: %0d", c_fifo_count()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Empty: %0d", c_fifo_is_empty()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Full:  %0d", c_fifo_is_full()), UVM_LOW)
        
        // Peek at remaining contents
        if (c_fifo_count() > 0) begin
            `uvm_info(get_type_name(), "  Contents:", UVM_LOW)
            for (int i = 0; i < c_fifo_count(); i++) begin
                `uvm_info(get_type_name(), $sformatf("    [%0d] = 0x%02h", i, c_fifo_peek(i)), UVM_LOW)
            end
        end
        
        `uvm_info(get_type_name(), "=== DPI-C Full Test Complete ===", UVM_LOW)
    endtask

endclass

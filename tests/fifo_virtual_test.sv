//-----------------------------------------------------------------------------
// File: fifo_virtual_test.sv
// Description: UVM tests that run virtual sequences for multi-agent coordination
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Base virtual sequence test
//-----------------------------------------------------------------------------

class fifo_virtual_base_test extends uvm_test;

    `uvm_component_utils(fifo_virtual_base_test)

    fifo_ral_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_ral_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting virtual sequence test...", UVM_LOW)
        
        // Wait for reset
        #100ns;
        
        // Run the test-specific sequence
        run_test_sequence();
        
        #200ns;
        phase.drop_objection(this);
    endtask

    // Override in derived tests
    virtual task run_test_sequence();
        `uvm_info(get_type_name(), "Base test - no sequence", UVM_LOW)
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr;
        super.report_phase(phase);
        
        svr = uvm_report_server::get_server();
        
        if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0) begin
            `uvm_info(get_type_name(), "*** TEST FAILED ***", UVM_NONE)
        end else begin
            `uvm_info(get_type_name(), "*** TEST PASSED ***", UVM_NONE)
        end
    endfunction

endclass

//-----------------------------------------------------------------------------
// Config-Then-Write Test
// Demonstrates: Sequential register config followed by data traffic
//-----------------------------------------------------------------------------

class fifo_config_write_test extends fifo_virtual_base_test;

    `uvm_component_utils(fifo_config_write_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        fifo_config_then_write_sequence seq;
        
        `uvm_info(get_type_name(), "Running config-then-write sequence", UVM_LOW)
        
        seq = fifo_config_then_write_sequence::type_id::create("seq");
        seq.threshold = 6;
        seq.num_writes = 8;
        seq.start(env.v_sqr);
    endtask

endclass

//-----------------------------------------------------------------------------
// Parallel Traffic Test
// Demonstrates: Concurrent register and data traffic using fork/join
//-----------------------------------------------------------------------------

class fifo_parallel_traffic_test extends fifo_virtual_base_test;

    `uvm_component_utils(fifo_parallel_traffic_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        fifo_parallel_traffic_sequence seq;
        
        `uvm_info(get_type_name(), "Running parallel traffic sequence", UVM_LOW)
        
        seq = fifo_parallel_traffic_sequence::type_id::create("seq");
        seq.start(env.v_sqr);
    endtask

endclass

//-----------------------------------------------------------------------------
// Threshold Sweep Test
// Demonstrates: Parameterized testing with different configurations
//-----------------------------------------------------------------------------

class fifo_threshold_sweep_test extends fifo_virtual_base_test;

    `uvm_component_utils(fifo_threshold_sweep_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        fifo_threshold_sweep_sequence seq;
        
        `uvm_info(get_type_name(), "Running threshold sweep sequence", UVM_LOW)
        
        seq = fifo_threshold_sweep_sequence::type_id::create("seq");
        seq.start(env.v_sqr);
    endtask

endclass

//-----------------------------------------------------------------------------
// Write-Read Interleaved Test
// Demonstrates: Interleaved data operations with status monitoring
//-----------------------------------------------------------------------------

class fifo_interleaved_test extends fifo_virtual_base_test;

    `uvm_component_utils(fifo_interleaved_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        fifo_write_read_interleaved_sequence seq;
        
        `uvm_info(get_type_name(), "Running write-read interleaved sequence", UVM_LOW)
        
        seq = fifo_write_read_interleaved_sequence::type_id::create("seq");
        seq.start(env.v_sqr);
    endtask

endclass

//-----------------------------------------------------------------------------
// Full Virtual Sequence Test
// Runs all virtual sequences in succession
//-----------------------------------------------------------------------------

class fifo_full_virtual_test extends fifo_virtual_base_test;

    `uvm_component_utils(fifo_full_virtual_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        fifo_config_then_write_sequence     config_seq;
        fifo_parallel_traffic_sequence      parallel_seq;
        fifo_write_read_interleaved_sequence interleaved_seq;
        
        `uvm_info(get_type_name(), "=== Running Full Virtual Test Suite ===", UVM_LOW)

        // Test 1: Config then write
        `uvm_info(get_type_name(), "--- Test 1: Config-Then-Write ---", UVM_LOW)
        config_seq = fifo_config_then_write_sequence::type_id::create("config_seq");
        config_seq.threshold = 5;
        config_seq.num_writes = 7;
        config_seq.start(env.v_sqr);

        #100ns;

        // Test 2: Parallel traffic
        `uvm_info(get_type_name(), "--- Test 2: Parallel Traffic ---", UVM_LOW)
        parallel_seq = fifo_parallel_traffic_sequence::type_id::create("parallel_seq");
        parallel_seq.start(env.v_sqr);

        #100ns;

        // Test 3: Interleaved write/read
        `uvm_info(get_type_name(), "--- Test 3: Interleaved Operations ---", UVM_LOW)
        interleaved_seq = fifo_write_read_interleaved_sequence::type_id::create("interleaved_seq");
        interleaved_seq.start(env.v_sqr);

        `uvm_info(get_type_name(), "=== Full Virtual Test Suite Complete ===", UVM_LOW)
    endtask

endclass

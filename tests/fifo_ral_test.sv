//-----------------------------------------------------------------------------
// File: fifo_ral_test.sv
// Description: UVM tests using RAL for register access
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Base RAL test class
//-----------------------------------------------------------------------------

class fifo_ral_base_test extends uvm_test;

    `uvm_component_utils(fifo_ral_base_test)

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
        `uvm_info(get_type_name(), "Starting RAL test...", UVM_LOW)
        
        // Wait for reset
        #100ns;
        
        // Run the test-specific sequence
        run_test_sequence();
        
        #100ns;
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
// RAL Sanity Test
//-----------------------------------------------------------------------------

class fifo_ral_sanity_test extends fifo_ral_base_test;

    `uvm_component_utils(fifo_ral_sanity_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        fifo_ral_sanity_sequence seq;
        
        `uvm_info(get_type_name(), "Running RAL sanity sequence", UVM_LOW)
        
        seq = fifo_ral_sanity_sequence::type_id::create("seq");
        seq.reg_block = env.reg_block;
        seq.start(null);  // RAL sequences don't need a sequencer
    endtask

endclass

//-----------------------------------------------------------------------------
// RAL Reset Test (uses built-in uvm_reg_hw_reset_seq)
//-----------------------------------------------------------------------------

class fifo_ral_reset_test extends fifo_ral_base_test;

    `uvm_component_utils(fifo_ral_reset_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        fifo_ral_reset_sequence seq;
        
        `uvm_info(get_type_name(), "Running RAL reset sequence", UVM_LOW)
        
        seq = fifo_ral_reset_sequence::type_id::create("seq");
        seq.reg_block = env.reg_block;
        seq.start(null);
    endtask

endclass

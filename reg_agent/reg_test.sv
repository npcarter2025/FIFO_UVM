//-----------------------------------------------------------------------------
// File: reg_test.sv
// Description: UVM test for register agent verification
//-----------------------------------------------------------------------------

class reg_env extends uvm_env;

    `uvm_component_utils(reg_env)

    reg_agent   reg_agt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        reg_agt = reg_agent::type_id::create("reg_agt", this);
    endfunction

endclass

//-----------------------------------------------------------------------------
// Base test class
//-----------------------------------------------------------------------------

class reg_base_test extends uvm_test;

    `uvm_component_utils(reg_base_test)

    reg_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = reg_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting test...", UVM_LOW)
        
        // Let reset complete
        #100ns;
        
        run_test_sequence();
        
        #100ns;
        phase.drop_objection(this);
    endtask

    virtual task run_test_sequence();
        // Override in derived tests
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
// Sanity test - verifies register agent can read/write registers
//-----------------------------------------------------------------------------

class reg_sanity_test extends reg_base_test;

    `uvm_component_utils(reg_sanity_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_sequence();
        reg_sanity_sequence seq;
        seq = reg_sanity_sequence::type_id::create("seq");
        seq.start(env.reg_agt.sqr);
    endtask

endclass

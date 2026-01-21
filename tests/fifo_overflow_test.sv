`ifndef FIFO_OVERFLOW_TEST_SV
`define FIFO_OVERFLOW_TEST_SV

class fifo_overflow_test extends uvm_test;
    `uvm_component_utils(fifo_overflow_test)

    fifo_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        fifo_overflow_sequence seq;
        seq = fifo_overflow_sequence::type_id::create("seq");

        phase.raise_objection(this);

        seq.start(env.agt.sqr);

        phase.drop_objection(this);


    endtask


endclass

`endif


`ifndef FIFO_BASE_SEQUENCE_SVH
`define FIFO_BASE_SEQUENCE_SVH

class fifo_base_sequence extends uvm_sequence #(fifo_item);
    `uvm_object_utils(fifo_base_sequence)

    function new(string name = "fifo_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("SEQ", "Starting Sequence: Write 10, then Read 10", UVM_LOW)

        repeat(10) begin
            req = fifo_item::type_id::create("req");
            start_item(req);

            if(!req.randomize() with {op == 1;})
                `uvm_fatal("SEQ", "Randomization failed")
            finish_item(req);
        end

        repeat(10) begin
            req = fifo_item::type_id::create("req");
            start_item(req);

            if(!req.randomize() with {op == 0;})
                `uvm_fatal("SEQ", "Randomization failed")
            finish_item(req);
        end

    endtask
endclass

`endif 
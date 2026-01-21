`ifndef FIFO_OVERFLOW_SEQUENCE_SVH
`define FIFO_OVERFLOW_SEQUENCE_SVH

class fifo_overflow_sequence extends uvm_sequence #(fifo_item);
    `uvm_object_utils(fifo_overflow_sequence)

    function new(string name = "fifo_overflow_sequence");
        super.new(name);
    endfunction

    virtual task body();

        `uvm_info("SEQ", "Stressing the FIFO with 20 writes", UVM_LOW)

        repeat(20) begin

            req = fifo_item::type_id::create("req");
            start_item(req);

            if(!req.randomize() with {op == 1; w_data inside {[100:200]};}) begin
                `uvm_fatal("SEQ", "randomization failed")
            end
            finish_item(req);

            `uvm_info("SEQ", $sformatf("Sent Write: data=%0b", req.w_data), UVM_HIGH)

        end

        `uvm_info("SEQ", "Overflow sequence finished", UVM_LOW)


    endtask


endclass

`endif

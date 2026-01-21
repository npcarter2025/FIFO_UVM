`ifndef FIFO_COVERAGE_SVH
`define FIFO_COVERAGE_SVH

class fifo_coverage extends uvm_subscriber #(fifo_item);

    `uvm_component_utils(fifo_coverage)

    fifo_item item;

    covergroup fifo_cvg;
        option.per_instance = 1;
        option.name = "fifo_coverage_group";

        cp_op: coverpoint item.op {
            bins write = {1};
            bins read = {0};

        }

        cp_data: coverpoint item.w_data {
            bins low = {[0:127]};
            bins high = {[128:255]};
        }

        cross_op_data: cross cp_op, cp_data;

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        fifo_cvg = new();
    endfunction
    virtual function void write(fifo_item t);
        this.item = t;
        fifo_cvg.sample();
    endfunction


endclass

`endif
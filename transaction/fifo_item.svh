`ifndef FIFO_ITEM
`define FIFO_ITEM

class fifo_item extends uvm_sequence_item;

    rand bit [7:0] w_data;
    rand bit        op;

    bit [7:0]   r_data;
    bit         full;
    bit         empty;

    `uvm_object_utils_begin(fifo_item)
        `uvm_field_int(w_data, UVM_ALL_ON)
        `uvm_field_int(op,     UVM_ALL_ON)
        `uvm_field_int(r_data, UVM_ALL_ON)
    `uvm_object_utils_end


    function new(string name = "fifo_item");
        super.new(name);
    endfunction

    constraint data_c {w_data inside {[0:255]}; }


endclass

`endif 

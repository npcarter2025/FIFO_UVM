

class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)

    uvm_analysis_imp #(fifo_item, fifo_scoreboard) item_collected_export;

    bit [7:0] queue_model [$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void write(fifo_item item);
        if(item.op == 1) begin
            queue_model.push_back(item.w_data);
            `uvm_info("SCB", $sformatf("Stored: %0b", item.w_data), UVM_LOW)
        end
        else begin
            if (queue_model.size() > 0) begin
                bit [7:0] expected = queue_model.pop_front();
                if (item.r_data == expected)
                    `uvm_info("SCB", $sformatf("PASS! Read %0h", item.r_data), UVM_LOW)
                else
                    `uvm_error("SCB", $sformatf("FAIL! Expected: %0h, Got: %0h", expected, item.r_data))
            end
        end
    endfunction

endclass

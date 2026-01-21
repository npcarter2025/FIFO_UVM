

class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)

    virtual fifo_if vif;

    uvm_analysis_port #(fifo_item) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Could not get vif")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.sel) begin

                fifo_item item = fifo_item::type_id::create("item");

                if (vif.mon_cb.w_enable && vif.mon_cb.w_ready) begin
                    item.op     = 1;
                    item.w_data = vif.mon_cb.w_data;
                    item_collected_port.write(item);
                end

                if (vif.mon_cb.r_enable && vif.mon_cb.r_ready) begin
                    item.op     = 0;
                    item.r_data = vif.mon_cb.r_data;
                    item_collected_port.write(item);
                end
            end
        end
    endtask

endclass
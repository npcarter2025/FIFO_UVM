`ifndef REG_MONITOR_SVH
`define REG_MONITOR_SVH

//-----------------------------------------------------------------------------
// Class: reg_monitor
// Description: UVM monitor for register bus transactions
//-----------------------------------------------------------------------------

class reg_monitor extends uvm_monitor;

    `uvm_component_utils(reg_monitor)

    virtual reg_if vif;

    // Analysis port to broadcast observed transactions
    uvm_analysis_port #(reg_item) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual reg_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("REG_MON", "Could not get virtual interface from config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("REG_MON", "Monitor run_phase started", UVM_LOW)

        // Wait for reset to deassert
        @(vif.mon_cb);
        wait(vif.rst_n);
        @(vif.mon_cb);

        `uvm_info("REG_MON", "Reset complete, monitor active", UVM_LOW)

        forever begin
            @(vif.mon_cb);
            
            // Detect write transaction
            if (vif.mon_cb.wen && vif.mon_cb.ready) begin
                reg_item item = reg_item::type_id::create("item");
                item.rw    = 1;  // Write
                item.addr  = vif.mon_cb.addr;
                item.wdata = vif.mon_cb.wdata;
                item.ready = 1;

                `uvm_info("REG_MON", $sformatf("Observed WRITE: %s", item.convert2string()), UVM_MEDIUM)
                item_collected_port.write(item);
            end

            // Detect read transaction
            if (vif.mon_cb.ren && vif.mon_cb.ready) begin
                reg_item item = reg_item::type_id::create("item");
                item.rw    = 0;  // Read
                item.addr  = vif.mon_cb.addr;
                item.rdata = vif.mon_cb.rdata;
                item.ready = 1;

                `uvm_info("REG_MON", $sformatf("Observed READ: %s", item.convert2string()), UVM_MEDIUM)
                item_collected_port.write(item);
            end
        end
    endtask

endclass

`endif

`ifndef FIFO_DRIVER_SVH
`define FIFO_DRIVER_SVH

class fifo_driver extends uvm_driver #(fifo_item);

    `uvm_component_utils(fifo_driver)

    virtual fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV", "Could not get virtual interface from config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);

        `uvm_info("DRV", "Driver run_phase started, waiting for reset...", UVM_LOW)

        // Wait for reset to deassert
        @(vif.drv_cb);
        wait(!vif.rst);
        @(vif.drv_cb);

        `uvm_info("DRV", "Reset complete, driver ready", UVM_LOW)

        // Initialize signals
        vif.drv_cb.sel          <= 0;
        vif.drv_cb.w_enable     <= 0;
        vif.drv_cb.r_ready      <= 0;

        forever begin
            `uvm_info("DRV", "Waiting for next item...", UVM_HIGH)
            seq_item_port.get_next_item(req);
            `uvm_info("DRV", $sformatf("Got item: op=%0d, w_data=%0h", req.op, req.w_data), UVM_LOW)

            drive_item(req);

            seq_item_port.item_done();
            `uvm_info("DRV", "Item done", UVM_HIGH)
        end
    endtask

    task drive_item(fifo_item item);
        @(vif.drv_cb);
        vif.drv_cb.sel <= 1'b1;

        if (item.op == 1) begin : WRITE_OP
            `uvm_info("DRV", $sformatf("WRITE: data=%0h", item.w_data), UVM_LOW)
            
            // Wait for FIFO to be ready to accept write
            while(!vif.drv_cb.w_ready) @(vif.drv_cb);
            
            // Drive write signals
            vif.drv_cb.is_write <= 1'b1;
            vif.drv_cb.w_enable <= 1'b1;
            vif.drv_cb.w_data   <= item.w_data;
            
            // Wait one cycle for the write to register
            @(vif.drv_cb);
            
            // Deassert write enable
            vif.drv_cb.w_enable <= 1'b0;
            `uvm_info("DRV", "WRITE complete", UVM_LOW)
        end
        else begin : READ_OP
            `uvm_info("DRV", "READ starting", UVM_LOW)
            
            // Wait for FIFO to have data
            while(!vif.drv_cb.r_enable) @(vif.drv_cb);
            
            // Signal ready to receive
            vif.drv_cb.is_write <= 1'b0;
            vif.drv_cb.r_ready  <= 1'b1;
            
            // Wait one cycle for the read to complete
            @(vif.drv_cb);
            
            // Capture the data
            item.r_data = vif.drv_cb.r_data;
            `uvm_info("DRV", $sformatf("READ complete: data=%0h", item.r_data), UVM_LOW)

            vif.drv_cb.r_ready <= 1'b0;
        end

        vif.drv_cb.sel <= 1'b0;
    endtask

endclass

`endif

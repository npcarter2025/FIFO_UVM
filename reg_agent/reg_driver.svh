`ifndef REG_DRIVER_SVH
`define REG_DRIVER_SVH

//-----------------------------------------------------------------------------
// Class: reg_driver
// Description: UVM driver for register bus transactions
//-----------------------------------------------------------------------------

class reg_driver extends uvm_driver #(reg_item);

    `uvm_component_utils(reg_driver)

    virtual reg_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual reg_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("REG_DRV", "Could not get virtual interface from config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("REG_DRV", "Driver run_phase started, waiting for reset...", UVM_LOW)

        // Wait for reset to deassert
        @(vif.drv_cb);
        wait(vif.rst_n);
        @(vif.drv_cb);

        `uvm_info("REG_DRV", "Reset complete, driver ready", UVM_LOW)

        // Initialize signals
        vif.drv_cb.addr  <= '0;
        vif.drv_cb.wdata <= '0;
        vif.drv_cb.wen   <= 1'b0;
        vif.drv_cb.ren   <= 1'b0;

        forever begin
            `uvm_info("REG_DRV", "Waiting for next item...", UVM_HIGH)
            seq_item_port.get_next_item(req);
            `uvm_info("REG_DRV", $sformatf("Got item: %s", req.convert2string()), UVM_MEDIUM)

            drive_item(req);

            seq_item_port.item_done();
            `uvm_info("REG_DRV", "Item done", UVM_HIGH)
        end
    endtask

    //-------------------------------------------------------------------------
    // Drive a single register transaction
    //-------------------------------------------------------------------------
    task drive_item(reg_item item);
        @(vif.drv_cb);

        if (item.is_write()) begin
            // Register Write
            `uvm_info("REG_DRV", $sformatf("WRITE: addr=0x%02h data=0x%08h", 
                      item.addr, item.wdata), UVM_MEDIUM)

            vif.drv_cb.addr  <= item.addr;
            vif.drv_cb.wdata <= item.wdata;
            vif.drv_cb.wen   <= 1'b1;
            vif.drv_cb.ren   <= 1'b0;

            @(vif.drv_cb);

            // Wait for ready (single cycle for this simple bus)
            while (!vif.drv_cb.ready) @(vif.drv_cb);

            // Deassert write enable
            vif.drv_cb.wen <= 1'b0;

            `uvm_info("REG_DRV", "WRITE complete", UVM_MEDIUM)
        end
        else begin
            // Register Read
            `uvm_info("REG_DRV", $sformatf("READ: addr=0x%02h", item.addr), UVM_MEDIUM)

            vif.drv_cb.addr <= item.addr;
            vif.drv_cb.wen  <= 1'b0;
            vif.drv_cb.ren  <= 1'b1;

            @(vif.drv_cb);

            // Wait for ready
            while (!vif.drv_cb.ready) @(vif.drv_cb);

            // Capture read data
            item.rdata = vif.drv_cb.rdata;

            // Deassert read enable
            vif.drv_cb.ren <= 1'b0;

            `uvm_info("REG_DRV", $sformatf("READ complete: data=0x%08h", item.rdata), UVM_MEDIUM)
        end

        item.ready = 1'b1;
    endtask

endclass

`endif

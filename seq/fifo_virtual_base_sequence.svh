`ifndef FIFO_VIRTUAL_BASE_SEQUENCE_SVH
`define FIFO_VIRTUAL_BASE_SEQUENCE_SVH

//-----------------------------------------------------------------------------
// Class: fifo_virtual_base_sequence
// Description: Base class for virtual sequences that coordinate multiple agents
//              Uses `uvm_declare_p_sequencer to access virtual sequencer handles
//-----------------------------------------------------------------------------

class fifo_virtual_base_sequence extends uvm_sequence;

    `uvm_object_utils(fifo_virtual_base_sequence)

    // Declare p_sequencer as fifo_virtual_sequencer type
    `uvm_declare_p_sequencer(fifo_virtual_sequencer)

    function new(string name = "fifo_virtual_base_sequence");
        super.new(name);
    endfunction

    //-------------------------------------------------------------------------
    // Convenience handles - populated in body() pre_body()
    //-------------------------------------------------------------------------
    fifo_sequencer  fifo_sqr;
    reg_sequencer   reg_sqr;
    fifo_reg_block  reg_block;

    //-------------------------------------------------------------------------
    // Pre-body: Get handles from virtual sequencer
    //-------------------------------------------------------------------------
    virtual task pre_body();
        super.pre_body();
        
        // Get sequencer handles from p_sequencer
        fifo_sqr  = p_sequencer.fifo_sqr;
        reg_sqr   = p_sequencer.reg_sqr;
        reg_block = p_sequencer.reg_block;

        if (fifo_sqr == null)
            `uvm_fatal(get_type_name(), "fifo_sqr handle is null!")
        if (reg_sqr == null)
            `uvm_fatal(get_type_name(), "reg_sqr handle is null!")
        if (reg_block == null)
            `uvm_fatal(get_type_name(), "reg_block handle is null!")

        `uvm_info(get_type_name(), "Virtual sequence handles acquired", UVM_HIGH)
    endtask

    //-------------------------------------------------------------------------
    // Helper: Enable FIFO via RAL
    //-------------------------------------------------------------------------
    task enable_fifo();
        uvm_status_e status;
        `uvm_info(get_type_name(), "Enabling FIFO...", UVM_MEDIUM)
        reg_block.ctrl.enable.set(1);
        reg_block.ctrl.update(status);
        if (status != UVM_IS_OK)
            `uvm_error(get_type_name(), "Failed to enable FIFO")
    endtask

    //-------------------------------------------------------------------------
    // Helper: Set almost-full threshold via RAL
    //-------------------------------------------------------------------------
    task set_threshold(bit [7:0] thresh);
        uvm_status_e status;
        `uvm_info(get_type_name(), $sformatf("Setting threshold to %0d", thresh), UVM_MEDIUM)
        reg_block.thresh.thresh_val.set(thresh);
        reg_block.thresh.update(status);
        if (status != UVM_IS_OK)
            `uvm_error(get_type_name(), "Failed to set threshold")
    endtask

    //-------------------------------------------------------------------------
    // Helper: Clear FIFO via RAL
    //-------------------------------------------------------------------------
    task clear_fifo();
        uvm_status_e status;
        `uvm_info(get_type_name(), "Clearing FIFO...", UVM_MEDIUM)
        reg_block.ctrl.clear.set(1);
        reg_block.ctrl.update(status);
        if (status != UVM_IS_OK)
            `uvm_error(get_type_name(), "Failed to clear FIFO")
    endtask

    //-------------------------------------------------------------------------
    // Helper: Read and return STATUS register
    //-------------------------------------------------------------------------
    task read_status(output bit empty, output bit full, output bit almost_full, output bit [7:0] count);
        uvm_status_e status;
        uvm_reg_data_t rdata;
        
        reg_block.status.read(status, rdata);
        if (status != UVM_IS_OK)
            `uvm_error(get_type_name(), "Failed to read STATUS")
        
        empty       = reg_block.status.empty.get();
        full        = reg_block.status.full.get();
        almost_full = reg_block.status.almost_full.get();
        count       = reg_block.status.count.get();
        
        `uvm_info(get_type_name(), $sformatf("STATUS: empty=%0d, full=%0d, almost_full=%0d, count=%0d",
                  empty, full, almost_full, count), UVM_MEDIUM)
    endtask

    //-------------------------------------------------------------------------
    // Helper: Write N items to FIFO via data agent
    //-------------------------------------------------------------------------
    task write_fifo_items(int num_items, bit [7:0] start_data = 8'hA0);
        fifo_base_sequence fifo_seq;
        
        `uvm_info(get_type_name(), $sformatf("Writing %0d items to FIFO", num_items), UVM_MEDIUM)
        
        for (int i = 0; i < num_items; i++) begin
            fifo_item item = fifo_item::type_id::create("item");
            start_item(item, -1, fifo_sqr);
            item.op = 1;  // Write
            item.w_data = start_data + i;
            finish_item(item);
        end
    endtask

    //-------------------------------------------------------------------------
    // Helper: Read N items from FIFO via data agent
    //-------------------------------------------------------------------------
    task read_fifo_items(int num_items);
        `uvm_info(get_type_name(), $sformatf("Reading %0d items from FIFO", num_items), UVM_MEDIUM)
        
        for (int i = 0; i < num_items; i++) begin
            fifo_item item = fifo_item::type_id::create("item");
            start_item(item, -1, fifo_sqr);
            item.op = 0;  // Read
            finish_item(item);
            `uvm_info(get_type_name(), $sformatf("Read data[%0d] = 0x%02h", i, item.r_data), UVM_MEDIUM)
        end
    endtask

endclass

`endif

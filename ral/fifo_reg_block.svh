`ifndef FIFO_REG_BLOCK_SVH
`define FIFO_REG_BLOCK_SVH

//-----------------------------------------------------------------------------
// Class: fifo_reg_block
// Description: RAL register block containing all FIFO registers
//
// Register Map:
//   0x00 - CTRL   (RW)
//   0x04 - STATUS (RO)
//   0x08 - THRESH (RW)
//-----------------------------------------------------------------------------

class fifo_reg_block extends uvm_reg_block;

    `uvm_object_utils(fifo_reg_block)

    // Registers
    rand fifo_ctrl_reg   ctrl;
    rand fifo_status_reg status;
    rand fifo_thresh_reg thresh;

    // Address map
    uvm_reg_map reg_map;

    function new(string name = "fifo_reg_block");
        // 7.2: Enable all RAL coverage (field values, address hits, etc.)
        super.new(name, build_coverage(UVM_CVR_ALL));
    endfunction

    virtual function void build();
        // Create registers
        ctrl = fifo_ctrl_reg::type_id::create("ctrl");
        ctrl.configure(this, null, "");
        ctrl.build();

        status = fifo_status_reg::type_id::create("status");
        status.configure(this, null, "");
        status.build();

        thresh = fifo_thresh_reg::type_id::create("thresh");
        thresh.configure(this, null, "");
        thresh.build();

        // Create address map
        // Parameters: name, base_addr, n_bytes (bus width), endianness
        reg_map = create_map(
            .name("reg_map"),
            .base_addr(0),
            .n_bytes(4),              // 32-bit bus = 4 bytes
            .endian(UVM_LITTLE_ENDIAN)
        );

        // Add registers to map with their offsets
        reg_map.add_reg(ctrl,   'h00, "RW");
        reg_map.add_reg(status, 'h04, "RO");
        reg_map.add_reg(thresh, 'h08, "RW");

        // Lock the model - no more changes allowed
        lock_model();

        // 7.2: Enable coverage sampling if coverage was built
        if (has_coverage(UVM_CVR_ALL)) begin
            set_coverage(UVM_CVR_ALL);
        end
    endfunction

    //-------------------------------------------------------------------------
    // Convenience methods for common operations
    //-------------------------------------------------------------------------

    // Enable the FIFO
    task enable_fifo(uvm_status_e status);
        ctrl.enable.set(1);
        ctrl.update(status);
    endtask

    // Disable the FIFO
    task disable_fifo(uvm_status_e status);
        ctrl.enable.set(0);
        ctrl.update(status);
    endtask

    // Clear the FIFO
    task clear_fifo(uvm_status_e status);
        ctrl.clear.set(1);
        ctrl.update(status);
    endtask

    // Set almost-full threshold
    task set_threshold(uvm_status_e status, bit [7:0] val);
        thresh.thresh_val.set(val);
        thresh.update(status);
    endtask

    // Get current FIFO count
    task get_count(uvm_status_e status, output bit [7:0] val);
        this.status.read(status, val);
        val = this.status.count.get();
    endtask

    // Check if FIFO is empty
    task is_empty(uvm_status_e status, output bit val);
        uvm_reg_data_t rdata;
        this.status.read(status, rdata);
        val = this.status.empty.get();
    endtask

    // Check if FIFO is full
    task is_full(uvm_status_e status, output bit val);
        uvm_reg_data_t rdata;
        this.status.read(status, rdata);
        val = this.status.full.get();
    endtask

endclass

`endif

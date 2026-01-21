`ifndef FIFO_STATUS_REG_SVH
`define FIFO_STATUS_REG_SVH

//-----------------------------------------------------------------------------
// Class: fifo_status_reg
// Description: RAL model for STATUS register (offset 0x04)
//
// Fields:
//   [0]     EMPTY       - RO, FIFO is empty
//   [1]     FULL        - RO, FIFO is full
//   [2]     ALMOST_FULL - RO, count >= threshold
//   [3]     OVERFLOW    - W1C, overflow occurred
//   [4]     UNDERFLOW   - W1C, underflow occurred
//   [7:5]   Reserved1
//   [15:8]  COUNT       - RO, current entry count
//   [31:16] Reserved2
//-----------------------------------------------------------------------------

class fifo_status_reg extends uvm_reg;

    `uvm_object_utils(fifo_status_reg)

    // Register fields
    rand uvm_reg_field empty;
    rand uvm_reg_field full;
    rand uvm_reg_field almost_full;
    rand uvm_reg_field overflow;
    rand uvm_reg_field underflow;
    rand uvm_reg_field reserved1;
    rand uvm_reg_field count;
    rand uvm_reg_field reserved2;

    function new(string name = "fifo_status_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // EMPTY field - bit 0
        empty = uvm_reg_field::type_id::create("empty");
        empty.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RO"),
            .volatile(1),  // Changes based on FIFO state
            .reset(1),     // FIFO starts empty
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );

        // FULL field - bit 1
        full = uvm_reg_field::type_id::create("full");
        full.configure(
            .parent(this),
            .size(1),
            .lsb_pos(1),
            .access("RO"),
            .volatile(1),
            .reset(0),
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );

        // ALMOST_FULL field - bit 2
        almost_full = uvm_reg_field::type_id::create("almost_full");
        almost_full.configure(
            .parent(this),
            .size(1),
            .lsb_pos(2),
            .access("RO"),
            .volatile(1),
            .reset(0),
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );

        // OVERFLOW field - bit 3 (W1C - write 1 to clear)
        overflow = uvm_reg_field::type_id::create("overflow");
        overflow.configure(
            .parent(this),
            .size(1),
            .lsb_pos(3),
            .access("W1C"),
            .volatile(1),  // Can be set by hardware
            .reset(0),
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );

        // UNDERFLOW field - bit 4 (W1C - write 1 to clear)
        underflow = uvm_reg_field::type_id::create("underflow");
        underflow.configure(
            .parent(this),
            .size(1),
            .lsb_pos(4),
            .access("W1C"),
            .volatile(1),
            .reset(0),
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );

        // Reserved1 field - bits 7:5
        reserved1 = uvm_reg_field::type_id::create("reserved1");
        reserved1.configure(
            .parent(this),
            .size(3),
            .lsb_pos(5),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );

        // COUNT field - bits 15:8
        count = uvm_reg_field::type_id::create("count");
        count.configure(
            .parent(this),
            .size(8),
            .lsb_pos(8),
            .access("RO"),
            .volatile(1),  // Changes based on FIFO state
            .reset(0),
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );

        // Reserved2 field - bits 31:16
        reserved2 = uvm_reg_field::type_id::create("reserved2");
        reserved2.configure(
            .parent(this),
            .size(16),
            .lsb_pos(16),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );
    endfunction

endclass

`endif

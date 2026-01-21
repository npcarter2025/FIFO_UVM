`ifndef FIFO_CTRL_REG_SVH
`define FIFO_CTRL_REG_SVH

//-----------------------------------------------------------------------------
// Class: fifo_ctrl_reg
// Description: RAL model for CTRL register (offset 0x00)
//
// Fields:
//   [0]    ENABLE  - RW, FIFO enable
//   [1]    CLEAR   - W1S (self-clearing), FIFO clear
//   [31:2] Reserved
//-----------------------------------------------------------------------------

class fifo_ctrl_reg extends uvm_reg;

    `uvm_object_utils(fifo_ctrl_reg)

    // Register fields
    rand uvm_reg_field enable;
    rand uvm_reg_field clear;
    rand uvm_reg_field reserved;

    function new(string name = "fifo_ctrl_reg");
        // 32-bit register, no coverage
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // ENABLE field - bit 0
        enable = uvm_reg_field::type_id::create("enable");
        enable.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RW"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        // CLEAR field - bit 1 (self-clearing, modeled as W1S)
        // Note: In hardware, writing 1 clears FIFO and bit auto-clears
        // We model it as W1S so reads always return 0
        clear = uvm_reg_field::type_id::create("clear");
        clear.configure(
            .parent(this),
            .size(1),
            .lsb_pos(1),
            .access("W1S"),
            .volatile(1),  // Volatile because it self-clears
            .reset(0),
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        // Reserved field - bits 31:2
        reserved = uvm_reg_field::type_id::create("reserved");
        reserved.configure(
            .parent(this),
            .size(30),
            .lsb_pos(2),
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

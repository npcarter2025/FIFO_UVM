`ifndef FIFO_THRESH_REG_SVH
`define FIFO_THRESH_REG_SVH

//-----------------------------------------------------------------------------
// Class: fifo_thresh_reg
// Description: RAL model for THRESH register (offset 0x08)
//
// Fields:
//   [4:0]   THRESH_VAL - RW, almost-full threshold value (5 bits for DEPTH=16)
//   [31:5]  Reserved
//
// Note: Hardware implements $clog2(DEPTH)+1 bits = 5 bits for DEPTH=16
//-----------------------------------------------------------------------------

class fifo_thresh_reg extends uvm_reg;

    `uvm_object_utils(fifo_thresh_reg)

    // Register fields
    rand uvm_reg_field thresh_val;
    rand uvm_reg_field reserved;

    // Default threshold (DEPTH-1 = 15 for DEPTH=16)
    local int unsigned default_thresh = 15;

    // Threshold field size: $clog2(DEPTH)+1 = 5 for DEPTH=16
    local int unsigned thresh_size = 5;

    function new(string name = "fifo_thresh_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    // Allow setting default threshold based on FIFO depth
    function void set_default_thresh(int unsigned val);
        default_thresh = val;
    endfunction

    virtual function void build();
        // THRESH_VAL field - bits 4:0 (5 bits for DEPTH=16)
        // Matches hardware: logic [$clog2(DEPTH):0] reg_thresh
        thresh_val = uvm_reg_field::type_id::create("thresh_val");
        thresh_val.configure(
            .parent(this),
            .size(thresh_size),
            .lsb_pos(0),
            .access("RW"),
            .volatile(0),
            .reset(default_thresh),
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        // Reserved field - bits 31:5
        reserved = uvm_reg_field::type_id::create("reserved");
        reserved.configure(
            .parent(this),
            .size(32 - thresh_size),
            .lsb_pos(thresh_size),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );
    endfunction

    // Constraint for valid threshold values (0 to DEPTH=16)
    constraint thresh_valid_c {
        thresh_val.value inside {[1:16]};
    }

endclass

`endif

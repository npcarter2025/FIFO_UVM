`ifndef REG_ITEM_SVH
`define REG_ITEM_SVH

//-----------------------------------------------------------------------------
// Class: reg_item
// Description: Transaction class for register read/write operations
//-----------------------------------------------------------------------------

class reg_item extends uvm_sequence_item;

    // Transaction type: 1 = write, 0 = read
    rand bit        rw;         // 1 = write, 0 = read
    rand bit [7:0]  addr;       // Register address
    rand bit [31:0] wdata;      // Write data

    // Response fields (filled by driver/monitor)
    bit [31:0]      rdata;      // Read data
    bit             ready;      // Transaction completed

    `uvm_object_utils_begin(reg_item)
        `uvm_field_int(rw,    UVM_ALL_ON)
        `uvm_field_int(addr,  UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(ready, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "reg_item");
        super.new(name);
    endfunction

    // Constraints
    constraint addr_align_c {
        addr[1:0] == 2'b00;  // Word-aligned addresses
    }

    constraint valid_addr_c {
        addr inside {8'h00, 8'h04, 8'h08};  // CTRL, STATUS, THRESH
    }

    // Helper functions for readability
    function bit is_write();
        return rw == 1;
    endfunction

    function bit is_read();
        return rw == 0;
    endfunction

    function string convert2string();
        return $sformatf("%s addr=0x%02h wdata=0x%08h rdata=0x%08h",
                         rw ? "WRITE" : "READ", addr, wdata, rdata);
    endfunction

endclass

`endif

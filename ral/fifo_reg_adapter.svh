`ifndef FIFO_REG_ADAPTER_SVH
`define FIFO_REG_ADAPTER_SVH

//-----------------------------------------------------------------------------
// Class: fifo_reg_adapter
// Description: Converts between RAL operations and reg_item transactions
//
// This adapter bridges the UVM RAL model to the register agent by:
//   - reg2bus: Converting uvm_reg_bus_op to reg_item for driving
//   - bus2reg: Converting reg_item responses back to uvm_reg_bus_op
//-----------------------------------------------------------------------------

class fifo_reg_adapter extends uvm_reg_adapter;

    `uvm_object_utils(fifo_reg_adapter)

    function new(string name = "fifo_reg_adapter");
        super.new(name);
        
        // Configure adapter behavior
        supports_byte_enable = 0;  // No byte enables on this bus
        provides_responses   = 1;  // Driver provides response items
    endfunction

    //-------------------------------------------------------------------------
    // reg2bus: Convert RAL operation to bus transaction
    //-------------------------------------------------------------------------
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        reg_item item = reg_item::type_id::create("item");

        // Map RAL operation to reg_item fields
        item.rw    = (rw.kind == UVM_WRITE) ? 1 : 0;
        item.addr  = rw.addr[7:0];
        item.wdata = rw.data;
        item.rdata = 0;
        item.ready = 0;

        `uvm_info("REG_ADAPTER", $sformatf("reg2bus: %s addr=0x%02h data=0x%08h",
                  (rw.kind == UVM_WRITE) ? "WRITE" : "READ", item.addr, item.wdata), UVM_HIGH)

        return item;
    endfunction

    //-------------------------------------------------------------------------
    // bus2reg: Convert bus response to RAL operation result
    //-------------------------------------------------------------------------
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        reg_item item;

        if (!$cast(item, bus_item)) begin
            `uvm_fatal("REG_ADAPTER", "Failed to cast bus_item to reg_item")
        end

        // Map reg_item response back to RAL
        rw.kind   = item.rw ? UVM_WRITE : UVM_READ;
        rw.addr   = item.addr;
        rw.data   = item.rw ? item.wdata : item.rdata;
        rw.status = item.ready ? UVM_IS_OK : UVM_NOT_OK;

        `uvm_info("REG_ADAPTER", $sformatf("bus2reg: %s addr=0x%02h data=0x%08h status=%s",
                  item.rw ? "WRITE" : "READ", rw.addr, rw.data,
                  rw.status == UVM_IS_OK ? "OK" : "NOT_OK"), UVM_HIGH)
    endfunction

endclass

`endif

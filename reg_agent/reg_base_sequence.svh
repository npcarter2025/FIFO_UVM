`ifndef REG_BASE_SEQUENCE_SVH
`define REG_BASE_SEQUENCE_SVH

//-----------------------------------------------------------------------------
// Class: reg_base_sequence
// Description: Base sequence for register operations
//-----------------------------------------------------------------------------

class reg_base_sequence extends uvm_sequence #(reg_item);

    `uvm_object_utils(reg_base_sequence)

    // Register addresses
    localparam ADDR_CTRL   = 8'h00;
    localparam ADDR_STATUS = 8'h04;
    localparam ADDR_THRESH = 8'h08;

    function new(string name = "reg_base_sequence");
        super.new(name);
    endfunction

    //-------------------------------------------------------------------------
    // Helper tasks for register operations
    //-------------------------------------------------------------------------

    // Write to a register
    task reg_write(bit [7:0] addr, bit [31:0] data);
        reg_item item = reg_item::type_id::create("item");
        start_item(item);
        item.rw    = 1;  // Write
        item.addr  = addr;
        item.wdata = data;
        finish_item(item);
        `uvm_info(get_type_name(), $sformatf("REG_WRITE: addr=0x%02h data=0x%08h", addr, data), UVM_MEDIUM)
    endtask

    // Read from a register
    task reg_read(bit [7:0] addr, output bit [31:0] data);
        reg_item item = reg_item::type_id::create("item");
        start_item(item);
        item.rw   = 0;  // Read
        item.addr = addr;
        finish_item(item);
        data = item.rdata;
        `uvm_info(get_type_name(), $sformatf("REG_READ: addr=0x%02h data=0x%08h", addr, data), UVM_MEDIUM)
    endtask

    // Write and verify
    task reg_write_check(bit [7:0] addr, bit [31:0] data, bit [31:0] mask = 32'hFFFFFFFF);
        bit [31:0] read_data;
        reg_write(addr, data);
        reg_read(addr, read_data);
        if ((read_data & mask) !== (data & mask)) begin
            `uvm_error(get_type_name(), $sformatf("Write-check failed at addr=0x%02h: wrote=0x%08h, read=0x%08h (mask=0x%08h)",
                       addr, data, read_data, mask))
        end else begin
            `uvm_info(get_type_name(), $sformatf("Write-check passed at addr=0x%02h", addr), UVM_MEDIUM)
        end
    endtask

endclass

//-----------------------------------------------------------------------------
// Class: reg_sanity_sequence
// Description: Simple sanity test sequence for register agent verification
//-----------------------------------------------------------------------------

class reg_sanity_sequence extends reg_base_sequence;

    `uvm_object_utils(reg_sanity_sequence)

    function new(string name = "reg_sanity_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] rdata;

        `uvm_info(get_type_name(), "Starting register sanity sequence", UVM_LOW)

        // Test 1: Read default values
        `uvm_info(get_type_name(), "=== Test 1: Read default values ===", UVM_LOW)
        reg_read(ADDR_CTRL, rdata);
        if (rdata !== 32'h0) `uvm_error(get_type_name(), $sformatf("CTRL default mismatch: got 0x%08h", rdata))
        
        reg_read(ADDR_STATUS, rdata);
        if (rdata[0] !== 1'b1) `uvm_error(get_type_name(), $sformatf("STATUS.EMPTY not set: got 0x%08h", rdata))
        
        reg_read(ADDR_THRESH, rdata);
        `uvm_info(get_type_name(), $sformatf("THRESH default = 0x%08h", rdata), UVM_LOW)

        // Test 2: Write and read back CTRL
        `uvm_info(get_type_name(), "=== Test 2: CTRL write/read ===", UVM_LOW)
        reg_write(ADDR_CTRL, 32'h00000001);  // Enable FIFO
        reg_read(ADDR_CTRL, rdata);
        if (rdata !== 32'h00000001) `uvm_error(get_type_name(), $sformatf("CTRL write-back failed: got 0x%08h", rdata))

        // Test 3: Write and read back THRESH
        `uvm_info(get_type_name(), "=== Test 3: THRESH write/read ===", UVM_LOW)
        reg_write(ADDR_THRESH, 32'h0000000A);  // Set threshold to 10
        reg_read(ADDR_THRESH, rdata);
        if (rdata[4:0] !== 5'hA) `uvm_error(get_type_name(), $sformatf("THRESH write-back failed: got 0x%08h", rdata))

        // Test 4: Read STATUS (should show empty)
        `uvm_info(get_type_name(), "=== Test 4: STATUS read ===", UVM_LOW)
        reg_read(ADDR_STATUS, rdata);
        `uvm_info(get_type_name(), $sformatf("STATUS = 0x%08h (empty=%b, full=%b)", rdata, rdata[0], rdata[1]), UVM_LOW)

        // Test 5: Clear FIFO via CTRL
        `uvm_info(get_type_name(), "=== Test 5: CTRL.CLEAR test ===", UVM_LOW)
        reg_write(ADDR_CTRL, 32'h00000003);  // Enable + Clear
        reg_read(ADDR_CTRL, rdata);
        if (rdata !== 32'h00000001) `uvm_error(get_type_name(), $sformatf("CTRL.CLEAR not self-clearing: got 0x%08h", rdata))

        `uvm_info(get_type_name(), "Register sanity sequence complete", UVM_LOW)
    endtask

endclass

`endif

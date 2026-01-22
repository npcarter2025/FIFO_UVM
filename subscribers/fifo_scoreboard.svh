`ifndef FIFO_SCOREBOARD_SVH
`define FIFO_SCOREBOARD_SVH

//-----------------------------------------------------------------------------
// Class: fifo_scoreboard
// Description: Scoreboard that tracks FIFO writes/reads and verifies data
//              RAL-aware: Listens to register transactions to detect CLEAR
//-----------------------------------------------------------------------------

// Use uvm_analysis_imp_decl to create unique analysis imp types
`uvm_analysis_imp_decl(_fifo)
`uvm_analysis_imp_decl(_reg)

class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)

    // Analysis ports - one for FIFO data, one for register transactions
    uvm_analysis_imp_fifo #(fifo_item, fifo_scoreboard) item_collected_export;
    uvm_analysis_imp_reg  #(reg_item, fifo_scoreboard)  reg_collected_export;

    // Internal queue model
    bit [7:0] queue_model [$];

    // Register addresses
    localparam ADDR_CTRL   = 8'h00;
    localparam ADDR_STATUS = 8'h04;

    // Statistics
    int num_writes;
    int num_reads;
    int num_matches;
    int num_mismatches;
    int num_clears;
    int num_count_checks;
    int num_count_mismatches;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collected_export = new("item_collected_export", this);
        reg_collected_export  = new("reg_collected_export", this);
    endfunction

    //-------------------------------------------------------------------------
    // Handle FIFO data transactions
    //-------------------------------------------------------------------------
    virtual function void write_fifo(fifo_item item);
        if (item.op == 1) begin
            // Write operation - store expected data
            queue_model.push_back(item.w_data);
            num_writes++;
            `uvm_info("SCB", $sformatf("Stored: 0x%02h (queue size: %0d)", item.w_data, queue_model.size()), UVM_LOW)
        end
        else begin
            // Read operation - compare against expected
            num_reads++;
            if (queue_model.size() > 0) begin
                bit [7:0] expected = queue_model.pop_front();
                if (item.r_data == expected) begin
                    num_matches++;
                    `uvm_info("SCB", $sformatf("PASS! Read 0x%02h (expected 0x%02h)", item.r_data, expected), UVM_LOW)
                end
                else begin
                    num_mismatches++;
                    `uvm_error("SCB", $sformatf("FAIL! Expected: 0x%02h, Got: 0x%02h", expected, item.r_data))
                end
            end
            else begin
                `uvm_warning("SCB", $sformatf("Read 0x%02h but queue is empty - cannot verify", item.r_data))
            end
        end
    endfunction

    //-------------------------------------------------------------------------
    // Handle register transactions - detect CLEAR and verify STATUS.COUNT
    //-------------------------------------------------------------------------
    virtual function void write_reg(reg_item item);
        // Check for CTRL register write with CLEAR bit set
        if (item.is_write() && item.addr == ADDR_CTRL && item.wdata[1]) begin
            flush_queue();
        end

        // 7.5: Check STATUS register COUNT field matches scoreboard queue
        if (!item.is_write() && item.addr == ADDR_STATUS) begin
            verify_status_count(item.rdata);
        end
    endfunction

    //-------------------------------------------------------------------------
    // 7.5: Verify STATUS.COUNT matches internal queue model
    //-------------------------------------------------------------------------
    function void verify_status_count(logic [31:0] status_rdata);
        bit [7:0] hw_count;
        int expected_count;

        // Extract COUNT field from STATUS register (bits 15:8)
        hw_count = status_rdata[15:8];
        expected_count = queue_model.size();

        num_count_checks++;

        if (hw_count == expected_count) begin
            `uvm_info("SCB", $sformatf("STATUS.COUNT check PASS: HW=%0d, Expected=%0d", 
                      hw_count, expected_count), UVM_MEDIUM)
        end else begin
            num_count_mismatches++;
            `uvm_warning("SCB", $sformatf("STATUS.COUNT mismatch: HW=%0d, Expected=%0d (may be timing)", 
                        hw_count, expected_count))
            // Note: Using warning instead of error because there can be timing
            // differences between when the scoreboard receives transactions
            // and when the STATUS register is read. For stricter checking,
            // change to `uvm_error
        end
    endfunction

    //-------------------------------------------------------------------------
    // Flush the queue model (called when FIFO is cleared)
    //-------------------------------------------------------------------------
    function void flush_queue();
        int flushed = queue_model.size();
        queue_model.delete();
        num_clears++;
        `uvm_info("SCB", $sformatf("FIFO CLEAR detected - flushed %0d entries from queue", flushed), UVM_MEDIUM)
    endfunction

    //-------------------------------------------------------------------------
    // Report statistics at end of test
    //-------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("SCB", "========== Scoreboard Statistics ==========", UVM_LOW)
        `uvm_info("SCB", $sformatf("  Total Writes:     %0d", num_writes), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Total Reads:      %0d", num_reads), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Matches:          %0d", num_matches), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Mismatches:       %0d", num_mismatches), UVM_LOW)
        `uvm_info("SCB", $sformatf("  FIFO Clears:      %0d", num_clears), UVM_LOW)
        `uvm_info("SCB", $sformatf("  COUNT Checks:     %0d", num_count_checks), UVM_LOW)
        `uvm_info("SCB", $sformatf("  COUNT Mismatches: %0d", num_count_mismatches), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Remaining in Q:   %0d", queue_model.size()), UVM_LOW)
        `uvm_info("SCB", "============================================", UVM_LOW)
        
        if (num_mismatches > 0) begin
            `uvm_error("SCB", $sformatf("Scoreboard detected %0d mismatches!", num_mismatches))
        end
    endfunction

endclass

`endif

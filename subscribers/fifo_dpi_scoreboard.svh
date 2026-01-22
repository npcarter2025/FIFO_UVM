`ifndef FIFO_DPI_SCOREBOARD_SVH
`define FIFO_DPI_SCOREBOARD_SVH

//-----------------------------------------------------------------------------
// Class: fifo_dpi_scoreboard
// Description: Enhanced scoreboard that uses DPI-C reference model
//              Extends base scoreboard, replacing SV queue with C model
//-----------------------------------------------------------------------------

class fifo_dpi_scoreboard extends fifo_scoreboard;
    `uvm_component_utils(fifo_dpi_scoreboard)

    // Configuration
    bit use_c_model = 1;          // Toggle between SV queue and C model
    int fifo_depth = 16;          // FIFO depth for C model initialization

    // Additional statistics for C model
    int c_model_overflows;
    int c_model_underflows;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //-------------------------------------------------------------------------
    // Build Phase - Initialize C model
    //-------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (use_c_model) begin
            // Initialize C FIFO model
            c_fifo_init(fifo_depth);
            c_model_overflows = 0;
            c_model_underflows = 0;
            `uvm_info("DPI_SCB", $sformatf("DPI-C FIFO model initialized (depth=%0d)", fifo_depth), UVM_LOW)
        end
    endfunction

    //-------------------------------------------------------------------------
    // Handle FIFO data transactions - Override to use C model
    //-------------------------------------------------------------------------
    virtual function void write_fifo(fifo_item item);
        // If not using C model, use parent's SV queue implementation
        if (!use_c_model) begin
            super.write_fifo(item);
            return;
        end

        // Use C model for verification
        if (item.op == 1) begin
            // Write operation - push to C model
            int status = c_fifo_push(item.w_data);
            num_writes++;
            
            if (status < 0) begin
                c_model_overflows++;
                `uvm_warning("DPI_SCB", $sformatf("C model overflow on push 0x%02h", item.w_data))
            end
            else begin
                `uvm_info("DPI_SCB", $sformatf("C Model: Pushed 0x%02h (count=%0d)", 
                          item.w_data, c_fifo_count()), UVM_LOW)
            end
        end
        else begin
            // Read operation - compare with C model
            byte expected;
            num_reads++;
            
            if (c_fifo_is_empty()) begin
                c_model_underflows++;
                `uvm_warning("DPI_SCB", $sformatf("Read 0x%02h but C model is empty", item.r_data))
            end
            else begin
                expected = c_fifo_pop();
                
                if (item.r_data == expected) begin
                    num_matches++;
                    `uvm_info("DPI_SCB", $sformatf("C Model PASS: Read 0x%02h (expected 0x%02h)", 
                              item.r_data, expected), UVM_LOW)
                end
                else begin
                    num_mismatches++;
                    `uvm_error("DPI_SCB", $sformatf("C Model FAIL: Expected 0x%02h, Got 0x%02h", 
                              expected, item.r_data))
                end
            end
        end
    endfunction

    //-------------------------------------------------------------------------
    // Handle register transactions - Override for C model clear
    //-------------------------------------------------------------------------
    virtual function void write_reg(reg_item item);
        // Check for CTRL register write with CLEAR bit set
        if (item.is_write() && item.addr == ADDR_CTRL && item.wdata[1]) begin
            flush_queue();
        end

        // Check STATUS.COUNT against C model
        if (!item.is_write() && item.addr == ADDR_STATUS && use_c_model) begin
            verify_status_count_dpi(item.rdata);
        end
        else if (!item.is_write() && item.addr == ADDR_STATUS) begin
            // Use parent's verify function if not using C model
            verify_status_count(item.rdata);
        end
    endfunction

    //-------------------------------------------------------------------------
    // Verify STATUS.COUNT against C model
    //-------------------------------------------------------------------------
    function void verify_status_count_dpi(logic [31:0] status_rdata);
        bit [7:0] hw_count;
        int c_count;

        hw_count = status_rdata[15:8];
        c_count = c_fifo_count();

        num_count_checks++;

        if (hw_count == c_count) begin
            `uvm_info("DPI_SCB", $sformatf("STATUS.COUNT vs C model PASS: HW=%0d, C=%0d", 
                      hw_count, c_count), UVM_MEDIUM)
        end
        else begin
            num_count_mismatches++;
            `uvm_warning("DPI_SCB", $sformatf("STATUS.COUNT vs C model mismatch: HW=%0d, C=%0d (timing)", 
                        hw_count, c_count))
        end
    endfunction

    //-------------------------------------------------------------------------
    // Flush queue - Override to clear C model
    //-------------------------------------------------------------------------
    virtual function void flush_queue();
        if (use_c_model) begin
            int old_count = c_fifo_count();
            c_fifo_clear();
            num_clears++;
            `uvm_info("DPI_SCB", $sformatf("C Model: FIFO cleared (had %0d entries)", old_count), UVM_MEDIUM)
        end
        else begin
            super.flush_queue();
        end
    endfunction

    //-------------------------------------------------------------------------
    // Debug: Dump C model state
    //-------------------------------------------------------------------------
    function void dump_c_model();
        if (use_c_model) begin
            `uvm_info("DPI_SCB", "Dumping C model state:", UVM_LOW)
            c_fifo_dump();
            
            // Also show peek of all entries
            for (int i = 0; i < c_fifo_count(); i++) begin
                `uvm_info("DPI_SCB", $sformatf("  [%0d] = 0x%02h", i, c_fifo_peek(i)), UVM_LOW)
            end
        end
    endfunction

    //-------------------------------------------------------------------------
    // Report statistics at end of test
    //-------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        `uvm_info("DPI_SCB", "========== DPI-C Scoreboard Statistics ==========", UVM_LOW)
        `uvm_info("DPI_SCB", $sformatf("  Model Type:       %s", use_c_model ? "DPI-C" : "SV Queue"), UVM_LOW)
        `uvm_info("DPI_SCB", $sformatf("  Total Writes:     %0d", num_writes), UVM_LOW)
        `uvm_info("DPI_SCB", $sformatf("  Total Reads:      %0d", num_reads), UVM_LOW)
        `uvm_info("DPI_SCB", $sformatf("  Matches:          %0d", num_matches), UVM_LOW)
        `uvm_info("DPI_SCB", $sformatf("  Mismatches:       %0d", num_mismatches), UVM_LOW)
        `uvm_info("DPI_SCB", $sformatf("  FIFO Clears:      %0d", num_clears), UVM_LOW)
        `uvm_info("DPI_SCB", $sformatf("  COUNT Checks:     %0d", num_count_checks), UVM_LOW)
        `uvm_info("DPI_SCB", $sformatf("  COUNT Mismatches: %0d", num_count_mismatches), UVM_LOW)
        
        if (use_c_model) begin
            `uvm_info("DPI_SCB", $sformatf("  C Model Overflows:  %0d", c_model_overflows), UVM_LOW)
            `uvm_info("DPI_SCB", $sformatf("  C Model Underflows: %0d", c_model_underflows), UVM_LOW)
            `uvm_info("DPI_SCB", $sformatf("  C Model Final Count: %0d", c_fifo_count()), UVM_LOW)
        end
        else begin
            `uvm_info("DPI_SCB", $sformatf("  Remaining in Q:   %0d", queue_model.size()), UVM_LOW)
        end
        
        `uvm_info("DPI_SCB", "==================================================", UVM_LOW)
        
        if (num_mismatches > 0) begin
            `uvm_error("DPI_SCB", $sformatf("Scoreboard detected %0d mismatches!", num_mismatches))
        end
    endfunction

endclass

`endif

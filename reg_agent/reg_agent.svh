`ifndef REG_AGENT_SVH
`define REG_AGENT_SVH

//-----------------------------------------------------------------------------
// Class: reg_agent
// Description: UVM agent for register bus - assembles driver, monitor, sequencer
//-----------------------------------------------------------------------------

class reg_agent extends uvm_agent;

    `uvm_component_utils(reg_agent)

    // Agent components
    reg_sequencer   sqr;
    reg_driver      drv;
    reg_monitor     mon;

    // Configuration
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Always create monitor
        mon = reg_monitor::type_id::create("mon", this);

        // Only create driver and sequencer if active
        if (is_active == UVM_ACTIVE) begin
            sqr = reg_sequencer::type_id::create("sqr", this);
            drv = reg_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect driver to sequencer if active
        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass

`endif

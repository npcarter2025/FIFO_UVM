`ifndef FIFO_RAL_ENV_SVH
`define FIFO_RAL_ENV_SVH

//-----------------------------------------------------------------------------
// Class: fifo_ral_env
// Description: UVM environment with RAL integration
//              Includes both FIFO data agent and register agent with RAL
//              Plus virtual sequencer for coordinated sequences
//-----------------------------------------------------------------------------

class fifo_ral_env extends uvm_env;

    `uvm_component_utils(fifo_ral_env)

    //-------------------------------------------------------------------------
    // Components
    //-------------------------------------------------------------------------
    
    // FIFO data path agent (existing)
    fifo_agent      fifo_agt;
    fifo_scoreboard scb;
    fifo_coverage   cov;

    // Register agent (Phase 2)
    reg_agent       reg_agt;

    // RAL model (Phase 3)
    fifo_reg_block  reg_block;
    fifo_reg_adapter reg_adapter;

    // Virtual sequencer (Phase 5) - coordinates both agents
    fifo_virtual_sequencer  v_sqr;

    //-------------------------------------------------------------------------
    // Constructor
    //-------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //-------------------------------------------------------------------------
    // Build Phase
    //-------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create FIFO data path components
        fifo_agt = fifo_agent::type_id::create("fifo_agt", this);
        scb      = fifo_scoreboard::type_id::create("scb", this);
        cov      = fifo_coverage::type_id::create("cov", this);

        // Create register agent
        reg_agt = reg_agent::type_id::create("reg_agt", this);

        // Create and build RAL model
        reg_block = fifo_reg_block::type_id::create("reg_block");
        reg_block.build();

        // Create RAL adapter
        reg_adapter = fifo_reg_adapter::type_id::create("reg_adapter");

        // Create virtual sequencer
        v_sqr = fifo_virtual_sequencer::type_id::create("v_sqr", this);

    endfunction

    //-------------------------------------------------------------------------
    // Connect Phase
    //-------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect FIFO agent monitor to scoreboard and coverage
        fifo_agt.mon.item_collected_port.connect(scb.item_collected_export);
        fifo_agt.mon.item_collected_port.connect(cov.analysis_export);

        // Connect RAL model to register agent
        // This tells the RAL which sequencer and adapter to use for bus transactions
        reg_block.reg_map.set_sequencer(reg_agt.sqr, reg_adapter);

        // Set auto-predict mode (update RAL mirror after each transaction)
        reg_block.reg_map.set_auto_predict(1);

        // Connect virtual sequencer handles to agent sequencers
        v_sqr.fifo_sqr  = fifo_agt.sqr;
        v_sqr.reg_sqr   = reg_agt.sqr;
        v_sqr.reg_block = reg_block;

        `uvm_info(get_type_name(), "RAL and virtual sequencer connected", UVM_MEDIUM)
    endfunction

    //-------------------------------------------------------------------------
    // Convenience methods
    //-------------------------------------------------------------------------
    
    // Get the register block handle
    function fifo_reg_block get_reg_block();
        return reg_block;
    endfunction

    // Get the virtual sequencer handle
    function fifo_virtual_sequencer get_virtual_sequencer();
        return v_sqr;
    endfunction

endclass

`endif

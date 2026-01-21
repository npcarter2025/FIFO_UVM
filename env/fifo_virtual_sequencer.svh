`ifndef FIFO_VIRTUAL_SEQUENCER_SVH
`define FIFO_VIRTUAL_SEQUENCER_SVH

//-----------------------------------------------------------------------------
// Class: fifo_virtual_sequencer
// Description: Virtual sequencer that coordinates both FIFO data agent and
//              register agent sequencers. Used for virtual sequences that
//              need to control both data path and register operations.
//-----------------------------------------------------------------------------

class fifo_virtual_sequencer extends uvm_sequencer;

    `uvm_component_utils(fifo_virtual_sequencer)

    //-------------------------------------------------------------------------
    // Sequencer handles - set by environment in connect_phase
    //-------------------------------------------------------------------------
    
    // Handle to FIFO data sequencer
    fifo_sequencer  fifo_sqr;
    
    // Handle to register sequencer
    reg_sequencer   reg_sqr;

    //-------------------------------------------------------------------------
    // RAL model handle - for convenience in virtual sequences
    //-------------------------------------------------------------------------
    fifo_reg_block  reg_block;

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
        `uvm_info(get_type_name(), "Virtual sequencer built", UVM_MEDIUM)
    endfunction

endclass

`endif

//-----------------------------------------------------------------------------
// Package: reg_pkg
// Description: Package containing all register agent components
//-----------------------------------------------------------------------------

package reg_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Transaction
    `include "reg_item.svh"

    // Agent components
    `include "reg_sequencer.svh"
    `include "reg_driver.svh"
    `include "reg_monitor.svh"
    `include "reg_agent.svh"

    // Sequences
    `include "reg_base_sequence.svh"

endpackage

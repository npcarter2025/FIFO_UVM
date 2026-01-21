//-----------------------------------------------------------------------------
// Package: fifo_ral_test_pkg
// Description: Package containing all RAL-integrated test components
//-----------------------------------------------------------------------------

package fifo_ral_test_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Import register agent package
    import reg_pkg::*;

    // Import RAL package
    import fifo_ral_pkg::*;

    //-------------------------------------------------------------------------
    // FIFO data path components (from original fifo_pkg)
    //-------------------------------------------------------------------------
    
    // Transaction
    `include "transaction/fifo_item.svh"

    // Agent components
    `include "agent/fifo_sequencer.svh"
    `include "agent/fifo_driver.svh"
    `include "agent/fifo_monitor.svh"
    `include "agent/fifo_agent.svh"

    // Subscribers
    `include "subscribers/fifo_scoreboard.svh"
    `include "subscribers/fifo_coverage.svh"

    //-------------------------------------------------------------------------
    // RAL-integrated environment and sequences
    //-------------------------------------------------------------------------
    
    // Environment with RAL
    `include "env/fifo_ral_env.svh"

    // RAL sequences
    `include "seq/fifo_ral_sequence.svh"

    // Original FIFO sequences (for data path testing)
    `include "seq/fifo_base_sequence.svh"
    `include "seq/fifo_overflow_sequence.svh"

    //-------------------------------------------------------------------------
    // RAL Tests
    //-------------------------------------------------------------------------
    `include "tests/fifo_ral_test.sv"

endpackage

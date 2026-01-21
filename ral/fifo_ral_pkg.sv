//-----------------------------------------------------------------------------
// Package: fifo_ral_pkg
// Description: Package containing all FIFO RAL model components
//-----------------------------------------------------------------------------

package fifo_ral_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Import reg_pkg for reg_item (used by adapter)
    import reg_pkg::*;

    // Register models
    `include "fifo_ctrl_reg.svh"
    `include "fifo_status_reg.svh"
    `include "fifo_thresh_reg.svh"

    // Register block
    `include "fifo_reg_block.svh"

    // Adapter
    `include "fifo_reg_adapter.svh"

endpackage

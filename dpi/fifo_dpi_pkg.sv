//-----------------------------------------------------------------------------
// Package: fifo_dpi_pkg
// Description: Package containing DPI-C components for FIFO verification
//-----------------------------------------------------------------------------

package fifo_dpi_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Import base packages
    import reg_pkg::*;
    import fifo_ral_pkg::*;
    import fifo_ral_test_pkg::*;

    //-------------------------------------------------------------------------
    // DPI-C Import Declarations
    //-------------------------------------------------------------------------
    `include "dpi/fifo_dpi.svh"

    //-------------------------------------------------------------------------
    // DPI-C Aware Components
    //-------------------------------------------------------------------------
    `include "subscribers/fifo_dpi_scoreboard.svh"

    //-------------------------------------------------------------------------
    // DPI-C Tests
    //-------------------------------------------------------------------------
    `include "tests/fifo_dpi_test.sv"

endpackage

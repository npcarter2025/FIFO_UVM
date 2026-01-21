package fifo_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

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

    // Environment
    `include "env/fifo_env.svh"

    // Sequences
    `include "seq/fifo_base_sequence.svh"
    `include "seq/fifo_overflow_sequence.svh"

    // Tests
    `include "tests/fifo_test.sv"
    `include "tests/fifo_overflow_test.sv"

endpackage
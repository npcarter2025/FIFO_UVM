`ifndef FIFO_DPI_SVH
`define FIFO_DPI_SVH

//-----------------------------------------------------------------------------
// File: fifo_dpi.svh
// Description: DPI-C import declarations for C functions
//-----------------------------------------------------------------------------

//=============================================================================
// FIFO Model Functions (from fifo_model.c)
//=============================================================================

// Initialize the C FIFO model with specified depth
import "DPI-C" function void c_fifo_init(input int fifo_depth);

// Push data to FIFO, returns 0 on success, -1 on overflow
import "DPI-C" function int c_fifo_push(input byte data);

// Pop data from FIFO, returns data (0xFF if empty)
import "DPI-C" function byte c_fifo_pop();

// Get current number of entries in FIFO
import "DPI-C" function int c_fifo_count();

// Check if FIFO is empty (returns 1 if empty, 0 otherwise)
import "DPI-C" function int c_fifo_is_empty();

// Check if FIFO is full (returns 1 if full, 0 otherwise)
import "DPI-C" function int c_fifo_is_full();

// Check if FIFO count >= threshold
import "DPI-C" function int c_fifo_almost_full(input int threshold);

// Clear the FIFO
import "DPI-C" function void c_fifo_clear();

// Peek at data at index without removing
import "DPI-C" function byte c_fifo_peek(input int index);

// Get and clear overflow flag
import "DPI-C" function int c_fifo_get_overflow();

// Get and clear underflow flag
import "DPI-C" function int c_fifo_get_underflow();

// Debug: dump FIFO contents to stdout
import "DPI-C" function void c_fifo_dump();

//=============================================================================
// Test Utility Functions (from test_utils.c)
//=============================================================================

// Initialize random seed (0 = time-based, otherwise use provided seed)
import "DPI-C" function void c_seed_random(input int seed);

// Generate a random byte
import "DPI-C" function byte c_random_byte();

// Generate random number in range [min, max]
import "DPI-C" function int c_random_range(input int min, input int max);

// Generate incrementing pattern starting from 'start'
import "DPI-C" function void c_generate_incrementing(
    output byte data[],
    input int size,
    input byte start
);

// Generate decrementing pattern starting from 'start'
import "DPI-C" function void c_generate_decrementing(
    output byte data[],
    input int size,
    input byte start
);

// Generate walking ones pattern (0x01, 0x02, 0x04, ...)
import "DPI-C" function void c_generate_walking_ones(
    output byte data[],
    input int size
);

// Generate walking zeros pattern (0xFE, 0xFD, 0xFB, ...)
import "DPI-C" function void c_generate_walking_zeros(
    output byte data[],
    input int size
);

// Generate alternating pattern (0xAA, 0x55, ...)
import "DPI-C" function void c_generate_alternating(
    output byte data[],
    input int size
);

// Fill array with random data
import "DPI-C" function void c_generate_random(
    output byte data[],
    input int size
);

// Calculate XOR checksum
import "DPI-C" function byte c_calculate_checksum(
    input byte data[],
    input int size
);

// Calculate arithmetic sum (mod 256)
import "DPI-C" function byte c_calculate_sum(
    input byte data[],
    input int size
);

// Compare two arrays, return number of mismatches
import "DPI-C" function int c_compare_arrays(
    input byte a[],
    input byte b[],
    input int size
);

// Find pattern in data, return index or -1
import "DPI-C" function int c_find_pattern(
    input byte data[],
    input int data_size,
    input byte pattern[],
    input int pattern_size
);

// Reverse array in place
import "DPI-C" function void c_reverse_array(
    inout byte data[],
    input int size
);

`endif

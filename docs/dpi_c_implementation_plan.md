# DPI-C Implementation Plan for FIFO UVM Testbench

## Overview

This document outlines a plan to integrate DPI-C (Direct Programming Interface for C) into the FIFO UVM testbench. DPI-C enables SystemVerilog to call C/C++ functions and vice versa, providing opportunities for reference models, complex stimulus generation, and external tool integration.

---

## Phase 8: DPI-C Integration

### Goals
- Create a C reference model for the FIFO
- Integrate the C model with the UVM scoreboard
- Demonstrate DPI-C import/export capabilities
- Add utility functions for test data generation

---

## Implementation Steps

### Step 8.1: Create C Reference Model

**File:** `dpi/fifo_model.c`

**Description:** Implement a golden FIFO model in C that mirrors the DUT behavior.

```c
// fifo_model.c
#include "svdpi.h"
#include <string.h>

#define MAX_DEPTH 256

static unsigned char fifo_mem[MAX_DEPTH];
static int head = 0;
static int tail = 0;
static int count = 0;
static int depth = 16;

// Initialize the FIFO model
void c_fifo_init(int fifo_depth) {
    depth = fifo_depth;
    head = 0;
    tail = 0;
    count = 0;
    memset(fifo_mem, 0, sizeof(fifo_mem));
}

// Push data to FIFO, returns 0 on success, -1 on overflow
int c_fifo_push(unsigned char data) {
    if (count >= depth) return -1;
    fifo_mem[tail] = data;
    tail = (tail + 1) % depth;
    count++;
    return 0;
}

// Pop data from FIFO, returns data (undefined if empty)
unsigned char c_fifo_pop() {
    if (count <= 0) return 0xFF;
    unsigned char data = fifo_mem[head];
    head = (head + 1) % depth;
    count--;
    return data;
}

// Get current count
int c_fifo_count() {
    return count;
}

// Check if empty
int c_fifo_is_empty() {
    return (count == 0);
}

// Check if full
int c_fifo_is_full() {
    return (count >= depth);
}

// Clear the FIFO
void c_fifo_clear() {
    head = 0;
    tail = 0;
    count = 0;
}

// Peek at data without removing (for debug)
unsigned char c_fifo_peek(int index) {
    if (index >= count) return 0xFF;
    return fifo_mem[(head + index) % depth];
}
```

---

### Step 8.2: Create DPI-C Header File

**File:** `dpi/fifo_dpi.svh`

**Description:** SystemVerilog import declarations for C functions.

```systemverilog
`ifndef FIFO_DPI_SVH
`define FIFO_DPI_SVH

// Import C FIFO model functions
import "DPI-C" function void c_fifo_init(input int fifo_depth);
import "DPI-C" function int c_fifo_push(input byte data);
import "DPI-C" function byte c_fifo_pop();
import "DPI-C" function int c_fifo_count();
import "DPI-C" function int c_fifo_is_empty();
import "DPI-C" function int c_fifo_is_full();
import "DPI-C" function void c_fifo_clear();
import "DPI-C" function byte c_fifo_peek(input int index);

`endif
```

---

### Step 8.3: Create DPI-C Aware Scoreboard

**File:** `subscribers/fifo_dpi_scoreboard.svh`

**Description:** Enhanced scoreboard that uses C reference model for verification.

```systemverilog
class fifo_dpi_scoreboard extends fifo_scoreboard;
    `uvm_component_utils(fifo_dpi_scoreboard)

    bit use_c_model = 1;  // Toggle between SV queue and C model

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (use_c_model) begin
            c_fifo_init(16);  // Initialize C model with DEPTH=16
            `uvm_info("SCB", "Using DPI-C reference model", UVM_LOW)
        end
    endfunction

    // Override write_fifo to use C model
    virtual function void write_fifo(fifo_item item);
        if (!use_c_model) begin
            super.write_fifo(item);
            return;
        end

        if (item.op == 1) begin
            // Write operation
            int status = c_fifo_push(item.w_data);
            if (status < 0) begin
                `uvm_warning("SCB", "C model overflow detected")
            end
            num_writes++;
            `uvm_info("SCB", $sformatf("C Model: Pushed 0x%02h (count=%0d)", 
                      item.w_data, c_fifo_count()), UVM_LOW)
        end
        else begin
            // Read operation
            byte expected = c_fifo_pop();
            num_reads++;
            if (item.r_data == expected) begin
                num_matches++;
                `uvm_info("SCB", $sformatf("C Model PASS: Read 0x%02h", item.r_data), UVM_LOW)
            end
            else begin
                num_mismatches++;
                `uvm_error("SCB", $sformatf("C Model FAIL: Expected 0x%02h, Got 0x%02h", 
                          expected, item.r_data))
            end
        end
    endfunction

    // Override flush for C model
    virtual function void flush_queue();
        if (use_c_model) begin
            c_fifo_clear();
            num_clears++;
            `uvm_info("SCB", "C Model: FIFO cleared", UVM_MEDIUM)
        end
        else begin
            super.flush_queue();
        end
    endfunction

endclass
```

---

### Step 8.4: Add Utility Functions in C

**File:** `dpi/test_utils.c`

**Description:** Utility functions for stimulus generation and analysis.

```c
#include "svdpi.h"
#include <stdlib.h>
#include <time.h>

static int seeded = 0;

// Initialize random seed
void c_seed_random(int seed) {
    if (seed == 0) {
        srand(time(NULL));
    } else {
        srand(seed);
    }
    seeded = 1;
}

// Generate random byte
unsigned char c_random_byte() {
    if (!seeded) c_seed_random(0);
    return (unsigned char)(rand() % 256);
}

// Generate incrementing pattern
void c_generate_incrementing(unsigned char* data, int size, unsigned char start) {
    for (int i = 0; i < size; i++) {
        data[i] = (start + i) % 256;
    }
}

// Generate walking ones pattern
void c_generate_walking_ones(unsigned char* data, int size) {
    for (int i = 0; i < size; i++) {
        data[i] = 1 << (i % 8);
    }
}

// Calculate simple checksum
unsigned char c_calculate_checksum(const unsigned char* data, int size) {
    unsigned char sum = 0;
    for (int i = 0; i < size; i++) {
        sum ^= data[i];
    }
    return sum;
}

// Compare two arrays, return number of mismatches
int c_compare_arrays(const unsigned char* a, const unsigned char* b, int size) {
    int mismatches = 0;
    for (int i = 0; i < size; i++) {
        if (a[i] != b[i]) mismatches++;
    }
    return mismatches;
}
```

**SystemVerilog imports:**

```systemverilog
// test_utils imports
import "DPI-C" function void c_seed_random(input int seed);
import "DPI-C" function byte c_random_byte();
import "DPI-C" function void c_generate_incrementing(
    output byte data[], input int size, input byte start);
import "DPI-C" function void c_generate_walking_ones(
    output byte data[], input int size);
import "DPI-C" function byte c_calculate_checksum(
    input byte data[], input int size);
import "DPI-C" function int c_compare_arrays(
    input byte a[], input byte b[], input int size);
```

---

### Step 8.5: Update Makefile

**File:** `Makefile` (modifications)

**Description:** Add compilation rules for C files.

```makefile
# DPI-C sources
DPI_DIR = dpi
DPI_SRCS = $(DPI_DIR)/fifo_model.c $(DPI_DIR)/test_utils.c

# Compile with DPI
compile_dpi:
    vcs -sverilog -ntb_opts uvm-1.2 \
        $(DPI_SRCS) \
        +incdir+$(DPI_DIR) \
        ... (other flags)

# Or compile C separately
DPI_OBJ = $(DPI_DIR)/fifo_dpi.so

$(DPI_OBJ): $(DPI_SRCS)
    gcc -shared -fPIC -o $@ $^ -I$(VCS_HOME)/include

run_dpi_test: $(DPI_OBJ)
    ./simv +UVM_TESTNAME=fifo_dpi_test -sv_lib $(DPI_OBJ)
```

---

### Step 8.6: Create DPI-C Test

**File:** `tests/fifo_dpi_test.sv`

**Description:** Test that exercises DPI-C functionality.

```systemverilog
class fifo_dpi_test extends fifo_virtual_base_test;
    `uvm_component_utils(fifo_dpi_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        // Override scoreboard with DPI version
        fifo_scoreboard::type_id::set_type_override(
            fifo_dpi_scoreboard::type_id::get());
        super.build_phase(phase);
    endfunction

    virtual task run_test_sequence();
        fifo_config_then_write_sequence seq;
        
        `uvm_info(get_type_name(), "Running test with DPI-C scoreboard", UVM_LOW)
        
        seq = fifo_config_then_write_sequence::type_id::create("seq");
        seq.start(env.v_sqr);
        
        // Verify C model state matches expectations
        `uvm_info(get_type_name(), $sformatf("C Model final count: %0d", c_fifo_count()), UVM_LOW)
    endtask
endclass
```

---

## Directory Structure After Implementation

```
Fifo_UVM/
├── dpi/
│   ├── fifo_model.c        # C FIFO reference model
│   ├── test_utils.c        # C utility functions
│   ├── fifo_dpi.svh        # SV import declarations
│   └── Makefile            # Optional: separate C compilation
├── subscribers/
│   ├── fifo_scoreboard.svh
│   └── fifo_dpi_scoreboard.svh  # DPI-C enabled scoreboard
├── tests/
│   └── fifo_dpi_test.sv    # Test using DPI-C
└── ...
```

---

## Implementation Checklist

| Step | Task | Files | Status |
|------|------|-------|--------|
| 8.1 | Create C FIFO reference model | `dpi/fifo_model.c` | ⬜ |
| 8.2 | Create DPI-C header file | `dpi/fifo_dpi.svh` | ⬜ |
| 8.3 | Create DPI-C aware scoreboard | `subscribers/fifo_dpi_scoreboard.svh` | ⬜ |
| 8.4 | Add C utility functions | `dpi/test_utils.c` | ⬜ |
| 8.5 | Update Makefile for DPI | `Makefile` | ⬜ |
| 8.6 | Create DPI-C test | `tests/fifo_dpi_test.sv` | ⬜ |
| 8.7 | Run and verify | - | ⬜ |

---

## Advanced Extensions (Optional)

### 8.A: Export SV Functions to C

Allow C code to call back into SystemVerilog:

```systemverilog
export "DPI-C" function sv_log_message;

function void sv_log_message(string msg);
    `uvm_info("DPI", msg, UVM_LOW)
endfunction
```

### 8.B: C++ Integration

Use C++ for more complex models with classes:

```cpp
// fifo_model.cpp
extern "C" {
    #include "svdpi.h"
    
    class FifoModel {
        // C++ class implementation
    };
    
    static FifoModel* model = nullptr;
    
    void c_fifo_init(int depth) {
        model = new FifoModel(depth);
    }
    // ... wrap other methods
}
```

### 8.C: File-Based Test Vectors

Read test patterns from files:

```c
int c_load_test_vectors(const char* filename, unsigned char* data, int max_size) {
    FILE* f = fopen(filename, "rb");
    if (!f) return -1;
    int count = fread(data, 1, max_size, f);
    fclose(f);
    return count;
}
```

### 8.D: Performance Profiling

Add timing analysis in C:

```c
#include <sys/time.h>

static struct timeval start_time;

void c_start_timer() {
    gettimeofday(&start_time, NULL);
}

double c_get_elapsed_ms() {
    struct timeval now;
    gettimeofday(&now, NULL);
    return (now.tv_sec - start_time.tv_sec) * 1000.0 +
           (now.tv_usec - start_time.tv_usec) / 1000.0;
}
```

---

## Benefits Summary

| Benefit | Description |
|---------|-------------|
| **Reference Model** | Golden C model for scoreboard comparison |
| **Reusability** | C models can be shared with software teams |
| **Performance** | Complex computations run faster in C |
| **External Integration** | Connect to databases, files, networks |
| **Legacy Support** | Reuse existing C/C++ verification IP |

---

## Deliverable

A working DPI-C integration that:
1. ✅ Implements a C reference FIFO model
2. ✅ Integrates with the UVM scoreboard
3. ✅ Provides utility functions for test generation
4. ✅ Demonstrates bidirectional SV↔C communication
5. ✅ All existing tests continue to pass

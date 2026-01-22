# Virtual Sequences and RAL Implementation Plan

This document outlines the architecture and implementation plan for adding **Virtual Sequences** and **Register Abstraction Layer (RAL)** to the FIFO UVM testbench.

---

## Table of Contents

1. [Virtual Sequences](#virtual-sequences)
   - [When You Need Them](#when-you-need-them)
   - [Architecture](#architecture)
   - [Key Code Patterns](#key-code-patterns)
2. [RAL (Register Abstraction Layer)](#ral-register-abstraction-layer)
   - [DUT Register Additions](#dut-register-additions)
   - [RAL Model Structure](#ral-model-structure)
   - [Key RAL Classes](#key-ral-classes)
   - [Using RAL in Sequences](#using-ral-in-sequences)
3. [Implementation Action Plan](#implementation-action-plan)

---

## Virtual Sequences

### When You Need Them

Virtual sequences coordinate multiple agents. The current testbench has one agent, so to use virtual sequences you would:

1. **Split read/write into separate agents** (artificial but educational)
2. **Add a config/CSR agent** (pairs naturally with RAL) ← **Recommended**
3. **Add a second FIFO** and coordinate traffic between them

Option 2 is the most natural fit since it also motivates RAL.

### Architecture

```
                    ┌─────────────────────┐
                    │   virtual_sequence  │
                    └──────────┬──────────┘
                               │ starts sub-sequences on
                    ┌──────────▼──────────┐
                    │  virtual_sequencer  │
                    │  ┌───────┬────────┐ │
                    │  │fifo_  │ reg_   │ │
                    │  │sqr_h  │ sqr_h  │ │  (handles to real sequencers)
                    └──┴───────┴────────┴─┘
                          │          │
              ┌───────────┘          └───────────┐
              ▼                                  ▼
        ┌──────────┐                      ┌──────────┐
        │fifo_agent│                      │ reg_agent│
        │  (data)  │                      │  (CSRs)  │
        └──────────┘                      └──────────┘
```

### Key Code Patterns

#### Virtual Sequencer

```systemverilog
class fifo_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(fifo_virtual_sequencer)
    
    fifo_sequencer  fifo_sqr_h;   // handle to data agent's sequencer
    reg_sequencer   reg_sqr_h;    // handle to register agent's sequencer
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
```

#### Virtual Sequence

```systemverilog
class fifo_virtual_sequence extends uvm_sequence;
    `uvm_object_utils(fifo_virtual_sequence)
    `uvm_declare_p_sequencer(fifo_virtual_sequencer)  // gives you p_sequencer handle
    
    task body();
        fifo_write_sequence  write_seq;
        reg_config_sequence  cfg_seq;
        
        // Configure FIFO threshold via register agent
        cfg_seq = reg_config_sequence::type_id::create("cfg_seq");
        cfg_seq.start(p_sequencer.reg_sqr_h);
        
        // Now run data traffic via FIFO agent
        write_seq = fifo_write_sequence::type_id::create("write_seq");
        write_seq.start(p_sequencer.fifo_sqr_h);
        
        // Or run them in parallel with fork/join
    endtask
endclass
```

#### Environment connect_phase

```systemverilog
virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    v_sqr.fifo_sqr_h = fifo_agt.sqr;
    v_sqr.reg_sqr_h  = reg_agt.sqr;
endfunction
```

---

## RAL (Register Abstraction Layer)

### DUT Register Additions

A simple register block with a bus interface is required. Here's a minimal register map:

| Address | Register  | Bits                          | Description              |
|---------|-----------|-------------------------------|--------------------------|
| 0x00    | `CTRL`    | [0] enable, [1] clear         | Control register         |
| 0x04    | `STATUS`  | [0] empty, [1] full, [7:2] count | Read-only status      |
| 0x08    | `THRESH`  | [7:0] almost_full_thresh      | Almost-full threshold    |

#### Simple Bus Interface Signals

```systemverilog
// Simple register interface (directly on FIFO or as wrapper)
input  logic        reg_valid,
input  logic        reg_write,    // 1=write, 0=read
input  logic [7:0]  reg_addr,
input  logic [31:0] reg_wdata,
output logic [31:0] reg_rdata,
output logic        reg_ready
```

### RAL Model Structure

```
┌─────────────────────────────────────────────────────┐
│                  fifo_reg_block                     │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐             │
│  │CTRL_reg │  │STAT_reg │  │THRESH_  │             │
│  │ .enable │  │ .empty  │  │  reg    │             │
│  │ .clear  │  │ .full   │  │ .thresh │             │
│  └─────────┘  │ .count  │  └─────────┘             │
│               └─────────┘                           │
│  ┌────────────────────────────────────┐            │
│  │         uvm_reg_map                │            │
│  │   addr 0x00 → CTRL_reg             │            │
│  │   addr 0x04 → STAT_reg             │            │
│  │   addr 0x08 → THRESH_reg           │            │
│  └────────────────────────────────────┘            │
└─────────────────────────────────────────────────────┘
```

### Key RAL Classes

#### 1. Individual Register Example (CTRL)

```systemverilog
class fifo_ctrl_reg extends uvm_reg;
    `uvm_object_utils(fifo_ctrl_reg)
    
    rand uvm_reg_field enable;
    rand uvm_reg_field clear;
    
    function new(string name = "fifo_ctrl_reg");
        super.new(name, 32, UVM_NO_COVERAGE);  // 32-bit register
    endfunction
    
    virtual function void build();
        enable = uvm_reg_field::type_id::create("enable");
        enable.configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 0);  
        //               width, lsb, access, volatile, reset, has_reset, is_rand, individually_accessible
        
        clear = uvm_reg_field::type_id::create("clear");
        clear.configure(this, 1, 1, "RW", 0, 1'b0, 1, 1, 0);
    endfunction
endclass
```

#### 2. Register Block

```systemverilog
class fifo_reg_block extends uvm_reg_block;
    `uvm_object_utils(fifo_reg_block)
    
    rand fifo_ctrl_reg   CTRL;
    rand fifo_status_reg STATUS;
    rand fifo_thresh_reg THRESH;
    
    uvm_reg_map reg_map;
    
    function new(string name = "fifo_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        CTRL = fifo_ctrl_reg::type_id::create("CTRL");
        CTRL.configure(this);
        CTRL.build();
        
        STATUS = fifo_status_reg::type_id::create("STATUS");
        STATUS.configure(this);
        STATUS.build();
        
        THRESH = fifo_thresh_reg::type_id::create("THRESH");
        THRESH.configure(this);
        THRESH.build();
        
        // Create address map
        reg_map = create_map("reg_map", 'h0, 4, UVM_LITTLE_ENDIAN);
        reg_map.add_reg(CTRL,   'h00, "RW");
        reg_map.add_reg(STATUS, 'h04, "RO");
        reg_map.add_reg(THRESH, 'h08, "RW");
        
        lock_model();  // finalize
    endfunction
endclass
```

#### 3. Adapter (Converts RAL ops to bus protocol)

```systemverilog
class fifo_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(fifo_reg_adapter)
    
    function new(string name = "fifo_reg_adapter");
        super.new(name);
        supports_byte_enable = 0;
        provides_responses   = 1;
    endfunction
    
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        reg_item item = reg_item::type_id::create("item");
        item.write = (rw.kind == UVM_WRITE);
        item.addr  = rw.addr;
        item.data  = rw.data;
        return item;
    endfunction
    
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        reg_item item;
        if (!$cast(item, bus_item))
            `uvm_fatal("ADAPTER", "Bad cast")
        rw.kind   = item.write ? UVM_WRITE : UVM_READ;
        rw.addr   = item.addr;
        rw.data   = item.data;
        rw.status = UVM_IS_OK;
    endfunction
endclass
```

### Using RAL in Sequences

Once set up, RAL gives you elegant register access:

```systemverilog
task body();
    uvm_status_e status;
    uvm_reg_data_t value;
    
    // Write threshold register
    reg_block.THRESH.write(status, 8'hC0);
    
    // Read status register
    reg_block.STATUS.read(status, value);
    
    // Access individual fields
    reg_block.CTRL.enable.set(1);
    reg_block.CTRL.update(status);  // writes all modified fields
    
    // Mirror check (compare model to DUT)
    reg_block.STATUS.mirror(status, UVM_CHECK);
endtask
```

---

## Implementation Action Plan

### Phase 1: DUT Register Module

**Goal:** Add a simple register interface to the FIFO DUT.

| Step | Task | Files to Create/Modify |
|------|------|------------------------|
| 1.1 | Design register map (CTRL, STATUS, THRESH) | Design doc |
| 1.2 | Create `fifo_regs.sv` module with bus interface | `fifo_regs.sv` |
| 1.3 | Integrate registers with FIFO (wire up enable, clear, almost_full_thresh, status signals) | `fifo.sv` |
| 1.4 | Create a top-level wrapper `fifo_top.sv` that instantiates both | `fifo_top.sv` |
| 1.5 | Write a simple directed test to verify registers work (non-UVM sanity check) | `tb_top.sv` or standalone |

**Deliverable:** FIFO with working registers, manually verified.

---

### Phase 2: Register Agent

**Goal:** Create a UVM agent for the register bus interface.

| Step | Task | Files to Create |
|------|------|-----------------|
| 2.1 | Create `reg_item.svh` - transaction for register read/write | `reg_item.svh` |
| 2.2 | Create `reg_if.sv` - interface for register bus | `reg_if.sv` |
| 2.3 | Create `reg_driver.svh` - drives register transactions | `reg_driver.svh` |
| 2.4 | Create `reg_monitor.svh` - observes register transactions | `reg_monitor.svh` |
| 2.5 | Create `reg_sequencer.svh` - sequencer (usually typedef) | `reg_sequencer.svh` |
| 2.6 | Create `reg_agent.svh` - assembles driver/monitor/sequencer | `reg_agent.svh` |
| 2.7 | Create `reg_pkg.sv` - package for all register agent files | `reg_pkg.sv` |
| 2.8 | Write a simple register sequence and test to verify the agent | `reg_base_sequence.svh`, `reg_test.sv` |

**Deliverable:** Working register agent that can read/write DUT registers.

---

### Phase 3: RAL Model

**Goal:** Build the UVM RAL model for the FIFO registers.

| Step | Task | Files to Create |
|------|------|-----------------|
| 3.1 | Create `fifo_ctrl_reg.svh` - CTRL register model | `ral/fifo_ctrl_reg.svh` |
| 3.2 | Create `fifo_status_reg.svh` - STATUS register model | `ral/fifo_status_reg.svh` |
| 3.3 | Create `fifo_thresh_reg.svh` - THRESH register model | `ral/fifo_thresh_reg.svh` |
| 3.4 | Create `fifo_reg_block.svh` - register block with address map | `ral/fifo_reg_block.svh` |
| 3.5 | Create `fifo_reg_adapter.svh` - converts RAL ops to reg_item | `ral/fifo_reg_adapter.svh` |
| 3.6 | Create `fifo_ral_pkg.sv` - package for RAL files | `ral/fifo_ral_pkg.sv` |

**Deliverable:** Complete RAL model that compiles.

---

### Phase 4: RAL Integration

**Goal:** Connect RAL to the register agent and environment.

| Step | Task | Files to Modify |
|------|------|-----------------|
| 4.1 | Add `fifo_reg_block` instance to `fifo_env` | `fifo_env.svh` |
| 4.2 | Add `reg_agent` instance to `fifo_env` | `fifo_env.svh` |
| 4.3 | In `connect_phase`, set the RAL model's sequencer and adapter | `fifo_env.svh` |
| 4.4 | Update `tb_top.sv` to instantiate `reg_if` and connect to DUT | `tb_top.sv` |
| 4.5 | Pass `reg_if` to environment via `uvm_config_db` | `tb_top.sv` |
| 4.6 | Write a RAL test sequence using `reg_block.CTRL.write()` etc. | `fifo_ral_sequence.svh` |
| 4.7 | Create `fifo_ral_test.sv` to run the RAL sequence | `fifo_ral_test.sv` |

**Deliverable:** RAL integrated and functional; can read/write registers via RAL API.

---

### Phase 5: Virtual Sequencer

**Goal:** Create the virtual sequencer to coordinate both agents.

| Step | Task | Files to Create/Modify |
|------|------|------------------------|
| 5.1 | Create `fifo_virtual_sequencer.svh` with handles to both sequencers | `fifo_virtual_sequencer.svh` |
| 5.2 | Instantiate virtual sequencer in `fifo_env` | `fifo_env.svh` |
| 5.3 | Connect sequencer handles in `fifo_env.connect_phase()` | `fifo_env.svh` |

**Deliverable:** Virtual sequencer instantiated and connected.

---

### Phase 6: Virtual Sequences

**Goal:** Write virtual sequences that coordinate register config and data traffic.

| Step | Task | Files to Create |
|------|------|-----------------|
| 6.1 | Create `fifo_virtual_base_sequence.svh` - base class with `p_sequencer` | `fifo_virtual_base_sequence.svh` |
| 6.2 | Create `fifo_config_then_write_sequence.svh` - configure threshold, then write data | `fifo_config_then_write_sequence.svh` |
| 6.3 | Create `fifo_parallel_traffic_sequence.svh` - fork register and data traffic | `fifo_parallel_traffic_sequence.svh` |
| 6.4 | Create `fifo_virtual_test.sv` - test that runs virtual sequences | `fifo_virtual_test.sv` |
| 6.5 | Verify end-to-end: configure almost_full threshold → write data → check STATUS register | Run simulation |

**Deliverable:** Working virtual sequences that demonstrate multi-agent coordination.

---

### Phase 7: Enhancements (Optional)

| Step | Task | Description |
|------|------|-------------|
| 7.1 | Add RAL predictor | Auto-update RAL mirror from monitor observations |
| 7.2 | Add RAL coverage | Enable `UVM_CVR_ALL` in reg_block for automatic coverage |
| 7.3 | Register reset test | Use `reg_block.reset()` and verify DUT matches |
| 7.4 | Bit-bash test | Built-in RAL sequence to test all register bits |
| 7.5 | Add scoreboard integration | Check STATUS register matches scoreboard's queue count |

---

## File Structure After Implementation

```
Fifo_UVM/
├── docs/
│   └── virtual_sequences_and_ral_plan.md   (this file)
├── rtl/
│   ├── fifo.sv                             (modified - add threshold/enable)
│   ├── fifo_regs.sv                        (new - register module)
│   └── fifo_top.sv                         (new - top wrapper)
├── tb/
│   ├── fifo_if.sv
│   ├── reg_if.sv                           (new)
│   └── tb_top.sv                           (modified)
├── agents/
│   ├── fifo_agent/
│   │   ├── fifo_pkg.sv
│   │   ├── fifo_item.svh
│   │   ├── fifo_driver.svh
│   │   ├── fifo_monitor.svh
│   │   ├── fifo_sequencer.svh
│   │   └── fifo_agent.svh
│   └── reg_agent/                          (new)
│       ├── reg_pkg.sv
│       ├── reg_item.svh
│       ├── reg_driver.svh
│       ├── reg_monitor.svh
│       ├── reg_sequencer.svh
│       └── reg_agent.svh
├── ral/                                    (new)
│   ├── fifo_ral_pkg.sv
│   ├── fifo_ctrl_reg.svh
│   ├── fifo_status_reg.svh
│   ├── fifo_thresh_reg.svh
│   ├── fifo_reg_block.svh
│   └── fifo_reg_adapter.svh
├── env/
│   ├── fifo_env.svh                        (modified)
│   ├── fifo_scoreboard.svh
│   ├── fifo_coverage.svh
│   └── fifo_virtual_sequencer.svh          (new)
├── sequences/
│   ├── fifo_base_sequence.svh
│   ├── fifo_overflow_sequence.svh
│   ├── reg_base_sequence.svh               (new)
│   ├── fifo_virtual_base_sequence.svh      (new)
│   ├── fifo_config_then_write_sequence.svh (new)
│   └── fifo_parallel_traffic_sequence.svh  (new)
├── tests/
│   ├── fifo_test.sv
│   ├── fifo_overflow_test.sv
│   ├── fifo_ral_test.sv                    (new)
│   └── fifo_virtual_test.sv                (new)
└── Makefile                                (modified)
```

---

## Summary

| Phase | Focus | Key Learning |
|-------|-------|--------------|
| 1 | DUT Registers | RTL design, bus protocols |
| 2 | Register Agent | Agent architecture (again, reinforcement) |
| 3 | RAL Model | `uvm_reg`, `uvm_reg_block`, `uvm_reg_field` |
| 4 | RAL Integration | Adapter, sequencer connection, `uvm_config_db` |
| 5 | Virtual Sequencer | Multi-agent coordination setup |
| 6 | Virtual Sequences | `p_sequencer`, coordinated traffic |
| 7 | Enhancements | Predictor, coverage, built-in sequences |

This progression builds each concept on the previous one, ensuring a solid understanding before moving forward.

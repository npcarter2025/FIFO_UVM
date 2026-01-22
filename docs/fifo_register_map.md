# FIFO Register Map Design Document

## Overview

This document describes the register interface for the FIFO DUT. The register interface provides software control and status monitoring of the FIFO through a simple memory-mapped bus interface.

## Register Summary

| Offset | Name   | Access | Description                          |
|--------|--------|--------|--------------------------------------|
| 0x00   | CTRL   | RW     | Control register                     |
| 0x04   | STATUS | RO     | Status register                      |
| 0x08   | THRESH | RW     | Almost-full threshold register       |

## Bus Interface

The register module uses a simple synchronous bus interface:

| Signal      | Direction | Width | Description                              |
|-------------|-----------|-------|------------------------------------------|
| clk         | input     | 1     | Clock                                    |
| rst_n       | input     | 1     | Active-low reset                         |
| addr        | input     | 8     | Register address                         |
| wdata       | input     | 32    | Write data                               |
| rdata       | output    | 32    | Read data                                |
| wen         | input     | 1     | Write enable                             |
| ren         | input     | 1     | Read enable                              |
| ready       | output    | 1     | Transaction ready (always 1 for simplicity) |

## Register Definitions

### CTRL Register (Offset 0x00)

Control register for FIFO operations.

| Bits  | Name      | Access | Reset | Description                              |
|-------|-----------|--------|-------|------------------------------------------|
| [0]   | ENABLE    | RW     | 0     | FIFO enable (1=enabled, 0=disabled)      |
| [1]   | CLEAR     | RW/SC  | 0     | Clear/reset FIFO (self-clearing)         |
| [31:2]| Reserved  | RO     | 0     | Reserved for future use                  |

- **ENABLE**: When set to 1, the FIFO accepts read/write transactions. When 0, the FIFO ignores all data transactions.
- **CLEAR**: Writing 1 clears the FIFO (resets pointers and count). This bit auto-clears to 0 after one clock cycle.

### STATUS Register (Offset 0x04)

Read-only status register reflecting current FIFO state.

| Bits   | Name        | Access | Description                              |
|--------|-------------|--------|------------------------------------------|
| [0]    | EMPTY       | RO     | FIFO is empty                            |
| [1]    | FULL        | RO     | FIFO is full                             |
| [2]    | ALMOST_FULL | RO     | FIFO count >= almost_full threshold      |
| [3]    | OVERFLOW    | RO/W1C | Overflow occurred (write when full)      |
| [4]    | UNDERFLOW   | RO/W1C | Underflow occurred (read when empty)     |
| [15:8] | COUNT       | RO     | Current number of entries in FIFO        |
| [31:16]| Reserved    | RO     | Reserved for future use                  |

- **EMPTY**: Asserted when count == 0
- **FULL**: Asserted when count == DEPTH
- **ALMOST_FULL**: Asserted when count >= THRESH register value
- **OVERFLOW/UNDERFLOW**: Sticky error flags, write 1 to clear

### THRESH Register (Offset 0x08)

Almost-full threshold configuration.

| Bits   | Name        | Access | Reset       | Description                          |
|--------|-------------|--------|-------------|--------------------------------------|
| [7:0]  | THRESH_VAL  | RW     | DEPTH-1     | Almost-full threshold value          |
| [31:8] | Reserved    | RO     | 0           | Reserved for future use              |

- **THRESH_VAL**: When FIFO count >= this value, ALMOST_FULL status bit is set.

## Signal Interface to FIFO Core

The register module outputs control signals and inputs status signals from the FIFO core:

### Control Outputs (to FIFO)
| Signal            | Width | Description                              |
|-------------------|-------|------------------------------------------|
| fifo_enable       | 1     | FIFO enable (from CTRL.ENABLE)           |
| fifo_clear        | 1     | FIFO clear pulse (from CTRL.CLEAR)       |
| almost_full_thresh| 8     | Almost-full threshold (from THRESH)      |

### Status Inputs (from FIFO)
| Signal            | Width | Description                              |
|-------------------|-------|------------------------------------------|
| fifo_empty        | 1     | FIFO empty flag                          |
| fifo_full         | 1     | FIFO full flag                           |
| fifo_count        | 8     | Current FIFO entry count                 |
| fifo_overflow     | 1     | Overflow event pulse                     |
| fifo_underflow    | 1     | Underflow event pulse                    |

## Timing Diagram

```
                 ___     ___     ___     ___     ___
    clk      ___|   |___|   |___|   |___|   |___|   |___
                     _______
    wen      _______|       |_______________________________
                     _______
    addr     XXXXXXX|  0x00 |XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                     _______
    wdata    XXXXXXX| 0x001 |XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  (Enable FIFO)
                             _______________________________
    fifo_enable ____________|
```

## Implementation Notes

1. All registers are 32-bit aligned
2. Read of undefined addresses returns 0
3. Write to read-only registers is ignored
4. The CLEAR bit is self-clearing (write 1, automatically returns to 0)
5. Overflow/Underflow bits are sticky and require W1C (write-1-to-clear)

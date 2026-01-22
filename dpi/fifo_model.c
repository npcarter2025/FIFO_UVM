//-----------------------------------------------------------------------------
// File: fifo_model.c
// Description: DPI-C FIFO reference model for verification
//              Provides a golden model to compare against the DUT
//-----------------------------------------------------------------------------

#include "svdpi.h"
#include <string.h>
#include <stdio.h>

#define MAX_DEPTH 256

// FIFO state
static unsigned char fifo_mem[MAX_DEPTH];
static int head = 0;
static int tail = 0;
static int count = 0;
static int depth = 16;
static int overflow_flag = 0;
static int underflow_flag = 0;

//-----------------------------------------------------------------------------
// c_fifo_init: Initialize the FIFO model
//-----------------------------------------------------------------------------
void c_fifo_init(int fifo_depth) {
    if (fifo_depth > MAX_DEPTH) {
        fifo_depth = MAX_DEPTH;
    }
    depth = fifo_depth;
    head = 0;
    tail = 0;
    count = 0;
    overflow_flag = 0;
    underflow_flag = 0;
    memset(fifo_mem, 0, sizeof(fifo_mem));
}

//-----------------------------------------------------------------------------
// c_fifo_push: Push data to FIFO
// Returns: 0 on success, -1 on overflow
//-----------------------------------------------------------------------------
int c_fifo_push(unsigned char data) {
    if (count >= depth) {
        overflow_flag = 1;
        return -1;  // Overflow
    }
    fifo_mem[tail] = data;
    tail = (tail + 1) % depth;
    count++;
    return 0;
}

//-----------------------------------------------------------------------------
// c_fifo_pop: Pop data from FIFO
// Returns: data byte (0xFF if empty, sets underflow flag)
//-----------------------------------------------------------------------------
unsigned char c_fifo_pop(void) {
    if (count <= 0) {
        underflow_flag = 1;
        return 0xFF;  // Underflow indicator
    }
    unsigned char data = fifo_mem[head];
    head = (head + 1) % depth;
    count--;
    return data;
}

//-----------------------------------------------------------------------------
// c_fifo_count: Get current number of entries
//-----------------------------------------------------------------------------
int c_fifo_count(void) {
    return count;
}

//-----------------------------------------------------------------------------
// c_fifo_is_empty: Check if FIFO is empty
//-----------------------------------------------------------------------------
int c_fifo_is_empty(void) {
    return (count == 0) ? 1 : 0;
}

//-----------------------------------------------------------------------------
// c_fifo_is_full: Check if FIFO is full
//-----------------------------------------------------------------------------
int c_fifo_is_full(void) {
    return (count >= depth) ? 1 : 0;
}

//-----------------------------------------------------------------------------
// c_fifo_almost_full: Check if count >= threshold
//-----------------------------------------------------------------------------
int c_fifo_almost_full(int threshold) {
    return (count >= threshold) ? 1 : 0;
}

//-----------------------------------------------------------------------------
// c_fifo_clear: Clear the FIFO
//-----------------------------------------------------------------------------
void c_fifo_clear(void) {
    head = 0;
    tail = 0;
    count = 0;
    // Note: overflow/underflow flags are sticky, not cleared
}

//-----------------------------------------------------------------------------
// c_fifo_peek: Peek at data without removing (for debug)
// Returns: data at index from head, or 0xFF if invalid
//-----------------------------------------------------------------------------
unsigned char c_fifo_peek(int index) {
    if (index < 0 || index >= count) {
        return 0xFF;
    }
    return fifo_mem[(head + index) % depth];
}

//-----------------------------------------------------------------------------
// c_fifo_get_overflow: Get and clear overflow flag
//-----------------------------------------------------------------------------
int c_fifo_get_overflow(void) {
    int flag = overflow_flag;
    overflow_flag = 0;
    return flag;
}

//-----------------------------------------------------------------------------
// c_fifo_get_underflow: Get and clear underflow flag
//-----------------------------------------------------------------------------
int c_fifo_get_underflow(void) {
    int flag = underflow_flag;
    underflow_flag = 0;
    return flag;
}

//-----------------------------------------------------------------------------
// c_fifo_dump: Debug function to print FIFO contents
//-----------------------------------------------------------------------------
void c_fifo_dump(void) {
    printf("[C Model] FIFO State: depth=%d, count=%d, head=%d, tail=%d\n",
           depth, count, head, tail);
    printf("[C Model] Contents: ");
    for (int i = 0; i < count; i++) {
        printf("0x%02X ", fifo_mem[(head + i) % depth]);
    }
    printf("\n");
}

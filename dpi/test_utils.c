//-----------------------------------------------------------------------------
// File: test_utils.c
// Description: DPI-C utility functions for test stimulus generation
//-----------------------------------------------------------------------------

#include "svdpi.h"
#include <stdlib.h>
#include <string.h>
#include <time.h>

static int seeded = 0;

//-----------------------------------------------------------------------------
// c_seed_random: Initialize random seed
// seed=0 uses time-based seed, otherwise uses provided seed
//-----------------------------------------------------------------------------
void c_seed_random(int seed) {
    if (seed == 0) {
        srand((unsigned int)time(NULL));
    } else {
        srand((unsigned int)seed);
    }
    seeded = 1;
}

//-----------------------------------------------------------------------------
// c_random_byte: Generate a random byte
//-----------------------------------------------------------------------------
unsigned char c_random_byte(void) {
    if (!seeded) {
        c_seed_random(0);
    }
    return (unsigned char)(rand() % 256);
}

//-----------------------------------------------------------------------------
// c_random_range: Generate random number in range [min, max]
//-----------------------------------------------------------------------------
int c_random_range(int min, int max) {
    if (!seeded) {
        c_seed_random(0);
    }
    if (max <= min) return min;
    return min + (rand() % (max - min + 1));
}

//-----------------------------------------------------------------------------
// c_generate_incrementing: Generate incrementing pattern
//-----------------------------------------------------------------------------
void c_generate_incrementing(unsigned char* data, int size, unsigned char start) {
    for (int i = 0; i < size; i++) {
        data[i] = (unsigned char)((start + i) % 256);
    }
}

//-----------------------------------------------------------------------------
// c_generate_decrementing: Generate decrementing pattern
//-----------------------------------------------------------------------------
void c_generate_decrementing(unsigned char* data, int size, unsigned char start) {
    for (int i = 0; i < size; i++) {
        data[i] = (unsigned char)((start - i) % 256);
    }
}

//-----------------------------------------------------------------------------
// c_generate_walking_ones: Generate walking ones pattern
//-----------------------------------------------------------------------------
void c_generate_walking_ones(unsigned char* data, int size) {
    for (int i = 0; i < size; i++) {
        data[i] = (unsigned char)(1 << (i % 8));
    }
}

//-----------------------------------------------------------------------------
// c_generate_walking_zeros: Generate walking zeros pattern
//-----------------------------------------------------------------------------
void c_generate_walking_zeros(unsigned char* data, int size) {
    for (int i = 0; i < size; i++) {
        data[i] = (unsigned char)(~(1 << (i % 8)));
    }
}

//-----------------------------------------------------------------------------
// c_generate_alternating: Generate alternating pattern (0xAA, 0x55, ...)
//-----------------------------------------------------------------------------
void c_generate_alternating(unsigned char* data, int size) {
    for (int i = 0; i < size; i++) {
        data[i] = (i % 2 == 0) ? 0xAA : 0x55;
    }
}

//-----------------------------------------------------------------------------
// c_generate_random: Fill array with random data
//-----------------------------------------------------------------------------
void c_generate_random(unsigned char* data, int size) {
    if (!seeded) {
        c_seed_random(0);
    }
    for (int i = 0; i < size; i++) {
        data[i] = (unsigned char)(rand() % 256);
    }
}

//-----------------------------------------------------------------------------
// c_calculate_checksum: XOR checksum of data
//-----------------------------------------------------------------------------
unsigned char c_calculate_checksum(const unsigned char* data, int size) {
    unsigned char sum = 0;
    for (int i = 0; i < size; i++) {
        sum ^= data[i];
    }
    return sum;
}

//-----------------------------------------------------------------------------
// c_calculate_sum: Arithmetic sum (mod 256)
//-----------------------------------------------------------------------------
unsigned char c_calculate_sum(const unsigned char* data, int size) {
    unsigned int sum = 0;
    for (int i = 0; i < size; i++) {
        sum += data[i];
    }
    return (unsigned char)(sum % 256);
}

//-----------------------------------------------------------------------------
// c_compare_arrays: Compare two arrays
// Returns: number of mismatches
//-----------------------------------------------------------------------------
int c_compare_arrays(const unsigned char* a, const unsigned char* b, int size) {
    int mismatches = 0;
    for (int i = 0; i < size; i++) {
        if (a[i] != b[i]) {
            mismatches++;
        }
    }
    return mismatches;
}

//-----------------------------------------------------------------------------
// c_find_pattern: Find first occurrence of pattern in data
// Returns: index of match, or -1 if not found
//-----------------------------------------------------------------------------
int c_find_pattern(const unsigned char* data, int data_size,
                   const unsigned char* pattern, int pattern_size) {
    if (pattern_size > data_size) return -1;
    
    for (int i = 0; i <= data_size - pattern_size; i++) {
        int match = 1;
        for (int j = 0; j < pattern_size; j++) {
            if (data[i + j] != pattern[j]) {
                match = 0;
                break;
            }
        }
        if (match) return i;
    }
    return -1;
}

//-----------------------------------------------------------------------------
// c_reverse_array: Reverse array in place
//-----------------------------------------------------------------------------
void c_reverse_array(unsigned char* data, int size) {
    for (int i = 0; i < size / 2; i++) {
        unsigned char temp = data[i];
        data[i] = data[size - 1 - i];
        data[size - 1 - i] = temp;
    }
}

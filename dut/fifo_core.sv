//-----------------------------------------------------------------------------
// Module: fifo_core
// Description: Synchronous FIFO with register-controlled enable/clear
//              and status outputs for register integration
//-----------------------------------------------------------------------------

module fifo_core #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // Control inputs from register module
    input  logic                    fifo_enable,
    input  logic                    fifo_clear,
    input  logic [$clog2(DEPTH):0]  almost_full_thresh,

    // Status outputs to register module
    output logic                    fifo_empty,
    output logic                    fifo_full,
    output logic [$clog2(DEPTH):0]  fifo_count,
    output logic                    fifo_overflow,
    output logic                    fifo_underflow,

    // Data interface (active-high reset style for backward compatibility)
    input  bit                      is_write,
    input  logic                    sel,

    // Write Signals
    input  logic                    w_enable,
    input  logic [WIDTH-1:0]        w_data,
    output logic                    w_ready,

    // Read Signals
    output logic                    r_enable,
    output logic [WIDTH-1:0]        r_data,
    input  logic                    r_ready
);

    //-------------------------------------------------------------------------
    // Internal Signals
    //-------------------------------------------------------------------------
    logic [WIDTH-1:0]               memory [DEPTH-1:0];
    logic [$clog2(DEPTH)-1:0]       r_ptr, w_ptr;
    logic [$clog2(DEPTH):0]         count;  // Extra bit to represent DEPTH

    logic r_fire, w_fire;
    logic effective_enable;

    //-------------------------------------------------------------------------
    // Control Logic
    //-------------------------------------------------------------------------
    // FIFO is operational only when enabled via registers AND sel is high
    assign effective_enable = fifo_enable & sel;

    // Status outputs
    assign fifo_empty = (count == 0);
    assign fifo_full  = (count >= DEPTH);
    assign fifo_count = count;

    // Ready/valid signals
    assign w_ready   = fifo_enable && (count < DEPTH);
    assign r_enable  = fifo_enable && (count > 0);

    // Fire conditions
    assign w_fire = effective_enable && w_enable && w_ready;
    assign r_fire = effective_enable && r_enable && r_ready;

    // Read data output
    assign r_data = memory[r_ptr];

    //-------------------------------------------------------------------------
    // Error Detection
    //-------------------------------------------------------------------------
    // Overflow: write attempted when full
    assign fifo_overflow  = effective_enable && w_enable && fifo_full;
    // Underflow: read attempted when empty
    assign fifo_underflow = effective_enable && r_ready && fifo_empty;

    //-------------------------------------------------------------------------
    // Sequential Logic
    //-------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Async reset
            for (int i = 0; i < DEPTH; i++) begin
                memory[i] <= '0;
            end
            r_ptr <= '0;
            w_ptr <= '0;
            count <= '0;
        end else if (fifo_clear) begin
            // Software-triggered clear
            for (int i = 0; i < DEPTH; i++) begin
                memory[i] <= '0;
            end
            r_ptr <= '0;
            w_ptr <= '0;
            count <= '0;
        end else if (effective_enable) begin
            // Normal operation
            if (w_fire) begin
                memory[w_ptr] <= w_data;
                w_ptr <= (w_ptr + 1) % DEPTH;
            end

            if (r_fire) begin
                r_ptr <= (r_ptr + 1) % DEPTH;
            end

            // Update count
            if (w_fire && !r_fire) begin
                count <= count + 1;
            end else if (r_fire && !w_fire) begin
                count <= count - 1;
            end
            // If both fire, count stays the same
        end
    end

endmodule

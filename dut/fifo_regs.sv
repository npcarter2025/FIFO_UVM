//-----------------------------------------------------------------------------
// Module: fifo_regs
// Description: Register interface module for FIFO control and status
//
// Register Map:
//   0x00 - CTRL   (RW)  : Control register [0]=enable, [1]=clear(self-clearing)
//   0x04 - STATUS (RO)  : Status register
//   0x08 - THRESH (RW)  : Almost-full threshold
//-----------------------------------------------------------------------------

module fifo_regs #(
    parameter DEPTH     = 16,
    parameter WIDTH     = 8,
    parameter ADDR_W    = 8,
    parameter DATA_W    = 32
)(
    input  logic                clk,
    input  logic                rst_n,

    // Bus Interface
    input  logic [ADDR_W-1:0]   addr,
    input  logic [DATA_W-1:0]   wdata,
    output logic [DATA_W-1:0]   rdata,
    input  logic                wen,
    input  logic                ren,
    output logic                ready,

    // Control outputs to FIFO core
    output logic                fifo_enable,
    output logic                fifo_clear,
    output logic [$clog2(DEPTH):0] almost_full_thresh,

    // Status inputs from FIFO core
    input  logic                fifo_empty,
    input  logic                fifo_full,
    input  logic [$clog2(DEPTH):0] fifo_count,
    input  logic                fifo_overflow,
    input  logic                fifo_underflow
);

    //-------------------------------------------------------------------------
    // Register Address Definitions
    //-------------------------------------------------------------------------
    localparam ADDR_CTRL   = 8'h00;
    localparam ADDR_STATUS = 8'h04;
    localparam ADDR_THRESH = 8'h08;

    //-------------------------------------------------------------------------
    // Register Storage
    //-------------------------------------------------------------------------
    // CTRL register bits
    logic        reg_ctrl_enable;
    logic        reg_ctrl_clear;

    // THRESH register
    logic [$clog2(DEPTH):0] reg_thresh;

    // STATUS register (sticky error bits)
    logic        reg_overflow_sticky;
    logic        reg_underflow_sticky;

    // Derived status signals
    logic        almost_full;

    //-------------------------------------------------------------------------
    // Combinational Logic
    //-------------------------------------------------------------------------

    // Always ready (single-cycle access)
    assign ready = 1'b1;

    // Control outputs
    assign fifo_enable       = reg_ctrl_enable;
    assign fifo_clear        = reg_ctrl_clear;
    assign almost_full_thresh = reg_thresh;

    // Almost full comparison
    assign almost_full = (fifo_count >= reg_thresh);

    //-------------------------------------------------------------------------
    // Read Data Mux
    //-------------------------------------------------------------------------
    always_comb begin
        rdata = '0;
        if (ren) begin
            case (addr)
                ADDR_CTRL: begin
                    rdata[0] = reg_ctrl_enable;
                    rdata[1] = reg_ctrl_clear;  // Will typically read as 0 (self-clearing)
                end
                ADDR_STATUS: begin
                    rdata[0]    = fifo_empty;
                    rdata[1]    = fifo_full;
                    rdata[2]    = almost_full;
                    rdata[3]    = reg_overflow_sticky;
                    rdata[4]    = reg_underflow_sticky;
                    rdata[15:8] = {{(8-$clog2(DEPTH)-1){1'b0}}, fifo_count};
                end
                ADDR_THRESH: begin
                    rdata[$clog2(DEPTH):0] = reg_thresh;
                end
                default: begin
                    rdata = '0;
                end
            endcase
        end
    end

    //-------------------------------------------------------------------------
    // Register Write Logic
    //-------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset values
            reg_ctrl_enable     <= 1'b0;
            reg_ctrl_clear      <= 1'b0;
            reg_thresh          <= DEPTH - 1;  // Default: almost full at DEPTH-1
            reg_overflow_sticky <= 1'b0;
            reg_underflow_sticky<= 1'b0;
        end else begin
            // Self-clearing: CLEAR bit always clears after one cycle
            if (reg_ctrl_clear) begin
                reg_ctrl_clear <= 1'b0;
            end

            // Capture overflow/underflow events (sticky)
            if (fifo_overflow) begin
                reg_overflow_sticky <= 1'b1;
            end
            if (fifo_underflow) begin
                reg_underflow_sticky <= 1'b1;
            end

            // Register writes
            if (wen) begin
                case (addr)
                    ADDR_CTRL: begin
                        reg_ctrl_enable <= wdata[0];
                        reg_ctrl_clear  <= wdata[1];  // Will self-clear next cycle
                    end
                    ADDR_STATUS: begin
                        // W1C for sticky error bits
                        if (wdata[3]) reg_overflow_sticky  <= 1'b0;
                        if (wdata[4]) reg_underflow_sticky <= 1'b0;
                    end
                    ADDR_THRESH: begin
                        reg_thresh <= wdata[$clog2(DEPTH):0];
                    end
                    default: ; // Ignore writes to undefined addresses
                endcase
            end
        end
    end

endmodule

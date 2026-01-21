

module fifo#(DEPTH=16, WIDTH=8)(
    input logic clk,
    input logic rst,

    input bit is_write,
    input logic sel,

    // Write Signals
    input logic w_enable,
    input logic [WIDTH-1:0] w_data,
    output logic w_ready,

    // Read Signals
    output logic r_enable,
    output logic [7:0] r_data,
    input logic r_ready

);

    logic [7:0] memory [DEPTH-1:0];
    logic [$clog2(DEPTH)-1:0] r_ptr, w_ptr;
    logic [$clog2(DEPTH)-1:0] count;

    logic r_fire, w_fire;

    assign w_ready = (count <= DEPTH);
    assign r_enable = (count > 0);

    assign w_fire = (w_enable && w_ready);
    assign r_fire = (r_enable && r_ready);

    assign r_data = memory[r_ptr];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < DEPTH; i++) begin
                memory[i] <= 'b0;
            end
            r_ptr <= 0;
            w_ptr <= 0;
            count <= 0;

        end else if (sel) begin

            if (w_fire) begin
                memory[w_ptr] <= w_data;
                w_ptr <= (w_ptr + 1) % DEPTH;
            end

            if (r_fire) begin
                r_ptr <= (r_ptr + 1) % DEPTH;

            end

            if (w_fire && ~r_fire) begin
                count <= count + 1;
            end
            if (r_fire && ~w_fire) begin
                count <= count - 1;

            end

        end

    end

endmodule

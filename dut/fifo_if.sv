
interface fifo_if #(
    parameter WIDTH=8, 
    DEPTH=16
)(   
    input logic clk, 
    input logic rst
);

    bit                 is_write;
    logic               sel;

    logic               w_enable;
    logic [WIDTH-1:0]   w_data;
    logic               w_ready;

    logic               r_enable;
    logic [WIDTH-1:0]   r_data;
    logic               r_ready;


    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;
        output sel, is_write, w_enable, w_data, r_ready;
        input w_ready, r_enable, r_data;
    endclocking


    clocking mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input sel, is_write, w_enable, w_data, w_ready, r_enable, r_data, r_ready;
    endclocking

    modport DRV (clocking drv_cb, input clk);
    
    modport MON (clocking mon_cb, input clk);

endinterface

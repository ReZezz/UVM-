`timescale 1ns/1ps
`include "uvm_macros.svh"

import uvm_pkg::*;
`include "my_driver.sv"

module top_tb;

reg                    clk;
reg                    rst_n;
reg       [7:0]        rxd;
reg                    rxd_dv;
wire      [7:0]        txd;
wire                   txd_en;

dut my_dut(
    .clk     (clk),
    .rst_n   (rst_n),
    .rxd     (rxd),
    .rxd_dv  (rxd_dv),
    .txd     (txd),
    .txd_en  (txd_en)
);

initial begin                                        //三个initial是并行运行的
    clk = 0;
    forever begin
        #100 clk = ~clk;
    end
end

initial begin
    rst_n = 1'b0;
    #1000;
    rst_n = 1'b1;
end

initial begin
    run_test("my_driver");                           //由于加入了factory机制，所以不需要再对my_driver做实例化，也不需要对main_phase显式调用了,同时也没有显示调用finish语句结束仿真
end

endmodule
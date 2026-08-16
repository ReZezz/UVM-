`timescale  1ns/1ps
`include "uvm_macros.svh"

import uvm_pkg::*;
`include "my_driver.sv"

module top_tb;

reg clk;
reg rst_n;
reg [7:0] rxd;
reg rxd_dv;
wire [7:0] txd;
wire txd_en;

dut my_dut(
    .clk    (clk),                       //括号里的是top的clk
    .rst_n  (rst_n),
    .rxd    (rxd),
    .rxd_dv (rxd_dv),
    .txd    (txd),
    .txd_en (txd_en)
);

initial begin                            //三个initial是并行同时运行的
    my_driver drv;
    drv = new(drv, null);
    drv.main_phase(null);                //main_phase对top的变量操作，而top的变量与dut的变量连接了起来
    $finish();
end

initial begin
    clk = 0;
    forever begin
        #100 clk = ~clk;
    end
end

initial begin
    rst_n = 1'b0;                        //rst_n是低有效复位，当rst_n=0时表示按下了复位键，=1时表示松开了复位键
    #1000;
    rst_n = 1'b1;
end

endmodule
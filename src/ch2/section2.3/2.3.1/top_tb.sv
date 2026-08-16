`timescale 1ns/1ps
`include "uvm_macros.svh"
`include "my_transaction.sv"
`include "my_driver.sv"
`include "my_if.sv"
import uvm_pkg::*;

module top_tb;

reg clk;
reg rst_n;
//reg [7:0] rxd;
//reg rxd_dv;
//reg [7:0] txd;
//reg txd_en;

my_if input_if(clk, rst_n);
my_if output_if(clk, rst_n);

dut my_dut(
    .clk     (clk),
    .rst_n   (rst_n),
    .rxd     (input_if.data),
    .rxd_dv  (input_if.valid),
    .txd     (output_if.data),
    .txd_en  (output_if.valid)
);

initial begin
    clk = 0;
    forever begin
        #100 clk = ~clk;
    end
end

initial begin
    rst_n = 0;
    #1000;
    rst_n = 1;
end

initial begin
    run_test("my_driver");
end

initial begin
    uvm_config_db # (virtual my_if)::set(null, "uvm_test_top", "vif", input_if);
end

endmodule
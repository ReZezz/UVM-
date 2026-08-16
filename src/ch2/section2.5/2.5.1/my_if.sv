`ifndef MY_IF_SV
`define MY_IF_SV

interface my_if(input clk, input rst_n);

    logic [7:0] data;
    logic       valid;
endinterface
`endif
`ifndef MY_IF_SV
`define MY_IF_SV

interface my_if(input clk, input rst_n);         //两个input是interface需要的信号，interface没办法自己产生时钟和复位信号，
                                                 //需要外部传入,使interface内部的信号同步在clk时钟下、让模块、测试台、接口 共用同一个时钟和复位
    logic [7: 0] data;                           //这里没有写input或者output，interface里的信号默认的方向是inout，是双向的
    logic        valid;
endinterface
`endif
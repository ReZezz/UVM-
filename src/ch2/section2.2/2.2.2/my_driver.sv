`ifndef MY_DRIVER_SV
`define MY_DRIVER_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
class my_driver extends uvm_driver;

    `uvm_component_utils(my_driver)                                //加入了factory机制,无需实例以及显式调用main_phase
    function new(string name = "my_driver", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("my_driver", "new is called", UVM_LOW);
    endfunction
        extern virtual task main_phase(uvm_phase phase);           //extern是关键词，表示这个任务具体代码没在类的内部，而是在外部。
endclass                                                           //virtual关键字，表示这个任务可以被子类重写

task my_driver::main_phase(uvm_phase phase);                       //::是明确方法、变量等属于哪个类，这里是说main_phase属于my_driver类，由于前面类里的
    `uvm_info("my_driver", "main_phase is called", UVM_LOW);       //任务用了extern，要把具体代码写在外面，也就是写在这里，如果不写::，这里的任务会被当成全局任务然后报错
    top_tb.rxd <= 8'b0;
    top_tb.rxd_dv <= 1'b0;
    while(!top_tb.rst_n)
        @(posedge top_tb.clk);
    for(int i = 0; i < 256; i++)begin
        @(posedge top_tb.clk);
        top_tb.rxd <= $urandom_range(0, 255);
        top_tb.rxd_dv <= 1'b1;
        `uvm_info("my_driver", "data is drived", UVM_LOW);
    end
    @(posedge top_tb.clk);
    top_tb.rxd_dv <= 1'b0;
endtask
`endif                                                             //对ifndef的end
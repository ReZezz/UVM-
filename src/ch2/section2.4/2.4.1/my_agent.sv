`ifndef MY_AGENT_SV
`define MY_AGENT_SV
`include "my_driver.sv"
`include "my_monitor.sv"
`include "my_transaction.sv"
`include "my_sequencer.sv"
import uvm_pkg::*;

class my_agent extends uvm_agent;
    `uvm_component_utils(my_agent)
    my_sequencer sqr;
    my_driver drv;
    my_monitor mon;

    uvm_analysis_port # (my_transaction) ap;                             //创建一个端口句柄

    function new(string name, uvm_component parent);                     //本身是component
        super.new(name, parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
endclass

function void my_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(is_active == UVM_ACTIVE)begin                                     //当is_active的值为UVM_ACTIVE时，该模式下才实例化driver，如果是UVM_PASSIVE，则不实例化driver
        sqr = my_sequencer::type_id::create("sqr",this);
        drv = my_driver::type_id::create("drv",this);
    end
    mon = my_monitor::type_id::create("mon",this);
endfunction
                                                                         //connect_phase是uvm内建的phase，在build_phase完成之后立马执行，执行顺序是从树叶到树根
function void my_agent::connect_phase(uvm_phase phase);                  //在agent内部，将monitor的端口连接到agent的外壳端口上
    super.connect_phase(phase);
    ap = mon.ap;                                                         //把agent内部的monitor的端口连接到agent的ap端口，防止env直接把手伸进agent里面找transaction数据
endfunction                                                              //这样做的好处是agent内部的monitor的端口和reference model的端口进行通信时，不需要env直接把手伸进
                                                                         //agent内部找数据，所以不需要env知道agent内部细节。保护了封装，降低了耦合度
`endif                                                                   //这里相当于只创建了ap句柄，没有创建实例，只是把monitor的值赋给它，相当于是指向monitor.ap的指针
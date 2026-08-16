`ifndef MY_AGENT_SV
`define MY_AGENT_SV
`include "my_driver.sv"
`include "my_monitor.sv"
import uvm_pkg::*;

class my_agent extends uvm_agent;
    `uvm_component_utils(my_agent)
    my_driver drv;
    my_monitor mon;
    function new(string name, uvm_component parent);                     //本身是component
        super.new(name, parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
endclass

function void my_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(is_active == UVM_ACTIVE)begin                                     //当is_active的值为UVM_ACTIVE时，该模式下才实例化driver，如果是UVM_PASSIVE，则不实例化driver
        drv = my_driver::type_id::create("drv",this);
    end
    mon = my_monitor::type_id::create("mon",this);
endfunction

function void my_agent::connect_phase(uvm_phase phase);                  //目前只是占位样板，没做实质性连接动作
    super.connect_phase(phase);
endfunction

`endif
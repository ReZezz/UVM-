`ifndef MY_SEQUENCER_SV
`define MY_SEQUENCER_SV
`include "my_transaction.sv"

class my_sequencer extends uvm_sequencer #(my_transaction);                 //#(my_transaction)表示sequencer是一个参数化的类，表示这个类要处理的
                                                                            //数据类型是my_transaction
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    `uvm_component_utils(my_sequencer)
endclass

`endif
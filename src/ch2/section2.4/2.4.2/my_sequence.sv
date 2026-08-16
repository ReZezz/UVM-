`ifndef MY_SEQUENCE_SV
`define MY_SEQUENCE_SV
`include "my_transaction.sv"

class my_sequence extends uvm_sequence # (my_transaction);
    my_transaction m_trans;

    function new(string name = "my_sequence");
        super.new(name);
    endfunction

    virtual task body();                                             //每一个sequence都有一个body任务
        repeat (10) begin                                            //重复调用uvm_do宏十次，发十个包
            `uvm_do(m_trans);                                        //uvm_do宏用于创建一个my_transaction实例、将其随机化、并最终传给sequencer
        end
        #1000;
    endtask

    `uvm_object_utils(my_sequence)
endclass

`endif
`ifndef MY_SEQUENCE_SV
`define MY_SEQUENCE_SV
`include "my_transaction.sv"

class my_sequence extends uvm_sequence # (my_transaction);
    my_transaction m_trans;

    function new(string name = "my_sequence");
        super.new(name);
    endfunction

    virtual task body();                                             //每一个sequence都有一个body任务
        if(starting_phase != null)                                   //starting_phase != null表示此时sequencer把main_phase的通行证复制了一份给sequence的starting_phase变量
                                                                     //也就是说代码运行到了uvm_config_db#(uvm_object_wrapper)::set（）...此时sequence被default_sequence启动了
            starting_phase.raise_objection(this);                    //raise_objection是告诉仿真器不要结束当前的phase，不是启动sequence
        repeat (10) begin                                            //重复调用uvm_do宏十次，发十个包
            `uvm_do(m_trans);                                        //uvm_do宏用于创建一个my_transaction实例、将其随机化、并最终传给sequencer
        end
        #1000;
        if(starting_phase != null)
            starting_phase.drop_objection(this);
    endtask

    `uvm_object_utils(my_sequence)
endclass

`endif
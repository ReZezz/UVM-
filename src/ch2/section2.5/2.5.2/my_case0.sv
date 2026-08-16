`ifndef MY_CASE0_SV
`define MY_CASE0_SV
`include "my_transaction.sv"
`include "base_test.sv"

class case0_sequence extends uvm_sequence#(my_transaction);
    my_transaction m_trans;

    function new(string name = "case0_sequence");
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

    `uvm_object_utils(case0_sequence)
endclass

class my_case0 extends base_test;                                    //这里继承的是base_test!!!不是uvm_test，base_test里面有env的实例化

    function new(string name = "my_case0", uvm_component parent = null);
        super.new(name, parent);                                     //父类base_test里面有report
    endfunction
    extern virtual function void build_phase(uvm_phase phase);
    `uvm_component_utils(my_case0);
endclass

function void my_case0::build_phase(uvm_phase phase);
    super.build_phase(phase);                                        //这里是执行父类的build_phase，也就是base_test的build_phase，里面创建了env的实例

    uvm_config_db#(uvm_object_wrapper)::set(this,
                                    "env.i_agt.sqr.main_phase",
                                    "default_sequence",
                                    case0_sequence::type_id::get());
    $display("this is case0!!!");
endfunction

`endif 
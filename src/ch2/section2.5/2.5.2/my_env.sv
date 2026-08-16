`ifndef MY_ENV_SV
`define MY_ENV_SV
`include "my_agent.sv"
`include "my_model.sv"
`include "my_scoreboard.sv"
//`include "my_sequence.sv"

import uvm_pkg::*;

class my_env extends uvm_env;

    my_agent i_agt;                                                   //创建一个my_agent类的句柄i_agt 
    my_agent o_agt;                                                   //创建一个my_agent类的句柄o_agt
    my_model mdl;                                                     //创建一个my_model类的句柄mdl
    my_scoreboard scb;                                                //创建一个my_scoreboard类的句柄scb

    uvm_tlm_analysis_fifo # (my_transaction) agt_mdl_fifo;            //创建一个fifo句柄,这样命名表示该fifo连接agent和reference model
                                                                      //使用fifo而不是直接将agent和reference model连接起来是因为analysis_port是非阻塞性质的，在ap.write
                                                                      //函数调用完成之后马上返回，如果这时候blocking_get_port正在忙其他事情，此时就需要把这个tr暂存在fifo中
    uvm_tlm_analysis_fifo # (my_transaction) agt_scb_fifo;
    uvm_tlm_analysis_fifo # (my_transaction) mdl_scb_fifo;

    function new(string name = "my_env", uvm_component parent);       //这里uvm_component parent的参数为null，因为super.new(name, parent);是创建父类，其中创建的
        super.new(name, parent);                                      //父类的name是my_env(父类获取了子类的参数)，而父类没有从子类获得到uvm_component parent，所以
    endfunction                                                       //父类的这个参数是默认值null(uvm库决定的)，而子类没给参数就默认继承父类的参数null
                                                                   
    virtual function void build_phase(uvm_phase phase);               //uvm的创建阶段,此时有两个build_phase，执行顺序是先执行树根my_env的build_phase，再执行树叶
        super.build_phase(phase);                                     //my_driver的build_phase。就是从上往下执行，所有的build_phase都执行完之后再执行其他phase
        i_agt = my_agent::type_id::create("i_agt",this);              //调用uvm自动创建一个my_agent的实例名字叫i_agt，父节点是this指针指向的my_env
        o_agt = my_agent::type_id::create("o_agt",this);              //调用uvm自动创建一个my_agent的实例名字叫o_agt，父节点是this指针指向的my_env
        i_agt.is_active = UVM_ACTIVE;                                 //设置dut的输入接口的monitor的模式为active，即需要实例化my_driver
        o_agt.is_active = UVM_PASSIVE;                                //设置dut的输出接口的monitor的模式为passive，即不需要实例化my_driver
        mdl = my_model::type_id::create("mdl", this);                 //创建一个reference model实例
        scb = my_scoreboard::type_id::create("scb", this);            //创建一个scoreboard实例
        agt_scb_fifo = new("agt_scb_fifo", this);                     //创建一个agt_scb_fifo实例
        mdl_scb_fifo = new("mdl_scb_fifo", this);                     //创建一个mdl_scb_fifo实例
        agt_mdl_fifo = new("agt_mdl_fifo", this);                     //创建一个agt_mdl_fifo实例
    endfunction                                                       //以上代码只能在build_phase里运行，不能改成main_phase或者其他phase，否则会报错

    extern virtual function void connect_phase(uvm_phase phase);
//    extern virtual task main_phase(uvm_phase phase);                //既然已经使用default_sequence自动启动sequence了，那么也就不需要手动启动sequence了

    `uvm_component_utils(my_env)                                      //factory机制，不需要显式生成实例,这行代码对位置不挑剔，放在class定义的前面、后面无论哪里都没关系
endclass

function void my_env::connect_phase(uvm_phase phase);                 //连接i_agt中的monitor和reference model的transaction
    super.connect_phase(phase);
    i_agt.ap.connect(agt_mdl_fifo.analysis_export);                   //连接i_agent发送端和fifo（agt_mdl_fifo）
    mdl.port.connect(agt_mdl_fifo.blocking_get_export);               //连接model接收端和fifo（agt_mdl_fifo）,总的来说就是把i_agent和model连起来了，用来发期望数据

    mdl.ap.connect(mdl_scb_fifo.analysis_export);                     //连接model发送端和fifo(mdl_scb_fifo)
    scb.exp_port.connect(mdl_scb_fifo.blocking_get_export);           //连接scoreboard的接收端和fifo(mdl_scb_fifo)，总的来说就是把model和scoreboard连接起来了
                                                                      //上面两对连接总体上说就是：i_agent-->reference model-->scoreboard，这条路传输的是期望值
    o_agt.ap.connect(agt_scb_fifo.analysis_export);                   //连接o_agt的发送端和fifo(agt_scb_fifo)
    scb.act_port.connect(agt_scb_fifo.blocking_get_export);           //连接scoreboard的接收端和fifo(agt_scb_fifo)，总的来说是把o_agt和scoreboard连接起来，这条路传输的是实际值
endfunction


`endif
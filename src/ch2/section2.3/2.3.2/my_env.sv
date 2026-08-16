`ifndef MY_ENV_SV
`define MY_ENV_SV
`include "my_driver.sv"
import uvm_pkg::*;

class my_env extends uvm_env;

    my_driver drv;                                                    //创建一个my_driver的句柄drv

    function new(string name = "my_env", uvm_component parent);       //这里uvm_component parent的参数为null，因为super.new(name, parent);是创建父类，其中创建的
        super.new(name, parent);                                      //父类的name是my_env(父类获取了子类的参数)，而父类没有从子类获得到uvm_component parent，所以
    endfunction                                                       //父类的这个参数是默认值null(uvm库决定的)，而子类没给参数就默认继承父类的参数null

    virtual function void build_phase(uvm_phase phase);               //uvm的创建阶段,此时有两个build_phase，执行顺序是先执行树根my_env的build_phase，再执行树叶
        super.build_phase(phase);                                     //my_driver的build_phase。就是从上往下执行，所有的build_phase都执行完之后再执行其他phase
        drv = my_driver::type_id::create("drv", this);                 //调用uvm自动创建一个my_driver的实例名字叫drv，父节点是this指针指向的my_env
    endfunction

    `uvm_component_utils(my_env)                                      //factory机制，不需要显式生成实例,这行代码对位置不挑剔，放在class定义的前面、后面无论哪里都没关系
endclass

`endif
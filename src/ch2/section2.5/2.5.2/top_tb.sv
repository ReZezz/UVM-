`timescale 1ns/1ps
`include "uvm_macros.svh"

import uvm_pkg::*;
`include "my_driver.sv"
`include "my_if.sv"
`include "my_transaction.sv"
`include "my_env.sv"
`include "my_monitor.sv"
`include "my_agent.sv"
`include "base_test.sv"
`include "my_case1.sv"
`include "my_case0.sv"


module top_tb;

reg                    clk;
reg                    rst_n;
//reg       [7:0]        rxd;                        //interface已经接管了dut的除了clk和rst_n以外的所有信号，这行已经不需要了
//reg                    rxd_dv;                     //interface已经接管了dut的除了clk和rst_n以外的所有信号，这行已经不需要了
//wire      [7:0]        txd;                        //interface已经接管了dut的除了clk和rst_n以外的所有信号，这行已经不需要了
//wire                   txd_en;                     //interface已经接管了dut的除了clk和rst_n以外的所有信号，这行已经不需要了

my_if input_if(clk, rst_n);                          //输入方向的interface，用来连接dut的rxd和rxd_dv，clk和rst_n是参数
my_if output_if(clk, rst_n);                         //输出方向的interface，用来连接dut的txd和txd_en，clk和rst_n是参数
                                                     //interface是用于硬件世界，在top中可以直接调用
dut my_dut(
    .clk     (clk),
    .rst_n   (rst_n),
    .rxd     (input_if.data),
    .rxd_dv  (input_if.valid),
    .txd     (output_if.data),
    .txd_en  (output_if.valid)
);

initial begin                                        //三个initial是并行运行的
    clk = 0;
    forever begin
        #100 clk = ~clk;
    end
end

initial begin
    rst_n = 1'b0;
    #1000;
    rst_n = 1'b1;
end

initial begin                                        //加入base_test之后其成了树根，因此这里不再是my_env
    run_test();                                      //由于加入了factory机制，所以不需要做实例化，也不需要对main_phase显式调用了,同时也没有显示调用finish语句结束仿真
end
                                                     //一般都是top层用set，因为只有top层有真实的硬件地址，driver等uvm软件层是没有真实的硬件地址的
initial begin                                        //第一个参数null是父类，这里是top所以写null，"uvm_test_top"是run_test产生的实例，第三个参数可以理解成要传到哪里，第四个参数是要传的东西
    uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.i_agt.drv", "vif", input_if);//加入base_test之后树根不再是env而是base_test，所以，路径要改变
                                                     //uvm_config_db#(virtual my_if):我要传递的类型是：虚拟接口 my_if
                                                     //::set:我要发送数据     null:发送者是顶层（top），没有父节点，写 null,由于top_tb不是一个类，无法使用this指针，所以写null
                                                     //"uvm_test_top.i_agt.drv":接收的是test组件的i_agt的drv,也就是i_agt的drv实例
                                                     //"vif":给这个数据起个名字，叫vif   
                                                     //input_if:真正要传递的东西-真实的 interface 实例
//  uvm_config_db#(virtual my_if)::set(null, "uvm_test_top", "vif2", output_if);  //如果要传递两个参数的话
    uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.i_agt.mon", "vif", input_if);
    uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.o_agt.mon", "vif", output_if);
end

endmodule
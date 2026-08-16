`ifndef MY_MODEL_SV
`define MY_MODEL_SV
`include "my_transaction.sv"
import uvm_pkg::*;

class my_model extends uvm_component;
    `uvm_component_utils(my_model)
                                                                      //这里的port和ap是句柄，不是真正的端口实例
    uvm_blocking_get_port #(my_transaction) port;                     //定义一个阻塞式获取端口，名字叫做port，只能传my_transaction类型。定义好一个数据通道，等待数据
    uvm_analysis_port #(my_transaction) ap;                           //定义一个分析端口，名字叫做ap，只能传my_transaction类型。定义好一个数据通道，等待数据
                                                                      //uvm_blocking_get_port是uvm的transaction级别通信的数据接收方式之一
                                                                      //uvm_analysis_port是uvm的transaction级别通信的数据发送方式之一
    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
endclass

function my_model::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void my_model::build_phase(uvm_phase phase);
    super.build_phase(phase);
    port = new("port", this);                                         //创建port端口实例，用来拿数据
    ap = new("ap", this);                                             //创建ap端口实例
endfunction

task my_model::main_phase(uvm_phase phase);
    my_transaction tr;                                                //创建my_transaction实例tr，用来保存从monitor拿到的原始的数据
    my_transaction new_tr;                                            //my_transaction new_tr;，把原来的数据复制给它，发送给scoreboard
    super.main_phase(phase);                                          //这一句话必须在变量声明的后面不能写在第一行，不然会报错
    while(1)begin
        port.get(tr);                                                 //阻塞等待，一直等到monitor发一包数据，拿到后存进tr  tr是句柄，连接port端，不需要创建实例                                           
        new_tr = new("new_tr");                                       //创建一个新包
        new_tr.copy(tr);                                              //把tr复制给new_tr,使用uvm_field宏的函数完成，简化代码
        `uvm_info("my_model","get one transaction, copy and print it:", UVM_LOW);
        new_tr.print();                                               //打印new_tr的值，使用uvm_field宏的函数完成，简化代码
        ap.write(new_tr);                                             //把复制好的新包，发送出去，发送到任何地方，不管有没有接收
    end
endtask
`endif
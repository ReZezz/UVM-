`include "my_transaction.sv"                                                    //必须写在最前面，因为编译器是先编译MY_DRIVER_SV的话，class my_driver里面用了
`ifndef MY_DRIVER_SV                                                            //extern task drive_one_pkt(my_transaction tr)，已经用了my_transaction，会报错
`define MY_DRIVER_SV
import uvm_pkg::*;
`include "uvm_macros.svh"

class my_driver extends uvm_driver;

    virtual my_if vif;                                                          //由于driver是软件世界，无法直接用硬件世界的interface，所以需要使用virtual
//    virtual my_if vif2;                                                       //可以同时用多个config_db传参

    `uvm_component_utils(my_driver)                                             //加入了factory机制,无需实例以及显式调用main_phase
    function new(string name = "my_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);                         //拿interface的接口
        super.build_phase(phase);                                               //uvm_config_db # (virtual my_if)::get(this, "", "vif", vif)意思是
        if(!uvm_config_db # (virtual my_if)::get(this, "", "vif", vif))         //去config_db里拿名字叫做"vif"的virtual interface，放到自己的vif变量里                                                                                                                                                    
            `uvm_fatal("my_driver", "virtual interface must be set for vif!!!") //如果没有拿到，那就打印报错信息“virtual interface must be set for vif!!!”，并自动调用finish函数停止仿真                                                                        
    endfunction                                                                 //driver是数据发送方，但却是用的get指令是因为，config_db传送的不是数据而是硬件地址，driver要发给dut，但不知道dut
                                                                                //的硬件地址，所以需要接收来自top发送的dut硬件地址
    extern task main_phase(uvm_phase phase);                                    //extern是关键词，表示这个任务具体代码没在类的内部，而是在外部。
    extern task drive_one_pkt(my_transaction tr);                               //发送数据的任务，需要传入一个参数：参数类型是my_transaction，具体参数是tr
endclass                                                                        //virtual关键字，表示这个任务可以被子类重写
                                                                                //::是明确方法、变量等属于哪个类，这里是说main_phase属于my_driver类，由于前面类里的
task my_driver::main_phase(uvm_phase phase);                                    //任务用了extern，要把具体代码写在外面，也就是写在这里，如果不写::，这里的任务会被当成全局任务然后报错
    my_transaction tr;                                                          //创建一个可以指向my_transaction的句柄tr，uvm中不会直接操作对象，而是通过句柄来调用对象、访问对象的变量                                                      
    phase.raise_objection(this);                     
    vif.data <= 8'b0;
    vif.valid <= 1'b0;
    while(!vif.rst_n)                                                           //虽然clk和rst_n不是在interface中直接定义成logic，但是这两个信号也是存在于interface中的，可以通过vif.调用
        @(posedge vif.clk);                                                     //而且interface中的这两个信号可以当成logic类型，之所以写成input是因为这两个信号是需要从外部传入的
    for(int i = 0; i < 2; i++)begin
        tr = new("tr");                                                         //创建一个实例
        assert(tr.randomize() with {pload.size == 200;});                       //随机化这个数据包,自动生成 dmac、smac、ether_type、pload、crc,而且强制pload长度=200字节
        drive_one_pkt(tr);
    end
    repeat(5) @(posedge vif.clk);                                               //repeat(5)是把后面的一行语句重复五次，就是等待五个时钟周期
    phase.drop_objection(this);
endtask

task my_driver::drive_one_pkt(my_transaction tr);
    bit [47:0] tmp_data;
    bit [ 7:0] data_q[$];                                                       //[$]表示这是一个队列，且队列的每个元素的长度是8bit=1字节，这个队列的长度是不固定的，随时可以加随时、可以减

    tmp_data = tr.dmac;                                                         //把48=6x8的DMAC压入队列
    for(int i = 0; i < 6; i++)begin
        data_q.push_back(tmp_data[7:0]);                                        //push_back是队列的内置函数，把括号内的数据放到数列data_q的最高位
        tmp_data = (tmp_data >> 8);
    end

    tmp_data = tr.smac;                                                         //把48=6x8的SMAC压入队列
    for(int i = 0; i < 6; i++)begin
        data_q.push_back(tmp_data[7:0]);                                        //push_back是队列的内置函数，把括号内的数据放到数列data_q的最高位
        tmp_data = (tmp_data >> 8);
    end

    tmp_data = tr.ether_type;                                                   //把16=2x8的ether_type压入队列
    for(int i = 0; i < 2; i++)begin
        data_q.push_back(tmp_data[7:0]);                                        //push_back是队列的内置函数，把括号内的数据放到数列data_q的最高位
        tmp_data = (tmp_data >> 8);
    end

    for(int i = 0; i < tr.pload.size; i++)begin
        data_q.push_back(tr.pload[i]);                                          //由于pload的大小不固定，所以一位一位地把pload的数据放入data_q
    end

    tmp_data = tr.crc;                                                          //把32=4x8的ether_type压入队列
    for(int i = 0; i < 4; i++)begin
        data_q.push_back(tmp_data[7:0]);                                        //push_back是队列的内置函数，把括号内的数据放到数列data_q的最高位
        tmp_data = (tmp_data >> 8);
    end
    `uvm_info("my_driver", "begin to driver one_pkt", UVM_LOW);
    repeat(3) @(posedge vif.clk);                                               //等待三个时钟周期

    while (data_q.size() > 0)begin
        @(posedge vif.clk);
        vif.valid <= 1'b1;
        vif.data <= data_q.pop_front();                                         //把data_q的最前面的一个字节拿出来赋值给vif.data，并且把这个字节删除，由于data_q的
    end                                                                         //定义是bit [7:0] data_q[$]，所以data_q.pop_front()函数一次取出前面一个字节,这里的最前面是指最高位

    @(posedge vif.clk);
    vif.valid <= 1'b0;
    `uvm_info("my_driver", "end drive one pkt", UVM_LOW);
endtask

`endif                                                                          //对ifndef的end
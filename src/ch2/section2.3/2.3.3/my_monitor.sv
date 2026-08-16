`ifndef MY_MONITOR_SV
`define MY_MONITOR_SV
`include "my_if.sv"
`include "my_transaction.sv"

class my_monitor extends uvm_monitor;
    virtual my_if vif;                                                        //vif这个名字在其他类里也这么叫，但本质上vif是局部变量，类和类之间的
    `uvm_component_utils(my_monitor)                                          //vif名称一样不会互相干扰

    function new(string name = "my_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db # (virtual my_if)::get(this, "", "vif",vif))        //vif不区分方向，可以读也可以写，所以不用担心连接DUT的输入口和输出口
            `uvm_fatal("my_monitor", "virtual interface must be set for vif!!!")
    endfunction

    extern task main_phase(uvm_phase phase);
    extern task collect_one_pkt(my_transaction tr);                           //这里没有用tr句柄，因为这里的tr是参数名称
endclass

task my_monitor::main_phase(uvm_phase phase);
    my_transaction tr;
    while(1)begin
        tr = new("tr");
        collect_one_pkt(tr);
    end
endtask

task my_monitor::collect_one_pkt(my_transaction tr);
    bit [7:0] data_q[$];
    int psize;
    while(1)begin
        @(posedge vif.clk);
        if (vif.valid) break;
    end

    `uvm_info("my_monitor", "begin to collect one pkt",UVM_LOW);
    while(vif.valid) begin
        data_q.push_back(vif.data);                                           //data_q把所有数据都保存下来
        @(posedge vif.clk);
    end

    for(int i = 0; i < 6; i++)begin                                           //字节移位拼接操作，每次循环把原来的dmac向左移8位，然后把最新读到的字节放在最右边
        tr.dmac = {tr.dmac[39:0], data_q.pop_front()};                        //tr.dmac = {左半部分40位，右半部分8位}
    end

    for(int i = 0; i < 6; i++)begin                                           //字节移位拼接操作，每次循环把原来的smac向左移8位，然后把最新读到的字节放在最右边
        tr.smac = {tr.smac[39:0], data_q.pop_front()};                        //tr.smac = {左半部分40位，右半部分8位}
    end

    for(int i = 0; i < 2; i++)begin                                           //字节移位拼接操作，每次循环把原来的ether_type向左移8位，然后把最新读到的字节放在最右边
        tr.ether_type = {tr.ether_type[7:0], data_q.pop_front()};             //tr.ether_type = {左半部分8位，右半部分8位}
    end
                                                                              //这里是计算pload的长度，因为data_q.pop_front会把最高的一个字节赋值给前面，并把它删除掉。
    psize = data_q.size() - 4;                                                //所以到这里，data_q中只剩下pload对应的数据和四个字节的crc。-4就只剩下pload对应的数据了
    tr.pload = new[psize];                                                    //给pload开对应长度的空间

    for(int i = 0; i < psize; i++)begin                                       //把pload对应的数据放到tr的pload位置上
        tr.pload[i] = data_q.pop_front();
    end

    for(int i = 0; i < 4; i++)begin                                           //字节移位拼接操作，每次循环把原来的crc向左移8位，然后把最新读到的字节放在最右边
        tr.crc = {tr.crc[23:0], data_q.pop_front()};                          //tr.crc = {左半部分24位，右半部分8位}
    end
    `uvm_info("my_monitor", "end collect one pkt, print it:", UVM_LOW);
    tr.my_print();                                                            //显式调用函数
endtask


`endif
`ifndef MY_MONITOR_SV
`define MY_MONITOR_SV
`include "my_if.sv"
`include "my_transaction.sv"

class my_monitor extends uvm_monitor;
    uvm_analysis_port # (my_transaction) ap;                                  //由于reference model是需要接收来自monitor的transaction，所以在
                                                                              //这里需要定义发送transaction的端口
    virtual my_if vif;                                                        //vif这个名字在其他类里也这么叫，但本质上vif是局部变量，类和类之间的
    `uvm_component_utils(my_monitor)                                          //vif名称一样不会互相干扰

    function new(string name = "my_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db # (virtual my_if)::get(this, "", "vif",vif))        //vif不区分方向，可以读也可以写，所以不用担心连接DUT的输入口和输出口
            `uvm_fatal("my_monitor", "virtual interface must be set for vif!!!")
        ap = new("ap",this);                                                  //实例化ap端口
    endfunction

    extern task main_phase(uvm_phase phase);
    extern task collect_one_pkt(my_transaction tr);                           //这里没有用tr句柄，因为这里的tr是参数名称
endclass

task my_monitor::main_phase(uvm_phase phase);
    my_transaction tr;
    while(1)begin
        tr = new("tr");
        collect_one_pkt(tr);
        ap.write(tr);                                                         //写好端口后，把对应的数据发送出去
    end
endtask

task my_monitor::collect_one_pkt(my_transaction tr);                          //原本collect函数很复杂，但是加入field_automation机制之后，优化化简了很多(field_automation机制如何化简的？)

    byte unsigned data_q[$];
    byte unsigned data_array[];
    logic [7:0] data;
    logic valid = 0;
    int data_size;

    while(1)begin                                                             //因为是检测vif.valid控制启停，所以data_q一定是收集了完整的一个包
        @(posedge vif.clk);
        if(vif.valid)break;
    end

    `uvm_info("my_monitor","begin to collect one pkt", UVM_LOW);              //当vif.valid拉高之后开始收集数据
    while(vif.valid)begin
        data_q.push_back(vif.data);                                           //在vif.valid拉高期间收集一包完整的数据
        @(posedge vif.clk);
    end
    data_size = data_q.size();                                                //算数据大小
    data_array = new[data_size];                                              //创建一个一样大的静态数组（方便拆包）用来复制数据
    for(int i = 0; i < data_size; i++)begin
        data_array[i] = data_q[i];
    end
    tr.pload = new[data_size - 18];                                           //pload是不知道的，需要先算出来，才能创建pload的空间，在拆包时自动放进去
    data_size = tr.unpack_bytes(data_array) / 8;
    `uvm_info("my_monitor","end collect one pkt", UVM_LOW);
endtask


`endif
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

task my_monitor::collect_one_pkt(my_transaction tr);

    byte unsigned data_q[$];
    byte unsigned data_array[];
    logic [7:0] data;
    logic valid = 0;
    int data_size;

    while(1)begin
        @(posedge vif.clk);
        if(vif.valid)break;
    end

    `uvm_info("my_monitor","begin to collect one pkt", UVM_LOW);
    while(vif.valid)begin
        data_q.push_back(vif.data);
        @(posedge vif.clk);
    end
    data_size = data_q.size();
    data_array = new[data_size];
    for(int i = 0; i < data_size; i++)begin
        data_array[i] = data_q[i];
    end
    tr.pload = new[data_size - 18];
    data_size = tr.unpack_bytes(data_array) / 8;
    `uvm_info("my_monitor","end collect one pkt", UVM_LOW);
endtask


`endif
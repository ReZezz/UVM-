`ifndef MY_DRIVER_SV
`define MY_DRIVER_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
class my_driver extends uvm_driver;

    virtual my_if vif;                                                          //由于driver是软件世界，无法直接用硬件世界的interface，所以需要使用virtual
//    virtual my_if vif2;                                                       //可以同时用多个config_db传参

    `uvm_component_utils(my_driver)                                             //加入了factory机制,无需实例以及显式调用main_phase
    function new(string name = "my_driver", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("my_driver", "new is called", UVM_LOW);
    endfunction
//为了把vif和接口和dut中的input_if接口连接起来，需要在top中赋值。但是
//由于使用了objection机制，所以实际上top通过run_test("my_driver");创 
//建了一个脱离于top_tb层次机构的实例，无法直接调用，top_tb.my_driver.xxx
//所以需要加入config_db机制
    virtual function void build_phase(uvm_phase phase);                         //build_phase是一个函数phase，不消耗仿真时间
        super.build_phase(phase);
        `uvm_info("my_driver", "build_phase is called", UVM_LOW);               //uvm_config_db # (virtual my_if)::get(this, "", "vif", vif)意思是
        if(!uvm_config_db # (virtual my_if)::get(this, "", "vif", vif))         //去config_db里拿名字叫做"vif"的virtual interface，放到自己的vif变量里                                                                                                                                                    
            `uvm_fatal("my_driver", "virtual interface must be set for vif!!!") //如果没有拿到，那就打印报错信息“virtual interface must be set for vif!!!”，并自动调用finish函数停止仿真   
//        if(!uvm_config_db # (virtual my_if)::get(this, "", "vif", vif))       //如果要传多个参就这样重复写                                                                                                                                                         
//            `uvm_fatal("my_driver", "virtual interface must be set for vif!!!")                                                                       
    endfunction                                                                 //driver是数据发送方，但却是用的get指令是因为，config_db传送的不是数据而是硬件地址，driver要发给dut，但不知道dut
                                                                                //的硬件地址，所以需要接收来自top发送的dut硬件地址
    extern virtual task main_phase(uvm_phase phase);                            //extern是关键词，表示这个任务具体代码没在类的内部，而是在外部。
endclass                                                                        //virtual关键字，表示这个任务可以被子类重写

task my_driver::main_phase(uvm_phase phase);                                    //::是明确方法、变量等属于哪个类，这里是说main_phase属于my_driver类，由于前面类里的
    phase.raise_objection(this);
    `uvm_info("my_driver", "main_phase is called", UVM_LOW);                    //任务用了extern，要把具体代码写在外面，也就是写在这里，如果不写::，这里的任务会被当成全局任务然后报错
    vif.data <= 8'b0;
    vif.valid <= 1'b0;
    while(!vif.rst_n)                                                           //虽然clk和rst_n不是在interface中直接定义成logic，但是这两个信号也是存在于interface中的，可以通过vif.调用
        @(posedge vif.clk);                                                     //而且interface中的这两个信号可以当成logic类型，之所以写成input是因为这两个信号是需要从外部传入的
    for(int i = 0; i < 256; i++)begin
        @(posedge vif.clk);
        vif.data <= $urandom_range(0, 255);
        vif.valid <= 1'b1;
        `uvm_info("my_driver", "data is drived", UVM_LOW);
    end
    @(posedge vif.clk);
    vif.valid <= 1'b0;
    phase.drop_objection(this);
endtask
`endif                                                             //对ifndef的end
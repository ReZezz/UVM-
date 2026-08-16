`ifndef MY_SCOREBOARD_SV
`define MY_SCOREBOADR_SV
`include "my_transaction.sv"

class my_scoreboard extends uvm_scoreboard;
    my_transaction expect_queue[$];                                                         //定义一个动态数组，格式是transaction的格式，用来存来自reference model的预期数据
    uvm_blocking_get_port # (my_transaction) exp_port;                                      //定义一个阻塞式获取端口，名字叫做exp_port，只能传my_transaction类型。定义好一个数据通道，等待数据
    uvm_blocking_get_port # (my_transaction) act_port;                                      //这里的exp_port和act_port是句柄，不是真正的端口实例
    `uvm_component_utils(my_scoreboard);

    extern function new(string name, uvm_component parent = null);
    extern function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
endclass

function my_scoreboard::new(string name, uvm_component parent = null);
    super.new(name, parent);
endfunction

function void my_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp_port = new("exp_port",this);                                                        //创建exp_port实例
    act_port = new("act_port",this);                                                        //创建act_port实例
endfunction

task my_scoreboard::main_phase(uvm_phase phase);
    my_transaction get_expect, get_actual, temp_tran;
    bit result;

    super.main_phase(phase);
    fork                                                                                    //里面有两个while线程，这两个线程是并行运行的
        while(1)begin
            exp_port.get(get_expect);                                                       //拿到来自reference model的数据放入到get_expect里
            expect_queue.push_back(get_expect);                                             //把拿到的期望数据压入expect_queue动态数组内，这里是直接把
        end                                                                                 //一整个transaction压入里面
        while(1)begin
            act_port.get(get_actual);                                                       //拿到来自o_agent的实际数据放入到get_actual里，直接操作一整个transaction
            if(expect_queue.size() > 0)begin
                temp_tran = expect_queue.pop_front();                                       //弹出一个包
                result = get_actual.my_compare(temp_tran);                                  //把弹出来的那个包做对比
                if(result)begin
                    `uvm_info("my_scoreboard", "Comepare SUCCESSFUL", UVM_LOW);
                end
                else begin
                    `uvm_error("my_scoreboard", "Compare FAILED");
                    $display("the expect pkt is");
                    temp_tran.my_print();
                    $display("the actual pkt is");
                    get_actual.my_print();
                end
            end
            else begin
                `uvm_error("my_scoreboard", "Received from DUT, while Expect Queue is empty");
                $display("the unexpected pkt is");
                get_actual.my_print();
            end
        end
    join
endtask

`endif
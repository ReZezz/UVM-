`ifndef MY_TRANSACTION_SV
`define MY_TRANSACTION_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class my_transaction extends uvm_sequence_item;                          //my_transaction的基类是uvm_sequence_item,uvm中所有的transaction都要从uvm_sequence_item派生
                                                                         //加rand表示这些都可以随机生成
    rand bit [47:0] dmac;                                                //以太网目的地址
    rand bit [47:0] smac;                                                //以太网源地址
    rand bit [15:0] ether_type;                                          //以太网类型
    rand byte       pload[];                                             //携带的数据
    rand bit [31:0] crc;                                                 //前面数据的校验值

    constraint pload_cons{                                               //限制pload有效载荷的长度必须在46到1500之间
        pload.size >= 46;
        pload.size <= 1500;
    }

    function bit[31:0] calc_crc();                                       //CRC计算函数
        // 以太网标准 CRC32 计算函数（直接复制）
        bit [31:0] crc_reg = 32'hffffffff;  // 初始值
        int i;

        // 依次计算 dmac + smac + ether_type + payload
        for (i = 0; i < 6; i++)  crc_reg = calc_byte(crc_reg, dmac[8*(6-i)-1 -: 8]);
        for (i = 0; i < 6; i++)  crc_reg = calc_byte(crc_reg, smac[8*(6-i)-1 -: 8]);
        crc_reg = calc_byte(crc_reg, ether_type[15:8]);
        crc_reg = calc_byte(crc_reg, ether_type[ 7:0]);
        for (i = 0; i < pload.size(); i++) crc_reg = calc_byte(crc_reg, pload[i]);

        // 取反 = 以太网最终CRC
        calc_crc = ~crc_reg;
    endfunction

    // 字节级CRC计算（标准函数，别动）                                      
    function bit [31:0] calc_byte(input bit [31:0] crc_in, input byte d);//CRC计算函数
        bit [31:0] c = crc_in;
        for (int j=0; j<8; j++) begin
            c = (c >> 1) ^ ( (c[0] ^ d[j]) ? 32'hEDB88320 : 0 );
        end
        return c;
    endfunction

    function void post_randomize();                                      //当数据包随机生成完成后，自动调用calc_crc函数计算CRC并赋值给crc
        crc = calc_crc();                                                //randomize是自动给所有带rand的变量赋随机值的函数,rand bit [47:0] dmac;就已经调用了randomize函数
    endfunction                                                          //post_randomize是SV提供的一个函数，当randomize被调用之后就自动执行post_randomize函数
    
//    `uvm_object_utils(my_transaction)                                  //注册到UVM工厂，让它可以被自动创建,这里没有使用uvm_component_utils宏来实现factory机制，而是使用uvm_object_utils
                                                                         //写了`uvm_object_utils_begin(my_transaction)和`uvm_object_utils_end就不能再写`uvm_object_utils(my_transaction)了
                                                                         //my_transaction有生命周期而my_driver是一直存在的,一般来说my_transaction这种类都是派生自uvm_object或其派生类。
    function new(string name = "my_transaction");                        //uvm_sequence_item的祖先就是uvm_object。uvm中具有这种特征的类都要使用uvm_object_utils宏来实现
        super.new();
    endfunction

    `uvm_object_utils_begin(my_transaction)                              //为了方便，这里不手动写copy、print、compare函数，使用uvm的field_automation机制实现以上功能
        `uvm_field_int(dmac, UVM_ALL_ON)                                 //uvm_field_int是针对bit类型的uvm_field宏
        `uvm_field_int(smac, UVM_ALL_ON)
        `uvm_field_int(ether_type, UVM_ALL_ON)
        `uvm_field_array_int(pload, UVM_ALL_ON)                          //uvm_field_array_int是针对byte类型动态数组的uvm_field宏
        `uvm_field_int(crc, UVM_ALL_ON)
    `uvm_object_utils_end                                                //使用uvm_object_utils_begin和uvm_object_utils_end实现my_transaction的factory注册

endclass
`endif
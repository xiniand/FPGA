//时间尺度
//模块
//例化子模块：1.复制子模块接口 2.取个新名字
//对激励信号赋值
`timescale 1ns/1ps

module tb ();

reg     in_a;
reg     in_b;
reg     clk;
reg     sel;

wire    out;

initial begin//只工作一次
    in_a    =0;  //0时刻，初始值
    in_b    =0;  //0时刻，初始值
    sel     =0;  //0时刻，初始值
    clk     =0;  //0时刻，初始值
    #20 //20ns
    repeat(10)begin
        sel =  {$random};//产生随机数
        in_a = {$random};//产生随机数
        in_b = {$random};//产生随机数
        #40 ;//40ns
    end
end

always #10 clk = ~clk;//总是执行 每过10ns时钟翻转一次

top top_u(
.in_a    (in_a),
.in_b    (in_b),
.sel     (sel ),
.out     (out )
);


endmodule
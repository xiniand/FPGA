/* `timescale 1ns/1ns
module test;
reg         [1:0]   sw ;
wire        [3:0]   led;
//产生刺激信号
initial begin
    sw = 2'b00; #20
    sw = 2'b01; #20
    sw = 2'b10; #20
    sw = 2'b11; #20
    $stop;
end
//例化
//第一个名字是源代码名字,第二个名字是源代码在测试代码里面的名字
decoder2_4 decoder2_4_inst(
    //左边的信号名字是源代码信号名字,右边的名字是源代码在测试代码里面的名字
    .sw      (sw ),   //sw[0],sw[1]
    .led     (led)    //led[0],led[1],led[2],led[3]
);
endmodule */

`timescale 1ns/1ns
module test;
reg         clk     ;
reg         rst     ;
reg   [2:0]  sj      ;
wire  [2:0] cnt     ;
//产生50mhz时钟
always #10 clk = ~clk;
//产生激励
initial begin
    clk = 0;    //确定clk是从1开始还是0开始
    rst = 0;
    #100
    repeat(2)begin
        sj =  {$random};
        rst = 1;
        #200;
    end
    $stop;
end
//例化
cnt cnt_inst(
    .clk         (clk)  ,   //50MHZ(50000000次)
    .rst         (rst)  ,   //重置系统
    .sj          (sj )  ,
    .cnt         (cnt)     
);
endmodule
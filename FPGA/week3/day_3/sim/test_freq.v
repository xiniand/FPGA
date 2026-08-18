`timescale 1ns/1ns
module test_freq;
reg         clk    ;
reg         rst    ;
wire        led;
//产生50MHz
always #10 clk = ~clk;
//参数重定义
parameter   NUM = 125;
//激励
initial begin
    clk = 0;
    rst = 0;
    #1
    rst = 1;
    #500000
    $stop;
end
//例化
freq #(
    .CNT_NUM        (NUM)
) freq_inst(
    .clk         (clk    ),   //原始时钟(50MHz)
    .rst         (rst    ),
    .led     (led)    //输出4分频时钟(12.5MHz)
);
endmodule
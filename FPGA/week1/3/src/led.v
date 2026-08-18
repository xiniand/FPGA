module led (
    input                   clk         ,
    input                   rst         ,
    input                   SW          ,
    output  reg     [3:0]   led         
);
//定义内部信号
reg     [1:0]   sw_in       ;   //对SW进行寄存,得到SW的下降沿
wire            sw_negedge  ;   //SW的下降沿
//对SW进行寄存,得到SW的下降沿
always @(posedge clk)
    if(rst == 0)
        sw_in <= 0;
    else
        sw_in <= {sw_in[0],SW};     //移位寄存
//SW的下降沿
assign sw_negedge = ~sw_in[0] & sw_in[1];
//输出
always @(posedge clk)
    if(rst == 0)
        led <= 0;
    else if(sw_negedge)
        led <= led + 1;

endmodule
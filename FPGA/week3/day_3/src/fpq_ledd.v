module fpq_ledd (
    input clk,
    input rst_n,
    output reg clk_out,  //输出分频信号
    output reg led
);    
localparam NUMBER = 25_000_000;
localparam delay = 2;
reg [1:0] cnt;
reg [24:0] cnt_1;
//偶分频计数器
always @(posedge clk)
    if(!rst_n)
        cnt <= 0;       //复位
    else if(cnt == delay - 1)
        cnt <= 0;       //清零
    else
        cnt <= cnt+1;   //累加

//分频器
always @(posedge clk)
    if(!rst_n)
        clk_out <= 0;
    else if(cnt == (delay-1)/2)
        clk_out <= ~clk_out;
    else if(cnt == delay-1)
        clk_out <= ~clk_out;

//普通计数器
always @(posedge clk_out)
    if(!rst_n)
        cnt_1 <= 0;       //复位
    else if(cnt_1 == NUMBER )
        cnt_1 <= 0;       //清零
    else
        cnt_1 <= cnt_1+1;  //累加

always @(posedge clk_out)
    if(!rst_n)
        led <= 0;   
    else if(cnt_1 == NUMBER)
        led <= ~led;
endmodule
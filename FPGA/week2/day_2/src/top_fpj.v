//奇数分频
module top_fpj (
    input   clk ,
    input   rst ,
    output  clk_fpj
);
parameter   delay = 3;
//计数器
reg [1:0]   cnt_1;//上升沿
reg [1:0]   cnt_2;//下降沿

always@(posedge clk)
    if(!rst)
        cnt_1 <= 0;
    else if(cnt_1 == delay-1)
        cnt_1 <= 0;
    else
        cnt_1 <= cnt_1 + 1;

always@(negedge clk)
    if(!rst)
        cnt_2 <= 0;
    else if(cnt_2 ==delay - 1)
        cnt_2 <= 0;
    else
        cnt_2 <= cnt_2 + 1;
    
//分频时钟
reg clk_1;
reg clk_2;
always@(posedge clk)
    if(!rst)
        clk_1 <= 0;
    else if(cnt_1 == 1)
        clk_1 <= 1;
    else if(cnt_1 == 2)
        clk_1 <= 0;
    else
        clk_1 <= clk_1;

always@(negedge clk)
    if(!rst)
        clk_2 <= 0;
    else if(cnt_2 == 1)
        clk_2 <= 1;
    else if(cnt_2 == 2)
        clk_2 <= 0;
    else
        clk_2 <= clk_2;

assign  clk_fpj = clk_1 | clk_2;




endmodule
module freq_j (
    input               clk         ,   //原始时钟(50MHz)
    input               rst         ,
    output              clk_out         //输出5分频时钟(10MHz)
);
parameter      NUMBER  =    3  ;   //分频系数
reg     [2:0]   cnt_num         ;   //分频计数器
reg             out_clk1        ,   //奇数上升沿
                out_clk2        ;   //奇数下降沿
//分频计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_num <= 0;
    else
        cnt_num <= (cnt_num == NUMBER - 1) ? 0 : cnt_num + 1;
//奇数上升沿
always @(posedge clk or negedge rst)
    if(rst == 0)
        out_clk1 <= 0;
    else if(cnt_num == (NUMBER - 1) >> 1)
        out_clk1 <= ~out_clk1;
    else if(cnt_num == NUMBER - 1)
        out_clk1 <= ~out_clk1;
//奇数下降沿
always @(negedge clk or negedge rst)
    if(rst == 0)
        out_clk2 <= 0;
    else if(cnt_num == (NUMBER - 1) >> 1)
        out_clk2 <= ~out_clk2;
    else if(cnt_num == NUMBER - 1)
        out_clk2 <= ~out_clk2;

assign clk_out = out_clk1 | out_clk2; 
endmodule
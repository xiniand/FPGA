module freq_o (
    input               clk         ,   //原始时钟(50MHz)
    input               rst         ,
    output      reg     clk_out         //输出4分频时钟(12.5MHz)
);
parameter          NUMBER = 4      ;   //分频系数
reg     [2:0]       cnt             ;   //频率计数器
//频率计数器
always @(posedge clk or negedge rst)    
    if(rst == 0)    
        cnt <= 0;
    else if(cnt == NUMBER - 1)
        cnt <= 0;
    else
        cnt <= cnt + 1;
//输出4分频时钟(12.5MHz)
always @(posedge clk or negedge rst)
    if(rst == 0)
        clk_out <= 0;
    else if(cnt == (NUMBER - 1)>>1)
        clk_out <= ~clk_out;
    else if(cnt == NUMBER - 1)
        clk_out <= ~clk_out;
endmodule  
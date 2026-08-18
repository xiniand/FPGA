/* module freq (
    input               clk         ,   //原始时钟(50MHz)
    input               rst         ,
    output      reg     clk_out         //输出4分频时钟(12.5MHz)
);
localparam      NUMBER = 4  ;   //分频系数
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
endmodule  */
module freq (
    input               clk         ,   //原始时钟(50MHz)
    input               rst         ,
    output      reg     led             
);
parameter           NUMBER = 4              ,   //分频系数
                    CNT_NUM = 12_499_999    ;   
reg                 clk_out                 ;
reg     [2:0]       cnt                     ;   //频率计数器
reg     [23:0]      cnt_num                 ;
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
always @(posedge clk_out or negedge rst)
    if(rst == 0)
        cnt_num <= 0;
    else if(cnt_num == CNT_NUM)
        cnt_num <= 0;
    else
        cnt_num <= cnt_num + 1;
always @(posedge clk_out or negedge rst)
    if(rst == 0)
        led <= 0;
    else if(cnt_num == CNT_NUM)
        led <= ~led;
endmodule 
module pos (
    input           clk     ,           //时钟
    input           rst     ,           //复位信号
    input           sw      ,           //原始的开关
    output   reg    led     
);
localparam TIME = 24_999_999;           //0.5s时间参数
//定义内部信号
reg    [24:0]   cnt         ;           //计数器
reg    [1:0]    sw_in       ;           //对原始开关进行寄存
wire            sw_posedge  ;           //检测上升沿
reg             led_en      ;   
//对原始开关进行寄存
always@(posedge clk)
    if(!rst == 0)
        sw_in <= 0;
    else
        sw_in <= sw;
assign sw_posedge = ~sw_in & sw;
//计数
always@(posedge clk)
    if(!rst == 0)
        cnt <= 0;
    else if(cnt == TIME)
        cnt <= 0;
    else
        cnt <= cnt+1;
//控制暂停
always@(posedge clk)
    if(!rst == 0)
        led_en <= 0;
    else if(sw_posedge)
        led_en <= ~led_en;
//开关
always@(posedge clk)
    if(!rst == 0)
        led <= 0;
    else if(led_en)
        if(cnt == TIME)
            led <= ~led; 
endmodule
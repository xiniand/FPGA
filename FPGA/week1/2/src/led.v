module led (
    input           sw      ,
    input           rst     ,
    input           clk     ,
    output    reg   led     
);
localparam TIME = 24_999_999;           //0.5s时间参数
//定义内部信号
reg    [24:0]   cnt         ;           //计数器
//对原始开关进行寄存
reg     led_en          ;
wire    sw_posedge      ;
reg     sw_in           ;
always@(posedge clk)
    if(!rst == 0)
        sw_in <= 0;
    else
        sw_in <= sw;
assign sw_posedge = sw ^~ ~sw_in;//检测上升沿和下降沿
always@(posedge clk)
    if(!rst == 0)
        led_en <=0;
    else if(sw_posedge)
        led_en <= ~led_en;
//只有当时钟上升沿有效，才执行always
always @(posedge clk)               //assign不能带时钟,always可带可不带
    //第一优先级
    if(!rst == 0)                    //自动复位
        cnt <= 0;                   //非阻塞赋值   
    else if(led_en)                 //手动复位
        if(cnt == TIME)
            cnt <= 0;
        else
            cnt <= cnt + 1;         //累加
//led部分
always @(posedge clk) 
    if(!rst == 0)
        led <= 0;
    else if(cnt == TIME)
        led <= ~led;     
endmodule
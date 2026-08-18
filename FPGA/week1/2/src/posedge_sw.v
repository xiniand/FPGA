module posedge_sw (
    input       clk     ,
    input       rst     ,
    input       sw      ,//原始的开关
    output   reg   led     
);
localparam TIME = 24_999_999;           //0.5s时间参数
//定义内部信号
reg    [24:0]   cnt         ;           //计数器
reg    [1:0]    sw_in       ;           //对原始开关进行寄存
wire            sw_posedge  ;           //检测上升沿
reg             led_en       ;   
//对原始开关进行寄存
    always @(posedge clk)
        if(rst == 0)
            sw_in <= 2'b0;
        else begin
            sw_in[0] <= sw;      //第一次寄存
            sw_in[1] <= sw_in[0];//第二次寄存
        end
//检测上升沿
assign sw_posedge = sw_in[0] & ~sw_in[1];
//控制开始和暂停
always@(posedge clk)
    if(rst == 0)
        led_en <=0;
    else if(sw_posedge)
        led_en <= ~led_en;
//只有当时钟上升沿有效，才执行always
always @(posedge clk)               //assign不能带时钟,always可带可不带
    //第一优先级
    if(rst == 0)                    //自动复位
        cnt <= 0;                   //非阻塞赋值   
    else if(led_en)                 //手动复位
        if(cnt == TIME)
            cnt <= 0;
        else
            cnt <= cnt + 1;         //累加
//led部分
always @(posedge clk) 
    if(rst == 0)
        led <= 0;
    else if(cnt == TIME)
        led <= ~led;            
endmodule

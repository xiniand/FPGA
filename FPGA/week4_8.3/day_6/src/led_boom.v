module led_boom (
    input           clk     ,
    input           rst     ,
    input           boom    ,   //爆炸使能
    output  reg [3:0] led       //爆炸闪烁 LED
);
//爆炸效果：boom 有效时 LED 以 TIME 为周期全亮/全灭交替闪烁
//参考 LED 流水灯（water.v）的分频思路
parameter TIME = 25_000_000;    //闪烁周期 0.5s（50MHz）

reg [24:0]  cnt;

//分频计数
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt <= 0;
    else if(boom) begin
        if(cnt == TIME - 1)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end
    else
        cnt <= 0;

//闪烁翻转
always @(posedge clk or negedge rst) begin
    if(rst == 0)
        led <= 0;
    else if(boom) begin
        if(cnt == TIME - 1)
            led <= ~led;
    end
    else
        led <= 0;
end

endmodule

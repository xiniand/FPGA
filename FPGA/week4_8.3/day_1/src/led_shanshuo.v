module led_shanshuo (
    input               clk         ,
    input               rst         ,
    input               state_en    ,
    output  reg [3:0]   led      
);
parameter   NUMBER  =   24_999_999  ;
reg     [24:0]      cnt             ;   //0.5秒计数器
//0.5秒计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt <= 25'd0;
    else if(state_en == 1)
        if(cnt == NUMBER)
            cnt <= 25'd0;
        else 
            cnt <= cnt + 25'd1;
always @(posedge clk or negedge rst)
    if(rst == 0)
        led <= 4'b1001;
    else if(cnt == NUMBER)
        //移位拼接
        led <= ~led;
endmodule
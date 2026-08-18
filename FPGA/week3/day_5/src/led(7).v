`timescale 1ns/1ns
module led (
    input               clk         ,
    input               rst         ,
    input               key         ,
    output  reg [3:0]   led         
);
/*------------按键消抖-----------*/
parameter       CNT_MAX =   999_999 ;   //20ms时间参数
reg     [19:0]  cnt_num             ;   //20ms计数器
reg             key_out             ;
//20ms计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_num <= 20'd0;
    else if(key == 1'b0)
        if(cnt_num == CNT_MAX)
            cnt_num <= cnt_num;
        else
            cnt_num <= cnt_num + 20'd01;
    else if(key == 1'b1)
        cnt_num <= 20'd0;
//输出
//assign key_out = (cnt_num == CNT_MAX - 1) ? 1'b1 : 1'b0;
always @(posedge clk or negedge rst)
    if(rst == 0)
        key_out <= 1'b0;
    else if(cnt_num == CNT_MAX - 1)
        key_out <= 1'b1;
    else
        key_out <= 1'b0; 

/*-------------流水灯--------------*/
parameter   NUMBER  =   24_999_999  ;
reg     [24:0]      cnt_liushui     ;   //0.5秒计数器
reg     [3:0]       led_liushui     ;
//0.5秒计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_liushui <= 25'd0;
    else if(key_en)
        if(cnt_liushui == NUMBER)
            cnt_liushui <= 25'd0;
        else 
            cnt_liushui <= cnt_liushui + 25'd1;
always @(posedge clk or negedge rst)
    if(rst == 0)
        led_liushui <= 4'b0001;
    else if(cnt_liushui == NUMBER)
        //移位拼接
        led_liushui <= {led_liushui[2:0],~led_liushui[3]};

/*---------------跑马灯------------*/
reg     [24:0]      cnt_paoma       ;   //0.5秒计数器
reg     [3:0]       led_paoma       ;
//0.5秒计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_paoma <= 25'd0;
    else if(key_en == 0)
        if(cnt_paoma == NUMBER)
            cnt_paoma <= 25'd0;
        else 
            cnt_paoma <= cnt_paoma + 25'd1;
always @(posedge clk or negedge rst)
    if(rst == 0)
        led_paoma <= 4'b0001;
    else if(cnt_paoma == NUMBER)
        //移位拼接
        led_paoma <= {led_paoma[2:0],led_paoma[3]};

reg             key_en      ;   //反向电路，根据消抖后的按键信号来选择,为高电平就选择流水灯,为低电平就选择跑马灯
always @(posedge clk or negedge rst)
    if(rst == 0)
        key_en <= 0;
    else if(key_out)
        key_en <= ~key_en;
always @(posedge clk or negedge rst)
    if(rst == 0)
        led <= 0;
    else if(key_en)
        led <= led_liushui;
    else if(!key_en)
        led <= led_paoma;
endmodule
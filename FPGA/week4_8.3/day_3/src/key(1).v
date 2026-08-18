module key(1) (
    input               clk         ,
    input               rst         ,
    input               key         ,   //未消抖按键信号
    output              key_out         //已消抖按键信号
);
parameter       CNT_MAX =   999_999 ;   //20ms时间参数
reg     [19:0]  cnt_num             ;   //20ms计数器
reg     [1:0]   key_in              ;   //同步打拍消除亚稳态
//同步打拍消除亚稳态
always @(posedge clk or negedge rst)
    if(rst == 0)
        key_in <= 1;
    else
        key_in <= {key_in[0],key};
//20ms计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_num <= 0;
    else if(key_in[1] == 0)
        if(cnt_num == CNT_MAX)
            cnt_num <= cnt_num;
        else
            cnt_num <= cnt_num + 1;
    else if(key_in[1] == 1)
        cnt_num <= 0;
//输出
assign key_out = (cnt_num == CNT_MAX - 1) ? 1 : 0;
endmodule
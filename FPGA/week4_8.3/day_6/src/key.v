module key (
    input   key,
    input   clk,
    input   rst,
    output  flag
);

parameter delay_1 = 100_000_0;//20ms

reg [19:0]  cnt ;
reg [1:0]   key_in ;//同步打拍信号
reg         flag_r ;

//同步打拍消除亚稳态
always @(posedge clk or negedge rst)begin
    if(rst == 0)
        key_in <= 2'b11;
    else
        key_in <= {key_in[0],key};
end

//计数消抖：低电平持续超过消抖时间视为有效按下
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt <= 0;
    else if(key_in[1] == 0)
        if(cnt == delay_1 - 1)
            cnt <= cnt;
        else
            cnt <= cnt + 1;
    else
        cnt <= 0;

//消抖稳定后输出一拍脉冲
always @(posedge clk or negedge rst)
    if(rst == 0)
        flag_r <= 0;
    else if(key_in[1] == 0 && cnt == delay_1 - 2)
        flag_r <= 1;
    else
        flag_r <= 0;

assign flag = flag_r;

endmodule

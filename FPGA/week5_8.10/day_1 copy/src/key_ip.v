module key_ip(
    input  clk  ,
    input  rst_n,
    input  key  ,
    output key_out
);
parameter  TIME_key =  1_000_000    ;
reg [19:0 ] cnt_key             ; //消抖计数器
reg [1:0  ] key_in              ; //引入同步信号打拍信号
//同步打拍消除亚稳态
always @(posedge clk or negedge rst_n)
    if(!rst_n)
        key_in <= 2'b11;           //复位为高电平(未按下)
    else
        key_in <= {key_in[0],key}; //每个时钟同步打拍
//按键消抖
always @(posedge clk or negedge rst_n)
    if(!rst_n)
        cnt_key <= 0;             //复位
    else if(key_in[1] == 0)begin
        if(cnt_key == TIME_key-1)
            cnt_key <= cnt_key;   //保持
        else
            cnt_key <= cnt_key+1; //计数
    end
    else
        cnt_key <= 0;             //清零

assign key_out = (cnt_key == TIME_key - 2)? 1 : 0;      //输出消抖信号

endmodule
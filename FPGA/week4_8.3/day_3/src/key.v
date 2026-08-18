module key (
    input   key,
    input   clk,
    input   rst,
    output  flag
);

parameter delay = 100_000_0;//20ms
reg [19:0]  cnt ;
reg [1:0]   key_in;//同步打拍信号
//同步打拍消除亚稳态
always @(posedge clk or negedge rst)begin
    if(rst == 0)
        key_in <= 1;
    else
        key_in <= {key_in[0],key};
end
//计数
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt <= 0;
    else if(key_in[1] == 0)
        if(cnt == delay - 1)
            cnt <= cnt;
        else
            cnt <= cnt + 1;
    else if(key_in[1] == 1)
        cnt <= 0;
//消抖后的信号
assign  flag = (cnt == delay-2)? 1 : 0;

endmodule
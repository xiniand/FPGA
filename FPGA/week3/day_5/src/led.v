module led_1 (
    input               clk ,
    input               rst ,
    input               key ,
    output   [3:0]   led
);

parameter delay_1 = 99_999_9;
reg [19:0]  cnt;
wire        flag;
//按键消抖模块
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt <= 0;
    else if(key == 0)begin
        if(cnt == delay_1)
            cnt <= cnt;
        else
            cnt <= cnt + 1;
    end
    else
        cnt <= 0;
end
assign flag = (cnt == delay_1 - 1)?1:0;
//灯
parameter   delay = 24_999_999;
reg     [24:0]  cnt_1   ;
reg     [24:0]  cnt_2   ;
reg             en      ;
reg     [3:0]   led_liu ;
reg     [3:0]   led_pao ;
//使能模块
always @(posedge clk or negedge rst) begin
    if(!rst)
        en <= 0;
    else if(flag)
        en <= ~en;
end
//0.5s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_1 <= 0;
    else if(cnt_1 == delay)
        cnt_1 <= 0;
    else 
        cnt_1 <= cnt_1 + 1;
end
//0.5s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_2 <= 0;
    else if(cnt_2 == delay)
        cnt_2 <= 0;
    else 
        cnt_2 <= cnt_2 + 1;
end
//流水灯
always @(posedge clk or negedge rst) begin
    if(!rst)
        led_liu <= 4'b0001;
    else if(cnt_1 == delay)
        led_liu <= {led_liu[2:0],led_liu[3]};
end
//跑马灯
always @(posedge clk or negedge rst) begin
    if(!rst)
        led_pao <= 4'b0001;
    else if(cnt_2 == delay)
        led_pao <= {led_pao[2:0],~led_pao[3]};
end

assign led = (en)?led_liu:led_pao;

endmodule
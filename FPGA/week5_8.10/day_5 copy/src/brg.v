//波特率发生器
module brg (
    input       clk     ,
    input       rst_n   ,//异步复位信号
    input       brg_en  ,
    output  reg tick     //bit脉冲
);
parameter CLK_FREQ = 50_000_000                     ;// 系统时钟频率 
parameter BAUD_RATE = 9_600                         ;// 目标波特率
localparam COUNT_MAX = (CLK_FREQ / BAUD_RATE) - 1   ;
/* parameter COUNT_MAX = 5207; */
reg     [12:0]  cnt_tick     ;//计数5208个周期发送一个bit
wire            add_cnt_tick ,//计数开始
                end_cnt_tick ;//计数结束
//波特率发生器计数5208个周期发送一个bit 50MHZ时钟5208个周期每秒发送9600 bit
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_tick <= 0;
    else if(add_cnt_tick)begin
        if(end_cnt_tick)
            cnt_tick <= 0;
        else
            cnt_tick <= cnt_tick + 1;
    end
end
assign add_cnt_tick = brg_en;
assign end_cnt_tick = add_cnt_tick&&(cnt_tick == COUNT_MAX);
//波特率脉冲信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tick <= 0;
    else if(end_cnt_tick)
        tick <= 1;
    else 
        tick <= 0;
end
endmodule
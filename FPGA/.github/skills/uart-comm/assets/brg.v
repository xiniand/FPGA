//波特率发生器：在系统时钟下计数产生 bit 采样脉冲 tick
//每 (CLK_FREQ/BAUD_RATE) 个时钟周期产生一个 tick
module brg (
    input       clk     ,//系统时钟
    input       rst_n   ,//低有效复位
    input       brg_en  ,//使能
    output  reg tick     //bit 脉冲(每个位周期一个)
);
parameter CLK_FREQ  = 50_000_000;//系统时钟频率
parameter BAUD_RATE = 9_600      ;//目标波特率
localparam COUNT_MAX = (CLK_FREQ / BAUD_RATE) - 1;

reg [15:0]  cnt_tick;//计数
wire        add_cnt_tick ,
            end_cnt_tick ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_tick <= 0;
    else if(add_cnt_tick) begin
        if(end_cnt_tick)
            cnt_tick <= 0;
        else
            cnt_tick <= cnt_tick + 1;
    end
end
assign add_cnt_tick = brg_en;
assign end_cnt_tick = add_cnt_tick && (cnt_tick == COUNT_MAX);

//tick 脉冲：每个位周期末尾产生一个时钟周期宽的高电平
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tick <= 0;
    else if(end_cnt_tick)
        tick <= 1;
    else
        tick <= 0;
end
endmodule

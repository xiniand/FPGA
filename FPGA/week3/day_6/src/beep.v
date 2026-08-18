module beep (
    input       clk,
    input       rst,
    output  reg beep 
);
parameter   L1 = 190840,
            L2 = 170068,
            L3 = 151515,
            L4 = 142857,
            L5 = 127226,
            L6 = 113378,
            L7 = 100000,
            TIME = 24_999_999,//0.5s
            COUNT = 6;
reg [24:0]  time_cnt;//0.5s计数器
wire        add_time_cnt,
            end_time_cnt;
reg [17:0]  l_cnt,//音频计数器
            frq_data;
wire        add_l_cnt,
            end_l_cnt;
//音符计数器
reg [3:0]   yin_cnt;
wire        add_yin_cnt,
            end_yin_cnt;
wire [16:0] duty;
//0.5s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        time_cnt <= 0;
    else if(add_time_cnt)
        if(end_time_cnt)
            time_cnt <= 0;
        else
            time_cnt <= time_cnt + 1;
end
assign add_time_cnt = 1;
assign end_time_cnt = add_time_cnt && (time_cnt == TIME);
//频率计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        l_cnt <= 0;
    else if(add_l_cnt)
        if(end_l_cnt)
            l_cnt <= 0;
        else
            l_cnt <= l_cnt + 1;
end
assign add_l_cnt = 1;
assign end_l_cnt = add_l_cnt && (l_cnt == frq_data);
//音符计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        yin_cnt <= 0;
    else if(add_yin_cnt)
        if(end_yin_cnt)
            yin_cnt <= 0;
        else
            yin_cnt <= yin_cnt + 1;
end
assign add_yin_cnt = 1;
assign end_yin_cnt = add_yin_cnt && (yin_cnt == COUNT);
//寄存频率
always @(posedge clk or negedge rst) begin
    if(!rst)
        frq_data <= 0;
    else
        case (yin_cnt)
            0:frq_data <= L1;
            1:frq_data <= L2;
            2:frq_data <= L3;
            3:frq_data <= L4;
            4:frq_data <= L5;
            5:frq_data <= L6;
            6:frq_data <= L7;
            default: frq_data <= L1;
        endcase
end
//调整占空比
assign duty = frq_data >> 1;
//输出
always @(posedge clk or negedge rst) begin
    if(!rst)
        beep <= 0;
    else if(l_cnt == duty)
        beep <= 1;
    else if(end_l_cnt)
        beep <= 0;
end
endmodule
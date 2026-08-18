//数据接收器
module rx (
    input               clk     ,
    input               rst_n   ,
    input               rx      ,
    input               tick    ,//外部波特率脉冲（内部以位定时中点采样，此信号备用）
    output  reg         rx_done ,//接收完成：cnt==5207&&baud_cnt==9(停止位结束)时拉高
    output  reg [7:0]   data
);

localparam  IDLE    =   2'b00,//空闲态
            START   =   2'b01,//起始态
            RECX    =   2'b10,//接收态
            STOP    =   2'b11;//停止态
parameter   CLK_FREQ  = 50_000_000 ;//系统时钟频率
parameter   BAUD_RATE = 9_600      ;//波特率
localparam  COUNT_MAX = (CLK_FREQ / BAUD_RATE) - 1;//5207，一个bit周期
localparam  MID_POINT = COUNT_MAX >> 1             ;//2603，bit中点采样

wire        flag    ;//下降沿rx_rg == 2'b10
reg [1:0]   rx_rg   ;//二级寄存
reg [4:0]   baud_cnt,//接收的数据位数
            n_baud_cnt;
reg [7:0]   data_rg ;//接收的数据寄存
reg [1:0]   n_state ,//次态
            c_state ;//现态
reg [12:0]  cnt     ;//位内采样计数器

wire        rx_pos  = (cnt == MID_POINT) ;//bit中点采样时刻
wire        rx_end  = (cnt == COUNT_MAX) ;//bit周期结束时刻

//rx_rg两级寄存（同步+消抖），flag为下降沿检测
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_rg <= 2'b11;
    else
        rx_rg <= {rx_rg[0],rx};
end
assign flag = (rx_rg == 2'b10);

//位内定时器：空闲态检测到起始位下降沿后从0开始，每bit周期循环
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= 13'd0;
    else if((c_state == IDLE) && flag)
        cnt <= 13'd0;
    else if(c_state == IDLE)
        cnt <= 13'd0;
    else if(cnt == COUNT_MAX)
        cnt <= 13'd0;
    else
        cnt <= cnt + 1'b1;
end

//状态切换
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE;
    else 
        c_state <= n_state;
end

//baud_cnt寄存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        baud_cnt <= 5'd0;
    else
        baud_cnt <= n_baud_cnt;
end

//状态转移+baud_cnt计数
always @(*) begin
    n_state    = c_state;
    n_baud_cnt = baud_cnt;
    case (c_state)
        IDLE:begin
            if(flag)begin
                n_state    = START;
                n_baud_cnt = 5'd0;
            end
        end 
        START:begin
            //起始位中点采样确认：低电平为有效起始位，高电平为毛刺放弃
            if(rx_pos)begin
                if(rx_rg[1] == 1'b0)
                    n_state = RECX;
                else
                    n_state = IDLE;
                n_baud_cnt = 5'd0;
            end
        end 
        RECX :begin
            //每bit周期结束推进baud_cnt，收满8个数据位进入STOP
            if(rx_end)begin
                if(baud_cnt == 5'd8)begin
                    n_state    = STOP;
                    n_baud_cnt = 5'd9;//停止位
                end
                else
                    n_baud_cnt = baud_cnt + 1'b1;
            end
        end 
        STOP :begin
            if(rx_end)
                n_state = IDLE;
        end  
        default:
            n_state = IDLE;
    endcase
end

//数据位中点采样：LSB先，右移存入data_rg
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_rg <= 8'd0;
    else if((c_state == RECX) && rx_pos)
        data_rg <= {rx_rg[1], data_rg[7:1]};
end

//停止位结束：输出接收完成信号与数据
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_done <= 1'b0;
        data    <= 8'd0;
    end
    else if((c_state == STOP) && rx_end) begin
        rx_done <= 1'b1;//一帧(起始+8数据+停止)接收完成
        data    <= data_rg;
    end
    else
        rx_done <= 1'b0;
end

endmodule
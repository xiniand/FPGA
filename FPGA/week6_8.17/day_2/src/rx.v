//数据接收器
module rx (
    input               clk         ,
    input               rst_n       ,
    input               rx          ,
    output  reg         rx_done     ,//使能：flag拉高；cnt==5207&&bit(baud_cnt)==9
    output  reg         parity_error,
    output  reg [7:0]   data    
);
parameter   CLK_FREQ    = 50_000_000                 ;// 系统时钟频率 
parameter   BAUD_RATE   = 9600                      ;// 目标波特率
localparam  COUNT_MAX   = (CLK_FREQ / BAUD_RATE) - 1 ;
localparam  IDLE        = 3'b000,//空闲态
            START       = 3'b001,//起始态
            RECX        = 3'b010,//接收态
            PARITY      = 3'b011,//校验态
            STOP        = 3'b100;//停止态
reg [12:0]  cnt_bit     ;//计数5208个周期发送一个bit
wire        flag        ;//下降沿rx_rg == 2'b10
reg         flag_d1     ;
reg [1:0]   rx_rg       ;//二级寄存
reg [4:0]   baud_cnt    ,//接受的数据位数
            n_baud_cnt  ;
reg [7:0]   data_rg     ;//接收的数据寄存
reg [2:0]   n_state     ,//次态
            c_state     ;//现态
wire        rx_mid      ,//中间采样点
            rx_end      ;//一个bit发送时间结束点
reg         flag_sync   ;//寄存一级
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        flag_sync <= 1'b0;
    else
        flag_sync <= flag;
end
//计数器一个bit时间
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_bit <= 0;
    else if(flag_sync && (c_state == IDLE || c_state == STOP))      
        cnt_bit <= 0;
    else if(cnt_bit == COUNT_MAX)
        cnt_bit <= 0;
    else
        cnt_bit <= cnt_bit + 1;
end
assign  rx_end  = cnt_bit == COUNT_MAX      ;//一个bit结束
assign  rx_mid  = cnt_bit == COUNT_MAX  >>1 ;//中间值采样 
//rx_rg两级寄存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_rg <= 2'b11;
    else
        rx_rg <= {rx_rg[0],rx};
end
//下降沿检测
assign  flag    =   (rx_rg == 2'b10);
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
//状态转移
always @(*) begin
    n_state    = c_state;
    n_baud_cnt = baud_cnt;
    case (c_state)
        IDLE:begin
            if(flag_sync)begin//起始位即将从高电平拉低时下降沿进入起始态
                n_state = START ;
                n_baud_cnt=0    ;
            end
            else
                n_state = IDLE  ;
        end 
        START:begin
            if(rx_mid)begin
                if(rx_rg[1] == 0)begin//起始位为0时进入接收态数据位数计数器清零
                    n_state = RECX;
                    n_baud_cnt = 0;
                end 
                else
                    n_state = IDLE;
            end
        end 
        RECX :begin
            if(rx_mid)begin//发送数据信号tick
                if(baud_cnt == 7)begin
                    n_state = PARITY;
                end
                else begin
                    n_baud_cnt = baud_cnt + 1;
                    n_state = RECX;
                end 
            end
        end 
        PARITY:begin
            if(rx_mid)begin
                n_state = STOP;
                n_baud_cnt = 0;
            end
            else
                n_state = PARITY;

        end 
        STOP :begin
            if(flag_sync) begin                      // 下一帧起始位提前到达（背靠背）
                n_state = START;
                n_baud_cnt = 0;
            end 
            else if(rx_mid) begin
                if(rx_rg[1] == 1) begin         // 停止位正确
                    n_state = IDLE;
                end 
                else begin                  // 帧错误！强制回到IDLE
                    n_state = IDLE;
                end
            end
        end  
        default:n_state = IDLE;
    endcase
end
//输出
//发送位时每tick baud_cnt + 1将rx信号经过两级寄存后的rx_rg[1]给data_rg高位进行移位寄存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_rg <= 0;
    else if((c_state == RECX)&&rx_mid)
        data_rg <= {rx_rg[1],data_rg[7:1]};
end
//校验位验证
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        parity_error <= 0;
    else if(c_state == PARITY && rx_mid)
        parity_error <= (rx_rg[1] != ^data_rg); // 用当前采到的校验位判定偶校验
end
//停止态时 中间采样拉高使能将 data_rg寄存器中的数据给data
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        data <= 0;
        rx_done <= 0;
    end 
    else if(c_state == STOP && rx_mid  && rx_rg[1] && ~parity_error)begin
        data <= data_rg;
        rx_done <= 1;
    end
    else
        rx_done <= 0;
end
endmodule
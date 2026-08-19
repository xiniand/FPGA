//UART 接收器：检测起始位下降沿，数据位中点采样恢复，支持校验与帧错误检测
module uart_rx (
    input           clk     ,//系统时钟
    input           rst_n   ,//低有效复位
    input           tick    ,//波特率脉冲(brg 产生)
    input           rx      ,//串行输入(空闲为高)
    output  reg     rx_done ,//接收一组数据完成信号
    output  reg     parity_error,//校验/帧错误标志(1=错误)
    output  reg [7:0] data  //接收到的数据
);
parameter   MODE = 0;    //0无校验 1奇校验 2偶校验
localparam  IDLE   = 3'b000,
            START  = 3'b001,
            RECV   = 3'b010,
            PARITY = 3'b011,
            STOP   = 3'b100;
reg [2:0]   c_state , n_state;
reg [3:0]   cnt_bit;//已接收数据位数
reg [7:0]   data_rg;//移位寄存器
reg [1:0]   rx_ff  ;//同步打拍
wire        rx_in = rx_ff[1];

//同步打拍防亚稳态
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_ff <= 2'b11;
    else
        rx_ff <= {rx_ff[0], rx};
end

//第一段：现态更新(时序)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE;
    else
        c_state <= n_state;
end

//第二段：次态转移 + 数据移位(组合)，先赋默认值防锁存器
always @(*) begin
    n_state = c_state;
    case(c_state)
        IDLE : if(!rx_in) n_state = START;//检测到起始位下降沿
        START: if(tick) begin
                   n_state  = RECV;
               end
        RECV : if(tick) begin
                   if(cnt_bit == 7) begin
                       n_state = (MODE == 0) ? STOP : PARITY;
                   end
               end
        PARITY: if(tick) n_state = STOP;
        STOP : if(tick) n_state = IDLE;
        default: n_state = IDLE;
    endcase
end

//数据移位：RECV 状态每个 tick 采入一位(LSB first)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_rg <= 8'd0;
    else if(c_state == RECV && tick)
        data_rg <= {rx_in, data_rg[7:1]};//先收低位，右移存储
end

//数据位计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_bit <= 0;
    else if(c_state == RECV && tick) begin
        if(cnt_bit == 7)
            cnt_bit <= 0;
        else
            cnt_bit <= cnt_bit + 1;
    end
end

//完成/校验/错误检测：STOP 状态 tick 到来时输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_done      <= 0;
        parity_error <= 0;
        data         <= 8'd0;
    end
    else begin
        rx_done <= 0;
        if(c_state == STOP && tick) begin
            rx_done      <= 1;
            data         <= data_rg;
            //帧错误：停止位应为高
            if(rx_in == 1'b0)
                parity_error <= 1;
            else begin
                //校验检查
                if(MODE == 0)      parity_error <= 0;
                else if(MODE == 2) parity_error <= (^data_rg != rx_in);//偶校验
                else               parity_error <= (^data_rg == rx_in);//奇校验
            end
        end
    end
end
endmodule

//UART 发送器：在 tick 节拍下逐位发送，支持无/奇/偶校验
module uart_tx (
    input           clk     ,//系统时钟
    input           rst_n   ,//低有效复位
    input           tick    ,//波特率脉冲(brg 产生)
    input           tx_star ,//开始发送信号(建议单周期脉冲)
    input   [7:0]   tx_data ,//待发送数据
    output  reg     tx      ,//串行输出(空闲为高)
    output  reg     tx_done  //一组数据发送完成信号
);
parameter   MODE = 0;    //0无校验 1奇校验 2偶校验
localparam  IDLE   = 3'b000,//空闲
            START  = 3'b001,//起始位
            SEND   = 3'b010,//数据位
            PARITY = 3'b011,//校验位
            STOP   = 3'b100;//停止位
reg [2:0]   c_state , n_state;
reg [3:0]   cnt_bit;//已发送数据位数
reg [7:0]   data_rg;//锁存待发送数据

//锁存数据：IDLE 时收到开始信号则锁存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_rg <= 8'd0;
    else if(tx_star && c_state == IDLE)
        data_rg <= tx_data;
end

//第一段：现态更新(时序)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE;
    else
        c_state <= n_state;
end

//第二段：次态转移(组合)，先赋默认值防锁存器
always @(*) begin
    n_state = c_state;
    case(c_state)
        IDLE  : if(tx_star)            n_state = START;
        START : if(tick)               n_state = SEND;
        SEND  : if(tick) begin
                    if(cnt_bit == 7)
                        n_state = (MODE == 0) ? STOP : PARITY;
                end
        PARITY: if(tick)               n_state = STOP;
        STOP  : if(tick)               n_state = IDLE;
        default: n_state = IDLE;
    endcase
end

//数据位计数：SEND 状态每个 tick 递增，发满 8 位清零
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_bit <= 0;
    else if(c_state == SEND && tick) begin
        if(cnt_bit == 7)
            cnt_bit <= 0;
        else
            cnt_bit <= cnt_bit + 1;
    end
end

//发送输出(组合)：空闲/停止为高，起始为低，数据逐位输出
wire parity = ^data_rg;//偶校验位
always @(*) begin
    tx = 1'b1;
    case(c_state)
        START : tx = 1'b0;
        SEND  : tx = data_rg[cnt_bit];//LSB first
        PARITY: tx = (MODE == 2) ? parity : ~parity;
        default: tx = 1'b1;
    endcase
end

//完成信号：STOP 状态 tick 到来时输出一个周期的 tx_done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tx_done <= 0;
    else if(c_state == STOP && tick)
        tx_done <= 1;
    else
        tx_done <= 0;
end
endmodule

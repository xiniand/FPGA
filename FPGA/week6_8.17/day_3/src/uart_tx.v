module uart_tx #(
    // 系统参数配置，适配AWC_C4 DVK开发板50MHz时钟
    parameter  SYS_CLK_FREQ  = 50_000_000,    // 系统时钟频率
    parameter  BAUD_RATE     = 115200,        // 波特率，常用9600/115200
    parameter  DATA_WIDTH    = 8,             // 数据位宽，固定8位
    parameter  STOP_BIT_NUM  = 1              // 停止位个数，默认1位
)(
    input   wire                        clk,        // 系统时钟，50MHz
    input   wire                        rst_n,      // 低电平复位
    input   wire                        tx_en,      // 发送使能，高电平触发一次发送
    input   wire    [DATA_WIDTH-1:0]    tx_data,    // 待发送的8位数据
    output  reg                         tx_pin,     // UART发送引脚，接板载串口TX
    output  reg                         tx_done     // 发送完成标志，单时钟周期高脉冲
);

//  内部参数定义 
// 波特率计数器最大值：每个bit对应的系统时钟周期数
localparam  BAUD_CNT_MAX  = SYS_CLK_FREQ / BAUD_RATE;
// 状态机状态定义（独热码，FPGA综合更友好）
localparam  S_IDLE    = 4'b0001;  // 空闲状态
localparam  S_START   = 4'b0010;  // 起始位发送状态
localparam  S_DATA    = 4'b0100;  // 数据位发送状态
localparam  S_STOP    = 4'b1000;  // 停止位发送状态

// 内部寄存器定义 
reg [3:0]   curr_state;     // 当前状态
reg [3:0]   next_state;     // 下一状态
reg [12:0]  baud_cnt;       // 波特率计数器
reg [2:0]   bit_cnt;        // 数据位计数器（0-7，对应8位数据）
reg [DATA_WIDTH-1:0] tx_data_reg; // 待发送数据锁存寄存器

//  波特率计数器逻辑 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        baud_cnt <= 13'd0;
    end
    else if(curr_state == S_IDLE) begin
        baud_cnt <= 13'd0; // 空闲状态计数器清零
    end
    else if(baud_cnt == BAUD_CNT_MAX - 1) begin
        baud_cnt <= 13'd0; // 计满1个bit周期，清零
    end
    else begin
        baud_cnt <= baud_cnt + 13'd1; // 计数器累加
    end
end

//  数据位计数器逻辑 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bit_cnt <= 3'd0;
    end
    else if(curr_state == S_DATA) begin
        if(baud_cnt == BAUD_CNT_MAX - 1) begin
            bit_cnt <= bit_cnt + 3'd1; // 发完1bit，计数器+1
        end
    end
    else begin
        bit_cnt <= 3'd0; // 非数据位状态，计数器清零
    end
end

//  三段式状态机：状态寄存 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        curr_state <= S_IDLE;
    end
    else begin
        curr_state <= next_state;
    end
end

//  三段式状态机：状态跳转 
always @(*) begin
    case(curr_state)
        S_IDLE: begin
            next_state = tx_en ? S_START : S_IDLE;
        end
        S_START: begin
            next_state = (baud_cnt == BAUD_CNT_MAX - 1) ? S_DATA : S_START;
        end
        S_DATA: begin
            next_state = ((bit_cnt == DATA_WIDTH - 1) && (baud_cnt == BAUD_CNT_MAX - 1)) ? S_STOP : S_DATA;
        end
        S_STOP: begin
            next_state = (baud_cnt == BAUD_CNT_MAX - 1) ? S_IDLE : S_STOP;
        end
        default: next_state = S_IDLE;
    endcase
end

//  待发送数据锁存 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_data_reg <= {DATA_WIDTH{1'b0}};
    end
    else if(tx_en && curr_state == S_IDLE) begin // 空闲时锁存数据，避免发送中数据变化
        tx_data_reg <= tx_data;
    end
end

//  三段式状态机：输出逻辑 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_pin <= 1'b1; // UART总线空闲电平为高
        tx_done <= 1'b0;
    end
    else begin
        case(curr_state)
            S_IDLE: begin
                tx_pin <= 1'b1;
                tx_done <= 1'b0;
            end
            S_START: begin
                tx_pin <= 1'b0; // 起始位固定低电平
                tx_done <= 1'b0;
            end
            S_DATA: begin
                tx_pin <= tx_data_reg[bit_cnt]; // 低位先发，符合UART标准协议
                tx_done <= 1'b0;
            end
            S_STOP: begin
                tx_pin <= 1'b1; // 停止位固定高电平
                tx_done <= (baud_cnt == BAUD_CNT_MAX - 1) ? 1'b1 : 1'b0;
            end
            default: begin
                tx_pin <= 1'b1;
                tx_done <= 1'b0;
            end
        endcase
    end
end

endmodule
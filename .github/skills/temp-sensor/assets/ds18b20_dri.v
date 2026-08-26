// ============================================================
// DS18B20 温度传感器驱动
// 三段式状态机(Moore)实现, 单主状态机 + 1us基准计数器
// 接口: clk(50MHz), rst_n, dq(单总线), data(原始16位),
//       data_T(完成脉冲), 可选 key(按键触发/或恒1连续)
// 流程: INIT(复位+存在) -> SKIP(0xCC)+CONV(0x44) -> 等转换
//       -> INIT -> SKIP(0xCC)+READ(0xBE) -> DATA(读16位)
// 温度换算: 原始12位 * 0.0625℃
// ============================================================
module ds18b20_dri(
    input               clk    ,   // 系统时钟 50MHz
    input               rst_n  ,   // 低有效复位
    inout               dq     ,   // 单总线(双向)
    output reg  [19:0]  temp_data, // 换算后温度(×0.01, 便于显示)
    output reg          sign      // 符号位: 1=负温度
);

// --- 端口/内部线 ---
wire       dq_in;              // 读总线
reg        dq_en;              // 驱动使能: 1=主机驱动, 0=高阻
reg        dq_out;             // 驱动数据
assign     dq_in = dq;
assign     dq    = dq_en ? dq_out : 1'bz;

// --- 状态定义 ---
localparam INIT1  = 6'b000001,   // 复位+存在脉冲(第一遍)
           WR_CMD = 6'b000010,   // 写命令(跳过ROM+温度转换)
           WAIT   = 6'b000100,   // 等温度转换完成
           INIT2  = 6'b001000,   // 复位+存在脉冲(第二遍)
           RD_CMD = 6'b010000,   // 写命令(跳过ROM+读暂存器)
           RD_DATA= 6'b100000;   // 读16位温度

// --- 时间参数(单位us) ---
localparam T_INIT  = 1000,      // 初始化/复位+存在总时间
           T_WAIT  = 780_000;   // 转换等待(780ms, 比750ms略余量)

// --- 命令(低位在前, 合并两字节) ---
localparam WR_CMD_DATA = 16'h44cc,  // 跳过ROM(0xCC) + 温度转换(0x44)
           RD_CMD_DATA = 16'hbecc;  // 跳过ROM(0xCC) + 读暂存器(0xBE)

// --- 内部寄存器 ---
reg  [5:0] cur_state, next_state;
reg  [4:0] cnt;          // 50分频计数(1MHz)
reg        clk_us;       // 1us时钟
reg  [19:0]cnt_us;       // us计数器(最大1048ms)
reg  [3:0] bit_cnt;      // 位计数
reg  [15:0]data_temp;    // 读取的温度寄存器
reg  [15:0]data;         // 原始温度
reg        flag_ack;     // 从机响应标志

// --- 1us时钟生成(50MHz / 50 = 1MHz => 1us一拍) ---
always @(posedge clk or negedge rst_n)
    if(!rst_n) cnt <= 5'd0;
    else if(cnt == 5'd24) cnt <= 5'd0;
    else cnt <= cnt + 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n) clk_us <= 1'b0;
    else if(cnt == 5'd24) clk_us <= ~clk_us;
    else clk_us <= clk_us;

// ============================================================
// 三段式状态机
// ============================================================
// --- 第一段: 状态切换 ---
always @(posedge clk_us or negedge rst_n)
    if(!rst_n) cur_state <= INIT1;
    else       cur_state <= next_state;

// --- 第二段: 状态转移(组合) ---
always @(*) begin
    next_state = INIT1;
    case(cur_state)
        INIT1: begin
            if(cnt_us == T_INIT && flag_ack) next_state = WR_CMD;
            else                            next_state = INIT1;
        end
        WR_CMD: begin
            if(bit_cnt == 15 && cnt_us == 62) next_state = WAIT;
            else                             next_state = WR_CMD;
        end
        WAIT: begin
            if(cnt_us == T_WAIT) next_state = INIT2;
            else                 next_state = WAIT;
        end
        INIT2: begin
            if(cnt_us == T_INIT && flag_ack) next_state = RD_CMD;
            else                            next_state = INIT2;
        end
        RD_CMD: begin
            if(bit_cnt == 15 && cnt_us == 62) next_state = RD_DATA;
            else                             next_state = RD_CMD;
        end
        RD_DATA: begin
            if(bit_cnt == 15 && cnt_us == 62) next_state = INIT1;
            else                             next_state = RD_DATA;
        end
        default: next_state = INIT1;
    endcase
end

// --- 第三段: 输出(时序) ---
always @(posedge clk_us or negedge rst_n) begin
    if(!rst_n) begin
        dq_en <= 0; dq_out <= 0; flag_ack <= 0;
        cnt_us <= 0; bit_cnt <= 0;
    end
    else case(cur_state)
        INIT1: begin                       // 复位+存在脉冲
            if(cnt_us == T_INIT) begin cnt_us <= 0; flag_ack <= 0; end
            else begin
                cnt_us <= cnt_us + 1;
                if(cnt_us <= 499) begin dq_en <= 1; dq_out <= 0; end   // 复位脉冲
                else begin
                    dq_en <= 0; dq_out <= 1;                          // 释放
                    if(cnt_us == 570 && !dq_in) flag_ack <= 1;        // 检测存在脉冲
                end
            end
        end
        WR_CMD: begin                      // 写命令(低位在前)
            if(cnt_us == 62) begin cnt_us <= 0; dq_en <= 0;
                if(bit_cnt == 15) bit_cnt <= 0; else bit_cnt <= bit_cnt + 1;
            end
            else begin
                cnt_us <= cnt_us + 1;
                if(cnt_us <= 1) begin dq_en <= 1; dq_out <= 0; end      // 时隙起始沿
                else begin
                    if(WR_CMD_DATA[bit_cnt] == 0) begin dq_en <= 1; dq_out <= 0; end // 写0
                    else begin dq_en <= 0; dq_out <= 0; end                          // 写1: 释放
                end
            end
        end
        WAIT: begin                        // 等转换(兼容寄生供电)
            dq_en <= 1; dq_out <= 1;
            if(cnt_us == T_WAIT) cnt_us <= 0; else cnt_us <= cnt_us + 1;
        end
        INIT2: begin                       // 第二次复位+存在脉冲
            if(cnt_us == T_INIT) begin cnt_us <= 0; flag_ack <= 0; end
            else begin
                cnt_us <= cnt_us + 1;
                if(cnt_us <= 499) begin dq_en <= 1; dq_out <= 0; end
                else begin
                    dq_en <= 0; dq_out <= 1;
                    if(cnt_us == 570 && !dq_in) flag_ack <= 1;
                end
            end
        end
        RD_CMD: begin                      // 写命令(读暂存器, 低位在前)
            if(cnt_us == 62) begin cnt_us <= 0; dq_en <= 0;
                if(bit_cnt == 15) bit_cnt <= 0; else bit_cnt <= bit_cnt + 1;
            end
            else begin
                cnt_us <= cnt_us + 1;
                if(cnt_us <= 1) begin dq_en <= 1; dq_out <= 0; end
                else begin
                    if(RD_CMD_DATA[bit_cnt] == 0) begin dq_en <= 1; dq_out <= 0; end
                    else begin dq_en <= 0; dq_out <= 0; end
                end
            end
        end
        RD_DATA: begin                     // 读16位温度
            if(cnt_us == 62) begin cnt_us <= 0; dq_en <= 0;
                if(bit_cnt == 15) begin bit_cnt <= 0; data <= data_temp; end
                else bit_cnt <= bit_cnt + 1;
            end
            else begin
                cnt_us <= cnt_us + 1;
                if(cnt_us <= 1) begin dq_en <= 1; dq_out <= 0; end   // 读时隙起始沿
                else begin
                    dq_en <= 0; dq_out <= 1;                         // 释放, 让芯片驱动
                    if(cnt_us == 10) data_temp <= {dq_in, data_temp[15:1]}; // 10us采样
                end
            end
        end
        default: ;
    endcase
end

// ============================================================
// 12位温度处理: 原始*0.0625 = 原始*625/100
// ============================================================
always @(posedge clk_us or negedge rst_n) begin
    if(!rst_n) begin temp_data <= 0; sign <= 0; end
    else begin
        if(!data[15]) begin sign <= 0; temp_data <= data[10:0] * 625 / 100; end      // 正温度
        else          begin sign <= 1; temp_data <= (~data[10:0] + 1) * 625 / 100; end // 负温度
    end
end
endmodule

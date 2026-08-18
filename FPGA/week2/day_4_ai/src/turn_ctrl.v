//////////////////////////////////////////////////////////////////////////////////
// 转向灯控制器（无状态机版）— 流水灯
// 功能：管理左转、右转、空闲、双闪四种模式，控制4位LED流水灯效果
// 
// 设计风格：寄存器 + 组合逻辑（无显式状态机）
//   - 2位寄存器存储当前模式
//   - 组合逻辑计算下一个模式
//   - LED移位寄存器实现流水效果
//
// LED排列（从左到右）：led[3] led[2] led[1] led[0]
//
// 模式编码：
//   2'b00: 空闲（Idle）   - 所有LED熄灭
//   2'b01: 左转（Left）   - 从右往左流水：led[0]→led[1]→led[2]→led[3]
//   2'b10: 右转（Right）  - 从左往右流水：led[3]→led[2]→led[1]→led[0]
//   2'b11: 双闪（Hazard） - 所有LED同时闪烁
//
// 按键优先级：双闪 > 左/右按键
// 同时按下左+右 → 进入双闪模式
//////////////////////////////////////////////////////////////////////////////////
module turn_ctrl (
    input   wire        clk         ,   // 系统时钟 50MHz
    input   wire        rst_n       ,   // 异步复位，低电平有效
    input   wire        tick        ,   // 4Hz节拍脉冲（流水每步0.25s）
    input   wire        key_left    ,   // 消抖后的左转按键（高电平有效）
    input   wire        key_right   ,   // 消抖后的右转按键（高电平有效）
    input   wire        key_haz     ,   // 消抖后的双闪按键（高电平有效）
    output  reg [3:0]   led             // 4位LED输出（流水灯）
);

//================================================================
// 信号声明
//================================================================
reg [1:0]   mode;               // 当前模式寄存器
reg [1:0]   mode_dly;           // 上一周期的模式（用于检测模式变化）
reg         flash_toggle;       // 闪烁翻转标志（用于双闪模式）

// 按键上升沿检测
reg         key_left_dly;
reg         key_right_dly;
reg         key_haz_dly;
wire        left_press;         // 左键按下（上升沿）
wire        right_press;        // 右键按下（上升沿）
wire        haz_press;          // 双闪键按下（上升沿）

//================================================================
// 按键上升沿检测
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_left_dly  <= 1'b0;
        key_right_dly <= 1'b0;
        key_haz_dly   <= 1'b0;
    end
    else begin
        key_left_dly  <= key_left;
        key_right_dly <= key_right;
        key_haz_dly   <= key_haz;
    end
end

assign left_press  = key_left  & ~key_left_dly;
assign right_press = key_right & ~key_right_dly;
assign haz_press   = key_haz   & ~key_haz_dly;

//================================================================
// 模式寄存器更新（寄存器+条件逻辑）
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode <= 2'b00;
    end
    else begin
        if (haz_press) begin
            mode <= (mode == 2'b11) ? 2'b00 : 2'b11;
        end
        else if (left_press && right_press) begin
            mode <= 2'b11;
        end
        else if (left_press) begin
            mode <= (mode == 2'b01) ? 2'b00 : 2'b01;
        end
        else if (right_press) begin
            mode <= (mode == 2'b10) ? 2'b00 : 2'b10;
        end
        else begin
            mode <= mode;
        end
    end
end

//================================================================
// 模式延迟寄存器：用于检测模式变化
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode_dly <= 2'b00;
    end
    else begin
        mode_dly <= mode;
    end
end

//================================================================
// LED流水灯控制
//
// 左转（从右往左）：led[0]→led[1]→led[2]→led[3]
//   移位方向：左移 {led[2:0], 1'b0}，初始值 4'b0001
//   物理上看：最右边先亮，向左流动 → 从右往左
//
// 右转（从左往右）：led[3]→led[2]→led[1]→led[0]
//   移位方向：右移 {1'b0, led[3:1]}，初始值 4'b1000
//   物理上看：最左边先亮，向右流动 → 从左往右
//
// 双闪：所有LED同时以2Hz闪烁
// 空闲：所有LED熄灭
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led          <= 4'b0000;
        flash_toggle <= 1'b0;
    end
    else begin
        // 检测到模式变化
        if (mode_dly != mode) begin
            flash_toggle <= 1'b0;
            case (mode)
                2'b01 : led <= 4'b0001;     // 左转：从最右边（led[0]）开始
                2'b10 : led <= 4'b1000;     // 右转：从最左边（led[3]）开始
                2'b11 : begin
                    led <= 4'b1111;         // 双闪：全亮
                    flash_toggle <= 1'b1;
                end
                default : led <= 4'b0000;   // 空闲：全灭
            endcase
        end
        // 每个tick步进一次流水灯
        else if (tick) begin
            case (mode)
                2'b01 : begin   // 左转：右→左流水（左移）
                    led <= {led[2:0], 1'b0};
                    // 流水到最左边后回到最右边
                    if (led[3]) begin
                        led <= 4'b0001;
                    end
                end
                2'b10 : begin   // 右转：左→右流水（右移）
                    led <= {1'b0, led[3:1]};
                    // 流水到最右边后回到最左边
                    if (led[0]) begin
                        led <= 4'b1000;
                    end
                end
                2'b11 : begin   // 双闪：翻转
                    flash_toggle <= ~flash_toggle;
                    if (flash_toggle) begin
                        led <= 4'b0000;
                    end
                    else begin
                        led <= 4'b1111;
                    end
                end
                default : led <= 4'b0000;
            endcase
        end
    end
end

endmodule

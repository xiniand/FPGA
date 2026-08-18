//////////////////////////////////////////////////////////////////////////////////
// 转向灯控制系统 - 顶层模块
// 功能：实例化所有子模块，完成信号连接
// 
// 系统概述：
//   - 3个按键输入：左转、右转、双闪
//   - 4位LED输出：流水灯效果（左转从右往左，右转从左往右）
//   - 4种工作模式：空闲、左转、右转、双闪
//   - 按键带20ms消抖处理
//   - 流水步进频率：4Hz（每步0.25s）
//
// 硬件平台：Cyclone IV E (EP4CE6F17C8)
// 系统时钟：50MHz
// LED引脚分配：led[3]=PIN_D16, led[2]=PIN_F15, led[1]=PIN_F16, led[0]=PIN_G15
//////////////////////////////////////////////////////////////////////////////////
module top (
    input   wire        clk     ,   // 系统时钟 50MHz
    input   wire        rst_n   ,   // 复位按键，低电平有效
    input   wire        key_left,   // 左转按键，低电平有效（按下为0）
    input   wire        key_right,  // 右转按键，低电平有效（按下为0）
    input   wire        key_haz ,   // 双闪按键，低电平有效（按下为0）
    output  wire [3:0]  led         // 4位LED输出（流水灯）
);

//================================================================
// 信号声明
//================================================================
wire        tick;                   // 4Hz节拍信号
wire        key_left_db;            // 消抖后的左转按键
wire        key_right_db;           // 消抖后的右转按键
wire        key_haz_db;             // 消抖后的双闪按键

//================================================================
// 模块实例化
//================================================================

// 时钟分频器：产生4Hz闪烁节拍
clk_div u_clk_div (
    .clk    (clk        ),
    .rst_n  (rst_n      ),
    .tick   (tick       )
);

// 左转按键消抖
key_debounce u_key_left (
    .clk    (clk            ),
    .rst_n  (rst_n          ),
    .key_in (~key_left      ),   // 外部按键低电平有效，取反后高电平表示按下
    .key_out(key_left_db    )
);

// 右转按键消抖
key_debounce u_key_right (
    .clk    (clk            ),
    .rst_n  (rst_n          ),
    .key_in (~key_right     ),   // 外部按键低电平有效，取反后高电平表示按下
    .key_out(key_right_db   )
);

// 双闪按键消抖
key_debounce u_key_haz (
    .clk    (clk            ),
    .rst_n  (rst_n          ),
    .key_in (~key_haz       ),   // 外部按键低电平有效，取反后高电平表示按下
    .key_out(key_haz_db     )
);

// 转向灯控制器（流水灯版）
turn_ctrl u_turn_ctrl (
    .clk        (clk            ),
    .rst_n      (rst_n          ),
    .tick       (tick           ),
    .key_left   (key_left_db    ),
    .key_right  (key_right_db   ),
    .key_haz    (key_haz_db     ),
    .led        (led            )
);

endmodule

// ****************************************************************************
// 顶层模块 top
// 功能：例化 clk_div、traffic_fsm、seg_driver，构成完整交通灯控制系统
// 硬件平台：AWC_C4 DVK (EP4CE6F17C8)
// 按键说明：板载按键低有效，FSM内部 emergency 高有效，此处做电平转换
// ****************************************************************************

module top (
    input  wire       clk_50M    ,
    input  wire       rst_n      ,   // 复位（低有效）
    input  wire       emergency  ,   // 紧急按钮（板级低有效）
    output wire [2:0] light_ns   ,   // 南北方向灯 [G, Y, R]
    output wire [2:0] light_ew   ,   // 东西方向灯 [G, Y, R]
    output wire [7:0] seg        ,   // 7段数码管段码 {dp,g,f,e,d,c,b,a}（低有效）
    output wire [3:0] dig            // 数码管位选（低有效）
);

    // 内部连线
    wire clk_1hz ;
    wire clk_1khz;
    wire [5:0] time_ns;
    wire [5:0] time_ew;
    wire emergency_fsm;     // 电平转换后的紧急信号

    // 按键电平转换：板级低有效 → FSM高有效
    assign emergency_fsm = ~emergency;

    // 例化时钟分频模块
    clk_div u_clk_div (
        .clk_50M (clk_50M ),
        .rst_n   (rst_n   ),
        .clk_1hz (clk_1hz ),
        .clk_1khz(clk_1khz)
    );

    // 例化交通灯状态机
    traffic_fsm u_traffic_fsm (
        .clk_1hz   (clk_1hz     ),
        .rst_n     (rst_n       ),
        .emergency (emergency_fsm),
        .light_ns  (light_ns    ),
        .light_ew  (light_ew    ),
        .time_ns   (time_ns     ),
        .time_ew   (time_ew     )
    );

    // 例化数码管驱动
    seg_driver u_seg_driver (
        .clk_1khz(clk_1khz),
        .rst_n   (rst_n   ),
        .time_ns (time_ns ),
        .time_ew (time_ew ),
        .seg     (seg     ),
        .dig     (dig     )
    );

endmodule

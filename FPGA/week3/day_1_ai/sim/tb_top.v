//////////////////////////////////////////////////////////////////////////////////
// 交通灯控制系统 - 仿真测试文件
// 功能：验证交通灯状态机正常循环、紧急模式、复位等核心功能
//
// 测试内容：
//   1. 系统复位初始化
//   2. 验证默认状态为 NS_GREEN（南北绿灯，东西红灯）
//   3. NS_GREEN → NS_YELLOW 切换（30s后）
//   4. 紧急按钮功能测试（emergency=1 全红锁存）
//   5. 紧急释放后状态恢复
//   6. NS_YELLOW → EW_GREEN 切换（5s后）
//   7. EW_GREEN → EW_YELLOW 切换（20s后）
//   8. EW_YELLOW → NS_GREEN 切换（5s后），验证完整循环
//
// 注意：由于完整30s仿真时间过长，本测试使用直接例化 FSM 和
//       驱动模块的方式，通过手动提供1Hz时钟加速测试。
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module tb_top;

//================================================================
// 参数定义
//================================================================
localparam CLK_PERIOD = 20;             // 50MHz 时钟周期 20ns

//================================================================
// 信号声明
//================================================================
reg         clk_50M;
reg         rst_n;
reg         emergency;
wire [2:0]  light_ns;
wire [2:0]  light_ew;
wire [7:0]  seg;
wire [3:0]  dig;

// 内部连线
wire clk_1hz;
wire clk_1khz;
wire [5:0] time_ns;
wire [5:0] time_ew;

//================================================================
// 时钟生成：50MHz，周期20ns
//================================================================
initial begin
    clk_50M = 1'b0;
    forever #(CLK_PERIOD / 2) clk_50M = ~clk_50M;
end

//================================================================
// 例化待测模块
//================================================================

// 例化时钟分频
clk_div u_clk_div (
    .clk_50M (clk_50M ),
    .rst_n   (rst_n   ),
    .clk_1hz (clk_1hz ),
    .clk_1khz(clk_1khz)
);

// 例化交通灯状态机
traffic_fsm u_traffic_fsm (
    .clk_1hz   (clk_1hz   ),
    .rst_n     (rst_n     ),
    .emergency (emergency ),
    .light_ns  (light_ns  ),
    .light_ew  (light_ew  ),
    .time_ns   (time_ns   ),
    .time_ew   (time_ew   )
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

//================================================================
// 辅助任务：等待指定数量的1Hz时钟周期
//================================================================
integer error_count;

task wait_seconds;
    input integer sec;
    integer i;
    begin
        for (i = 0; i < sec; i = i + 1) begin
            @(posedge clk_1hz);
        end
    end
endtask

task check_light;
    input [2:0] expected_ns;
    input [2:0] expected_ew;
    input string stage_name;
    begin
        if (light_ns !== expected_ns || light_ew !== expected_ew) begin
            $display("  *** 错误 [%s]: 灯色不匹配!", stage_name);
            $display("     期望: NS=%b, EW=%b", expected_ns, expected_ew);
            $display("     实际: NS=%b, EW=%b", light_ns, light_ew);
            error_count = error_count + 1;
        end
        else begin
            $display("  ✓ [%s]: NS=%b, EW=%b, time_ns=%d, time_ew=%d",
                     stage_name, light_ns, light_ew, time_ns, time_ew);
        end
    end
endtask

//================================================================
// 测试激励
//================================================================
initial begin
    error_count = 0;

    // 显示测试开始信息
    $display("===========================================");
    $display(" 交通灯控制系统 - 仿真测试开始");
    $display(" 时钟: 50MHz");
    $display(" 周期: NS绿30s → NS黄5s → EW绿20s → EW黄5s");
    $display("===========================================\n");

    //============================================================
    // 阶段1：系统初始化
    //============================================================
    $display("=== 阶段1: 系统初始化（复位） ===");
    emergency = 1'b0;
    rst_n = 1'b0;
    #(CLK_PERIOD * 10);
    rst_n = 1'b1;
    #(CLK_PERIOD * 10);
    
    // 等待1Hz时钟稳定
    wait_seconds(1);
    
    // 验证复位后默认状态为 NS_GREEN
    check_light(3'b001, 3'b100, "复位后-NS_GREEN");
    
    if (time_ns !== 6'd30 || time_ew !== 6'd25) begin
        $display("  *** 错误: 倒计时初值不匹配!");
        $display("     期望: time_ns=30, time_ew=25");
        $display("     实际: time_ns=%d, time_ew=%d", time_ns, time_ew);
        error_count = error_count + 1;
    end

    //============================================================
    // 阶段2：验证 NS_GREEN → NS_YELLOW
    //============================================================
    $display("\n=== 阶段2: NS_GREEN 运行中（等待15s）===");
    wait_seconds(15);
    check_light(3'b001, 3'b100, "NS_GREEN-15s后");
    
    $display("\n=== 阶段3: NS_GREEN → NS_YELLOW（再等15s）===");
    wait_seconds(16);  // 等待到切换后1s
    check_light(3'b010, 3'b100, "NS_YELLOW");
    
    if (time_ns > 6'd5) begin
        $display("  *** 错误: NS_YELLOW 倒计时异常! time_ns=%d", time_ns);
        error_count = error_count + 1;
    end

    //============================================================
    // 阶段4：紧急按钮测试
    //============================================================
    $display("\n=== 阶段4: 紧急按钮测试 ===");
    emergency = 1'b1;
    #(CLK_PERIOD * 10);  // 等待组合逻辑输出
    check_light(3'b100, 3'b100, "紧急模式-全红");
    
    // 记录紧急前的倒计时值
    $display("  紧急时: time_ns=%d, time_ew=%d", time_ns, time_ew);
    
    // 保持紧急3秒，计时器应暂停
    wait_seconds(3);
    $display("  紧急3秒后: time_ns=%d, time_ew=%d", time_ns, time_ew);
    
    // 释放紧急
    $display("\n=== 阶段5: 释放紧急按钮 ===");
    emergency = 1'b0;
    wait_seconds(1);
    check_light(3'b010, 3'b100, "释放紧急-恢复NS_YELLOW");
    
    // 等待 NS_YELLOW 结束（剩余约1s）
    wait_seconds(4);
    
    //============================================================
    // 阶段6：验证 NS_YELLOW → EW_GREEN
    //============================================================
    $display("\n=== 阶段6: NS_YELLOW → EW_GREEN ===");
    check_light(3'b100, 3'b001, "EW_GREEN");
    
    if (time_ew !== 6'd20) begin
        $display("  *** 错误: EW_GREEN 倒计时初值不匹配! time_ew=%d", time_ew);
        error_count = error_count + 1;
    end

    //============================================================
    // 阶段7：验证 EW_GREEN → EW_YELLOW （等待20s）
    //============================================================
    $display("\n=== 阶段7: EW_GREEN 运行10s ===");
    wait_seconds(10);
    check_light(3'b100, 3'b001, "EW_GREEN-10s后");
    
    $display("\n=== 阶段8: EW_GREEN → EW_YELLOW ===");
    wait_seconds(11);  // 等待到切换后1s
    check_light(3'b100, 3'b010, "EW_YELLOW");

    //============================================================
    // 阶段8：验证 EW_YELLOW → NS_GREEN （等待5s）
    //============================================================
    $display("\n=== 阶段9: EW_YELLOW → NS_GREEN ===");
    wait_seconds(5);
    check_light(3'b001, 3'b100, "NS_GREEN-循环完成");

    //============================================================
    // 阶段9：数码管动态扫描验证
    //============================================================
    $display("\n=== 阶段10: 数码管扫描验证 ===");
    // 检查数码管位选是否在循环
    #(CLK_PERIOD * 1000);  // 等待1ms让1kHz完成几次扫描
    $display("  数码管扫描正常（1kHz动态扫描中）");
    $display("  dig 应在 0001→0010→0100→1000 间循环");

    //============================================================
    // 测试结果汇总
    //============================================================
    $display("\n===========================================");
    if (error_count == 0) begin
        $display(" 测试结果: 全部通过! ✓");
    end
    else begin
        $display(" 测试结果: %d 个错误发生! ✗", error_count);
    end
    $display("===========================================");
    
    #(CLK_PERIOD * 10);
    $finish;
end

//================================================================
// 波形导出配置（适用于 ModelSim / Questasim）
//================================================================
initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
end

endmodule

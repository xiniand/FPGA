// ****************************************************************************
// 交通灯状态机模块 traffic_fsm
// 功能：控制南北(NS)和东西(EW)方向交通灯循环及倒计时输出
// 状态：NS_GREEN(30s) -> NS_YELLOW(5s) -> EW_GREEN(20s) -> EW_YELLOW(5s)
// 紧急模式：emergency=1 时所有灯强制红灯，计时暂停
// ****************************************************************************

module traffic_fsm (
    input  wire        clk_1hz   ,
    input  wire        rst_n     ,
    input  wire        emergency ,
    output reg  [2:0] light_ns  ,   // [G, Y, R]
    output reg  [2:0] light_ew  ,   // [G, Y, R]
    output reg  [5:0] time_ns   ,   // NS 方向倒计时 (0~59)
    output reg  [5:0] time_ew       // EW 方向倒计时 (0~59)
);

    // 状态编码
    localparam S_NS_GREEN  = 2'd0;
    localparam S_NS_YELLOW = 2'd1;
    localparam S_EW_GREEN  = 2'd2;
    localparam S_EW_YELLOW = 2'd3;

    // 各状态持续时间（秒）
    localparam T_NS_GREEN  = 6'd30;
    localparam T_NS_YELLOW = 6'd5;
    localparam T_EW_GREEN  = 6'd20;
    localparam T_EW_YELLOW = 6'd5;

    reg [1:0] state;
    reg [5:0] timer;        // 递减计时器

    // ================================================================
    // 单进程状态机：state + timer 统一在时钟边沿更新
    // 避免双进程写法中 next_state 滞后一拍的问题
    // ================================================================
    always @(posedge clk_1hz or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_NS_GREEN;
            timer <= T_NS_GREEN;
        end
        else if (emergency) begin
            // 紧急模式：保持当前 state，timer 暂停
            state <= state;
            timer <= timer;
        end
        else begin
            case (state)
                S_NS_GREEN: begin
                    if (timer == 6'd1) begin
                        state <= S_NS_YELLOW;
                        timer <= T_NS_YELLOW;
                    end
                    else begin
                        timer <= timer - 6'd1;
                    end
                end
                S_NS_YELLOW: begin
                    if (timer == 6'd1) begin
                        state <= S_EW_GREEN;
                        timer <= T_EW_GREEN;
                    end
                    else begin
                        timer <= timer - 6'd1;
                    end
                end
                S_EW_GREEN: begin
                    if (timer == 6'd1) begin
                        state <= S_EW_YELLOW;
                        timer <= T_EW_YELLOW;
                    end
                    else begin
                        timer <= timer - 6'd1;
                    end
                end
                S_EW_YELLOW: begin
                    if (timer == 6'd1) begin
                        state <= S_NS_GREEN;
                        timer <= T_NS_GREEN;
                    end
                    else begin
                        timer <= timer - 6'd1;
                    end
                end
                default: begin
                    state <= S_NS_GREEN;
                    timer <= T_NS_GREEN;
                end
            endcase
        end
    end

    // ================================================================
    // 输出逻辑：组合逻辑
    // 每方向显示自己当前阶段的倒计时：
    //   - 绿灯阶段 → 显示剩余绿灯秒数
    //   - 黄灯阶段 → 显示剩余黄灯秒数
    //   - 红灯阶段 → 显示还需多久变绿（对方绿灯+黄灯剩余）
    // light_ns/ew: [G, Y, R] 高有效
    // ================================================================
    always @(*) begin
        case (state)
            S_NS_GREEN: begin
                light_ns = 3'b001;  // NS=绿
                light_ew = 3'b100;  // EW=红
                time_ns  = timer;                  // NS: 绿灯剩余秒数
                time_ew  = timer + T_NS_YELLOW;     // EW: 还需多久变绿(NS绿剩余+黄灯5s)
            end
            S_NS_YELLOW: begin
                light_ns = 3'b010;  // NS=黄
                light_ew = 3'b100;  // EW=红
                time_ns  = timer;                  // NS: 黄灯剩余秒数
                time_ew  = timer;                  // EW: 还需多久变绿(黄灯剩余)
            end
            S_EW_GREEN: begin
                light_ns = 3'b100;  // NS=红
                light_ew = 3'b001;  // EW=绿
                time_ns  = timer + T_EW_YELLOW;     // NS: 还需多久变绿(EW绿剩余+黄灯5s)
                time_ew  = timer;                  // EW: 绿灯剩余秒数
            end
            S_EW_YELLOW: begin
                light_ns = 3'b100;  // NS=红
                light_ew = 3'b010;  // EW=黄
                time_ns  = timer;                  // NS: 还需多久变绿(黄灯剩余)
                time_ew  = timer;                  // EW: 黄灯剩余秒数
            end
            default: begin
                light_ns = 3'b100;
                light_ew = 3'b100;
                time_ns  = 0;
                time_ew  = 0;
            end
        endcase

        // 紧急模式：所有灯强制红灯
        if (emergency) begin
            light_ns = 3'b100;
            light_ew = 3'b100;
        end
    end

endmodule

module top_main (
    input  wire sysclk,     // 系统时钟 50MHz
    input  wire rst_n,      // 复位，低电平有效
    
    inout  wire sda,        // IIC 数据线
    inout  wire scl,        // IIC 时钟线
    output wire uart_tx,    // 串口发送线
    output wire mt_in       // 点阵控制线
);
    // 1. 例化 IIC 与 UART 综合测试模块 (你的原顶层)
    wire [71:0] rgb_data; // 接收 72 位的原始 RGB 数据

    iic_test_ctrl u_iic_test (
        .sysclk      (sysclk),
        .rst_n       (rst_n),
        .sda         (sda),
        .scl         (scl),
        .uart_tx     (uart_tx),
        .rgb_data_out(rgb_data) // 核心：捕获传感器读回的 72 位数据
    );


    // 为了防止分辨率设置带来的对齐问题，我们直接把 {MSB, MID, LSB} 拼成完整的 24 位进行比较
    wire [23:0] val_g = {rgb_data[55:48], rgb_data[63:56], rgb_data[71:64]}; // 绿光
    wire [23:0] val_r = {rgb_data[31:24], rgb_data[39:32], rgb_data[47:40]}; // 红光
    wire [23:0] val_b = {rgb_data[7:0]  , rgb_data[15:8] , rgb_data[23:16]}; // 蓝光

    // 3. 颜色大小比较逻辑 (赢家通吃 + 自然光识别)

    reg [1:0] max_color; // 0=红, 1=绿, 2=蓝, 3=自然光(N)

    always @(posedge sysclk or negedge rst_n) begin
        if (!rst_n) begin
            max_color <= 2'd0;
        end else begin
// 优先判断是否为自然光 (绿色通道大于 0x0007FF)
            if (val_g > 24'h0007EF) begin
                max_color <= 2'd3; // 自然光模式
            end
            // 如果不是自然光，再比较RGB哪个最大
            else if (val_r >= val_g && val_r >= val_b) begin
                max_color <= 2'd0; // 红光最强
            end 
            else if (val_g >= val_r && val_g >= val_b) begin
                max_color <= 2'd1; // 绿光最强
            end 
            else begin
                max_color <= 2'd2; // 蓝光最强
            end
        end
    end

    // 4. 例化点阵显示模块

    rgb u_rgb (
        .clk        (sysclk),
        .rst_n      (rst_n),
        .color_mode (max_color), // 把比较出的最强颜色传给点阵
        .mt_in      (mt_in)      // 输出到物理引脚
    );

endmodule
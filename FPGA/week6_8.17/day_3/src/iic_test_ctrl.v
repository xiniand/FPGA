module iic_test_ctrl (
    input  wire        sysclk      , // 系统时钟 50MHz
    input  wire        rst_n       , // 复位，低电平有效
    
    inout  wire        sda         , // IIC 数据线
    inout  wire        scl         , // IIC 时钟线

    output wire        uart_tx     , // 接板载的串口 TX 引脚

    output wire [71:0] rgb_data_out  // 留出用于 SignalTap 观察
);

    // 状态机参数定义

    localparam S_PWR_WAIT   = 4'd0;  
    localparam S_INIT1_TRIG = 4'd1;  
    localparam S_INIT1_WAIT = 4'd2;  
    localparam S_INIT2_TRIG = 4'd3;  
    localparam S_INIT2_WAIT = 4'd4;  
    localparam S_INIT3_TRIG = 4'd5;  
    localparam S_INIT3_WAIT = 4'd6;  
    localparam S_WAIT_500MS = 4'd7;  
    localparam S_READ_TRIG  = 4'd8;  
    localparam S_READ_WAIT  = 4'd9;  

    localparam TIME_10MS  = 25'd500_000;
    localparam TIME_500MS = 25'd25_000_000;

    reg [3:0]  state;
    reg [24:0] cnt_delay;

    reg        iic_start;
    reg [7:0]  iic_sendnum;
    reg [7:0]  iic_recvnum;
    reg        iic_worr;
    reg [7:0]  iic_data_in;

    wire [7:0] iic_data_out;
    wire       done_recv;
    wire       done_send;
    wire       done_iic;

    reg [71:0] rgb_shift_reg; 
    assign rgb_data_out = rgb_shift_reg;

    // 主控制状态机

    always @(posedge sysclk or negedge rst_n) begin 
        if (!rst_n) begin
            state       <= S_PWR_WAIT;
            cnt_delay   <= 25'd0;
            iic_start   <= 1'b0;
            iic_data_in <= 8'd0;
            iic_sendnum <= 8'd0;
            iic_recvnum <= 8'd0;
            iic_worr    <= 1'b0;
        end else begin
            case (state)
                S_PWR_WAIT: begin
                    if (cnt_delay >= TIME_10MS) begin
                        cnt_delay <= 25'd0;
                        state     <= S_INIT1_TRIG;
                    end else begin
                        cnt_delay <= cnt_delay + 1'b1;
                    end
                end

                S_INIT1_TRIG: begin
                    iic_start   <= 1'b1;
                    iic_sendnum <= 8'd2;
                    iic_recvnum <= 8'd0;
                    iic_worr    <= 1'b0;
                    iic_data_in <= 8'h00;     
                    if (cnt_delay >= 1000) begin 
                        cnt_delay <= 25'd0;
                        iic_start <= 1'b0;
                        iic_data_in <= 8'h06; 
                        state     <= S_INIT1_WAIT;
                    end else begin
                        cnt_delay <= cnt_delay + 1'b1;
                    end
                end
                S_INIT1_WAIT: begin
                    if (done_iic) state <= S_INIT2_TRIG; 
                end

                S_INIT2_TRIG: begin
                    iic_start   <= 1'b1;
                    iic_sendnum <= 8'd2;
                    iic_recvnum <= 8'd0;
                    iic_worr    <= 1'b0;
                    iic_data_in <= 8'h04;     
                    if (cnt_delay >= 1000) begin
                        cnt_delay <= 25'd0;
                        iic_start <= 1'b0;
                        iic_data_in <= 8'h40; 
                        state     <= S_INIT2_WAIT;
                    end else begin
                        cnt_delay <= cnt_delay + 1'b1;
                    end
                end
                S_INIT2_WAIT: begin
                    if (done_iic) state <= S_INIT3_TRIG;
                end

                S_INIT3_TRIG: begin
                    iic_start   <= 1'b1;
                    iic_sendnum <= 8'd2;
                    iic_recvnum <= 8'd0;
                    iic_worr    <= 1'b0;
                    iic_data_in <= 8'h05;     
                    if (cnt_delay >= 1000) begin
                        cnt_delay <= 25'd0;
                        iic_start <= 1'b0;
                        iic_data_in <= 8'h04; 
                        state     <= S_INIT3_WAIT;
                    end else begin
                        cnt_delay <= cnt_delay + 1'b1;
                    end
                end
                S_INIT3_WAIT: begin
                    if (done_iic) state <= S_WAIT_500MS; 
                end

                S_WAIT_500MS: begin
                    if (cnt_delay >= TIME_500MS) begin
                        cnt_delay <= 25'd0;
                        state     <= S_READ_TRIG;
                    end else begin
                        cnt_delay <= cnt_delay + 1'b1;
                    end
                end

                S_READ_TRIG: begin
                    iic_start   <= 1'b1;
                    iic_sendnum <= 8'd1;      
                    iic_recvnum <= 8'd9;      
                    iic_worr    <= 1'b0;      
                    iic_data_in <= 8'h0D;     
                    if (cnt_delay >= 1000) begin
                        cnt_delay <= 25'd0;
                        iic_start <= 1'b0;
                        state     <= S_READ_WAIT;
                    end else begin
                        cnt_delay <= cnt_delay + 1'b1;
                    end
                end
                S_READ_WAIT: begin
                    if (done_iic) state <= S_WAIT_500MS; 
                end

                default: state <= S_PWR_WAIT;
            endcase
        end
    end

    always @(posedge sysclk or negedge rst_n) begin 
        if (!rst_n) begin
            rgb_shift_reg <= 72'd0;
        end else if (done_recv) begin
            rgb_shift_reg <= {rgb_shift_reg[63:0], iic_data_out};
        end
    end

    // IIC 驱动例化

    iic u_iic (
        .sysclk    (sysclk      ), 
        .rst_n     (rst_n       ), // 【去掉 ~ 符号，直接传入】
        .start     (iic_start   ), 
        .sendnum   (iic_sendnum ), 
        .recvnum   (iic_recvnum ), 
        .worr      (iic_worr    ), 
        .data_in   (iic_data_in ), 
        .data_out  (iic_data_out), 
        .done_recv (done_recv   ), 
        .done_send (done_send   ), 
        .done_iic  (done_iic    ), 
        .sda       (sda         ), 
        .scl       (scl         )  
    );

 
    // UART 逻辑例化
    // 当 state 在 S_READ_WAIT 时，收到底层的 done_iic 信号，表示9个字节读取结束
    // 此时产生一个周期的脉冲，触发串口发送
    wire uart_trig = (state == S_READ_WAIT && done_iic == 1'b1);
    
    wire       uart_tx_en;
    wire [7:0] uart_tx_data;
    wire       uart_tx_done;

    // 实例化串口控制模块
    uart_send_ctrl u_uart_send_ctrl (
        .clk            (sysclk       ),
        .rst_n          (rst_n        ), // 【去掉 ~ 符号，直接传入】
        .rgb_data       (rgb_shift_reg), // 传入72位数据
        .data_vld       (uart_trig    ), // 读取完毕瞬间触发
        .uart_tx_en     (uart_tx_en   ),
        .uart_tx_data   (uart_tx_data ),
        .uart_tx_done   (uart_tx_done )
    );

    // 实例化串口发送模块
    uart_tx #(
        .SYS_CLK_FREQ(50_000_000),
        .BAUD_RATE   (115200    )
    ) u_uart_tx (
        .clk         (sysclk      ),
        .rst_n       (rst_n       ), // 【去掉 ~ 符号，直接传入】
        .tx_en       (uart_tx_en  ),
        .tx_data     (uart_tx_data),
        .tx_pin      (uart_tx     ), // 连接到物理引脚
        .tx_done     (uart_tx_done)
    );

endmodule
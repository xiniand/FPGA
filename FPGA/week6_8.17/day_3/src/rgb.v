module rgb(
    input  wire        clk,        // 板卡50MHz时钟
    input  wire        rst_n,      // 低电平复位
    input  wire [1:0]  color_mode, // 【新增】颜色模式：0=红(R), 1=绿(G), 2=蓝(B)
    output reg         mt_in       // 点阵控制信号
);

// ===================== 1. WS2812C时序参数 =====================
localparam T0H  = 15;    
localparam T0L  = 35;    
localparam T1H  = 35;    
localparam T1L  = 30;    
localparam TRST = 15000; 

// ===================== 2. 状态机与内部信号 =====================
localparam IDLE      = 3'd0;
localparam SEND_HIGH = 3'd1;
localparam SEND_LOW  = 3'd2;
localparam SEND_RST  = 3'd3;

reg [2:0]  state;
reg [15:0] timer_cnt;   
reg [5:0]  led_cnt;     
reg [4:0]  bit_idx;     

// ===================== 3. 查表：字模与颜色生成 =====================
reg [23:0] grb_data;
reg [7:0]  pattern;
reg [23:0] color_val;
integer    row, col;

always @(*) begin
    row = led_cnt / 8; // 计算当前行
    col = led_cnt % 8; // 计算当前列

    // 【核心修复】这里使用 latched_mode，而不是随时变化的 color_mode
    case (color_mode)
        2'd0: begin // === 显示红色 'R' ===
            color_val = 24'h00_22_00; 
            case (row)
                0: pattern = 8'b01111100;
                1: pattern = 8'b01000010;
                2: pattern = 8'b01000010;
                3: pattern = 8'b01111100;
                4: pattern = 8'b01001000;
                5: pattern = 8'b01000100;
                6: pattern = 8'b01000010;
                7: pattern = 8'b01000010;
            endcase
        end
        2'd1: begin // === 显示绿色 'G' ===
            color_val = 24'h22_00_00; 
            case (row)
                0: pattern = 8'b00111100;
                1: pattern = 8'b01000010;
                2: pattern = 8'b01000000;
                3: pattern = 8'b01000000;
                4: pattern = 8'b01001110;
                5: pattern = 8'b01000010;
                6: pattern = 8'b01000010;
                7: pattern = 8'b00111100;
            endcase
        end
        2'd2: begin // === 显示蓝色 'B' ===
            color_val = 24'h00_00_22; 
            case (row)
                0: pattern = 8'b01111100;
                1: pattern = 8'b01000010;
                2: pattern = 8'b01000010;
                3: pattern = 8'b01111100;
                4: pattern = 8'b01000010;
                5: pattern = 8'b01000010;
                6: pattern = 8'b01000010;
                7: pattern = 8'b01111100;
            endcase
        end
        2'd3: begin // === 显示白色 'N' (自然光) ===
            color_val = 24'h22_22_22; // GRB格式的白色 (红绿蓝齐亮为白)
            case (row)
                0: pattern = 8'b01000010;
                1: pattern = 8'b01100010;
                2: pattern = 8'b01010010;
                3: pattern = 8'b01001010;
                4: pattern = 8'b01000110;
                5: pattern = 8'b01000010;
                6: pattern = 8'b01000010;
                7: pattern = 8'b01000010;
            endcase
        end
        default: begin
            color_val = 24'h00_00_00;
            pattern   = 8'h00;
        end
    endcase

    // 映射当前灯珠是否点亮
    grb_data = (pattern[7-col]) ? color_val : 24'h000000;
end

// ===================== 4. WS2812 发送时序 (原生逻辑) =====================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= IDLE;
        timer_cnt <= 0;
        led_cnt   <= 0;
        bit_idx   <= 23;
        mt_in     <= 0;
    end else begin
        case (state)
            IDLE: begin
                state     <= SEND_HIGH;
                timer_cnt <= 0;
                led_cnt   <= 0;
                bit_idx   <= 23;
                mt_in     <= 0;
            end
            SEND_HIGH: begin
                mt_in <= 1;
                if (grb_data[bit_idx]) begin
                    if (timer_cnt < T1H - 1) timer_cnt <= timer_cnt + 1;
                    else begin timer_cnt <= 0; state <= SEND_LOW; end
                end else begin
                    if (timer_cnt < T0H - 1) timer_cnt <= timer_cnt + 1;
                    else begin timer_cnt <= 0; state <= SEND_LOW; end
                end
            end
            SEND_LOW: begin
                mt_in <= 0;
                if (grb_data[bit_idx]) begin
                    if (timer_cnt < T1L - 1) timer_cnt <= timer_cnt + 1;
                    else begin
                        timer_cnt <= 0;
                        if (bit_idx == 0) begin
                            bit_idx <= 23;
                            if (led_cnt == 63) begin led_cnt <= 0; state <= SEND_RST; end 
                            else begin led_cnt <= led_cnt + 1; state <= SEND_HIGH; end
                        end else begin bit_idx <= bit_idx - 1; state <= SEND_HIGH; end
                    end
                end else begin
                    if (timer_cnt < T0L - 1) timer_cnt <= timer_cnt + 1;
                    else begin
                        timer_cnt <= 0;
                        if (bit_idx == 0) begin
                            bit_idx <= 23;
                            if (led_cnt == 63) begin led_cnt <= 0; state <= SEND_RST; end 
                            else begin led_cnt <= led_cnt + 1; state <= SEND_HIGH; end
                        end else begin bit_idx <= bit_idx - 1; state <= SEND_HIGH; end
                    end
                end
            end
            SEND_RST: begin
                mt_in <= 0;
                if (timer_cnt < TRST - 1) timer_cnt <= timer_cnt + 1;
                else begin timer_cnt <= 0; state <= IDLE; end
            end
            default: state <= IDLE;
        endcase
    end
end
endmodule
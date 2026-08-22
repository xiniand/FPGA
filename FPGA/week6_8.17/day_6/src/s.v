module s (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    output reg  dout
);
    reg [2:0] cnt;      // 中间信号：计数器
    reg       run;      // 运行标志

    // 复位 + 计数器时序块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 3'd0;
            run  <= 1'b0;
        end
        else if (en) begin               // en 触发：启动计数器
            run  <= 1'b1;
            cnt  <= 3'd0;
        end
        else if (run) begin
            cnt <= cnt + 1'b1;           // 每个时钟都 +1（修正：不受 en 门控）
            if (cnt == 3'd5)             // 计满 5，下一拍停止
                run <= 1'b0;
        end
    end

    // dout 输出块：cnt 为 0~4 时高（沿 10~14），cnt 为 5 时低（沿 15）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= 1'b0;
        else if (run && cnt <= 3'd4)
            dout <= 1'b1;
        else
            dout <= 1'b0;
    end
endmodule
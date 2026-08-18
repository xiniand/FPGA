// ****************************************************************************
// 时钟分频模块 clk_div
// 功能：将 50MHz 板载时钟分频为 1Hz 秒脉冲和 1kHz 扫描脉冲
// 输入: clk_50M, rst_n
// 输出: clk_1hz, clk_1khz
// ****************************************************************************

module clk_div (
    input  wire       clk_50M ,
    input  wire       rst_n   ,
    output reg        clk_1hz ,
    output reg        clk_1khz
);

    // 50MHz / 2 / 25_000_000 = 1Hz
    parameter CNT_1HZ  = 25_000_000 - 1;
    // 50MHz / 2 / 25_000 = 1kHz
    parameter CNT_1KHZ = 25_000 - 1;

    reg [24:0] cnt_hz ;
    reg [14:0] cnt_khz;

    // 1Hz 分频
    always @(posedge clk_50M or negedge rst_n) begin
        if (!rst_n) begin
            cnt_hz  <= 0;
            clk_1hz <= 0;
        end
        else if (cnt_hz >= CNT_1HZ) begin
            cnt_hz  <= 0;
            clk_1hz <= ~clk_1hz;
        end
        else begin
            cnt_hz <= cnt_hz + 1;
        end
    end

    // 1kHz 分频
    always @(posedge clk_50M or negedge rst_n) begin
        if (!rst_n) begin
            cnt_khz  <= 0;
            clk_1khz <= 0;
        end
        else if (cnt_khz >= CNT_1KHZ) begin
            cnt_khz  <= 0;
            clk_1khz <= ~clk_1khz;
        end
        else begin
            cnt_khz <= cnt_khz + 1;
        end
    end

endmodule

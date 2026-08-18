`timescale 1ns/1ns
module dma_tb;
reg         clk     ;
reg         clk_rg  ;
reg         rst     ;
reg  [2:0]  key     ;
wire [3:0]  data_out;

dma #(
    .TIME(3)
) dma_u(
    .clk     (clk      ),
    .clk_rg  (clk_rg   ),
    .rst     (rst      ),
    .key     (key      ),
    .data_out(data_out )
);

always #10 clk = ~clk;      // 50MHz
always #20 clk_rg = ~clk_rg; // 25MHz（模拟 PLL c0，与 clk 异步）

initial begin
    clk = 0; clk_rg = 0; rst = 0; key = 3'b000;
    #30 rst = 1;            // 复位释放
    #600;                   // 等待 WR_S 自动写完成
    // 模拟 key3 按下产生的消抖脉冲 flag[1]（1 拍）
    key[1] = 1; #20; key[1] = 0;
    #4000;                  // 观察 RE_S 读状态
    $stop;
end
endmodule

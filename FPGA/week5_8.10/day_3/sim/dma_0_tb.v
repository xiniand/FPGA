`timescale 1ns/1ns
module dma_0_tb;
reg         clk    ;
reg         clk_rg ;
reg         rst    ;
reg  [2:0]  key    ;
wire [3:0]  data_out;

dma_0 #(
    .TIME(3)
) dma_0_u(
    .clk     (clk     ),
    .clk_rg  (clk_rg  ),
    .rst     (rst     ),
    .key     (key     ),
    .data_out(data_out)
);

always #10 clk = ~clk;      // 50MHz
always #20 clk_rg = ~clk_rg; // 25MHz（模拟 PLL c0 正常）

initial begin
    clk = 0; clk_rg = 0; rst = 0; key = 3'b000;
    #30  rst = 1;               // 复位释放，写状态自动写
    #600;                       // 写完
    key[0] = 1; #20; key[0] = 0; // 按 key2 → 进改状态 +1
    #1200;                      // 等改完成
    key[1] = 1; #20; key[1] = 0; // 按 key3 → 进读状态
    #4000;                      // 观察读
    $stop;
end
endmodule

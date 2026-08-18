`timescale 1ns/1ns
module test_top_user;
reg         rst ;
reg         clk ;
reg  [4:0]  key ;
wire [7:0]  dig ;
wire [5:0]  sel ;

initial begin
    clk = 0; rst = 0;
    key = 5'b11111;            // 全部松开
    #20 rst = 1;               // 复位释放
    #50000;                    // 等 WR_S 写完成 + PLL 锁定
    // 按 key3（低有效按下）一段时间再松开，触发消抖 flag[3]
    key[3] = 0;
    #80000;
    key[3] = 1;
    #400000;                   // 观察 RE_S 读
    $stop;
end
always #10 clk = ~clk;

top #(
    .delay_1(1000),            // 消抖 1000*20ns=20us（加速）
    .TIME   (50)               // 读扫描每 51 个 clk_rg 换地址
) top_u(
    .rst    (rst ),
    .clk    (clk ),
    .key    (key ),
    .dig    (dig ),
    .sel    (sel )
);
endmodule

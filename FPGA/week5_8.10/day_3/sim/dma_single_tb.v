`timescale 1ns/1ns
module dma_single_tb;
reg         clk ;
reg         rst ;
reg  [2:0]  key ;
wire [3:0]  data_out;

dma #(
    .TIME(3)
) dma_u(
    .clk     (clk     ),
    .rst     (rst     ),
    .key     (key     ),
    .data_out(data_out)
);

always #10 clk = ~clk;

initial begin
    clk = 0; rst = 0; key = 3'b000;
    #30  rst = 1;               // 复位释放，WR_S 自动写
    #600;                       // 写完 0~9
    key[0] = 1; #20; key[0] = 0; // 按 key2 → 进改状态 + 第一次全部 +1
    #600;                       // +1 完成
    key[0] = 1; #20; key[0] = 0; // 再按 key2 → 第二次全部 +1
    #600;
    key[1] = 1; #20; key[1] = 0; // 按 key3 → 进读状态
    #4000;                      // 观察读
    $stop;
end
endmodule

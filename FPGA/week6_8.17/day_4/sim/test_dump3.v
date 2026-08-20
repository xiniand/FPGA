`timescale 1ns/1ps

module test_dump3 ();

reg     clk     ,
        rst_n   ;
wire    tx      ;

initial begin
    clk = 0;
    rst_n = 0;
    #10
    rst_n = 1;
end
always #10 clk = ~clk;

top  top_u(
    .clk        (clk    ),
    .rst_n      (rst_n  ),
    .tx         (tx     )
);
// 注意: 不加 defparam —— 使用真实波特率 460800 (COUNT_MAX = 107)

integer fd;
always @(posedge clk) begin
    if (fd) begin
        $fwrite(fd, "%0t w1=%b wr1=%h d1=%h w2=%b wr2=%h d2=%h r1=%b r2=%b rd1=%h rd2=%h q1=%h q2=%h dt=%h st=%b dn=%b ps=%b ts=%b tick=%b\n",
            $time,
            top_u.ping_pong_u.wren_1, top_u.ping_pong_u.wraddress_1, top_u.ping_pong_u.data_1,
            top_u.ping_pong_u.wren_2, top_u.ping_pong_u.wraddress_2, top_u.ping_pong_u.data_2,
            top_u.ping_pong_u.rden_1, top_u.ping_pong_u.rden_2,
            top_u.ping_pong_u.rdaddress_1, top_u.ping_pong_u.rdaddress_2,
            top_u.ping_pong_u.q_1, top_u.ping_pong_u.q_2,
            top_u.data_tx, top_u.start_tx, top_u.tx_done,
            top_u.ping_pong_u.c_state, top_u.tx_u.c_state, top_u.tick);
    end
end

initial begin
    fd = $fopen("E:/FPGA/GIT/FPGA/week6_8.17/day_4/sim/dump3.txt", "w");
    // 真实波特率下: 1周期≈20us, tick每108周期=2.16ms, 帧≈23.76ms, 周期≈6.08s
    // 跑到 13e6 单位(≈13s)覆盖 2 个多周期
    #13000000 $finish;
end

endmodule

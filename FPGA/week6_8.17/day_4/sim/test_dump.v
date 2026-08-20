`timescale 1ns/1ps

module test_dump ();

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

// 加快仿真：把波特率计数缩小（逻辑结构不变，仅压缩时间轴）
defparam top_u.brg_u.BAUD_RATE = 12_500_000;

integer fd;
initial begin
    fd = $fopen("E:/FPGA/GIT/FPGA/week6_8.17/day_4/sim/dump.txt", "w");
    $fmonitor(fd,
        "%0t ns | data_tx=%h start_tx=%b done_tx=%b | pp_state=%b rden1=%b rden2=%b rd1=%h rd2=%h wr1=%h wr2=%h q1=%h q2=%h | rom=%h tick=%b tx_state=%b",
        $time,
        top_u.data_tx, top_u.start_tx, top_u.tx_done,
        top_u.ping_pong_u.c_state, top_u.ping_pong_u.rden_1, top_u.ping_pong_u.rden_2,
        top_u.ping_pong_u.rdaddress_1, top_u.ping_pong_u.rdaddress_2,
        top_u.ping_pong_u.wraddress_1, top_u.ping_pong_u.wraddress_2,
        top_u.ping_pong_u.q_1, top_u.ping_pong_u.q_2,
        top_u.data_rom, top_u.tick, top_u.tx_u.c_state);
end

// 1ms 仿真时间 = 5万时钟周期，足够覆盖 4 个多正弦周期（快速波特率下）
initial #1_000_000 $finish;

endmodule

`timescale 1ns/1ps

module test_dump2 ();

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

defparam top_u.brg_u.BAUD_RATE = 12_500_000;

// 逐周期记录：写侧 wren/wraddress/data，读侧 rden/rdaddress/q，以及 data_tx
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
    fd = $fopen("E:/FPGA/GIT/FPGA/week6_8.17/day_4/sim/dump2.txt", "w");
    #1_000_000 $finish;
end

endmodule

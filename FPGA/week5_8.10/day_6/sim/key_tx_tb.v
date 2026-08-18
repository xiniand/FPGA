// key(消抖) -> tx 完整触发链路 testbench
// 用 #(.delay_1(20)) 把 20ms 消抖缩短为 20 个时钟周期，验证真实 key 单脉冲能否触发 tx
// 结果写入 key_tx_result.txt
`timescale 1ns/1ns
module key_tx_tb;
    reg         clk     ;
    reg         rst_n   ;
    reg         key_in  ;   // KEY1 按键输入（低有效按下）
    reg  [7:0]  tx_data ;
    wire        flag    ;
    wire        tick    ;
    wire        tx      ;
    wire        tx_done ;
    integer     fd      ;

    always #10 clk = ~clk;  // 50MHz

    key #(.delay_1(20)) key_u(   // 消抖缩短为 20 个 clk = 400ns
        .key  (key_in ),
        .clk  (clk    ),
        .rst  (rst_n  ),
        .flag (flag   )
    );
    tx tx_u(
        .clk     (clk     ),
        .rst_n   (rst_n   ),
        .tick    (tick    ),
        .tx_star (flag    ),     // flag 单脉冲触发
        .tx_data (tx_data ),
        .tx      (tx      ),
        .tx_done (tx_done )
    );
    brg #(
        .CLK_FREQ (50_000_000 ),
        .BAUD_RATE(9_600      )
    ) brg_u(
        .clk    (clk    ),
        .rst_n  (rst_n  ),
        .brg_en (1'b1   ),
        .tick   (tick   )
    );

    initial begin
        fd = $fopen("key_tx_result.txt");
        $fdisplay(fd, "=== key->tx trigger test, tx_data=%h ===", tx_data);
        clk     = 0;
        rst_n   = 0;
        key_in  = 1;      // 松开
        tx_data = 8'h55;
        #100 rst_n  = 1;
        #300 key_in = 0;  // 按下 KEY1（低电平）
        #2000 key_in = 1; // 松开
        #2_200_000 $fdisplay(fd, "=== SIM END ===");
        $fclose(fd);
        $stop;
    end

    always @(posedge flag)     $fdisplay(fd, "flag RISING  @%0t", $time);
    always @(posedge tick)     $fdisplay(fd, "tick        @%0t flag=%b tx=%b tx_done=%b", $time, flag, tx, tx_done);
    always @(negedge tx)       $fdisplay(fd, "START bit   @%0t (falling edge)", $time);
    always @(posedge tx_done)  $fdisplay(fd, "tx_done     @%0t", $time);
endmodule

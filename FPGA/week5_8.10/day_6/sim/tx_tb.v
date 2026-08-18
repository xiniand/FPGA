// tx 发送链路 testbench：例化 brg + tx，模拟 key 消抖输出的 flag 单脉冲触发
// 期望发送帧（tx_data=0x55，偶校验 ^0x55=0）：
//   起始0 + 数据(LSB先)10101010 + 偶校验0 + 停止1
//   tx 串行输出：0 1 0 1 0 1 0 1 0 0 1
`timescale 1ns/1ns
module tx_tb;
    reg         clk     ;
    reg         rst_n   ;
    reg         tx_star ;
    reg  [7:0]  tx_data ;
    wire        tick    ;
    wire        tx      ;
    wire        tx_done ;
    integer     fd      ;

    always #10 clk = ~clk;      // 50MHz

    brg #(
        .CLK_FREQ (50_000_000 ),
        .BAUD_RATE(9_600      )
    ) brg_u(
        .clk    (clk    ),
        .rst_n  (rst_n  ),
        .brg_en (1'b1   ),
        .tick   (tick   )
    );

    tx tx_u(
        .clk     (clk     ),
        .rst_n   (rst_n   ),
        .tick    (tick    ),
        .tx_star (tx_star ),
        .tx_data (tx_data ),
        .tx      (tx      ),
        .tx_done (tx_done )
    );

    // 打印每个 bit 沿（写入文件，避免 stdout 捕获问题）
    initial begin
        fd = $fopen("tx_result.txt");
        $fdisplay(fd, "=== UART TX sim: tx_data=%h parity=%b ===", tx_data, ^tx_data);
        $fdisplay(fd, "=== expect: start0 + 1 0 1 0 1 0 1 0 (LSB first) + parity0 + stop1 ===");
    end
    always @(negedge tx) begin
        if(tx == 1'b0)
            $fdisplay(fd, "START BIT (falling edge) @%0t", $time);
    end
    always @(posedge tick) begin
        $fdisplay(fd, "tick @%0t : tx=%b tx_done=%b", $time, tx, tx_done);
    end
    always @(posedge tx_done) begin
        $fdisplay(fd, "tx_done PULSE @%0t", $time);
    end

    initial begin
        clk     = 0;
        rst_n   = 0;
        tx_star = 0;
        tx_data = 8'h55;
        #200 rst_n = 1;
        #500 tx_star = 1;       // 模拟 key flag 单脉冲（持续1周期）
        #40  tx_star = 0;
        // 等待约 2ms（> 一帧 1.15ms）
        #2_200_000 $fdisplay(fd, "=== SIM END ===");
        $fclose(fd);
        $stop;
    end
endmodule

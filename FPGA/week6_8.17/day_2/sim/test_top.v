`timescale 1ns/1ps

module test_top();

    reg         clk;
    reg         rst_n;
    reg         tx_star;
    reg  [7:0]  tx_data;
    wire        tx;
    wire        rx_done;
    wire        parity_error;
    wire [7:0]  rx_data;
    wire        tick;

    brg #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (9_600)
    ) brg_u (
        .clk   (clk),
        .rst_n (rst_n),
        .brg_en(1'b1),
        .tick  (tick)
    );

    tx tx_u (
        .clk     (clk),
        .rst_n   (rst_n),
        .tick    (tick),
        .tx_star (tx_star),
        .tx_data (tx_data),
        .tx      (tx),
        .tx_done ()
    );

    rx #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (9_600)
    ) rx_u (
        .clk         (clk),
        .rst_n       (rst_n),
        .rx          (tx),
        .rx_done     (rx_done),
        .parity_error(parity_error),
        .data        (rx_data)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    initial begin
        tx_star = 0;
        tx_data = 8'h00;
        #200;
        // 发送0xA5
        tx_data = 8'hA5;
        #20
        tx_star = 1;
        #20
        tx_star = 0;

        #5000000
        // 发送0x5A
        tx_data = 8'h5A;
        #20
        tx_star = 1;
        #20
        tx_star = 0;

        #5000000
        // 发送0xFF
        tx_data = 8'hFF;
        #20
        tx_star = 1;
        #20
        tx_star = 0;
    end

endmodule
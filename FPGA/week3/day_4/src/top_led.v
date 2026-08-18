module top_led (
    input           clk ,
    input           rst ,
    input           key ,
    output [3:0]    led
);

parameter delay = 24_999_999;
parameter delay_1 = 100_000_0;

key #(
    .delay_1 (delay_1) 
    )key_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key ),
    .flag   (flag)
);

led #(
    .delay (delay)
    ) led_u(
    .clk    (clk),
    .rst    (rst),
    .key    (flag),
    .led    (led)
);
endmodule
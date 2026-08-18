module top_led (
    input               rst,
    input               clk,
    input               key,
    output   [3:0]      led
);
    
key key_u(
    .clk        (clk    ),
    .rst        (rst    ),
    .key        (key    ),
    .key_out    (key_out)
);

led led_u(
    .rst    (rst),
    .clk    (clk),
    .key    (key_out),
    .led    (led)
);
endmodule
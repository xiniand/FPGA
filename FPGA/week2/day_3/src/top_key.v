module top_key (
    input   clk,
    input   rst,
    input   key,
    output  [3:0]   led
);

key key_u(
    .key     (key),
    .clk     (clk),
    .rst     (rst),
    .flag    (flag)
);

led led_u(
    .clk     (clk),
    .rst     (rst),
    .key     (flag),
    .led     (led)
);


    
endmodule
module top_key (
    input       key,
    input       clk,
    input       rst,
    output      wire [3:0]   led
);
//key
wire flag   ;

key key_u(
    .key     (key),
    .clk     (clk),
    .rst     (rst),
    .flag    (flag)
);


led led_u(
    .flag    (flag),
    .clk     (clk),
    .rst     (rst),
    .led   	 (led)
);

endmodule
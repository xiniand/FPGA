module top_led (
    input   key, 
    input   clk,
    input   rst,
    output  [3:0]   led
);
    
wire    flag;

key key_u(
    .rst     (rst)  ,
    .clk     (clk)  ,
    .key     (key)  ,
    .flag    (flag)
);

led led_u(
    .rst    (rst)   ,
    .clk    (clk)   ,
    .key    (flag)  ,
    .led    (led)
);

endmodule
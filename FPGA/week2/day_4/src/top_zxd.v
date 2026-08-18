module top_zxd (
    input           clk,
    input           rst,
    input           key_right,//11右转，led左往右
    input           key_left,//10左转，led右往左
    input           key_ss,//01双闪，四个led闪
    input           key_iled,//00
    output  [3:0]   led
);
    wire    key_right_flag;
    wire    key_left_flag;
    wire    key_ss_flag;
    wire    key_iled_flag;
    wire    clk_out;

zxd_led zxd_led_u(
    .clk        (clk),
    .rst        (rst),
    .clk_out    (clk_out),
    .key_right  (key_right_flag),//11右转，led左往右
    .key_left   (key_left_flag),//10左转，led右往左
    .key_ss     (key_ss_flag),//01双闪，四个led闪
    .key_iled   (key_iled_flag),//00
    .led        (led)
);

clk clk_u(
    .clk     (clk),
    .rst     (rst),
    .clk_out (clk_out)
);

zxd_key key_right_u(
    .clk (clk),
    .rst (rst),
    .key (~key_right),
    .flag(key_right_flag)
);

zxd_key key_left_u(
    .clk (clk),
    .rst (rst),
    .key (~key_left),
    .flag(key_left_flag)
);

zxd_key key_ss_u(
    .clk (clk),
    .rst (rst),
    .key (~key_ss),
    .flag(key_ss_flag)
);

zxd_key key_iled_u(
    .clk (clk),
    .rst (rst),
    .key (~key_iled),
    .flag(key_iled_flag)
);

endmodule
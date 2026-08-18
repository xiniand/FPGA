module top_fpq #(parameter delay_1 = 6_250_000)(
    input   clk,
    input   rst,
    output  clk_out,
    output  [3:0]   led
);


fpj fpj_u(
    .rst     (rst    ),
    .clk     (clk    ),
    .clk_out (clk_out)
);

fpq_led #(
    .delay_1(delay_1)
)fpq_led_u(
    .clk    (clk_out),
    .rst    (rst),
    .led    (led)
);

endmodule
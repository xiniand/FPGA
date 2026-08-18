module top_3_8 (
    input          rst ,
    input          clk ,
    input   [1:0]   sw  ,
    output  [6:0]  dig ,
    output  [5:0]  sel
);
parameter   delay = 100_000_0;
wire[1:0]flag;


key #(
    .delay (delay) 
    )key_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (sw[1]  ),
    .flag   (flag[1])
);

key #(
    .delay (delay) 
    )key_1_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (sw[0]  ),
    .flag   (flag[0])
);

ziyima3_8 ziyima3_8_u(
    .rst    (rst ),
    .clk    (clk ),
    .sw     (flag),
    .dig    (dig ),
    .sel    (sel )

);

endmodule
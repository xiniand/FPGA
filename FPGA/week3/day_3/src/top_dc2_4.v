module top_dc2_4 (
    input               clk             ,
    input               rst             ,
    input               key             ,
    input               a_1             ,
    input               a_2             ,
    output              a_1_posedge     ,   //上升沿检测
    output              a_1_negedge     ,   //下降沿检测
    output              a_1_n           ,  //双边沿检测
    output              a_2_posedge     ,   //上升沿检测
    output              a_2_negedge     ,   //下降沿检测
    output              a_2_n           ,  //双边沿检测
    output       [3:0]  A               ,
/*     output              flag */
);
/*     wire    a_1_flag;
    wire    a_2_flag;

key key_a_1_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (a_1 ),
    .flag   (a_1_flag)
);

key key_a_2_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (a_2 ),
    .flag   (a_2_flag)
); */

dc2_4 dc2_4_u(
    .clk           (clk        ),
    .rst           (rst        ),
    .a_1           (a_1         ),
    .a_2           (a_2         ),
    .a_1_posedge   (a_1_posedge),   //上升沿检测
    .a_1_negedge   (a_1_negedge),   //下降沿检测
    .a_1_n         (a_1_n      ),  //双边沿检测
    .a_2_posedge   (a_2_posedge),   //上升沿检测
    .a_2_negedge   (a_2_negedge),   //下降沿检测
    .a_2_n         (a_2_n      ),  //双边沿检测
    .A             (A)
);

endmodule
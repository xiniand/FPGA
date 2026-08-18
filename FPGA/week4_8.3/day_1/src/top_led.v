module top_led (
    input               clk ,
    input               rst ,
    output  reg [3:0]   led 

);


parameter delay = 24_999_999;
parameter TIME_STATE = 200_000_000;
wire    state_en_1;
wire    state_en_2;
wire    state_en_3;
wire [3:0]   liushui_led     ,
            paoma_led       ,
            shanshuo_led    ;

paoma #(
    .delay (delay)
    ) paoma_u(
    .en     (state_en_2)    ,
    .clk    (clk)   ,
    .rst    (rst)   ,
    .led    (paoma_led)
);

liushui #(
    .delay (delay)
    ) liushui_u(
    .en     (state_en_1)    ,
    .clk    (clk)   ,
    .rst    (rst)   ,
    .led    (liushui_led)
);

shanshuo #(
    .delay (delay)
    ) shanshuo_u(
    .en     (state_en_3)    ,
    .clk    (clk)   ,
    .rst    (rst)   ,
    .led    (shanshuo_led)
);

ztj_led #(
    .TIME_STATE(TIME_STATE)
)   ztj_led_u(
    .clk         (clk       ),
    .rst         (rst       ),
    .state_en_1  (state_en_1), //流水灯
    .state_en_2  (state_en_2), //跑马灯
    .state_en_3  (state_en_3)  //闪烁
);

always @(*) begin
    case ({state_en_1,state_en_2,state_en_3})
        3'b100:led = liushui_led;
        3'b010:led = paoma_led;
        3'b001:led = shanshuo_led;  
        default: led = liushui_led;
    endcase
end



endmodule
module top_led (
    input           clk ,
    input           rst ,
    input           key ,
    output 	[3:0]   led ,
    output          flag
);

parameter delay = 24_999_999;
parameter delay_1 = 99_999_9;
reg             en;
always @(posedge clk or negedge rst) begin
    if(!rst)
        en <= 0;
    else if(flag)
        en <= ~en;
end

key #(
    .delay_1 (delay_1) 
    )key_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key ),
    .flag   (flag)
);

wire [3:0]   led_liu,led_pao;

paoma #(
    .delay (delay)
    ) paoma_u(
    .en     (en)    ,
    .clk    (clk)   ,
    .rst    (rst)   ,
    .key    (flag)  ,
    .led    (led_pao)
);

liushui #(
    .delay (delay)
    ) liushui_u(
    .en     (en)    ,
    .clk    (clk)   ,
    .rst    (rst)   ,
    .key    (flag)  ,
    .led    (led_liu)
);

assign led = (en == 0) ? led_liu : led_pao;

endmodule
module top_buzzer (
    input   clk     ,
    input   rst     ,
    input   key     ,
    output  buzzer
);
parameter   delay = 100_000_0;
reg         en;

always @(posedge clk or negedge rst) begin
    if(!rst)
        en <= 0;
    else if(flag)
        en <= ~en;
end

key #(
    .delay (delay) 
    )key_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key ),
    .flag   (flag)
);


buzzer_laohu  buzzer_laohu_u(
    .clk   (clk     ),
    .rst   (rst     ),
    .en     (en    ),
    .buzzer(buzzer_lh  )
);

buzzer_xx  buzzer_xx_u(
    .clk   (clk     ),
    .rst   (rst     ),
    .en    (en    ),
    .buzzer(buzzer_xx  )
);

assign buzzer = en? buzzer_xx : buzzer_lh;


endmodule
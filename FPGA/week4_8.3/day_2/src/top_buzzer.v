module top_buzzer (
    input   clk     ,
    input   rst     ,
    input   key     ,
    output  buzzer
);
parameter   delay = 100_000_0,
            G1      = 47801 ,
            G2      = 42589 ,
            G3      = 37936 ,
            G4      = 35816 ,
            G5      = 31887 ,
            G6      = 28409 ,
            G7      = 25303 ;


key #(
    .delay (delay) 
    )key_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key ),
    .flag   (flag)
);


buzzer #(
    .G1 ( G1 ),
    .G2 ( G2 ),
    .G3 ( G3 ),
    .G4 ( G4 ),
    .G5 ( G5 ),
    .G6 ( G6 ),
    .G7 ( G7 )
) buzzer_u(
    .clk   (clk     ),
    .rst   (rst     ),
    .key   (flag    ),
    .buzzer(buzzer  )
);

endmodule
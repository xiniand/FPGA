module top (
    input               clk     ,
    input               rst     ,
    input   [1:0]       key     ,
    output  [5:0]       sel     ,
    output  [6:0]       seg      
);



parameter   delay = 100_000_0   ;
parameter   shua_0  = 499_999   ,
            shua_1  = 599_999   ,
            shua_2  = 699_999   ,
            shua_3  = 799_999   ,
            shua_4  = 899_999   ,
            shua_5  = 999_999   ,
            shua_6  = 1099_999  ,
            shua_7  = 1199_999  ,
            shua_8  = 1299_999  ,
            shua_9  = 1399_999  ,
            shua_10 = 1499_999  ,
            shua_11 = 1599_999  ,
            shua_12 = 1699_999  ,
            shua_13 = 1799_999  ,
            shua_14 = 1899_999  ,
            shua_15 = 1999_999  ,
            shua_16 = 2099_999  ,
            shua_17 = 2199_999  ,
            shua_18 = 2299_999  ,
            shua_19 = 2399_999  ,
            shua_20 = 2499_999  ;
wire    [1:0]   flag            ;
wire    [22:0]  shua            ;

key #(
    .delay (delay) 
    )key_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key[1] ),
    .flag   (flag[1])
);

key #(
    .delay (delay) 
    )key_1_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key[0] ),
    .flag   (flag[0])
);

shuaxin #(
    .shua_0  (shua_0 ),
    .shua_1  (shua_1 ),
    .shua_2  (shua_2 ),
    .shua_3  (shua_3 ),
    .shua_4  (shua_4 ),
    .shua_5  (shua_5 ),
    .shua_6  (shua_6 ),
    .shua_7  (shua_7 ),
    .shua_8  (shua_8 ),
    .shua_9  (shua_9 ),
    .shua_10 (shua_10),
    .shua_11 (shua_11),
    .shua_12 (shua_12),
    .shua_13 (shua_13),
    .shua_14 (shua_14),
    .shua_15 (shua_15),
    .shua_16 (shua_16),
    .shua_17 (shua_17),
    .shua_18 (shua_18),
    .shua_19 (shua_19),
    .shua_20 (shua_20) 
) shuaxin_u(
    .clk    (clk  ),
    .rst    (rst  ),
    .key    (flag ),
    .shua   (shua )
);


smg smg_u(
    .rst    (rst ),
    .clk    (clk ),
    .shua   (shua),
    .seg    (seg ),
    .sel    (sel )

);




endmodule
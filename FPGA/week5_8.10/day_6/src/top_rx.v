module top_rx (
    input               clk     ,
    input               rst_n   ,
    input               rx      ,
    output              led     ,
    output      [7:0]   dig     ,
    output      [5:0]   sel     ,   
    output           	rx_done  //使能：flag拉高；cnt==5207&&bit(baud_cnt)==9 
);

wire [7:0]  rx_data             ;

rx rx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .rx             (rx             ),
    .rx_done        (rx_done        ),//使能：flag拉高；cnt==5207&&bit(baud_cnt)==9
    .parity_error   (led            ),
    .data           (rx_data        )
);


dt_smg dt_smg_u(
    .rst            (rst_n  ),
    .clk            (clk    ),
    .data           (rx_data),
    .dig            (dig    ),
    .sel            (sel    )
);
endmodule
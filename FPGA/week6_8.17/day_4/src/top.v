module top (
    input   clk ,
    input   rst_n,
    output  tx  
);

wire [7:0]  data_rom,
            data_tx ;
wire        tx_done ;
wire        start_tx;
wire        tick    ;
wire [7:0]  wraddress   ;

rom rom_u(
    .clk        (clk        ),
    .rst_n      (rst_n      ),
    .wraddress  (wraddress  ),
    .data_rom   (data_rom   )
);

ping_pong ping_pong_u(
    .clk        (clk        ),
    .rst_n      (rst_n      ),
    .data_rom   (data_rom   ),
    .done_tx    (tx_done    ),
    .data_tx    (data_tx    ),
    .wraddress  (wraddress  ),  
    .start_tx   (start_tx   )
);

tx tx_u(
    .clk       (clk     ),
    .rst_n     (rst_n   ),
    .tick      ( tick   ),
    .tx_star   (start_tx),//开始发送的信号
    .tx_data   (data_tx ),//要发送的数据 
    .tx        (tx      ),//发送的数据
    .tx_done   (tx_done )    //发送一组数据完成信号
);

brg brg_u(
    .clk        (clk    ),
    .rst_n      (rst_n  ),//异步复位信号
    .brg_en     (1      ),
    .tick       (tick   ) //bit脉冲
);

endmodule
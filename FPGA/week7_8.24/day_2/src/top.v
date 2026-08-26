module top (
    input               clk     ,
    input               rst_n   ,
    input               key     ,
    input               rx      ,
    inout               sda     ,//数据线总线
    inout               scl     ,//时钟线
    output  [7:0]    	dig     ,
    output  [5:0]    	sel   
);
    
wire            flag        ;
wire    [7:0]   data        ;
wire            iic_start   ;
wire            rw_ctrl     ;
wire    [7:0]   data_out    ;     
wire    [7:0]   data_in     ;
wire            iic_done    ;
wire            brg_en      ;
wire            rden        ,
                wren        ;

key key_u(
    .key        (key        ),
    .clk        (clk        ),
    .rst        (rst_n      ),
    .flag       (flag       )
);


iic iic_u(
    .clk        (clk       ),
    .rst_n      (rst_n     ),
    .iic_start  (iic_start ),//开始通信信号
    .rw_ctrl    (rw_ctrl   ),//读写控制0写1读
    .data_out   (data_out  ),//要发送的信号
    .key        (flag      ),
    .sda        (sda       ),//数据线总线
    .scl        (scl       ),//时钟线     
    .data_in    (data_in   ),//接收到的信号
    .iic_done   (iic_done  )
);

brg #(
    .CLK_FREQ (9600),
    .BAUD_RATE(50_000_000)
) brg_u(
    .clk            (clk                ),
    .rst_n          (rst_n              ),
    .brg_en         (brg_en             ),
    .tick           (tick               ) //bit脉冲
);

tx #(
    .MODE(2)
) tx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .tick           (tick           ),
    .tx_star        (fifo_rd_req    ),//FIFO有数据且TX空闲时自动触发
    .tx_data        (fifo_data_rg   ),//要发送的数据
    .brg_en         (brg_en         )
    .tx             (tx             ),//发送的数据
    .tx_done        (tx_done        ) //发送一组数据完成信号
);

rx #(
    .CLK_FREQ(9600),
    .BAUD_RATE(50_000_000),
    .MODE(2)
) rx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .rx             (rx             ),
    .rx_done        (rx_done        ),//接收完成信号
    .parity_error   (parity_error   ),//校验信号
    .data           (rx_data        ) //接收到的数据
);

fifo_data	fifo_data_inst (
	.aclr           ( ~rst_n            ),
	.clock          ( clk               ),
	.data           ( rx_data           ),
	.rdreq          ( rden              ),
	.wrreq          ( rx_done           ),
	.empty          ( empty             ),
	.full           ( full              ),
	.q              ( fifo_data         ),
	.usedw          ( usedw             )
);

dt_smg dt_smg_u(
    .rst        (rst        ),
    .clk        (clk        ),
    .data       (data       ),
    .dig        (dig        ),
    .sel        (sel        )
);

endmodule
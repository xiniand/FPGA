module top_uart (
    input               clk     ,
    input               rst_n   ,
    input               rx      ,
    output              led     ,
    output      [7:0]   dig     ,
    output      [5:0]   sel     ,   
    output           	rx_done  //使能：flag拉高；cnt==5207&&bit(baud_cnt)==9 
);
parameter CLK_FREQ = 50_000_000                     ;// 系统时钟频率 
parameter BAUD_RATE = 9600                          ;// 目标波特率
wire        tick                ;
wire [7:0]  rx_data             ;

rx rx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .rx             (rx             ),
    .tick           (tick           ),
    .rx_done        (rx_done        ),//使能：flag拉高；cnt==5207&&bit(baud_cnt)==9
    .parity_error   (led            ),
    .data           (rx_data        )
);

brg #(
    .CLK_FREQ (CLK_FREQ ),
    .BAUD_RATE(BAUD_RATE)
) brg_u(
    .clk            (clk    ),
    .rst_n          (rst_n  ),//异步复位信号
    .brg_en         (1      ),
    .tick           (tick   ) //bit脉冲
);


dt_smg dt_smg_u(
    .rst            (rst_n  ),
    .clk            (clk    ),
    .data           (rx_data),
    .dig            (dig    ),
    .sel            (sel    )
);
endmodule
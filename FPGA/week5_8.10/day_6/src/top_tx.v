module top_tx (
    input               clk     ,
    input               rst_n   ,
    input       [7:0]   tx_data ,
    input               tx_star ,
    output              tx         
);
parameter CLK_FREQ = 50_000_000                     ;// 系统时钟频率 
parameter BAUD_RATE = 9600                          ;// 目标波特率
wire        tick                ;
/* wire [7:0]  rx_data             ; */
/* wire        tx                  ; */
wire        tx_done             ;

tx tx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .tick           (tick           ),
    .tx_star        (tx_star        ),//开始发送的信号
    .tx_data        (tx_data        ),//要发送的数据 
    .tx             (tx             ),//发送的数据
    .tx_done        (tx_done        ) //发送一组数据完成信号
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


endmodule
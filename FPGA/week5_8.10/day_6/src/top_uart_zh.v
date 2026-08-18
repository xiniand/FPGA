module top_uart_zh (
    input               clk         ,
    input               rst_n       ,
/*     input               rx          , */
    input       [7:0]   tx_data     ,
    input               tx_star     ,
    output              tx          ,
    output              led         ,
    output      [7:0]   dig         ,
    output      [5:0]   sel         ,   
/*     output           	rx_done  //使能：flag拉高；cnt==5207&&bit(baud_cnt)==9  */
);
parameter TIME      = 50_000_000    ;
parameter CLK_FREQ  = 50_000_000    ;// 系统时钟频率 
parameter BAUD_RATE = 9600          ;// 目标波特率
wire        rx                      ;  
reg  [25:0] cnt_time                ;//1s计数器
wire        add_cnt_time            ,
            end_cnt_time            ;
wire        flag_tx_star            ;
wire        tick                    ;
wire [7:0]  rx_data                 ;
wire [7:0]  data                    ;
reg  [7:0]  data_rg                 ;
wire        almost_full             ,
            empty                   ,
            full                    ,
            usedw                   ;
wire        tx_done                 ,
            rx_done                 ,
            rdreq                   ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_time <= 0;
    else if(add_cnt_time)begin
        if(end_cnt_time)
            cnt_time <= 0;
        else 
            cnt_time <= cnt_time + 1;
    end 
end
assign  add_cnt_time = 1;
assign  end_cnt_time = add_cnt_time && (cnt_time == CLK_FREQ);
assign  rdreq        = end_cnt_time;

key key_u(
    .key            (tx_star        ),
    .clk            (clk            ),
    .rst            (rst_n          ),
    .flag           (flag_tx_star   )
);
//信号发送器
tx tx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .tick           (tick           ),
    .tx_star        (flag_tx_star   ),//开始发送的信号
    .tx_data        (tx_data        ),//要发送的数据 
    .tx             (tx             ),//发送的数据
    .tx_done        (tx_done        ) //发送一组数据完成信号
);
//信号接收器
rx #(
    .CLK_FREQ (CLK_FREQ ),
    .BAUD_RATE(BAUD_RATE)
) rx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .rx             (tx             ),
    .rx_done        (rx_done        ),//使能：flag拉高；cnt==5207&&bit(baud_cnt)==9
    .parity_error   (led            ),
    .data           (rx_data        )
);
//波特率生成模块
brg #(
    .CLK_FREQ (CLK_FREQ ),
    .BAUD_RATE(BAUD_RATE)
) brg_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),//异步复位信号
    .brg_en         (1              ),
    .tick           (tick           ) //bit脉冲
);
//动态数码管显示模块
dt_smg dt_smg_u(
    .rst            (rst_n          ),
    .clk            (clk            ),
    .data           (data_rg        ),
    .dig            (dig            ),
    .sel            (sel            )
);
//fifo模块将接受的数据按顺序显示
fifo_data	fifo_data_inst (
	.aclr           ( ~rst_n        ),
	.clock          ( clk           ),
	.data           ( rx_data       ),
	.rdreq          ( rdreq         ),
	.wrreq          ( rx_done       ),
	.almost_full    ( almost_full   ),
	.empty          ( empty         ),
	.full           ( full          ),
	.q              ( data          ),
	.usedw          ( usedw         )
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_rg <= 0;
    else if(rdreq)
        data_rg <= data;
end
endmodule
//将接收到的信号发送出去
module top_uart_jf (
    input               clk         ,
    input               rst_n       ,
    input               rx          ,//接受的数据
    input       [7:0]   tx_data     ,//发送的数据，由SW1-SW8分别对应tx_data的7-0
    input               tx_star     ,//key0控制发送信号，按一下发送一个信号
    output              tx          ,//发送信号
    output              led         ,//偶校验错误时led亮起，正确时灭的
    output      [7:0]   dig         ,
    output      [5:0]   sel            
);
parameter TIME      = 50_000_000    ;
parameter CLK_FREQ  = 50_000_000    ;//系统时钟频率 
parameter BAUD_RATE = 9600          ;//目标波特率
wire        rx_done                 ;//发送一组数据完成信号
reg  [25:0] cnt_time                ;//1s计数器
wire        add_cnt_time            ,
            end_cnt_time            ;
wire        flag_tx_star            ;//消抖后的发送开始信号
wire        tick                    ;//波特率发生器发出的一个脉冲信号
wire [7:0]  rx_data                 ;//接受的数据写入fifo
wire [7:0]  data                    ;//fifo输出的数据
reg  [7:0]  data_rg                 ;//寄存fifo输出的数据，让数码管保持在最厚一个数据，因为fifo读完就没数据了会清零 
wire        almost_full             ,
            empty                   ,
            full                    ,
            usedw                   ;
wire        tx_done                 ,//发送一组数据完成的信号
            parity_error            ,//校验信号（偶校验）
            wrreq                   ,//写使能
            rdreq                   ;//读使能
//1s计数器控制读使能，1s读出一个数据，从而控制数码管显示速度
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
assign  add_cnt_time = 1;//1s计时开始信号
assign  end_cnt_time = add_cnt_time && (cnt_time == TIME);//1s计时结束信号
assign  rdreq        = flag_tx_star;
assign  led          = parity_error;                //led由校验信号控制，正确不亮错误亮
assign  wrreq        = !parity_error &&  rx_done;   //写使能由校验信号和接收完信号控制，接收完一组写入一组，校验位错误时不写入
//按键消抖
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
    .tx_data        (data_rg        ),//要发送的数据 
    .tx             (tx             ),//发送的数据
    .tx_done        (tx_done        ) //发送一组数据完成信号
);
//信号接收器
rx rx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .rx             (rx             ),
    .rx_done        (rx_done        ),//使能：flag拉高；cnt==5207&&bit(baud_cnt)==9
    .parity_error   (parity_error   ),//校验信号
    .data           (rx_data        )//接收到的数据
);
//波特率生成模块
brg #(
    .CLK_FREQ (CLK_FREQ ),
    .BAUD_RATE(BAUD_RATE)
) brg_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .brg_en         (1              ),
    .tick           (tick           ) //bit脉冲
);
//动态数码管显示模块
dt_smg dt_smg_u(
    .rst            (rst_n          ),
    .clk            (clk            ),
    .data           (data_rg        ),//接收寄存的数据
    .dig            (dig            ),
    .sel            (sel            )
);

ram_xun ram_xun_u(
    .clk     		(clk            ),
    .rst_n   		(rst_n          ),
    .data_in 		(rx_data        ),
    .rden           (rdreq          ),
    .wren           (wrreq          ),
    .data_out       (data           )
);
//数据保持因为data后面会更新所以rg让他保持在最后一个
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_rg <= 0;
    else if(rdreq)
        data_rg <= data;
end
endmodule

module top_uart_jf (
    input               clk         ,
    input               rst_n       ,
    input               rx          ,//接受的数据
    input               tx_star     ,//key0控制发送信号
    output              tx          ,//发送信号
    output   reg        led         ,//偶校验错误时led亮起，正确时灭的
    output      [7:0]   dig         ,
    output      [5:0]   sel
);
parameter MODE = 2;     //0无校验，1奇校验，2偶校验
parameter TIME      = 25_000_000    ;
parameter CLK_FREQ  = 50_000_000    ;//系统时钟频率
parameter BAUD_RATE = 9600          ;//目标波特率
wire        rx_done                 ;//接收一组数据完成信号
reg  [25:0] cnt_time                ;//1s计数器
wire        add_cnt_time            ,
            end_cnt_time            ;
wire        flag_tx_star            ;//消抖后的发送开始信号（保留，未使用）
wire        tick                    ;//波特率发生器发出的一个脉冲信号
wire [7:0]  rx_data                 ;//接受的数据写入fifo
wire [7:0]  data                    ;//ram输出的数据
wire [7:0]  fifo_data               ;//fifo输出的数据
reg  [7:0]  fifo_data_rg            ;//fifo输出的数据寄存
reg  [7:0]  data_rg                 ;//寄存ram输出的数据，让数码管保持在最后一个数据
wire        almost_full             ,
            empty                   ,
            full                    ;
wire [7:0]  usedw                   ;//fifo中使用的数据量（修正位宽为8bit）
wire        tx_done                 ,//发送一组数据完成的信号
            parity_error            ,//校验信号（偶校验）
            wren                    ,//RAM写使能
            rden                    ;//RAM读使能


reg         tx_busy                 ;//TX正在发送标志
reg         fifo_rd_req             ;//FIFO读请求脉冲（单周期）
reg         fifo_rd_req_d1          ;//FIFO读请求延迟一拍（对齐FIFO输出时序）

// TX是否工作
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tx_busy <= 0;
    else if(fifo_rd_req)
        tx_busy <= 1;
    else if(tx_done)
        tx_busy <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        fifo_rd_req <= 0;
    else if(fifo_rd_req)          
        fifo_rd_req <= 0;
    else if(~empty && ~tx_busy)    
        fifo_rd_req <= 1;
end

// 延迟一拍，在FIFO输出有效时采集数据
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        fifo_rd_req_d1 <= 0;
    else
        fifo_rd_req_d1 <= fifo_rd_req;
end

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
assign  add_cnt_time    = 1;
assign  end_cnt_time    = add_cnt_time && (cnt_time == TIME);
assign  rden            = end_cnt_time;
assign  wren            = !parity_error &&  rx_done;   //RAM写使能
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        led <= 0;
    else if(parity_error)
        led <= 1;
end

//按键消抖（保留端口，未使用）
key key_u(
    .key            (tx_star        ),
    .clk            (clk            ),
    .rst            (rst_n          ),
    .flag           (flag_tx_star   )
);
//信号发送器：由fifo_rd_req触发，自动发送FIFO中的数据
tx #(
    .MODE(MODE)
) tx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .tick           (tick           ),
    .tx_star        (fifo_rd_req    ),//FIFO有数据且TX空闲时自动触发
    .tx_data        (fifo_data_rg   ),//要发送的数据
    .tx             (tx             ),//发送的数据
    .tx_done        (tx_done        ) //发送一组数据完成信号
);
//信号接收器
rx #(
    .CLK_FREQ (CLK_FREQ ),
    .BAUD_RATE(BAUD_RATE),
    .MODE(MODE)
) rx_u(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .rx             (rx             ),
    .rx_done        (rx_done        ),//接收完成信号
    .parity_error   (parity_error   ),//校验信号
    .data           (rx_data        ) //接收到的数据
);
//波特率生成模块
brg #(
    .CLK_FREQ (CLK_FREQ ),
    .BAUD_RATE(BAUD_RATE)
) brg_u(
    .clk            (clk                ),
    .rst_n          (rst_n              ),
    .brg_en         (1                  ),
    .tick           (tick               ) //bit脉冲
);
//动态数码管显示模块
dt_smg dt_smg_u(
    .rst            (rst_n              ),
    .clk            (clk                ),
    .data           (data_rg            ),//接收寄存的数据
    .dig            (dig                ),
    .sel            (sel                )
);

// FIFO：缓冲接收到的数据，TX自动从FIFO读取发送
fifo_data	fifo_data_inst (
	.aclr           ( ~rst_n            ),
	.clock          ( clk               ),
	.data           ( rx_data           ),
	.rdreq          ( fifo_rd_req       ),//TX空闲且FIFO有数据时读取（单周期脉冲）
	.wrreq          ( wren              ),//接收到数据时写入
	.almost_full    ( almost_full       ),
	.empty          ( empty             ),
	.full           ( full              ),
	.q              ( fifo_data         ),
	.usedw          ( usedw             )
);

// RAM：用于数码管显示（与TX链路独立）
ram_xun ram_xun_u(
    .clk     		(clk                ),
    .rst_n   		(rst_n              ),
    .data_in 		(rx_data            ),
    .rden           (rden               ),
    .wren           (wren               ),
    .data_out       (data               )
);
//数码管数据保持
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_rg <= 0;
    else if(rden)
        data_rg <= data;
end

// FIFO输出数据寄存：在读请求后一拍采集FIFO输出（匹配FIFO寄存器输出时序）
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        fifo_data_rg <= 0;
    else if(fifo_rd_req_d1)
        fifo_data_rg <= fifo_data;
end
endmodule

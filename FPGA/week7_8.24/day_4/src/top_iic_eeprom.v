module top_iic_eeprom (
    input           clk     ,
    input           rst_n   ,
    input           rx      ,
    inout           scl     ,
    inout           sda     ,
    output          tx
);
wire                parity_error;
wire                brg_en  ;
wire    [7:0]       rx_data ;
wire                rx_done ;
wire                tx_done ;
wire                tick    ;
wire                rw_ctrl ;
wire    [7:0]       data_i_iic ,
                    data_out;
wire    [7:0]       recvnum,
                    sendnum;
wire                tx_star,
                    iic_start;
wire                iic_done_r,
                    iic_done_w,
                    iic_done  ;  
reg [7:0] tx_data_rg;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)          
        tx_data_rg <= 8'd0;
    else if(iic_done_r) 
        tx_data_rg <= data_out;   // 脉冲来时 data_out 还有效
end
brg brg_u(
    .clk         (clk           ),
    .rst_n       (rst_n         ),//异步复位信号
    .brg_en      (1'b1          ),
    .tick        (tick          ) //bit脉冲
);

rx rx_u(
    .clk         (clk            ),
    .rst_n       (rst_n          ),
    .rx          (rx             ),
    .rx_done     (rx_done        ),//使能：flag拉高；cnt==5207&&bit(baud_cnt)==9
    .parity_error(parity_error   ),
    .data        (rx_data        )
);

tx tx_u(
    .clk         (clk           ),
    .rst_n       (rst_n         ),
    .tick        (tick          ),
    .tx_star     (iic_done_r    ),
    .tx_data     (tx_data_rg    ),//要发送的数据 
    .brg_en      (brg_en        ),
    .tx          (tx            ),//发送的数据
    .tx_done     (tx_done       ) //发送一组数据完成信号
);

iic_0 iic_0_u(
    .clk         (clk           ),
    .rst_n       (rst_n         ),
    .iic_start   (iic_start     ),//开始通信信号
    .rw_ctrl     (rw_ctrl       ),//读写控制0写1读
    .data_i_iic  (data_i_iic    ),//要发送的信号
    .sendnum     (sendnum       ),
    .recvnum     (recvnum       ),
    .sda         (sda           ),//数据线总线
    .scl         (scl           ),//时钟线     
    .data_out    (data_out      ) ,//接收到的信号
    .iic_done_r  (iic_done_r    ),//读完
    .iic_done_w  (iic_done_w    ),//写完
    .iic_done    (iic_done      )  //写完
);

eeprom_rw eeprom_rw(
    .clk         (clk           ),
    .rst_n       (rst_n         ),
    .rx_done     (rx_done       ),// UART 收到一字节(rx_done)
    .rx_data     (rx_data       ),// UART 接收数据(rx_data)
    .iic_done    (iic_done      ),
    .iic_done_w  (iic_done_w    ),
    .iic_start   (iic_start     ),// IIC 启动
    .rw_ctrl     (rw_ctrl       ),// 0:写, 1:读
    .sendnum     (sendnum       ),// IIC 发送字节数
    .recvnum     (recvnum       ),// IIC 接收字节数
    .data_i_iic  (data_i_iic    ) // 写入 EEPROM 的数据
);


endmodule
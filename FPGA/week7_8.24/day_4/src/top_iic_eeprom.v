module top_iic_eeprom (
    input           clk     ,
    input           rst_n   ,
    input           rx      ,
    input           key     ,
    inout           scl     ,
    inout           sda     ,
    output          tx
);
wire                parity_error;
wire                flag    ;
wire                brg_en  ;
wire    [7:0]       tx_data ;
wire    [7:0]       rx_data ;
wire                rx_done ;
wire                tx_done ;
wire                done    ;
wire                tick    ;
wire                rw_ctrl ;
wire    [7:0]       wr_data ,
                    data_out;

wire    [7:0]       recvnum,
                    sendnum,
                    waddr   ;
wire                dout_vld,
                    req;


wire                iic_done_r,
                    iic_done_w,
                    iic_done  ;  
assign  done    =   iic_done_r ||iic_done_w||iic_done ;

key key_u(
    .key (key    ),
    .clk (clk    ),
    .rst (rst_n  ),
    .flag(flag   )
);

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
    .tx_star     (dout_vld      ),
    .tx_data     (tx_data       ),//要发送的数据 
    .brg_en      (brg_en        ),
    .tx          (tx            ),//发送的数据
    .tx_done     (tx_done       ) //发送一组数据完成信号
);

iic_0 iic_0_u(
    .clk         (clk           ),
    .rst_n       (rst_n         ),
    .iic_start   (req           ),//开始通信信号
    .rw_ctrl     (rw_ctrl       ),//读写控制0写1读
    .waddr       (waddr         ),//字地址
    .data_i_iic  (wr_data       ),//要发送的信号
    .sendnum     (sendnum       ),
    .recvnum     (recvnum       ),
    .sda         (sda           ),//数据线总线
    .scl         (scl           ),//时钟线     
    .data_out    (data_out      ) ,//接收到的信号
    .iic_done_r  (iic_done_r    ),//读完
    .iic_done_w  (iic_done_w    ),//写完
    .iic_done    (iic_done      )  //写完
);

eeprom_rw eeprom_rw_u(
    .clk         (clk           ),
    .rst_n       (rst_n         ),
    .din_vld     (rx_done       ),// UART 收到一字节
    .din         (rx_data       ),// UART 接收数据
    .rd_en       (flag          ),// 按键触发读 EEPROM
    .done        (done          ),// IIC 完成信号
    .rd_data     (data_out      ),// IIC 读回数据
    .tx_done     (tx_done       ),// UART 发送完成
    .req         (req           ),// IIC 启动
    .rw_ctrl     (rw_ctrl       ),// 0:写, 1:读
    .waddr       (waddr         ),// 字地址
    .sendnum     (sendnum       ),// IIC 发送字节数
    .recvnum     (recvnum       ),// IIC 接收字节数
    .wr_data     (wr_data       ),// 写入 EEPROM 的数据
    .dout        (tx_data       ),// 读出送 UART 的数据
    .dout_vld    (dout_vld      ) // UART TX 启动
);
endmodule
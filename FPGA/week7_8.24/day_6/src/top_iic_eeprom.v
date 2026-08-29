module top_iic_eeprom (
    input           clk     ,
    input           rst_n   ,
    input           rx      ,
    inout           scl     ,
    inout           sda     ,
    output          RTC     ,
    output          tx
);
assign  RTC = 0;
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
wire    [7:0]       usedw,
							q;
wire                empty,
                    full ;
wire                rdreq;
reg                 flag;
wire                tx_idle;

//复位同步器:异步断言、同步释放
//rst_n是按键,释放沿(抖动)若落在clk有效沿附近会造成恢复/移除时间违例,
//部分寄存器复位、部分不复位,状态机进入不一致状态 → 上板表现"每次不一样"
reg [1:0] rst_n_sync;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rst_n_sync <= 2'b00;
    else
        rst_n_sync <= {rst_n_sync[0], 1'b1};
end
wire rst_n_in = rst_n_sync[1];

//第一次发送触发信号
always @(posedge clk or negedge rst_n_in) begin
    if(!rst_n_in)
        flag <= 0;
    else if(iic_done_r)   
        flag <= 1;  
    else if(iic_done)     
        flag <= 0;  
end

//开始信号       
assign tx_star = (flag || tx_done) && (usedw != 0);
assign rdreq   = tx_star && tx_idle;                 
brg brg_u(
    .clk         (clk           ),
    .rst_n       (rst_n_in         ),//异步复位信号
    .brg_en      (1'b1          ),
    .tick        (tick          ) //bit脉冲
);

rx rx_u(
    .clk         (clk            ),
    .rst_n       (rst_n_in       ),
    .rx          (rx             ),
    .rx_done     (rx_done        ),//使能：flag拉高；cnt==5207&&bit(baud_cnt)==9
    .parity_error(parity_error   ),
    .data        (rx_data        )
);

tx tx_u(
    .clk         (clk           ),
    .rst_n       (rst_n_in         ),
    .tick        (tick          ),
    .tx_star     (tx_star       ),
    .tx_idle     (tx_idle       ),
    .tx_data     (q             ),//要发送的数据 
    .brg_en      (brg_en        ),
    .tx          (tx            ),//发送的数据
    .tx_done     (tx_done       ) //发送一组数据完成信号
);

iic_0 iic_0_u(
    .clk         (clk           ),
    .rst_n       (rst_n_in         ),
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
    .rst_n       (rst_n_in         ),
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

fifo_data	fifo_data_inst (
	.aclr       ( ~rst_n_in      ),
	.clock      ( clk           ),
	.data       ( data_out      ),
	.rdreq      ( rdreq         ),
	.wrreq      ( iic_done_r    ),
	.empty      ( empty         ),
	.full       ( full          ),
	.q          ( q             ),
	.usedw      ( usedw         )
);

endmodule
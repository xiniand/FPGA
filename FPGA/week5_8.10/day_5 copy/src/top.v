//UART收发顶层：整合 brg + tx + rx（PC串口助手调试，不用LED、不用回发）
//- 发送：拨码设置 tx_data，tx_star 触发，FPGA 经 tx 发给 PC（PC 串口助手接收）
//- 接收：PC 串口助手发送，FPGA 经 rx 接收（rx_done 指示；rx_data 可接数码管等显示）
module top (
    input           clk     ,//50MHz系统时钟
    input           rst_n   ,//低有效复位
    input           rx      ,//串口接收（PC -> FPGA）
    input           tx_star ,//发送使能（拨码触发，需保持至少一个bit周期）
    input   [7:0]   tx_data ,//待发送数据（拨码开关）
    output          tx      ,//串口发送（FPGA -> PC）
    output          tx_done ,//发送完成
    output          rx_done  //接收完成
);

wire        tick    ;
wire [7:0]  rx_data ;

//波特率发生器：使能常开，产生9600bps的tick
brg brg_u(
    .clk   (clk   ),
    .rst_n (rst_n ),
    .brg_en(1'b1  ),
    .tick  (tick  )
);

//发送器：拨码数据经串口发给PC
tx tx_u(
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .tick   (tick   ),
    .tx_star(tx_star),
    .tx_data(tx_data),
    .tx     (tx     ),
    .tx_done(tx_done)
);

//接收器：接收PC发来的数据（rx_done指示，rx_data待后续显示）
rx rx_u(
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .rx     (rx     ),
    .tick   (tick   ),
    .rx_done(rx_done),
    .data   (rx_data)
);

endmodule

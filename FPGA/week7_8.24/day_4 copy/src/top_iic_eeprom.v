module top_iic_eeprom (
    input           clk     ,
    input           rst_n   ,
    input           rx      ,// UART RX
    input           key     ,// 按键：触发 EEPROM 读
    inout           scl     ,// IIC 时钟
    inout           sda     ,// IIC 数据
    output          tx       // UART TX
);

    //------------------------------------------------------------
    // 内部连线
    //------------------------------------------------------------
    wire            tick        ;// 波特率 bit 脉冲
    wire            rx_done     ;// UART 接收完成
    wire    [7:0]   rx_data     ;// UART 接收数据
    wire            tx_done     ;// UART 发送完成
    wire    [7:0]   tx_data     ;// UART 发送数据
    wire            tx_star     ;// UART 发送启动

    wire            key_flag    ;// 按键消抖后脉冲

    wire            iic_start   ;// IIC 启动
    wire            iic_rw      ;// IIC 读写控制
    wire    [7:0]   iic_wdata   ;// IIC 发送数据
    wire    [7:0]   iic_rdata   ;// IIC 接收数据
    wire    [7:0]   iic_sendnum ;// IIC 发送字节数
    wire    [7:0]   iic_recvnum ;// IIC 接收字节数
    wire            iic_done_r  ;// IIC 读完成
    wire            iic_done_w  ;// IIC 写完成
    wire            iic_done    ;// IIC 事务完成
    wire            iic_done_any;// 合并完成信号给 eeprom

    //------------------------------------------------------------
    // 波特率发生器：为 UART TX 提供 tick
    // 说明：tx 模块在 IDLE 时不输出 brg_en，会导致无法启动。
    // 这里把 brg 常开，tick 自由运行，tx 在 tx_star 上升沿与 tick 对齐。
    //------------------------------------------------------------
    brg brg_inst (
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .brg_en     (1'b1   ),
        .tick       (tick   )
    );

    //------------------------------------------------------------
    // 按键消抖
    //------------------------------------------------------------
    key key_inst (
        .key        (key    ),
        .clk        (clk    ),
        .rst        (rst_n  ),
        .flag       (key_flag)
    );

    //------------------------------------------------------------
    // UART 接收：PC 发字节 → EEPROM 写
    //------------------------------------------------------------
    rx rx_inst (
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .rx         (rx     ),
        .rx_done    (rx_done),
        .parity_error (),
        .data       (rx_data)
    );

    //------------------------------------------------------------
    // UART 发送：EEPROM 读出的字节 → PC
    //------------------------------------------------------------
    tx tx_inst (
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .tick       (tick   ),
        .tx_star    (tx_star),
        .tx_data    (tx_data),
        .brg_en     (),
        .tx         (tx     ),
        .tx_done    (tx_done)
    );

    //------------------------------------------------------------
    // IIC 主机：已完成 sda/scl 的三态控制，顶层直接连到 inout
    //------------------------------------------------------------
    iic_0 iic_0_inst (
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .iic_start  (iic_start),
        .rw_ctrl    (iic_rw ),
        .data_i_iic (iic_wdata),
        .sendnum    (iic_sendnum),
        .recvnum    (iic_recvnum),
        .sda        (sda    ),
        .scl        (scl    ),
        .data_out   (iic_rdata),
        .iic_done_r (iic_done_r),
        .iic_done_w (iic_done_w),
        .iic_done   (iic_done)
    );

    // iic_0 的三种 done 合并为 eeprom 需要的一次事务完成脉冲
    assign iic_done_any = iic_done_r | iic_done_w | iic_done;

    //------------------------------------------------------------
    // EEPROM 控制器：桥接 UART 与 IIC
    // 写流程：UART 来 1 字节 → IIC 写 1 字节
    // 读流程：按键触发 → IIC 读 1 字节 → UART 发回 PC
    //------------------------------------------------------------
    eeprom eeprom_inst (
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .din_vld    (rx_done),
        .din        (rx_data),
        .rd_en      (key_flag),
        .done       (iic_done_any),
        .rd_data    (iic_rdata),
        .tx_done    (tx_done),
        .req        (iic_start),
        .rw_ctrl    (iic_rw ),
        .sendnum    (iic_sendnum),
        .recvnum    (iic_recvnum),
        .wr_data    (iic_wdata),
        .dout       (tx_data),
        .dout_vld   (tx_star)
    );

endmodule

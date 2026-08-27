module eeprom (
    input           clk     ,
    input           rst_n   ,
    input           din_vld ,// UART 收到一字节（来自 rx.rx_done）
    input   [7:0]   din     ,// UART 接收数据（来自 rx.data）
    input           rd_en   ,// 按键触发读 EEPROM（来自 key.flag）
    input           done    ,// IIC 一次事务完成
    input   [7:0]   rd_data ,// IIC 读回数据（来自 iic_0.data_out）
    input           tx_done ,// UART 发送完成（来自 tx.tx_done）
    output          req     ,// IIC 启动（连 iic_0.iic_start）
    output          rw_ctrl ,// 0:写, 1:读（连 iic_0.rw_ctrl）
    output  [7:0]   waddr   ,// 字地址（连 iic_0.waddr）
    output  [7:0]   sendnum ,// IIC 发送字节数
    output  [7:0]   recvnum ,// IIC 接收字节数
    output  [7:0]   wr_data ,// 写入 EEPROM 的数据（连 iic_0.data_i_iic）
    output  [7:0]   dout    ,// 读出送 UART 的数据（连 tx.tx_data）
    output          dout_vld // UART TX 启动（连 tx.tx_star）
);

    localparam  IDLE        = 3'd0,
                WR_START    = 3'd1,
                WR_WAIT     = 3'd2,
                RD_START    = 3'd3,
                RD_WAIT     = 3'd4,
                TX_START    = 3'd5,
                TX_WAIT     = 3'd6;

    reg [2:0]   state, next_state;
    reg [7:0]   din_r;
    reg [7:0]   rd_data_r;
    reg         din_vld_r;
    reg         rd_pending;

    // 锁存 UART 数据：避免与 IIC 采样产生竞争
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            din_r <= 8'd0;
        else if (din_vld)
            din_r <= din;
    end

    // UART 有效信号延后一拍，确保 din_r 已更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            din_vld_r <= 1'b0;
        else
            din_vld_r <= din_vld;
    end

    // 按键读请求锁存：防止按写入期间漏掉按键
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_pending <= 1'b0;
        else if (rd_en)
            rd_pending <= 1'b1;
        else if (state == RD_START)
            rd_pending <= 1'b0;
    end

    // 状态寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // 次态组合逻辑
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:       if (din_vld_r)      next_state = WR_START;
                   else if (rd_pending)    next_state = RD_START;

            WR_START:                       next_state = WR_WAIT;

            WR_WAIT:    if (done)           next_state = IDLE;

            RD_START:                       next_state = RD_WAIT;

            RD_WAIT:    if (done)           next_state = TX_START;

            TX_START:                       next_state = TX_WAIT;

            TX_WAIT:    if (tx_done)        next_state = IDLE;

            default:                        next_state = IDLE;
        endcase
    end

    // 在 IIC 读完成时锁存读回数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_data_r <= 8'd0;
        else if (state == RD_WAIT && done)
            rd_data_r <= rd_data;
    end

    // 输出：直接驱动 iic_0 的 start/rw/data/send/recv
    // 说明：AT24C02 的字节写 = 0xA0 + 字地址 + 数据(3字节)，
    //       随机读 = 0xA0 + 字地址 + (repeated START) + 0xA1 + 数据 + NACK。
    //       iic_0 把第 0 个数据字节固定当作字地址(waddr)发送，
    //       因此写操作 sendnum=2(字地址+数据)，读操作 sendnum=1(仅字地址)，
    //       recvnum=1 让 iic_0 在发完字地址后自动再发 START 转入读。
    assign req      = (state == WR_START) || (state == RD_START);
    assign rw_ctrl  = 1'b0;   // 读写都从"写命令(0xA0)+字地址"开始
    assign sendnum  = ((state == WR_START) || (state == WR_WAIT)) ? 8'd2 :
                      ((state == RD_START) || (state == RD_WAIT)) ? 8'd1 : 8'd0;
    assign recvnum  = ((state == RD_START) || (state == RD_WAIT)) ? 8'd1 : 8'd0;
    assign wr_data  = din_r;
    assign waddr    = 8'h00;  // 固定读写地址 0x00（改这里可换地址）
    assign dout     = rd_data_r;
    assign dout_vld = (state == TX_START) || (state == TX_WAIT);

endmodule

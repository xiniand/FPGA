module eeprom_rw (
    input               clk         ,
    input               rst_n       ,
    input               rx_done     ,// UART 收到一字节(rx_done)
    input    [7:0]      rx_data     ,// UART 接收数据(rx_data)
    input               iic_done    ,
    input               iic_done_w  ,
    output              iic_start   ,// IIC 启动
    output              rw_ctrl     ,// 0:写, 1:读
    output   [7:0]      sendnum     ,// IIC 发送字节数
    output   [7:0]      recvnum     ,// IIC 接收字节数
    output   [7:0]      data_i_iic   // 写入 EEPROM 的数据
);

    localparam  IDLE        = 6'd0      ,//识别包头
                WORR        = 6'd1      ,//done_rx
                SENDNUM     = 6'd10     ,//done_rx
                RECVNUM     = 6'd100    ,//done_rx识别包尾
                ADDR        = 6'd1000   ,//done_rx识别包尾
                DATA        = 6'd10000  ,//done_rx识别包尾
                STOP        = 6'd100000 ;//IDLE

    reg [5:0]   c_state, n_state    ;//现态，次态
    reg         rw_ctrl_rg          ;//锁存按键读信号
    reg [7:0]   sendnum_rg          ;//锁存rx信号
    reg [7:0]   recvnum_rg          ;//锁存iic读回信号
    reg [7:0]   sendnum_cnt         ;//写数据个数计数
    reg [7:0]   recvnum_cnt         ;//读数据个数计数
    reg [7:0]   addr_rg             ;    
    reg [7:0]   databuf [0:15]      ;//多字节写数据缓冲(AT24C02页写8字节,16深够用)
    reg [3:0]   wr_idx              ;//帧解析:已收数据字节数
    reg [3:0]   send_idx            ;//iic_done_w:已切换到总线的数据字节数
    reg [7:0]   data_temp           ;

//状态切换
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            c_state <= IDLE;
        else 
            c_state <= n_state;    
    end
//状态转移
    always @(*) begin
        case (c_state)
            IDLE   :begin
                if(rx_done && rx_data == 8'hfe)
                    n_state = WORR;
                else 
                    n_state = c_state ;
            end
            WORR   :begin
                if(rx_done)
                    n_state = SENDNUM;
                else
                    n_state = c_state ;
            end
            SENDNUM:begin
                if(rx_done)
                    n_state = RECVNUM;
                else
                    n_state = c_state ;
            end
            RECVNUM:begin
                if(rx_done && sendnum_rg == 0)
                    n_state = STOP;
                else if(rx_done && sendnum_rg != 0)
                    n_state = ADDR;
                else
                    n_state = c_state ;
            end
            ADDR   :begin
                if(rx_done && sendnum_rg >8'b1)
                    n_state = DATA;
                else if(rx_done && sendnum_rg == 8'h01)
                    n_state = STOP;
                else
                    n_state = c_state;
            end
            DATA   :begin
                if(rx_done && sendnum_rg == sendnum_cnt + 1)
                    n_state = STOP;
                else
                    n_state = c_state ;
            end
            STOP   :begin
                if(iic_done)
                    n_state = IDLE;
                else
                    n_state = c_state;
            end
            default: n_state = IDLE;
        endcase
    end
//输出
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rw_ctrl_rg   <= 0;
            sendnum_rg   <= 0;
            recvnum_rg   <= 0;
            addr_rg      <= 0;
            sendnum_cnt  <= 0;
            recvnum_cnt  <= 0;
            wr_idx       <= 0;
        end
        else begin
            case (c_state)
                 IDLE   :begin
                    rw_ctrl_rg      <= 0;
                    sendnum_rg      <= 0;
                    recvnum_rg      <= 0;
                    addr_rg         <= 0;
                    sendnum_cnt     <= 0;
                    recvnum_cnt     <= 0;
                    wr_idx          <= 0;
                end
                WORR   :begin
                    if(rx_done)
                        rw_ctrl_rg   <= rx_data;
                    sendnum_rg   <= 0;
                    recvnum_rg   <= 0;
                    addr_rg      <= 0;
                    sendnum_cnt     <= 0;
                    recvnum_cnt     <= 0;
                end
                SENDNUM:begin
                    if(rx_done)
                        sendnum_rg   <= rx_data;
                    recvnum_rg   <= 0;
                    addr_rg      <= 0;
                    sendnum_cnt     <= 0;
                    recvnum_cnt     <= 0;
                end
                RECVNUM:begin
                    if(rx_done)
                        recvnum_rg   <= rx_data;
                    addr_rg      <= 0;
                    sendnum_cnt     <= 0;
                    recvnum_cnt     <= 0;
                end
                ADDR   :begin
                    if(rx_done)begin
                        addr_rg      <= rx_data;
                        sendnum_cnt     <= sendnum_cnt + 1;
                    end
                    recvnum_cnt     <= 0;
                end
                DATA   :begin
                    if(rx_done)begin
                        databuf[wr_idx] <= rx_data;//数据依次进缓冲
                        wr_idx          <= wr_idx + 1;
                        if(sendnum_cnt < sendnum_rg)
                            sendnum_cnt     <= sendnum_cnt + 1;
                    end
                end
                STOP   :;
                default: begin
                    rw_ctrl_rg   <= 0;
                    sendnum_rg   <= 0;
                    recvnum_rg   <= 0;
                    addr_rg      <= 0;
                end 
            endcase
        end
    end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_temp <= 0;
        send_idx  <= 0;
    end
    else if(c_state == IDLE)begin//帧间清零:每帧都从databuf[0]开始取数(核心修复)
        data_temp <= 0;
        send_idx  <= 0;
    end
    else if(iic_done_w)begin//每写完一个字节(含地址),切下一个数据进 data_temp
        data_temp <= databuf[send_idx];
        send_idx  <= send_idx + 1;
    end
    else if(rx_done && c_state == ADDR)
        data_temp <= rx_data;
    else if(rx_done && c_state == DATA)
        data_temp <= addr_rg;
end


assign  iic_start   = (c_state == STOP)?1:0;
assign  rw_ctrl     = rw_ctrl_rg;
assign  sendnum     = sendnum_rg;
assign  recvnum     = recvnum_rg;
assign  data_i_iic  = data_temp ;

/* fifo_data	fifo_data_inst (
	.aclr   ( ~rst_n),
	.clock  ( clk   ),
	.data   ( data  ),
	.rdreq  ( rdreq ),
	.wrreq  ( wrreq ),
	.empty  ( empty ),
	.full   ( full  ),
	.q      ( q     ),
	.usedw  ( usedw )
);
 */
endmodule
module eeprom_rw_Q (
    input               clk     ,
    input               rst_n   ,
    input       [3:0]   cmd     ,//三种模式001只写（写2读0） 010只读（写0读1） 100先写后读（写1读1）
    input               rx_done ,// UART 收到一字节(rx_done)
    input       [7:0]   rx_data ,// UART 接收数据(rx_data)
    input               rd_en   ,// 按键触发读 EEPROM
    input               done    ,// IIC 完成信号
    input       [7:0]   rd_data ,// IIC 读回数据
    input               tx_done ,// UART 发送完成
    output  reg         req     ,// IIC 启动
    output  reg         rw_ctrl ,// 0:写, 1:读
    output  reg [7:0]   sendnum ,// IIC 发送字节数
    output  reg [7:0]   recvnum ,// IIC 接收字节数
    output  reg [7:0]   data_i_iic,// 写入 EEPROM 的数据
/*     output  reg [7:0]   tx_data ,// 读出送 UART 的数据 */
    output  reg         tx_star  // UART TX 启动
);

    localparam  IDLE        = 6'd0      ,//空闲态
                WR_START    = 6'd1      ,//写开始信号
                WR_WAIT     = 6'd10     ,//写等待
                RD_START    = 6'd100    ,//读开始信号
                RD_WAIT     = 6'd1000   ,//读等待
                TX_START    = 6'd10000  ,//发送开始信号
                TX_WAIT     = 6'd100000 ;//发送等待

    reg [5:0]   c_state, n_state;//现态，次态
    reg [7:0]   rx_data_rg          ;//锁存rx信号
    reg [7:0]   rd_data_rg      ;//锁存iic读回信号
    reg         rx_done_rg      ;//接收一字节信号打一拍
    reg         rd_penrx_datag      ;//锁存按键读信号

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            rx_data_rg <= 0;
        else if(rx_done)
            rx_data_rg <= rx_data;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            rx_done_rg <= 0;
        else 
            rx_done_rg <= rx_done;
    end
//防止和写信号竞争    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_penrx_datag <= 1'b0;
        else if (rd_en)
            rd_penrx_datag <= 1'b1;
        else if (c_state == RD_START)
            rd_penrx_datag <= 1'b0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_data_rg <= 8'd0;
        else if (c_state == RD_WAIT && done)
            rd_data_rg <= rd_data;
    end
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
            IDLE    :begin
                if(rx_done_rg && (cmd == 001 ||cmd == 100))
                    n_state = WR_START;
                else if(rd_penrx_datag)
                    n_state = RD_START;
                else
                    n_state = c_state;
            end
            WR_START:begin
                n_state = WR_WAIT;
            end
            WR_WAIT :begin
                if(done && cmd == 001)
                    n_state = WR_START;
                else if(done && cmd == 100)
                    n_state = RD_START;
                else
                    n_state = c_state;
            end
            RD_START:begin
                n_state = RD_WAIT;
            end
            RD_WAIT :begin
                if(done)
                    n_state = TX_START;
                else
                    n_state = c_state;
            end
            TX_START:begin
                n_state = TX_WAIT;
            end
            TX_WAIT :begin
                if(tx_done)
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
            req         <=0;// IIC 启动
            rw_ctrl     <=0;// 0:写, 1:读
            sendnum     <=0;// IIC 发送字节数
            recvnum     <=0;// IIC 接收字节数
            data_i_iic     <=0;// 写入 EEPROM 的数据
            tx_data        <=0;// 读出送 UART 的数据
            tx_star    <=0;// UART TX 启动
        end
        else begin
            case (c_state)
                IDLE    :begin
                    req         <=0;// IIC 启动
                    rw_ctrl     <=0;// 0:写, 1:读
                    sendnum     <=0;// IIC 发送字节数
                    recvnum     <=0;// IIC 接收字节数
                    data_i_iic     <=rx_data_rg;// 写入 EEPROM 的数据
                    tx_data        <=rd_data_rg;// 读出送 UART 的数据
                    tx_star    <=0;// UART TX 启动
                end
                WR_START:begin
                    req         <=1;// IIC 启动
                    rw_ctrl     <=0;// 0:写, 1:读
                    sendnum     <=1;//IIC写字节数
                    recvnum     <=0;//IIC读字节数
                    data_i_iic     <=rx_data_rg;// 写入 EEPROM 的数据
                    tx_data        <=rd_data_rg;//读出送 UART 的数据
                    tx_star    <=0;//UART TX 启动
                end
                WR_WAIT :begin
                    req         <=0;// IIC 启动
                    rw_ctrl     <=0;// 0:写, 1:读
                    data_i_iic     <=rx_data_rg;// 写入 EEPROM 的数据
                    tx_data        <=rd_data_rg;// 读出送 UART 的数据
                    tx_star    <=0;// UART TX 启动
                end
                RD_START:begin
                    req         <=1;// IIC 启动
                    recvnum     <=1;//IIC读字节数
                    sendnum     <=0;//IIC写字节数
                    rw_ctrl     <=1;// 0:写, 1:读
                    data_i_iic     <=rx_data_rg;// 写入 EEPROM 的数据
                    tx_data        <=rd_data_rg;// 读出送 UART 的数据
                end
                RD_WAIT :begin
                    req         <=0;// IIC 启动
                    rw_ctrl     <=1;// 0:写, 1:读
                    data_i_iic     <=rx_data_rg;// 写入 EEPROM 的数据
                    tx_data        <=rd_data_rg;// 读出送 UART 的数据
                end
                TX_START:begin
                    data_i_iic     <=rx_data_rg;// 写入 EEPROM 的数据
                    tx_data        <=rd_data_rg;// 读出送 UART 的数据
                    tx_star    <=1;// UART TX 启动
                end
                TX_WAIT :begin
                    data_i_iic     <=rx_data_rg;// 写入 EEPROM 的数据
                    tx_data        <=rd_data_rg;// 读出送 UART 的数据
                    tx_star    <=1;// UART TX 启动
                end 
                default: begin
                    req         <=0;// IIC 启动
                    rw_ctrl     <=0;// 0:写, 1:读
                    sendnum     <=0;// IIC 发送字节数
                    recvnum     <=0;// IIC 接收字节数
                    data_i_iic     <=0;// 写入 EEPROM 的数据
                    tx_data        <=0;// 读出送 UART 的数据
                    tx_star    <=0;// UART TX 启动
                end 
            endcase
        end
    end

endmodule
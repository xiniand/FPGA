module DS18B20 (
    input   clk     ,
    input   rst_n   ,
    inout   dq      ,//dq总线
    output  data_T  //每完成一次读取输出一次脉冲
);
//三态门
reg       dq_en   ;//时钟总线的开关使能
reg       dq_out  ;
wire      dq_in   ;

assign    dq   = dq_en?dq_out:1'bz;
assign    dq_in= dq                ;

//时间参数
parameter   TIME_IDLE   =   49          ;//1us
            TIME_REST   =   24999       ;//500us    >=480us
            TIME_RELS0  =   999         ;//20us     15us--60us
            TIME_RACK   =   4999        ;//100us    60us--240us
            TIME_WAIT   =   37_499_999  ;//750ms    转换时间最大750ms
            TIME_LOW    =   99          ;//2us      >= 1us
            TIME_SEND   =   2999        ;//60us     写时隙，至少60us
            TIME_SEND   =   2999        ;//60us     读时隙，至少60us
            TIME_RELS1  =   149         ;//3us      >=1us
//主状态机
localparam  M_IDLE      =   8'b0        ,//空闲状态，等待开始通信；
            M_REST      =   8'b1        ,//发复位脉冲；		s_cmd == 00
            M_RELS      =   8'b10       ,//主机释放总线；	
            M_RACK      =   8'b100      ,//主机接收存在脉冲；	
            M_ROMS      =   8'b1000     ,//主机发跳过ROM命令；s_cmd == 01
            M_CONT      =   8'b10000    ,//主机发温度转换命令；s_cmd == 01
            M_WAIT      =   8'b100000   ,//等待温度转换完成；
            M_RCMD      =   8'b1000000  ,//主机发送温度读取命令；s_cmd == 01
            M_RTMP      =   8'b10000000 ;//主机读取温度值；s_cmd == 10
//从状态机
localparam  S_IDLE      =   5'b0        ,//初始状态；
            S_LOW       =   5'b1        ,//主机拉低总线；
            S_SEND      =   5'b10       ,//主机发送1bit数据；
            S_SAMP      =   5'b100      ,//主机接收1bit数据；
            S_RELS      =   5'b1000     ,//主机释放总线；
            S_DONE      =   5'b10000    ;//传输完成。
//命令  
localparam  SKIP        =   8'hCC,//跳过rom
            TEMP_Z      =   8'h44,//温度转化
            REG_RD      =   8'hBE;//寄存器读取
   
reg     [3:0]   cnt_bit                 ;
reg     [25:0]  cnt_time                ;
reg     [25:0]  s_cnt_time              ;
reg     [7:0]   m_c_state ,m_n_state    ;
reg     [4:0]   s_c_state ,s_n_state    ;
reg     [15:0]  temp_rg                 ;//原始温度寄存
reg     flag                            ,  //跳过ROM命令完成标志完成为0
        flag_tx                         ;//温度转化命令发送完成标志
//主从状态机握手信号
reg     s_start                         ,
        s_busy                          ;//从机是否工作
reg     [1:0]   s_cmd                   ;//00复位，01写 10读
reg             s_tx_bit                ,
                s_rx_bit                ;    
reg     [25:0]  cnt_wait                ;       
reg     [15:0]  temp_shift              ;
reg     [7:0]   cmd_buf                 ;   
reg             data_T                  ;    

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//主状态机
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//状态切换
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        m_c_state <= M_IDLE;
    else 
        m_c_state <= m_n_state;
end
//状态转移
always @(*) begin
    case (m_c_state)
        M_IDLE:begin
            if(cnt_time == TIME_IDLE)
                m_n_state = M_REST;
            else
                m_n_state = m_c_state;
        end
        M_REST:begin//发复位脉冲；		s_cmd == 00
            if(cnt_time == TIME_REST)
                m_n_state = M_RELS;
            else
                m_n_state = m_c_state;
        end
        M_RELS:begin//释放总线
            if(cnt_time == TIME_RELS0)
                m_n_state = M_RACK;
            else
                m_n_state = m_c_state;
        end
        M_RACK:begin//主机接收存在脉冲；
            if(cnt_time == TIME_RACK)begin
                if(dq == 0)
                    m_n_state = M_ROMS;
                else
                    m_n_state = M_IDLE;
            end
            else
                m_n_state = M_IDLE;
        end
        M_ROMS:begin//主机发跳过ROM命令；s_cmd == 01
            if (!s_busy && cnt_bit == 4'd7) begin
                if (flag == 1'b0) 
                    m_n_state = M_CONT;
                else 
                    m_n_state = M_RCMD;
            end
            else
                m_n_state = m_c_state;
        end
        M_CONT:begin//主机发送温度转化命令
            if (!s_busy && cnt_bit == 4'd7) 
                m_n_state = M_WAIT;
            else
                m_n_state = m_c_state;
        end
        M_WAIT:begin//等待转化
            if(cnt_time == TIME_WAIT)
                m_n_state = M_REST;
            else
                m_n_state = m_c_state;
        end
        M_RCMD:begin//主机发送温度读取命令
            if(!s_busy && cnt_bit == 4'd7)
                m_n_state = M_RTMP;
            else
                m_n_state = m_c_state;
        end
        M_RTMP:begin//主机读取温度
            if(!s_busy && cnt_bit == 4'd15)
                m_n_state = M_IDLE;
            else
                m_n_state = m_c_state;
        end
        default: m_n_state = M_IDLE;
    endcase
end
//主状态机输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_time    <= 26'b0;//延时计数器
        cnt_bit     <= 4'b0 ;//发送bit位数计数器
        cnt_wait    <= 26'b0;//等待750ms计数器
        s_start     <= 0    ;//从机开始信号
        s_cmd       <= 0    ;//00 复位 01 写 10 读
        s_tx_bit    <= 0    ;//要发送的位
        temp_shift  <= 0    ;//16位温度位
        flag        <= 0    ;//第一次寄存器操作为0，第二次寄存器操作为1，因为就两次所以反转就行
        cmd_buf     <= 0    ;//命令字节
        data_T      <= 0    ;//完成输出脉冲
    else begin
        case (m_c_state)
            M_IDLE:begin
                cnt_time  <= 0;
                cnt_bit   <= 0;
                cnt_wait  <= 0;
                s_start   <= 0;
                s_cmd     <= 2'b00;
                s_tx_bit  <= 0;
                temp_shift<= 0;
                flag      <= 0;
                cmd_buf   <= 0;
                data_T    <= 0;
            end
            M_REST:begin//发复位脉冲；		s_cmd == 00
                if(cnt_time == TIME_REST)
                    cnt_time  <= 0;
                else
                    cnt_time <= cnt_time + 1;
                cnt_bit   <= 0;
                cnt_wait  <= 0;
                s_start   <= 1;
                s_cmd     <= 2'b00;
                s_tx_bit  <= 0;
                temp_shift<= 0;
                data_T    <= 0;
            end
            M_RELS:begin//释放总线
                if(cnt_time == TIME_RELS0)
                    cnt_time  <= 0;
                else
                    cnt_time <= cnt_time + 1;
                cnt_bit   <= 0;
                cnt_wait  <= 0;
                s_start   <= 0;
                s_cmd     <= 2'b00;
                s_tx_bit  <= 0;
                temp_shift<= 0;
                cmd_buf   <= 0;
                data_T    <= 0;
            end
            M_RACK:begin//主机接收存在脉冲；
                if(cnt_time == TIME_RACK)
                    cnt_time  <= 0;
                else
                    cnt_time <= cnt_time + 1;
                cnt_bit   <= 0;
                cnt_wait  <= 0;
                s_start   <= 0;
                s_cmd     <= 2'b00;
                s_tx_bit  <= 0;
                temp_shift<= 0;
                cmd_buf   <= 0;
                data_T    <= 0;
            end
            M_ROMS:begin//主机发跳过ROM命令；s_cmd == 01
                cmd_buf   <= SKIP;
                cnt_time  <= 0;
                if(!s_busy && cnt_bit == 4'd7)
                    cnt_bit   <= 0;
                else if(!s_busy)begin
                    cnt_bit <= cnt_bit + 1;
                end

                if(!s_busy)begin
                    s_start   <= 1;
                    s_cmd     <= 2'b01;
                    s_tx_bit  <= cmd_buf[cnt_bit];
                end 
                else begin
                    s_start <= 0;
                end 
                temp_shift<= 0;
                data_T    <= 0;
            end 
            M_CONT:begin//主机发送温度转化命令
                cmd_buf   <= TEMP_Z;
                cnt_time  <= 0;
                cnt_wait  <= 0;
                if(!s_busy && cnt_bit == 4'd7)
                    cnt_bit <= 0;
                else if(!s_busy)
                    cnt_bit <= cnt_bit + 1;
                if(!s_busy)
                    s_start   <= 1;
                    s_cmd     <= 2'b01;
                    s_tx_bit  <= cmd_buf[cnt_bit];
                else
                    s_start <=0;
                temp_shift<= 0;
                data_T    <= 0;
            end
            M_WAIT:begin//等待转化
                cnt_wait <= cnt_wait + 1;
                if(m_n_state == M_REST)
                    flag      <= 1;
            end
            M_RCMD:begin//主机发送温度读取命令
                cmd_buf   <= REG_RD;
                cnt_time  <= 0;
                cnt_wait  <= 0;
                if(!s_busy && cnt_bit == 4'd7)
                    cnt_bit   <= 0;
                else if(!s_busy)
                    cnt_bit <= cnt_bit + 1;
                if(!s_busy)
                    s_start   <= 1;
                    s_cmd     <= 2'b01;//写操作
                    s_tx_bit  <= cmd_buf[cnt_bit];
                else
                    s_start <=0;
            end
            M_RTMP:begin//主机读取温度
                if(!s_busy)begin
                    s_start   <= 1;
                    s_cmd     <= 2'b10;//读操作
                end 
                else
                    s_start   <= 0;

                if(!s_busy && cnt_bit == 4'd15)begin
                    cnt_bit   <= 0;
                    temp_shift <= {s_rx_bit,temp_shift[15:1]};
                    data_T     <= 1'b1;  
                end 
                else if(!s_busy && s_start == 0)begin
                    cnt_bit <= cnt_bit + 1;
                    temp_shift <= {s_rx_bit,temp_shift[15:1]};
                    data_T     <= 1'b0;
                end 
                else    
                    data_T     <= 1'b0;
            end
            default: m_n_state = M_IDLE;
        endcase
    end
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//从状态机
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//状态切换
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        s_c_state <= S_IDLE;
    else 
        s_c_state <= s_n_state;
end
//状态转移
always @(*) begin
    case (s_c_state)
        S_IDLE:begin
            if(s_start == 1)
                s_n_state = S_LOW;
            else
                s_n_state = s_c_state;
        end
        S_LOW :begin
            case (s_cmd)
                2'b00:begin
                    if(s_cnt_time == TIME_REST)
                        s_n_state = S_RELS;
                    else
                        s_n_state = s_c_state;
                end
                2'b01:begin//写操作
                    if( s_tx_bit== 0)begin
                        if(s_cnt_time == TIME_SEND)//计数60us 写0时一直拉低60us
                            s_n_state = S_RELS;
                        else
                            s_n_state = s_c_state;
                    end 
                    else begin
                        if(s_cnt_time == TIME_LOW) //写1时总线拉低2us后拉高60us
                            s_n_state = S_SEND;
                        else
                            s_n_state = s_c_state;
                    end
                    else
                        s_n_state = s_c_state;
                end 
                2'b10:begin//读操作
                    if(s_cnt_time == TIME_LOW)
                        s_n_state = S_SAMP;
                    else
                        s_n_state = s_c_state;
                end  
                default: s_n_state = IDLE;
            endcase
        end
        S_SEND:begin
            if(s_cnt_time == TIME_SEND)
                s_n_state = S_RELS;
            else
                s_n_state = s_c_state;
        end
        S_SAMP:begin
            if(s_cnt_time == TIME_SAWP)
                s_n_state = S_RELS;
            else
                s_n_state = s_c_state ;
        end
        S_RELS:begin
            if(s_cnt_time == TIME_RELS1 + TIME_SEND + 1)
                s_n_state = S_DONE;
            else
                s_n_state = s_c_state;
        end
        S_DONE:begin
            s_n_state = S_IDLE;
        end
        default: s_n_state = S_IDLE;
    endcase
end

//从状态机输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        s_busy      <= 0;
        dq_en       <= 0;
        dq_out      <= 1;
        s_rx_bit    <= 0;
        s_cnt_time  <= 0;
    else
        case (s_c_state)
        S_IDLE:begin
            s_busy      <= 0;
            dq_en       <= 0;
            dq_out      <= 1;
            s_cnt_time  <= 0;
        end
        S_LOW :begin
            s_busy      <= 1;
            dq_en       <= 1;
            dq_out      <= 0;
            s_cnt_time  <= s_cnt_time + 1;
        end
        S_SEND:begin
            s_busy      <= 1;
            dq_en       <= 0;
            dq_out      <= 1;
            s_cnt_time  <= s_cnt_time + 1;
        end
        S_SAMP:begin
            s_busy      <= 1;
            dq_en       <= 0;
            s_cnt_time  <= s_cnt_time + 1;
            if(s_cnt_time == 499)
                s_rx_bit    <= dq_in;
        end
        S_RELS:begin
            s_busy      <= 1;
            dq_en       <= 0;
            dq_out      <= 1;
            s_cnt_time  <= s_cnt_time + 1;
        end
        S_DONE:begin
            s_busy      <= 0;
            dq_en       <= 0;
            dq_out      <= 1;
            s_cnt_time  <= 0;
        end 
        default:begin
            s_busy      <= 0;
            dq_en       <= 0;
            dq_out      <= 1;
            s_rx_bit    <= 0;
            s_cnt_time  <= 0;
        end
    endcase
end
endmodule
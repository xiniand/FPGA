module iic_0 (
    input               clk         ,
    input               rst_n       ,
    input               iic_start   ,//开始通信信号
    input               rw_ctrl     ,//读写控制0写1读
    input       [7:0]   data_i_icc  ,//要发送的信号
    input       [7:0]   sendnum     ,
    input       [7:0]   recvnum     ,
    inout               sda         ,//数据线总线
    inout               scl         ,//时钟线     
    output      [7:0]   data_in     ,//接收到的信号
    output              iic_done_r  ,//读完
    output              iic_done_w  ,//写完
    output              iic_done    //写完
);
    parameter   id_w      = 8'b10100000     ,//从机设备地址
                id_r      = 8'b10100001     ,
                clk_0     = 50_000_000      ,//板卡频率50MHZ
                iic_clk   = 100_000         ,//IIC的速度 100K
                delay     = clk_0/iic_clk   ,//一个IIC的工作周期
                MID       = delay/2         ,//iic的周期 1/2
                Q_MID     = delay/4         ,//iic的周期 1/4 
                TQ_MID    = MID+Q_MID       ;//iic的周期 3/4

    localparam  IDLE        = 11'b0             ,//空闲
                START_1     = 11'b1             ,//发送设备地址开始状态
                ID_W        = 11'b10            ,//主机发送设备地址,以及写信号0
                ACK1        = 11'b100           ,//从机->主机，从机应答信号
                WR_DATA     = 11'b1000          ,//RW为0写有效时进去
                ACK2        = 11'b10000         ,//从机应答信号
                START_2     = 11'b100000        ,//RW为1读有效时进去，再发送起始信号
                ID_R        = 11'b1000000       ,//串行输出从机地址+读位（1）
                ACK3        = 11'b10000000      ,//从机应答信号
                RD_DATA     = 11'b100000000     ,//读数据
                NACK        = 11'b1000000000    ,//主机发送读完一字节应答信号
                STOP        = 11'b10000000000   ;//停止信号

    reg [7:0]   sendnum_rg      ,//发送数据量寄存器
                recvnum_rg      ;//接收数据量寄存器
    reg [7:0]   sendnum_cnt     ,//发送数据个数
                recvnum_cnt     ;//接收数据个数
    reg [9:0]   cnt_time        ;//时间计数器
    reg [7:0]   cnt_bit         ;//当前正在写/读的数据位数
    reg [7:0]   data_rg         ;    
    reg [7:0]   data_temp       ;   
    reg [1:0]   iic_start_rg    ;
    reg         rw_reg          ;//寄存读写状态

    reg [11:0]  c_state         ,//现态
                n_state         ;//次态
    reg         ack_flag        ;//从机响应信号

    reg         sda_en          ;//时钟总线的开关使能
    reg         sda_out         ;
    wire        sda_in          ;   
    assign      sda   = sda_en?sda_out:1'bz;
    assign      sda_in= sda                ;

    reg         scl_en    ;//时钟总线的开关使能
    reg         scl_out   ;
    wire        scl_in    ;    
    assign      scl   = scl_en?scl_out:1'bz   ;
    assign      scl_in= scl                   ;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            iic_start_rg <= 2'b00;
        else
            iic_start_rg    <= {iic_start_rg[0],start_iic};
    end

    always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= 0;
    else
        c_state <= n_state;
    end

    always @(*) begin
        case (c_state)
            IDLE       :begin
                if(iic_start_rg == 2'b01)
                    n_state = START_1;
                else
                    n_state = c_state;
            end
            START_1    :begin
                if(cnt_time == delay + Q_MID - 1 && rw_reg == 0)
                    n_state = ID_W;
                else if(cnt_time == delay + Q_MID - 1 && rw_reg == 1)
                    n_state = ID_R;
                else
                    n_state = c_state;
            end
            ID_W       :begin//发送设备地址，写信号（0写）
                if(bit_cnt == 7 && cnt_time == delay - 1)
                    n_state = ACK1;
                else
                    n_state = c_state;
            end
            ACK1       :begin
                if(ack_flag == 1 && cnt_time == delay - 1)
                    n_state = IDLE;
                else if(ack_flag == 0 && cnt_time == delay - 1)
                    n_state = WR_DATA;
                else
                    n_state = c_state;
            end
            WR_DATA    :begin
                if(bit_cnt == 7 && cnt_time == delay - 1)
                    n_state = ACK2;
                else
                    n_state = c_state;
            end
            ACK2       :begin
                if(ack_flag == 1 && cnt_time == delay - 1 )
                    n_state = IDLE;
                else if(ack_flag == 0 && cnt_time == delay - 1 && sendnum_cnt == sendnum_rg && recvnum == 0)
                    n_state = STOP;
                else if(ack_flag == 0 && cnt_time == delay - 1 && sendnum_cnt == sendnum_rg && recvnum != 0)
                    n_state = START_2;
                else if(ack_flag == 0 && cnt_time == delay - 1 && sendnum_cnt < sendnum_rg )
                    n_state = WR_DATA;
                else
                    n_state = c_state;
            end
            START_2    :begin
                if(cnt_time == delay + Q_MID - 1 )
                    n_state = ID_R;
                else
                    n_state = c_state;
            end
            ID_R       :begin
                if(bit_cnt == 7 && cnt_time == delay - 1)
                    n_state = ACK3;
                else
                    n_state = c_state;
            end
            ACK3       :begin
                if(ack_flag == 1 && cnt_time == delay - 1)
                    n_state = IDLE;
                else if(ack_flag == 0 && cnt_time == delay - 1)
                    n_state = RD_DATA;
                else
                    n_state = c_state;
            end
            RD_DATA    :begin
                if(bit_cnt && cnt_time == delay - 1)
                    n_state = NACK;
                else
                    n_state = c_state;
            end
            NACK       :begin
                if(cnt_time == delay - 1 recvnum_cnt == recvnum_rg)
                    n_state = STOP;
                else if(cnt_time == delay - 1 && recvnum_cnt < recvnum_rg)
                    n_state = RD_DATA;
                else
                    n_state = c_state;
            end
            STOP       :begin
                if(cnt_time == delay + Q_MID - 1)
                    n_state = IDLE;
                else
                    n_state = c_state;
            end
            default:n_state = IDLE; 
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sendnum_rg   <=0;  
            recvnum_rg   <=0;  
            sendnum_cnt  <=0;  
            recvnum_cnt  <=0;  
            cnt_time     <=0;  
            cnt_bit      <=0;  
            data_rg      <=0;  
            data_temp    <=0;  
            rw_reg       <=0;  
            ack_flag     <=0;
            scl_en       <=0; 
            scl_out      <=1; 
            sda_en       <=0; 
            sda_out      <=1; 
        end
        else begin
            case (c_state)
            IDLE       :begin
                sendnum_rg   <=sendnum;
                recvnum_rg   <=recvnum;
                rw_reg       <=rw_ctrl;
                data_rg      <=data_i_icc;
                
                sendnum_cnt  <=0;
                recvnum_cnt  <=0;
                cnt_time     <=0;
                cnt_bit      <=0;
                
                data_temp    <=0;

                ack_flag     <=0;
                scl_en       <=0;
                scl_out      <=1;
                sda_en       <=0;
                sda_out      <=1;
            end
            START_1,START_2    :begin
                sendnum_cnt  <=0;
                recvnum_cnt  <=0;
                if(cnt_time == delay + Q_MID -1)
                    cnt_time     <=0;
                else
                    cnt_time    <= cnt_time + 1;
                cnt_bit      <=0;
                
                data_temp    <=0;
                ack_flag     <=0;
                scl_en       <=1;
                sda_en       <=1;
                if(cnt_time >= delay - 1)
                    scl_out      <=0;
                else
                    scl_out     <= 1;
                if(cnt_time >= MID - 1)
                    sda_out     <=0;
                else
                    sda_out     <=1;
            end
            ID_W       :begin//发送设备地址，写信号（0写）
                if(cnt_time == delay - 1)
                    cnt_time     <=0;
                else
                    cnt_time    <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7)
                        cnt_bit      <=0;
                    else
                        cnt_bit <= cnt_bit + 1;
                sendnum_cnt  <=0;
                recvnum_cnt  <=0;
                data_temp    <=0;
                ack_flag     <=0;


                scl_en       <=1;
                sda_en       <=1;
                if(cnt_time >= Q_MID && cnt_time <= TQ_MID)
                    scl_out      <=1;
                else
                    scl_out     <= 0;
                if(cnt_time == 1)
                    sda_out   <=id_w[7- cnt_bit];

            end
            ACK1,ACK3       :begin
                if(cnt_time == delay - 1)
                    cnt_time     <=0;
                else
                    cnt_time    <= cnt_time + 1;
                cnt_bit      <=0;
                sendnum_cnt  <=0;
                recvnum_cnt  <=0;
                data_temp    <=0;

                scl_en       <=1;
                sda_en       <=0;
                sda_out      <=1;
                if(cnt_time >= Q_MID && cnt_time <= TQ_MID)
                    scl_out      <=1;
                else
                    scl_out     <= 0;
                if(cnt_time == MID - 1)
                    ack_flag   <= sda_in;
            end
            WR_DATA    :begin
                if(cnt_time == delay - 1)
                    cnt_time     <=0;
                else
                    cnt_time    <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7)
                        cnt_bit      <=0;
                    else
                        cnt_bit <= cnt_bit + 1;
                data_temp    <=0;
                ack_flag     <=0;
                scl_en       <=1;
                sda_en       <=1;
                if(cnt_time >= Q_MID && cnt_time <= TQ_MID)
                    scl_out      <=1;
                else
                    scl_out     <= 0;
                if(cnt_time == 1)
                    sda_out   <=data_rg[7- cnt_bit];
            end
            ACK2       :begin
                if(cnt_time == delay - 1)
                    cnt_time     <=0;
                else
                    cnt_time    <= cnt_time + 1;
                cnt_bit      <=0;
                recvnum_cnt  <=0;
                data_temp    <=0;
                data_rg      <=data_i_icc;
                scl_en       <=1;
                sda_en       <=0;
                sda_out      <=1;
                if(cnt_time >= Q_MID && cnt_time <= TQ_MID)
                    scl_out      <=1;
                else
                    scl_out     <= 0;
                if(cnt_time == MID - 1) begin
                    ack_flag   <= sda_in;
                    sendnum_cnt  <=sendnum_cnt + 1;
                end
            end
            ID_R       :begin
                if(cnt_time == delay - 1)
                    cnt_time     <=0;
                else
                    cnt_time    <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7)
                        cnt_bit      <=0;
                    else
                        cnt_bit <= cnt_bit + 1;
                sendnum_cnt  <=0;
                recvnum_cnt  <=0;
                data_temp    <=0;
                ack_flag     <=0;


                scl_en       <=1;
                sda_en       <=1;
                if(cnt_time >= Q_MID && cnt_time <= TQ_MID)
                    scl_out      <=1;
                else
                    scl_out     <= 0;
                if(cnt_time == 1)
                    sda_out   <=id_r[7- cnt_bit];
            end
            RD_DATA    :begin
                if(cnt_time == delay - 1)
                    cnt_time     <=0;
                else
                    cnt_time    <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7)
                        cnt_bit      <=0;
                    else
                        cnt_bit <= cnt_bit + 1;
                sendnum_cnt  <=0;
                data_temp    <=0;
                ack_flag     <=0;

                scl_en       <=1;
                sda_en       <=0;
                sda_out      <=1;
                if(cnt_time >= Q_MID && cnt_time <= TQ_MID)
                    scl_out      <=1;
                else
                    scl_out     <= 0;
                if(cnt_time == MID)
                    data_temp[7-cnt_bit]   <=sda_in;
            end
            NACK       :begin
                if(cnt_time == delay - 1)
                    cnt_time     <=0;
                else
                    cnt_time    <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7)
                        cnt_bit      <=0;
                    else
                        cnt_bit <= cnt_bit + 1;
                ack_flag    <= 0;
                scl_en       <=1;
                sda_en       <=1;
                if(cnt_time >= Q_MID && cnt_time <= TQ_MID)
                    scl_out      <=1;
                else
                    scl_out     <= 0;
                if(cnt_time == MID)
                    recvnum_cnt <= recvnum_cnt + 1;

                if(recvnum_rg == recvnum_cnt )
                    sda_out <= 1;
                else
                    sda_out <= 0;
            end
            STOP       :begin
                sendnum_cnt  <=0;
                recvnum_cnt  <=0;
                if(cnt_time == delay + Q_MID -1)
                    cnt_time     <=0;
                else
                    cnt_time    <= cnt_time + 1;
                cnt_bit      <=0;
                
                data_temp    <=0;
                ack_flag     <=0;
                scl_en       <=1;
                sda_en       <=1;
                if(cnt_time >= Q_MID - 1)
                    scl_out      <=1;
                else
                    scl_out     <= 0;
                if(cnt_time >= TQ_MID - 1)
                    sda_out     <=1;
                else
                    sda_out     <=0;
            end
            default:begin
                sendnum_rg   <=0;  
                recvnum_rg   <=0;  
                sendnum_cnt  <=0;  
                recvnum_cnt  <=0;  
                cnt_time     <=0;  
                cnt_bit      <=0;  
                data_rg      <=0;  
                data_temp    <=0;  
                rw_reg       <=0;  
                ack_flag     <=0;
                scl_en       <=0; 
                scl_out      <=1; 
                sda_en       <=0; 
                sda_out      <=1;
            end 
        endcase
        end 
        
    end


endmodule
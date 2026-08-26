module iic (
    input               clk         ,
    input               rst_n       ,
    input               iic_start   ,//开始通信信号
    input               rw_ctrl     ,//读写控制0写1读
    input       [7:0]   data_i_icc  ,//要发送的信号
    input       [7:0]   sendnum     ,
    input       [7:0]   rednum      ,
    input               key         ,
    inout               sda         ,//数据线总线
    inout               scl         ,//时钟线     
    output  reg [7:0]   data_in     ,//接收到的信号
    output  reg         iic_done_r ,//读完
    output  reg         iic_done_w  //写完

);

parameter   ID_1        = 7'b1010000;//从机设备地址


localparam  IDLE        = 13'b0             ,//空闲
            START_1     = 13'b1             ,//发送设备地址开始状态
            ID_W        = 13'b10            ,//主机发送设备地址,以及写信号0
            ACK1        = 13'b100           ,//从机->主机，从机应答信号
            SEND_ADDR_L = 13'b1000          ,//写寄存器地址低八位（eeprom为8位）
            ACK3        = 13'b10000         ,//从机->主机，从机应答信号
            WR_DATA     = 13'b100000        ,//RW为0写有效时进去
            ACK4        = 13'b1000000       ,//从机应答信号
            START_2     = 13'b10000000      ,//RW为1读有效时进去，再发送起始信号
            ID_R        = 13'b100000000     ,//串行输出从机地址+读位（1）
            ACK5        = 13'b1000000000    ,//从机应答信号
            RD_DATA     = 13'b10000000000   ,//读数据
            NACK        = 13'b100000000000  ,//主机发送读完一字节应答信号
            STOP        = 13'b1000000000000 ;//停止信号

localparam  addr_max=255;//从机存储地址最大地址位


parameter clk_0     = 50_000_000    ;//板卡频率50MHZ
parameter iic_clk   = 100_000       ;//IIC的速度 100K
parameter delay     = clk_0/iic_clk ;//一个IIC的工作周期
parameter MID       = delay/2       ;//iic的周期 1/2
parameter Q_MID     = delay/4       ;//iic的周期 1/4 
parameter TQ_MID    = MID+Q_MID     ;//iic的周期 3/4
/* parameter delay     = 200           ;//4us */

reg [7:0]   sendnum_rg         ,
            rednum_rg          ;

reg [7:0]   addr            ;//写操作的地址位
reg         rw_reg          ;//寄存读写状态
reg [14:0]  c_state         ,//现态
            n_state         ;//次态
reg [9:0]   cnt_bit         ;//当前正在写/读的数据位数
reg         bit_done        ;//写/读完一组数据的信号
reg         ack_flag        ;//从机响应信号
reg [9:0]   cnt_time        ;
reg [7:0]   data            ;

wire [7:0]  ctrl_w = {ID_1, 1'b0};//控制字节：器件地址+写(0)
wire [7:0]  ctrl_r = {ID_1, 1'b1};//控制字节：器件地址+读(1)


reg         sda_en          ;//时钟总线的开关使能
reg         sda_out         ;
wire        sda_in          ;   

assign    sda   = sda_en?sda_out:1'bz;
assign    sda_in= sda                ;

reg       scl_en   ;//时钟总线的开关使能
wire      scl_in   ;    

assign    scl   = scl_en?1'b0:1'bz   ;
assign    scl_in= scl                ;

//状态切换
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= 0;
    else
        c_state <= n_state;
end
//状态转移
always @(*) begin
    case (c_state)
        IDLE       :begin
            if(key)
                n_state = START_1;
            else
                n_state = c_state;
        end
        START_1    :begin
            if(cnt_time == delay - 1)
                n_state = ID_W;
            else
                n_state = c_state;
        end
        ID_W       :begin//发送设备地址，写信号（0写）
            if(bit_done && cnt_time == delay - 1)
                n_state = ACK1;
            else
                n_state = c_state;
        end
        ACK1       :begin
            if(ack_flag == 0 && cnt_time == delay - 1)
                n_state = STOP;
            else if(ack_flag == 1 && cnt_time == delay - 1)
                n_state = SEND_ADDR_L;
            else
                n_state = c_state;
        end
        SEND_ADDR_L:begin
            if(bit_done && cnt_time == delay - 1)
                n_state = ACK3;
            else
                n_state = c_state;
        end
        ACK3       :begin
            if(ack_flag == 0 && cnt_time == delay - 1)
                n_state = STOP;
            else if(ack_flag == 1 && cnt_time == delay - 1 && rw_reg == 0)
                n_state = WR_DATA;
            else if(ack_flag == 1 && cnt_time == delay - 1 && rw_reg == 1)
                n_state = START_2;
            else
                n_state = c_state;
        end
        WR_DATA    :begin
            if(bit_done && cnt_time == delay - 1)
                n_state = ACK4;
            else
                n_state = c_state;
        end
        ACK4       :begin
            if(ack_flag == 0 && cnt_time == delay - 1 )
                n_state = STOP;
            else if(ack_flag == 0 && cnt_time == delay - 1 && sendnum_rg == 0)
                n_state = STOP;
            else if(ack_flag == 1 && cnt_time == delay - 1 && sendnum_rg != 0)
                n_state = WR_DATA;
            else
                n_state = c_state;
        end
        START_2    :begin
            if(cnt_time == delay - 1)
                n_state = ID_R;
            else
                n_state = c_state;
        end
        ID_R       :begin
            if(bit_done && cnt_time == delay - 1)
                n_state = ACK5;
            else
                n_state = c_state;
        end
        ACK5       :begin
            if(ack_flag == 0 && cnt_time == delay - 1)
                n_state = STOP;
            else if(ack_flag == 1 && cnt_time == delay - 1)
                n_state = RD_DATA;
            else
                n_state = c_state;
        end
        RD_DATA    :begin
            if(bit_done && cnt_time == delay - 1)
                n_state = NACK;
            else
                n_state = c_state;
        end
        NACK       :begin
            if(cnt_time == delay - 1 && rednum_rg == 0)
                n_state = STOP;
            else if(cnt_time == delay - 1 && rednum_rg != 0)
                n_state = RD_DATA;
            else
                n_state = c_state;
        end
        STOP       :begin
            if(cnt_time == delay - 1)
                n_state = IDLE;
            else
                n_state = c_state;
        end
        default:n_state = IDLE; 
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        scl_en      <=0;//scl使能
        cnt_bit     <=0;//当前发送的位数
        bit_done    <=0;//发送八位完成信号
        ack_flag    <=0;//应答信号
        cnt_time    <=0;//延时计时器
        rednum_rg   <=0;
        sendnum_rg  <=0;
        addr        <=0;//写的存储器地址
        rw_reg      <=0;//要进行写操作还是读操作
        sda_en      <=0;//sda_en 1主机控制 0从机控制
        sda_out     <=1;//主机控制时的sda
    end
    else begin
        case (c_state)
            IDLE       :begin
                scl_en      <=0;//scl使能
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                ack_flag    <=0;//应答信号
                cnt_time    <=0;//延时计时器
                rednum_rg   <=rednum;
                sendnum_rg  <=sendnum;
                addr        <=addr;//当前读/写的存储器地址
                rw_reg      <=rw_ctrl;//要进行写操作还是读操作
                sda_en      <=0;//sda_en 1主机控制 0从机控制
                sda_out     <=1;//主机控制时的sda
            end
            START_1    :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                ack_flag    <=0;//应答信号
                rw_reg      <=rw_ctrl;//要进行写操作还是读操作
                if(cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                if(cnt_time <= MID) begin
                    sda_en      <=1; 
                    sda_out     <=1;
                end
                else begin
                    sda_en      <=1; 
                    sda_out     <=0;
                end 
            end
            ID_W       :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7) begin
                        cnt_bit     <=0;//当前发送的位数
                        bit_done    <=1;
                    end 
                    else
                        cnt_bit     <= cnt_bit + 1;
                ack_flag    <=0;//应答信号
                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                sda_en      <=1;

                if(cnt_time ==1)
                    sda_out    <=ctrl_w[7-cnt_bit] ;
            end
            ACK1       :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                sda_en      <=0;
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                rw_reg      <=rw_reg;//要进行写操作还是读操作

                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                if(cnt_time == MID)
                    ack_flag <= ~sda_in;
            end
            SEND_ADDR_L:begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7) begin
                        cnt_bit     <=0;//当前发送的位数
                        bit_done    <=1;
                    end 
                    else
                        cnt_bit     <= cnt_bit + 1;
                ack_flag    <=0;//应答信号
                rw_reg      <=rw_reg;//要进行0写操作还是1读操作
                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                    sda_en      <=1;
                if(cnt_time ==1)
                    sda_out    <=addr[7-cnt_bit];
            end
            ACK3       :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                sda_en      <=0;
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                rw_reg      <=rw_reg;//要进行写操作还是读操作
                addr        <=addr ;
                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                if(cnt_time == MID)
                    ack_flag <= ~sda_in;
            end
            WR_DATA    :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7) begin
                        cnt_bit     <=0;//当前发送的位数
                        bit_done    <=1;
                    end 
                    else
                        cnt_bit     <= cnt_bit + 1;
                ack_flag    <=0;//应答信号
                rw_reg      <=rw_reg;//要进行0写操作还是1读操作
                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                sda_en      <=1;
                if(cnt_time ==1)
                    sda_out    <=data_out[7-cnt_bit];
            end
            ACK4       :begin
                if(cnt_time == delay - 1)begin
                    cnt_time <= 0;
                    addr     <=addr + 1;
                end
                else 
                    cnt_time <= cnt_time + 1;
                sda_en      <=0;
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                rw_reg      <=rw_reg;//要进行写操作还是读操作
                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                if(cnt_time == MID)
                    ack_flag <= ~sda_in;
            end
            START_2    :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                ack_flag    <=1;//应答信号
                addr        <=addr;//当前读/写的存储器地址
                rw_reg      <=rw_ctrl;//要进行写操作还是读操作
                if(cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                if(cnt_time <= MID) begin
                    sda_en      <=1; 
                    sda_out     <=1;
                end
                else begin
                    sda_en      <=1; 
                    sda_out     <=0;
                end 
            end
            ID_R       :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7) begin
                        cnt_bit     <=0;//当前发送的位数
                        bit_done    <=1;
                    end 
                    else
                        cnt_bit     <= cnt_bit + 1;
                ack_flag    <=0;//应答信号
                rw_reg      <=rw_reg;//要进行0写操作还是1读操作
                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                sda_en      <=1;
                if(cnt_time ==1)
                    sda_out    <=ctrl_r[7-cnt_bit];
            end
            ACK5       :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                sda_en      <=0;
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                rw_reg      <=rw_reg;//要进行写操作还是读操作
                addr      <=addr + 1;
                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                if(cnt_time == MID)
                    ack_flag <= ~sda_in;
            end
            RD_DATA    :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                if(cnt_time == delay - 1)
                    if(cnt_bit == 7) begin
                        cnt_bit     <=0;//当前发送的位数
                        bit_done    <=1;
                    end 
                    else
                        cnt_bit     <= cnt_bit + 1;
                ack_flag    <=0;//应答信号
                rw_reg      <=rw_reg;//要进行0写操作还是1读操作
                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                sda_en      <=0;
                if(cnt_time ==MID)
                    data_in[7-cnt_bit]<=sda_in;
            end
            NACK       :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                rw_reg      <=rw_reg;//要进行写操作还是读操作
                addr        <=addr + 1;
                if(cnt_time>=Q_MID && cnt_time<=TQ_MID)
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                if(rednum_rg == 0)begin
                    if(cnt_time == 1)begin
                        sda_en      <=0;
                        sda_out     <=1;
                    end
                end
                else if(rednum !=0)begin
                    if(cnt_time == 1)begin
                        sda_en      <=1;
                        sda_out     <=0;
                    end
                end
            end
            STOP       :begin
                if(cnt_time == delay - 1)
                    cnt_time <= 0;
                else 
                    cnt_time <= cnt_time + 1;
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                ack_flag    <=1;//应答信号
                addr        <=addr;//当前读/写的存储器地址
                rw_reg      <=rw_ctrl;//要进行0写操作还是1读操作
                if(cnt_time>=Q_MID )
                    scl_en      <=0;//scl使能0高阻
                else
                    scl_en      <=1;//scl使能1拉低
                if(cnt_time <= MID) begin
                    sda_en      <=1; 
                    sda_out     <=0;
                end
                else begin
                    sda_en      <=1; 
                    sda_out     <=1;
                end 
            end
            default:begin
                scl_en      <=0;//scl使能
                cnt_bit     <=0;//当前发送的位数
                bit_done    <=0;//发送八位完成信号
                ack_flag    <=0;//应答信号
                cnt_time    <=0;//延时计时器
                addr        <=addr;//当前读/写的存储器地址
                rw_reg      <=rw_ctrl;//要进行写操作还是读操作
                sda_en      <=0;//sda_en 1主机控制 0从机控制
                sda_out     <=1;//主机控制时的sda
            end 
        endcase
    end
end 

endmodule
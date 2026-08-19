module iic(
    input               sysclk      ,//系统时钟-->50MHZ
    input               rst_n       ,//复位
    input               start       ,//外界模块输送的开始信号-->start==1 表示IIC开始进行数据传输工作
    input       [7:0]   sendnum     ,//写数据个数-->控制写数据状态循环是否结束   SENDATA-->ACK2之间的循环
    input       [7:0]   recvnum     ,//读数据个数-->控制读数据状态循环是否结束   RECVDATA-->ACK3之间的循环
    input               worr        ,//方向位--> 1、worr==0  只有写   2、worr==0  有虚写（先写后读）   worr==1  只有读
    input       [7:0]   data_in     ,//需要写的数据

    output reg  [7:0]   data_out    ,//读出的数据
    output              done_recv   ,//读数据结束信号
    output              done_send   ,//写数据结束信号
    output              done_iic    ,//IIC工作结束信号
    inout               sda         ,//IIC的数据总线
    inout               scl          //IIC的时钟总线
);

    parameter clk       = 50_000_000    ;//板卡频率50MHZ
    parameter iic_clk   = 100_000       ;//IIC的速度 100K
    parameter delay     = clk/iic_clk   ;//一个IIC的工作周期
    parameter MID       = delay/2       ;//iic的周期 1/2 
    parameter Q_MID     = delay/4       ;//iic的周期 1/4 
    parameter TQ_MID    = MID+Q_MID     ;//iic的周期 3/4

    //----------?
    parameter IDW       = 8'ha6         ;//写地址
    parameter IDR       = 8'ha7         ;//读地址

    reg [7:0] cnt_send ;//写数据的计数器-->看现在具体写到哪一个数据了
    reg [7:0] cnt_recv ;//读数据的计数器-->看现在具体读到哪一个数据了
    reg [7:0] data_in_reg;//输入数据寄存器-->为了规避数据错误
    reg       worr_reg ;//方向位寄存器
    reg [1:0] start_reg;//开始信号寄存器
    reg       ack_flag ;//应答寄存器
    reg [8:0] cnt      ;//IIC工作周期计时器
    reg [3:0] cnt_bit  ;//数据位计数器-->看现在具体传输到哪一个数据了

    //三态门
    reg       sda_en   ;//数据总线的开关使能
    reg       sda_out  ;
    wire      sda_in   ;

    assign    sda   = sda_en?sda_out:1'bz;
    assign    sda_in= sda                ;

    reg       scl_en   ;//时钟总线的开关使能
    reg       scl_out  ;
    wire      scl_in   ;    

    assign    scl   = scl_en?scl_out:1'bz;
    assign    scl_in= scl                ;

    //开始信号寄存器-->用于检测相对应的电平值或沿信号
    always@(posedge sysclk)
        if(!rst_n)
            start_reg<=0;
        else
            start_reg<={start_reg[0],start};//  00  低电平   01 上升沿  11 高电平  10下降沿

    parameter IDLE      = 4'd0,//空闲
              START     = 4'd1,//开始状态
              ID        = 4'd2,//主从联系
              ACK1      = 4'd3,//从机->主机
              SENDDATA  = 4'd4,//写数据状态
              ACK2      = 4'd5,//从->主
              STOP      = 4'd6,//IIC工作结束状态
              RECVDATA  = 4'd7,//读数据状态
              ACK3      = 4'd8,//主->从
              START1    = 4'd9,//虚写的开始信号
              ID1       = 4'd10,//虚写主找从
              ACK4      = 4'd11;//从->主

    reg [3:0] cur_state,next_state;

    //三段式状态机第一段
    always@(posedge sysclk)
        if(!rst_n)
            cur_state<=IDLE;
        else
            cur_state<=next_state;

    //三段式状态机第二段
    //三段式状态机第二段
    always@(*)
        if(!rst_n)
            next_state=IDLE;
        else
            case(cur_state)
                IDLE     :begin
                            if(start_reg==2'b11)
                                next_state=START;
                            else
                                next_state=cur_state;
                end

                START    :begin
                            if(cnt==delay-1)
                                next_state=ID;
                            else
                                next_state=cur_state;
                end

                ID       :begin
                            if(cnt_bit==7 && cnt==delay-1)
                                next_state=ACK1;
                            else
                                next_state=cur_state;
                end

                ACK1     :begin
                            if(ack_flag==1 && cnt==delay-1)//应答无效，必须跳到STOP！
                                next_state=STOP;
                            else if(ack_flag==0 && worr_reg==1 && cnt==delay-1)
                                next_state=RECVDATA;
                            else if(ack_flag==0 && worr_reg==0 && cnt==delay-1)
                                next_state=SENDDATA;
                            else
                                next_state=cur_state;
                end

                SENDDATA :begin
                            if(cnt_bit==7 && cnt==delay-1)
                                next_state=ACK2;
                            else
                                next_state=cur_state;
                end

                ACK2     :begin
                            if(ack_flag==1 && cnt==delay-1)//应答无效，跳到STOP
                                next_state=STOP;
                            else if(ack_flag==0 && cnt==delay-1 && cnt_send==sendnum && recvnum==0)
                                next_state=STOP;
                            else if(ack_flag==0 && cnt==delay-1 && cnt_send==sendnum && recvnum!=0)
                                next_state=START1;
                            else if(ack_flag==0 && cnt==delay-1 && cnt_send< sendnum)
                                next_state=SENDDATA;
                            else
                                next_state=cur_state;
                end

                STOP     :begin
                            if(cnt==delay-1)
                                next_state=IDLE;
                            else
                                next_state=cur_state;
                end

                RECVDATA :begin
                            if(cnt_bit==7 && cnt==delay-1)
                                next_state=ACK3;
                            else
                                next_state=cur_state;
                end

                ACK3     :begin
                            if(cnt==delay-1 && cnt_recv==recvnum)
                                next_state=STOP;
                            else if(cnt==delay-1 && cnt_recv<recvnum)
                                next_state=RECVDATA;
                            else
                                next_state=cur_state;
                end

                START1   :begin
                            if(cnt==delay-1)
                                next_state=ID1; // 【已修复】：跳向正确的虚写设备地址
                            else
                                next_state=cur_state;
                end

                ID1      :begin
                            if(cnt_bit==7 && cnt==delay-1)
                                next_state=ACK4; // 【已修复】：跳向正确的虚写应答状态
                            else
                                next_state=cur_state;
                end

                ACK4     :begin
                            if(ack_flag==1 && cnt==delay-1)//应答无效，跳到STOP
                                next_state=STOP;
                            else if(ack_flag==0 && cnt==delay-1)
                                next_state=RECVDATA;
                            else
                                next_state=cur_state;
                end

                default  :next_state=IDLE;
            endcase

   //三段式状态机第三段
    always@(posedge sysclk)
        if(!rst_n)begin
            cnt_send       <=0;//写数据的计数器
            cnt_recv       <=0;//读数据的计数器
            data_in_reg    <=0;//写数据的寄存器
            worr_reg       <=0;//读写方向的寄存器
            ack_flag       <=0;//应答信号的寄存器
            cnt            <=0;//iic的工作周期计数器
            cnt_bit        <=0;//bit位计数器
            data_out       <=0;//读出去的数据
            sda_en         <=0;//数据使能
            sda_out        <=0;//数据输出
            scl_en         <=0;//时钟使能
            scl_out        <=0;//时钟输出
        end
        else
            case(cur_state)
                IDLE      :begin
                            cnt_send       <=0;//写数据的计数器
                            cnt_recv       <=0;//读数据的计数器
                            data_in_reg    <=data_in;//写数据的寄存器    寄存数据
                            worr_reg       <=worr;//读写方向的寄存器
                            ack_flag       <=0;//应答信号的寄存器
                            cnt            <=0;//iic的工作周期计数器
                            cnt_bit        <=0;//bit位计数器
                            data_out       <=0;//读出去的数据
                            sda_en         <=0;//数据使能
                            sda_out        <=1;//数据输出
                            scl_en         <=0;//时钟使能
                            scl_out        <=1;//时钟输出
                end

                START     :begin
                            cnt_send       <=0;//写数据的计数器
                            cnt_recv       <=0;//读数据的计数器
                            //data_in_reg    <=data_in;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=worr;//读写方向的寄存器              -------保持
                            ack_flag       <=0;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            cnt_bit        <=0;//bit位计数器
                            data_out       <=0;//读出去的数据

                            sda_en         <=1;//数据使能--》开关打开
                            if(cnt<=Q_MID)//前1/4个周期
                                sda_out        <=1;//数据输出
                            else
                                sda_out        <=0;

                            scl_en         <=1;//时钟使能
                            if(cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                ID        :begin
                            cnt_send       <=0;//写数据的计数器
                            cnt_recv       <=0;//读数据的计数器
                            //data_in_reg    <=data_in;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=worr;//读写方向的寄存器              -------保持
                            ack_flag       <=0;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            if(cnt==delay-1)
                                cnt_bit        <=cnt_bit+1;//bit位计数器
                            //else
                            //    cnt_bit        <=cnt_bit;

                            data_out       <=0;//读出去的数据

                            sda_en         <=1;//数据使能--》开关打开
                            if(worr_reg==0 && cnt==1)//如果是写方向
                                sda_out        <=IDW[7-cnt_bit];//数据输出  从高位开始往低位传输
                            else if(worr_reg==1 && cnt==1) //如果是读方向
                                sda_out        <=IDR[7-cnt_bit];
                            else
                                sda_out        <=sda_out;

                            scl_en         <=1;//时钟使能
                            if(cnt>=Q_MID && cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                ACK1      :begin
                            cnt_send       <=0;//写数据的计数器
                            cnt_recv       <=0;//读数据的计数器
                            //data_in_reg    <=data_in;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=worr;//读写方向的寄存器              -------保持

                            if(cnt==MID)
                                ack_flag       <=sda_in;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            
                            cnt_bit        <=0;//bit位计数器

                            data_out       <=0;//读出去的数据

                            sda_en         <=0;
                            sda_out        <=1;

                            scl_en         <=1;//时钟使能
                            if(cnt>=Q_MID && cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                SENDDATA  :begin
                            //cnt_send       <=cnt_send;//写数据的计数器-->保持
                            cnt_recv       <=0;//读数据的计数器
                            //data_in_reg    <=data_in;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=worr;//读写方向的寄存器              -------保持

                            ack_flag       <=0;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            
                            if(cnt==delay-1)
                                cnt_bit        <=cnt_bit+1;//bit位计数器

                            data_out       <=0;//读出去的数据

                            sda_en         <=1;
                            if(cnt==1)
                                sda_out        <=data_in_reg[7-cnt_bit];
                            
                            scl_en         <=1;//时钟使能
                            if(cnt>=Q_MID && cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                ACK2      :begin
                            if(cnt==MID)
                                cnt_send       <=cnt_send+1;//写数据的计数器

                            cnt_recv       <=0;//读数据的计数器

                            data_in_reg    <=data_in;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=worr;//读写方向的寄存器              ------保持

                            if(cnt==MID)
                                ack_flag       <=sda_in;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            
                            cnt_bit        <=0;//bit位计数器

                            data_out       <=0;//读出去的数据

                            sda_en         <=0;
                            sda_out        <=1;

                            scl_en         <=1;//时钟使能
                            if(cnt>=Q_MID && cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                STOP      :begin
                            cnt_send       <=0;//写数据的计数器

                            cnt_recv       <=0;//读数据的计数器
                            
                            data_in_reg    <=0;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=0;//读写方向的寄存器              -------保持


                            ack_flag       <=0;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            
                            cnt_bit        <=0;//bit位计数器

                            data_out       <=0;//读出去的数据

                            sda_en         <=1;
                            if(cnt<=TQ_MID)//  3/4
                                sda_out        <=0;
                            else
                                sda_out        <=1;

                            scl_en         <=1;//时钟使能
                            if(cnt<=Q_MID)//1/4
                                scl_out        <=0;//时钟输出
                            else
                                scl_out        <=1;
                end

                RECVDATA  :begin
                            //cnt_send       <=0;//写数据的计数器-->保持
                            //cnt_recv       <=cnt_recv;//读数据的计数器
                            //data_in_reg    <=data_in;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=worr;//读写方向的寄存器              -------保持

                            ack_flag       <=0;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            
                            if(cnt==delay-1)
                                cnt_bit        <=cnt_bit+1;//bit位计数器

                            if(cnt==MID)
                                data_out[7-cnt_bit]       <=sda_in;//读出去的数据

                            sda_en         <=0;
                            sda_out        <=1;

                            scl_en         <=1;//时钟使能
                            if(cnt>=Q_MID && cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                ACK3      :begin
                            if(cnt==MID)
                                cnt_recv       <=cnt_recv+1;//读数据的计数器

                            worr_reg       <=worr;//读写方向的寄存器              -------保持
                            ack_flag       <=0;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;
                            
                            cnt_bit        <=0;//bit位计数器
                            data_out       <=data_out;//读出去的数据

                            sda_en         <=1;
                            
                            // 【完美防毛刺NACK逻辑】
                            // 仅在状态刚开始时判断，锁定一整个周期，防止在SCL高电平时翻转产生误STOP信号
                            if(cnt == 0) begin
                                if(cnt_recv == recvnum - 1)
                                    sda_out <= 1; // 最后一个字节发NACK
                                else
                                    sda_out <= 0; // 其他字节发ACK
                            end
                            else begin
                                sda_out <= sda_out; // 保持稳定
                            end

                            scl_en         <=1;//时钟使能
                            if(cnt>=Q_MID && cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                START1    :begin
                            cnt_send       <=0;//写数据的计数器
                            cnt_recv       <=0;//读数据的计数器
                            //data_in_reg    <=data_in;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=worr;//读写方向的寄存器              -------保持
                            ack_flag       <=0;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            cnt_bit        <=0;//bit位计数器
                            data_out       <=0;//读出去的数据

                            sda_en         <=1;//数据使能--》开关打开
                            if(cnt<=Q_MID)//前1/4个周期
                                sda_out        <=1;//数据输出
                            else
                                sda_out        <=0;

                            scl_en         <=1;//时钟使能
                            if(cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                ID1       :begin
                            cnt_send       <=0;//写数据的计数器
                            cnt_recv       <=0;//读数据的计数器
                            //data_in_reg    <=data_in;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=worr;//读写方向的寄存器              -------保持
                            ack_flag       <=0;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            if(cnt==delay-1)
                                cnt_bit        <=cnt_bit+1;//bit位计数器

                            data_out       <=0;//读出去的数据

                            sda_en         <=1;//数据使能--》开关打开
                            if(cnt==1) //如果是读方向
                                sda_out        <=IDR[7-cnt_bit];
                            else
                                sda_out        <=sda_out;

                            scl_en         <=1;//时钟使能
                            if(cnt>=Q_MID && cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                ACK4      :begin
                            cnt_send       <=0;//写数据的计数器
                            cnt_recv       <=0;//读数据的计数器

                            //data_in_reg    <=data_in;//写数据的寄存器    寄存数据 ------保持
                            worr_reg       <=worr;//读写方向的寄存器              -------保持

                            if(cnt==MID)
                                ack_flag       <=sda_in;//应答信号的寄存器

                            if(cnt==delay-1)//iic的工作周期计数器
                                cnt            <=0;
                            else
                                cnt            <=cnt+1;

                            
                            cnt_bit        <=0;//bit位计数器

                            data_out       <=0;//读出去的数据

                            sda_en         <=0;
                            sda_out        <=1;

                            scl_en         <=1;//时钟使能
                            if(cnt>=Q_MID && cnt<=TQ_MID)//1/4~3/4处置为高电平
                                scl_out        <=1;//时钟输出
                            else
                                scl_out        <=0;
                end

                default   :begin
                            cnt_send       <=0;//写数据的计数器
                            cnt_recv       <=0;//读数据的计数器
                            data_in_reg    <=data_in;//写数据的寄存器    寄存数据
                            worr_reg       <=worr;//读写方向的寄存器
                            ack_flag       <=0;//应答信号的寄存器
                            cnt            <=0;//iic的工作周期计数器
                            cnt_bit        <=0;//bit位计数器
                            data_out       <=0;//读出去的数据
                            sda_en         <=0;//数据使能
                            sda_out        <=1;//数据输出
                            scl_en         <=0;//时钟使能
                            scl_out        <=1;//时钟输出
                end
            endcase   

    assign    done_recv   = (cur_state==ACK3 && cnt==MID)?1:0;
    assign    done_send   = (cur_state==ACK2 && cnt==MID)?1:0;
    assign    done_iic    = (cur_state==STOP && cnt==MID)?1:0;
endmodule
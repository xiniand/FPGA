//数据接收器
module rx (
    input               clk     ,
    input               rst_n   ,
    input               rx      ,
    input               tick    ,
    output  reg         rx_done ,//使能：flag拉高；cnt==5207&&bit(baud_cnt)==9
    output  reg [7:0]   data    
);
parameter CLK_FREQ = 50_000_000                     ;// 系统时钟频率 
parameter BAUD_RATE = 9_600                         ;// 目标波特率
localparam COUNT_MAX = (CLK_FREQ / BAUD_RATE) - 1   ;
localparam  IDLE    =   2'b00,//空闲态
            START   =   2'b01,//起始态
            RECX    =   2'b10,//接收态
            STOP    =   2'b11;//停止态
/* parameter COUNT_MAX = 5207; */
reg [12:0]  cnt_bit ;//计数5208个周期发送一个bit
wire        flag        ;//下降沿rx_rg == 2'b10
reg         flag_d1     ;
reg [1:0]   rx_rg       ;//二级寄存
reg [4:0]   baud_cnt    ,//接受的数据位数
            n_baud_cnt  ;
reg [7:0]   data_rg     ;//接收的数据寄存
reg [1:0]   n_state     ,//次态
            c_state     ;//现态
wire        rx_mid      ,
            rx_end      ;
//计数器一个bit时间
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_bit <= 0;
    else if(flag_d1)      
        cnt_bit <= 0;
    else if(cnt_bit == COUNT_MAX)
        cnt_bit <= 0;
    else
        cnt_bit <= cnt_bit + 1;
end
assign  rx_end  = cnt_bit == COUNT_MAX      ;
assign  rx_mid  = cnt_bit == COUNT_MAX>>1   ;

//rx_rg两级寄存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_rg <= 2'b11;
    else
        rx_rg <= {rx_rg[0],rx};
end
//下降沿检测
assign  flag    =   (rx_rg == 2'b10);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        flag_d1 <= 1'b0;
    else
        flag_d1 <= flag;
end
//状态切换
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE;
    else 
        c_state <= n_state;
end

//baud_cnt寄存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        baud_cnt <= 5'd0;
    else
        baud_cnt <= n_baud_cnt;
end
//状态转移
always @(*) begin
    n_state    = c_state;
    n_baud_cnt = baud_cnt;
    case (c_state)
        IDLE:begin
            if(flag)begin//起始位从高电平拉低时下降沿进入起始态
                n_state = START;
                n_baud_cnt=0;
            end
            else
                n_state = IDLE;
        end 
        START:begin
            if(rx_mid)begin
                if(rx_rg[1] == 0)begin//起始位为0时进入接收态数据位数计数器清零
                    n_state = RECX;
                    n_baud_cnt = 0;
                end 
                else
                    n_state = IDLE;
            end
        end 
        RECX :begin
            if(rx_mid)begin//发送数据信号tick
                if(baud_cnt == 7)begin
                    n_state = STOP;
                    n_baud_cnt = 0;
                end
                else begin
                    n_baud_cnt = baud_cnt + 1;
                    n_state = RECX;
                end 
            end
        end 
        STOP :begin
            if(rx_mid)//进入停止态之后下一个周期进入空闲态
                n_state = IDLE;
            else
                n_state = STOP;
        end  
        default: n_state = IDLE;
    endcase
end
//输出
//发送位时每tick baud_cnt + 1将rx信号经过两级寄存后的rx_rg[1]给data_rg高位进行移位寄存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_rg <= 0;
    else if((c_state == RECX)&&rx_mid)
        data_rg <= {rx_rg[1],data_rg[7:1]};
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        data <= 0;
        rx_done <= 0;
    end 
    else if(c_state == STOP && rx_mid)begin
        data <= data_rg;
        rx_done <= 1;
    end
    else
        rx_done <= 0;
end


endmodule
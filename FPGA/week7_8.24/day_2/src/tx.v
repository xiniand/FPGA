//数据发送器
module tx (
    input           clk     ,
    input           rst_n   ,
    input           tick    ,
    input           tx_star ,
    input  [7:0]    tx_data ,//要发送的数据 
    output          brg_en  ,
    output  reg     tx      ,//发送的数据
    output  reg     tx_done  //发送一组数据完成信号
);
    
localparam  IDLE = 2'b00,//空闲态
            START= 2'b01,//准备数据
            DATA = 2'b10,//发送数据
            STOP = 2'b11;//停止发送
reg [7:0]   data_rg     ,
            n_data_rg   ;
reg [1:0]   c_state     ,
            n_state     ;
reg [3:0]   cnt_bit     ,
            n_cnt_bit   ;
reg         n_tx        ,//锁存待发送数据
            n_tx_done   ;
assign  brg_en = (c_state == IDLE || !rst_n)?0:1;
//状态切换
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE ;
    else
        c_state <= n_state;
end

//状态转移
//说明：tick 为波特率bit脉冲（free-running），起始位与tick对齐，保证各bit长度精确
//IDLE态需等tick才进START，故tx_star需保持至少一个bit周期
always @(*) begin
    n_state     = c_state   ;
    n_tx        = tx        ;// 保持当前输出
    n_tx_done   = 1'b0      ;
    n_cnt_bit   = cnt_bit   ;
    n_data_rg   = data_rg   ;
    case (c_state)
        IDLE    :begin
            n_tx = 1'b1;            //空闲拉高
            if(tx_star)begin
                n_data_rg = tx_data;//锁存待发送数据
                if(tick)begin
                    n_state = START;//与tick对齐，进入起始位
                end
            end
        end 
        START   :begin
            n_tx = 1'b0;            //起始位拉低
            if(tick)begin
                n_state   = DATA;
                n_cnt_bit = 4'd0;
            end
        end 
        DATA    :begin
            n_tx      = data_rg[0]          ;//LSB先发送（当前位保持整个bit周期）
            if(tick)begin
                n_data_rg = {1'b0,data_rg[7:1]} ;//数据右移（仅tick时移一位）
                if(cnt_bit == 4'd7)         //8个数据位已发完
                    n_state = STOP;
                else
                    n_cnt_bit = cnt_bit + 1'b1;
            end
        end 
        STOP    :begin
            n_tx = 1'b1;            //停止位拉高
            if(tick)begin
                n_state   = IDLE;
                n_tx_done = 1'b1;   //发送完成
            end
        end 
        default: begin
            n_state = IDLE;
        end
    endcase
end

//输出寄存（tx/tx_done）
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx      <= 1'b1;
        tx_done <= 1'b0;
    end
    else begin
        tx      <= n_tx;
        tx_done <= n_tx_done;
    end
end

//数据与位计数寄存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_rg <= 8'd0;
        cnt_bit <= 4'd0;
    end
    else begin
        data_rg <= n_data_rg;
        cnt_bit <= n_cnt_bit;
    end
end

endmodule
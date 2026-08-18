//数据发送器
module tx (
    input           clk     ,
    input           rst_n   ,
    input           tick    ,
    input           tx_star ,
    input  [7:0]    tx_data ,//要发送的数据 
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

//状态切换
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE ;
    else
        c_state <= n_state;
end
//状态转移
always @(*) begin
    n_state     = state     ;
    n_tx        = tx        ;// 保持当前输出
    n_tx_done   = 1'b0      ;
    n_cnt_bit   = cnt_bit   ;
    n_data_rg   = data_rg   ;
    case (c_state)
        IDLE    :begin
            n_tx = 1'b1;    //默认起始位拉高
            if(tx_star)begin
                n_state = START;
                n_data_rg= tx_data;//寄存数据
            end
            else
                n_state = IDLE ;
        end 
        START   :begin
            n_tx = 1'b0;//起始位拉低
            if(tick)
                n_state = DATA ;
                n_cnt_bit =3'b0;
            else
                n_state = START;
        end 
        DATA    :begin
            n_tx      = data_rg[0]          ;
            n_data_rg = {1'b0,data_rg[7:1]} ;

        end 
        STOP    :begin

        end 
        default: 
    endcase
end
//输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        n_data_rg <= data_rg;
        
    end
end


endmodule
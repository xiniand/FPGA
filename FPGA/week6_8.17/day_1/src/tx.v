//数据发送器
module tx (
    input           clk     ,
    input           rst_n   ,
    input           tick    ,
    input           tx_star ,//开始发送的信号
    input  [7:0]    tx_data ,//要发送的数据 
    output  reg     tx      ,//发送的数据
    output  reg     tx_done  //发送一组数据完成信号
);
    
localparam  IDLE    = 3'b000,//空闲态
            START   = 3'b001,//准备数据
            SEND    = 3'b010,//发送数据
            PARITY  = 3'b011,//发送校验位
            STOP    = 3'b100;//停止发送
reg         parity_bit  ;
reg [7:0]   data_rg     ;
reg [2:0]   c_state     ,
            n_state     ;
reg [3:0]   cnt_bit     ,
            n_cnt_bit   ;
reg         tx_rg       ,//锁存待发送数据
            tx_done_rg  ;

//状态切换
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE ;
    else
        c_state <= n_state;
end
//状态转移
always @(*) begin
    n_state     = c_state     ;
    n_cnt_bit   = cnt_bit   ;
    case (c_state)
        IDLE    :begin
            if(tx_star)begin
                n_state = START;
                n_cnt_bit= 0;//清零发送的位数计数器
            end
            else
                n_state = IDLE ;
        end 
        START   :begin//一位起始位
            if(tick)begin
                n_state = SEND ;
                n_cnt_bit =0;//清零发送的位数计数器
				end
            else
                n_state = START;
        end 
        SEND    :begin
            if(tick)//八位数据位
                if(n_cnt_bit == 7)
                    n_state = PARITY;
                else begin 
                    n_cnt_bit = cnt_bit + 1;
                    n_state = SEND;
                end 
        end 
        PARITY  :begin//一位校验位
            if(tick)begin
                n_state = STOP;
                n_cnt_bit = 0;
            end 
            else
                n_state = PARITY;
        end
        STOP    :begin//一位停止位
            if(tick)begin
                n_state = IDLE;
                n_cnt_bit = 0;
            end 
            else begin
                n_state = STOP;
            end
        end 
        default: n_state = IDLE;
    endcase
end
//输出

//起始位数据位停止位
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        data_rg     <= 0;
        tx          <= 1;
        tx_done     <= 0;
        parity_bit  <= 0;
    end
    else if(c_state == IDLE)begin
        tx          <= 1;
        tx_done     <= 0;
	 end
    else if(c_state == START && tick)begin
        tx          <= 0    ;
        data_rg     <= tx_data ;//寄存要发送的数据
        parity_bit  <= ^tx_data;
	 end
    else if(c_state == SEND && tick)begin
        tx          <= data_rg[0];
        data_rg     <= {1'b0,data_rg[7:1]};
    end
    else if(c_state == PARITY && tick)begin
        tx          <= parity_bit;
    end
    else if(c_state == STOP && tick)begin
        tx          <= 1;
        tx_done     <= 1;
	 end 
end
//数据与位计数寄存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_bit <= 0;
    end
    else begin
        cnt_bit <= n_cnt_bit;
    end
end
endmodule
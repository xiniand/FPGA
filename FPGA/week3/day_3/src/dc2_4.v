module dc2_4 (
    input               clk         ,
    input               rst         ,
    input               a_1           ,
    input               a_2           ,
    output              a_1_posedge   ,   //上升沿检测
    output              a_1_negedge   ,   //下降沿检测
    output              a_1_n         ,  //双边沿检测
    output              a_2_posedge   ,   //上升沿检测
    output              a_2_negedge   ,   //下降沿检测
    output              a_2_n         ,  //双边沿检测
    output      reg [3:0]   A
/*     output      reg [3:0]   B
    output      reg [3:0]   C */
       
);

reg     a_1_dly     ;   //寄存原始的a_1信号
reg     a_2_dly     ;   //寄存原始的a_2信号
reg     a           ;
reg     b           ;
reg     [1:0]   cnt ;

always @(posedge clk)
    if(rst == 0)begin
        a_1_dly <= 0;
        a_2_dly <= 0;
    end
    else begin
        a_1_dly <= a_1;
        a_2_dly <= a_2;
    end
assign a_1_posedge =  a_1 & ~a_1_dly;
assign a_1_negedge = ~a_1 &  a_1_dly;
assign a_1_n = a_1 ^  a_1_dly;

assign a_2_posedge =  a_2 & ~a_2_dly;
assign a_2_negedge = ~a_2 &  a_2_dly;
assign a_2_n = a_2 ^  a_2_dly;
always @(posedge clk) begin
    if(!rst)
        a <= 0;
    else if(a_1_posedge)
        a <= 1;
    else if(a_1_negedge)
        a <= 0;
end

always @(posedge clk) begin
    if(!rst)
        b <= 0;
    else if (a_2_posedge)
        b <= 1;
    else if (a_2_negedge)
        b <= 0;
end
//上升沿
always @(posedge clk) begin
    if (rst == 0) begin
        A <= 4'b0001;        
    end 
    else 
        case ({a, b})
            2'b00: A <= 4'b0001;   
            2'b01: A <= 4'b0010;   
            2'b10: A <= 4'b0100;   
            2'b11: A <= 4'b1000; 
        endcase
end
//计数器
/* always @(posedge clk) begin
    if(!rst)
        cnt <= 0;
    else if(a_1_posedge)begin
		cnt <= cnt +1;
    end
end
//2_4译码器
always @(posedge clk) begin
    if (rst == 0) begin
        A <= 4'b0001;        
    end 
    else 
        case (cnt)
            2'b00: A <= 4'b0001;   
            2'b01: A <= 4'b0010;   
            2'b10: A <= 4'b0100;   
            2'b11: A <= 4'b1000; 
        endcase
end */


endmodule
/* //下降沿
always @(posedge clk)begin
    if((a_1_negedge == 0) & (a_2_negedge == 0))
        A = 4'b0001;
    else if((a_1_negedge == 0) & (a_2_negedge == 1))
        A = 4'b0010;
    else if((a_1_negedge == 1) & (a_2_negedge == 0))
        A = 4'b0100;
    else if((a_1_negedge == 1) & (a_2_negedge == 1))
        A = 4'b1000;
end
//双边沿
always @(posedge clk)begin
    if((a_1_posedge == 0) & (a_2_n == 0))
        A = 4'b0001;
    else if((a_1_posedge == 0) & (a_2_n == 1))
        A = 4'b0010;
    else if((a_1_posedge == 1) & (a_2_n == 0))
        A = 4'b0100;
    else if((a_1_posedge == 1) & (a_2_n == 1))
        A = 4'b1000;
end */
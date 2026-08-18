module posedge (
    input               clk         ,
    input               rst         ,
    input               a           ,
    output              a_posedge   ,   //上升沿检测
    output              a_negedge   ,   //下降沿检测
    output              a_p_n           //双边沿检测  
);
reg     a_dly   ;   //寄存原始的a信号

always @(posedge clk)
    if(rst == 0)
        a_dly <= 0;
    else
        a_dly <= a;
assign a_posedge = a & ~a_dly;
assign a_negedge = ~a & a_dly;
assign a_p_n = a ^ a_dly;
endmodule


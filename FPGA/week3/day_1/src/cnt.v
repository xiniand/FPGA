module cnt (
    input                   clk         ,   //50MHZ(50000000次)
    input                   rst         ,   //重置系统
    input            [2:0]    sj        ,
    output      reg  [2:0]  cnt              
);


always @(posedge clk)   //当时钟信号的上升沿有效就执行always
    //第一优先级
    if(rst == 0)
        cnt <= 0;
    else if(cnt == sj)
        cnt <= 0;
    else
        cnt <= cnt + 1;
endmodule
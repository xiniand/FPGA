module buzzer_2 (
    input                   clk                 ,
    input                   rst                 ,
    input                   sw2                 ,
    output                  buzzer              
);
parameter       D2  =   42589   ;
reg         [17:0]          cnt_freq            ;   //频率计数器
//频率计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_freq <= 0;
    else if(sw2) 
        if(cnt_freq == D2)
            cnt_freq <= 0;
        else
            cnt_freq <= cnt_freq + 1;
assign buzzer = (cnt_freq < D2 >> 1) ? 0 : 1;
endmodule
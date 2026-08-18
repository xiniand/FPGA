module buzzer_7 (
    input                   clk                 ,
    input                   rst                 ,
    input                   sw7                 ,
    output                  buzzer              
);
parameter       D7  =   25303  ;
reg         [17:0]          cnt_freq            ;   //频率计数器
//频率计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_freq <= 0;
    else if(sw7) 
        if(cnt_freq == D7)
            cnt_freq <= 0;
        else
            cnt_freq <= cnt_freq + 1;
assign buzzer = (cnt_freq < D7 >> 1) ? 0 : 1;
endmodule
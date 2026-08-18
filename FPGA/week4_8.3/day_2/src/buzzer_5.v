module buzzer_5 (
    input                   clk                 ,
    input                   rst                 ,
    input                   sw5                 ,
    output                  buzzer              
);
parameter       D5  =   31887  ;
reg         [17:0]          cnt_freq            ;   //频率计数器
//频率计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_freq <= 0;
    else if(sw5) 
        if(cnt_freq == D5)
            cnt_freq <= 0;
        else
            cnt_freq <= cnt_freq + 1;
assign buzzer = (cnt_freq < D5 >> 1) ? 0 : 1;
endmodule
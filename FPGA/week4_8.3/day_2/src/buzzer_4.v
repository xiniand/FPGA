module buzzer_4 (
    input                   clk                 ,
    input                   rst                 ,
    input                   sw4                 ,
    output                  buzzer              
);
parameter       D4  =   35816  ;
reg         [17:0]          cnt_freq            ;   //频率计数器
//频率计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_freq <= 0;
    else if(sw4) 
        if(cnt_freq == D4)
            cnt_freq <= 0;
        else
            cnt_freq <= cnt_freq + 1;
assign buzzer = (cnt_freq < D4 >> 1) ? 0 : 1;
endmodule
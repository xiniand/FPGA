module buzzer_6 (
    input                   clk                 ,
    input                   rst                 ,
    input                   sw6                 ,
    output                  buzzer              
);
parameter       D6  =   28409  ;
reg         [17:0]          cnt_freq            ;   //频率计数器
//频率计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_freq <= 0;
    else if(sw6)
        if(cnt_freq == D6)
            cnt_freq <= 0;
        else
            cnt_freq <= cnt_freq + 1;
assign buzzer = (cnt_freq < D6 >> 1) ? 0 : 1;
endmodule
module buzzer_1 (
    input                   clk                 ,
    input                   rst                 ,
    input                   sw1                 ,
    output                  buzzer              
);
parameter       D1  =   47801  ;
reg         [17:0]          cnt_freq            ;   //频率计数器
//频率计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_freq <= 0;
    else if(sw1) 
        if(cnt_freq == D1)
            cnt_freq <= 0;
        else
            cnt_freq <= cnt_freq + 1;
assign buzzer = (cnt_freq < D1 >> 1) ? 0 : 1;
endmodule
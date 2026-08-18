module buzzer_3 (
    input                   clk                 ,
    input                   rst                 ,
    input                   sw3                 ,
    output                  buzzer              
);
parameter       D3  =   37936   ;
reg         [17:0]          cnt_freq            ;   //频率计数器
//频率计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_freq <= 0;
    else if(sw3) 
        if(cnt_freq == D3)
            cnt_freq <= 0;
        else
            cnt_freq <= cnt_freq + 1;
assign buzzer = (cnt_freq < D3 >> 1) ? 0 : 1;
endmodule
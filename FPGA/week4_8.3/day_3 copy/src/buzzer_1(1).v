module buzzer_1 (
    input                   clk                 ,
    input                   rst                 ,
    input         [6:0]     sw                  ,
    output                  buzzer              
);
parameter       S1  =   47801   ,
                S2  =   42589   ,
                S3  =   37936   ,
                S4  =   35816   ,
                S5  =   31887   ,
                S6  =   28409   ,
                S7  =   25303   ;
reg     [17:0]  cnt_freq        ;   //频率计数器
reg     [17:0]  freq            ;   //根据开关的值寄存对于的频率
//根据开关的值寄存对于的频率
always @(posedge clk or negedge rst)
    if(rst == 0)
        freq <= 0;
    else
        case (sw)
            7'b1000000:freq <= S1;
            7'b0100000:freq <= S2;
            7'b0010000:freq <= S3;
            7'b0001000:freq <= S4;
            7'b0000100:freq <= S5;
            7'b0000010:freq <= S6;
            7'b0000001:freq <= S7; 
            default:freq <= 0; 
        endcase
//频率计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_freq <= 0;
    else if(cnt_freq == freq)
            cnt_freq <= 0;
        else
            cnt_freq <= cnt_freq + 1;
assign buzzer = (cnt_freq < freq >> 1) ? 0 : 1;
endmodule
module cnt_1 (
    input       clk     ,
    input       rst     ,
    output   reg   led
);
localparam TIME = 24_999_999; 
reg     [24:0]  cnt         ;
always@(posedge clk)
    if(rst == 0)
        cnt <= 0    ;
    else if(cnt==TIME)
        cnt <= 0    ;
    else
        cnt <= cnt+1;
always@(posedge clk)
    if(rst == 0)
        led <= 0    ;
    else if(cnt==TIME)
        led <= ~led  ;
endmodule
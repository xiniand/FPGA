module key_k (
    input   clk     ,
    input   rst     ,
    input   sw      ,
    output  sw_k    
);
    localparam TIME = 100_000_0;
always@(posedge clk)
    if(!rst)
        cnt <= 0;
    else if(sw == 1)
        if(cnt == TIME)
            cnt <= 0;
        else    
            cnt <= cnt + 1 ;
    else
        sw_k <= 0;
always @(posedge clk) begin
    
    
end
endmodule

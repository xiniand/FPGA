module clk (
    input   clk,
    input   rst,
    output  reg     clk_out
);
    
parameter   fp = 124_999_99;//4hz250,000,00分频0.5s
reg     [23:0]  cnt;
//计数
always @(posedge clk) begin
    if(!rst)
        cnt <= 0;
    else if(cnt == fp)
        cnt <= 0;
    else 
        cnt <= cnt + 1;
end
//时钟
always @(posedge clk) begin
    if(!rst)
        clk_out <= 0;
    else if(cnt == fp)
        clk_out <= 1;
    else    
        clk_out <= 0;
end



endmodule
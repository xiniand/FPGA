module fpq_o #(parameter delay = 3)(
    input       rst     ,
    input       clk     ,
    output  reg clk_out 
);
    
reg[3:0]    cnt     ;
//时钟计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt <= 0;
    else if(cnt == delay - 1)
        cnt <= 0;
    else 
        cnt <= cnt + 1;
end
//分频时钟
always @(posedge clk or negedge rst) begin
    if(!rst)
        clk_out <= 0;
    else if(cnt == (delay-1)/2)
        clk_out <= ~clk_out;
    else if(cnt == (delay - 1))
        clk_out <= ~clk_out;
end

endmodule
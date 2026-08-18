module top_fpq (
    input   clk,
    input   rst,
    output reg  clk_fp
);
parameter delay = 2;
reg [1:0]   cnt;
//计数器
always @(posedge clk) begin
    if(!rst)
        cnt <= 0;
    else if(cnt == delay - 1)
        cnt <= 0 ;
    else
        cnt <= cnt + 1;
end
//分频器
always @(posedge clk) begin
    if(!rst)
        clk_fp<=0;
    else if(cnt == delay - 1)
        clk_fp <= ~clk_fp;
end

endmodule
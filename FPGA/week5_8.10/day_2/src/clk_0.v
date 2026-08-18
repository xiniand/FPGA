/* module clk_0 (
    input   clk,
    input   rst,
    output  clk0
);
    
parameter TIME_1 = 24_999_999;
reg [24:0]  cnt_time_1;

always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_time_1<= 0;
    else if(cnt_time_1 == TIME_1)
        cnt_time_1 <= 0;
    else
        cnt_time_1 <= cnt_time_1 + 1;
end
assign  clk0 = (cnt_time_1 == TIME_1);



endmodule */
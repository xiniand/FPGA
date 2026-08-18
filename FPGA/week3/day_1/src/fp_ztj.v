module fp_ztj (
    input       clk,
    input       rst,
    output  reg clk_out
);
    
parameter   TIME = 24_999_999;//2HZ
reg [24:0]  cnt;

always @(posedge clk) begin
    if(!rst)
        cnt <= 0;
    else if(cnt == TIME)
        cnt <= 0;
    else
        cnt <= cnt +1;
end

always @(posedge clk) begin
    if(!rst)
        clk_out <= 0;
    else if(cnt == TIME)
        clk_out <= 1;
    else
        clk_out <= 0;
end

endmodule
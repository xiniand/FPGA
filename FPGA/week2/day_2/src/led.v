module led (
    input               flag,
    input               clk ,
    input               rst ,
    output  reg [3:0]   led
);
/* 
reg     [1:0]    sw_in    
wire    sw_posedge


always @(posedge clk) begin
    if(!rst)
        sw_in   <=  0;
    else 
        sw_in<={sw_in[0],sw};
end

assign  sw_posedge = ~sw_in[1] & sw_in[0] 
*/

always @(posedge clk) begin
    if(!rst)
        led <= 4'b0001;
    else if(flag)
        led <= {led[2:0],led[3]};
    else
        led <= led;
end

endmodule
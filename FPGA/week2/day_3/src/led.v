module led (
    input               clk,
    input               rst,
    input               key,
    output reg [3:0]    led
);

always @(posedge clk) begin
    if(!rst)
        led <= 4'b0001;
    else if(key)
        led <= {led[2:0],led[3]};
    else    
        led <= led;
end

endmodule
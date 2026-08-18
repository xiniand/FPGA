module led (
    input                   rst,
    input                   clk,
    input                   key,
    output  reg     [3:0]   led
);
    


always @(posedge clk) begin
    if(!rst)
        led <= 4'b0000;
    else if(key == 1)
        led <= ~led;
end

endmodule
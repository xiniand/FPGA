module fpq_led (
    input   clk,
    input   rst,
    output  reg [3:0]   led
);
    
reg[24:0]   cnt_1   ;

parameter   delay_1 = 6_250_000;
//led计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_1 <= 0;
    else if(cnt_1 == delay_1)
        cnt_1 <= 0;
    else 
        cnt_1 <= cnt_1 + 1;
end
//led
always @(posedge clk or negedge rst) begin
    if(!rst)
        led <= 4'b0000;
    else if(cnt_1 == delay_1)
        led <= ~led;
end

endmodule
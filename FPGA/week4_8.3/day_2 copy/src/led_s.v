module led_s(
    input  wire      clk  ,
    input  wire      rst_n,
    input wire       en   ,
    output reg  [3:0] led
);

parameter TIME_s = 24_999_999;
reg [24:0] cnt_s;


//led闪烁
always @(posedge clk or negedge rst_n)
    if(!rst_n)begin
        cnt_s <= 24'b0 ;
        led  <= 4'b0000;
    end
    else if(en  == 1)
        if(cnt_s == TIME_s)begin
            cnt_s <= 24'b0;
            led  <= ~led;
        end
        else    
            cnt_s <= cnt_s+1'b1;
endmodule
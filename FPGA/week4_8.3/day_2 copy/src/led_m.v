module led_m(
    input  wire       clk  ,
    input  wire       rst_n,
    input  wire       en   ,
    output reg [3:0]  led
);

parameter TIME_m = 24_999_999;
reg [24:0] cnt_m;

//跑马灯
always @(posedge clk or negedge rst_n)
    if(!rst_n)begin
        cnt_m <= 24'b0;
        led  <= 4'b0001;
    end
    else if(en  == 1)
        if(cnt_m == TIME_m)begin
            cnt_m <= 24'b0;
            led  <= {led [2:0],~led[3]};
         end
        else    
            cnt_m <= cnt_m+1'b1;
endmodule
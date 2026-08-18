module zxd_led (
    input   clk,
    input   rst,
    input   clk_out,
    input   key_right,//11右转，led左往右
    input   key_left,//10左转，led右往左
    input   key_ss,//01双闪，四个led闪
    input   key_iled,//00
    output  reg [3:0]   led

);

reg [1:0] cnt;
//计数器

always @(posedge clk) begin
    if(!rst)
        cnt <= 0;
    else if(key_right)
        cnt <= 2'b11;
    else if(key_left)
        cnt <= 2'b10;
    else if(key_ss)
        cnt <= 2'b01;
    else if(key_iled)
        cnt <= 2'b00;
end 
//led
always @(posedge clk_out) begin
    if(!rst)
        led <= 0;
    else begin
        if(cnt == 00)
            led <= 0;
        else if(cnt == 01)
            led <= ~led;
        else if(cnt == 10)begin
            if(led != 0001)
                led <= 4'b0001;
            else
                led <= {led[2:0],led[3]};
			end
        else if(cnt == 11)begin
            if(led != 1000)
                led <= 4'b1000;
            else
                led <= {led[0],led[3:1]};
			end
    end
end

endmodule
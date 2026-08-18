module led_d (
    input                   clk         ,
    input                   rst         ,
    input                   SW          ,
    output  reg     [3:0]   led         
);
//定义内部信号
reg     [1:0]   sw_in       ;   //对SW进行寄存,得到SW的下降沿
wire            sw_negedge  ;   //SW的下降沿
reg     [2:0]   cnt_1       ;
//开关控制
always@(posedge clk)
    if(rst == 0)
        sw_in <= 0;
    else    
        sw_in <= {sw_in[0],SW};
assign sw_negedge = sw_in[1] & ~sw_in[0];
//控制
always @(posedge clk) begin
    if(rst == 0)
        led <= 4'b0001;
    else if(sw_negedge)
        led <= {led[2:0],~led[3]};
end
/*
always@(posedge clk)
    if(rst == 0)begin
        cnt_1 <= 0;
        led <= 4'b0001;
    end
    else if(sw_negedge) begin
        cnt_1 <= cnt_1 + 1;
        led <= led*(2**cnt_1)-1;
    end
*/
/* always@(posedge clk)
    if(rst == 0)
        cnt_1 <= 0;
    else if(sw_negedge) 
        cnt_1 <= cnt_1 + 1;
//led灯
always@(posedge clk)
    if(rst == 0)
        led <= 0;
    else begin
        case (cnt_1)
            3'b000: led <= 4'b0001;
            3'b001: led <= 4'b0011;
            3'b010: led <= 4'b0111;
            3'b011: led <= 4'b1111;
            3'b100: led <= 4'b1110;
            3'b101: led <= 4'b1100;
            3'b110: led <= 4'b1000;
            3'b111: led <= 4'b0000;
        endcase
    end */
endmodule
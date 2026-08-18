module water (
    input                   clk     ,
    input                   rst     ,
    input                   sw      ,
    output  reg     [3:0]   led   
);
localparam  TIME =24_999_999;

reg     [24:0]  cnt;
reg     [1:0]   cnt_1;
reg             sw_in;
wire            sw_posedge;
reg             led_en;
//流水灯
always@(posedge clk)
    if(!rst == 0)
        cnt <= 0;
    else if(led_en)begin
        if(cnt == TIME)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end
always@(posedge clk)
    if(!rst == 0)
        cnt_1 <= 0;
    else if(led_en) begin 
        if(cnt == TIME )begin
            if(cnt_1 == 2'b11)
                cnt_1 <= 0;
            else
                cnt_1 <= cnt_1 + 1;
        end
    end
always@(posedge clk)
    if(!rst == 0)
        led <= 0;
    else begin
        case (cnt_1)
        2'b00: led <= 4'b0001;
        2'b01: led <= 4'b0010;
        2'b10: led <= 4'b0100;
        2'b11: led <= 4'b1000;
        endcase
    end
//开关控制暂停
always@(posedge clk)
    if(!rst == 0)
        sw_in <= 0;
    else
        sw_in <= sw;
assign sw_posedge = ~sw_in & sw;

always@(posedge clk)
    if(!rst == 0)
        led_en <=0;
    else if(sw_posedge)
        led_en <= ~led_en;

endmodule
module smg (
    input               rst ,
    input               clk ,
    output reg [7:0]    dig ,
    output  [5:0]    sel
);
/* parameter delay = 49_999; */
/* parameter TIME  = 499_999; */

parameter   TIME = 24_999_999;

assign  sel = 6'b000_000;

reg[24:0]   cnt_time;
reg[3:0]    data_num    ;
wire[3:0]   data;
//闪烁计数器
/* reg [4:0]   bcd_sel;
reg [15:0]  cnt_delay   ; */


always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_time<= 0;
    else if(cnt_time == TIME)
        cnt_time <= 0;
    else
        cnt_time <= cnt_time + 1;
end

always @(posedge clk or negedge rst) begin
    if(!rst)
        data_num<= 0;
    else if(cnt_time == TIME)begin
        if(data_num == 9)
            data_num <= 0;
        else
            data_num <= data_num + 1;
    end
end

always @(*) begin
    case (data)
          0: dig = 8'b1100_0000;//0
          1: dig = 8'b1111_1001;//1
          2: dig = 8'b1010_0100;//2
          3: dig = 8'b1011_0000;//3
          4: dig = 8'b1001_1001;//4
          5: dig = 8'b1001_0010;//5
          6: dig = 8'b1000_0010;//6
          7: dig = 8'b1111_1000;//7
          8: dig = 8'b1000_0000;//8
          9: dig = 8'b1001_0000;//9
        'hA: dig = 8'b1000_1000;
        'hB: dig = 8'b1000_0011; 
        'hC: dig = 8'b1100_0110; 
        'hD: dig = 8'b1010_0001; 
        'hE: dig = 8'b1000_0110; 
        'hF: dig = 8'b1000_1110; 
        default: dig = 8'b1100_0000;//0
    endcase
end
rom_data	rom_data_inst (
	.address    (data_num   ),
	.clock      (clk        ),
	.q          (data       )
);
endmodule
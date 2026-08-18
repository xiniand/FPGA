module ziyima3_8 (
    input               rst ,
    input               clk ,
    input      [1:0]    sw  ,
    output reg [6:0]    dig ,
    output  [5:0]       sel
);
    
parameter TIME = 50_000_000;
reg [3:0]   cnt_num     ;

assign  sel = 6'b000_000;

always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_num <= 0;
    else if(sw[1])                     
        cnt_num <= (cnt_num == 9) ? 0 : cnt_num + 1;
    else if(sw[0])                    
        cnt_num <= (cnt_num == 0) ? 9 : cnt_num - 1;
end

always @(posedge clk or negedge rst) begin
    case (cnt_num)
        4'b0000:  dig = 7'b100_0000;//0    
        4'b0001:  dig = 7'b111_1001;//1
        4'b0010:  dig = 7'b010_0100;//2
        4'b0011:  dig = 7'b011_0000;//3
        4'b0100:  dig = 7'b001_1001;//4
        4'b0101:  dig = 7'b001_0010;//5
        4'b0110:  dig = 7'b000_0010;//6
        4'b0111:  dig = 7'b111_1000;//7
        4'b1000:  dig = 7'b000_0000;//8
        4'b1001:  dig = 7'b001_0000;//9
        default:  dig = 7'b100_0000;//0
    endcase
end
endmodule
/* reg [25:0]  cnt_time    ;
wire        add_cnt_time,
            end_cnt_time; */
/* wire        add_cnt_num ,
            end_cnt_num ;
wire        add_cnt_nu ,
            end_cnt_nu ;
reg         en; */
//0.5s计数器
/* always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_time <= 0;
    else if(add_cnt_time)begin
        if(end_cnt_time)
            cnt_time <= 0;
        else
            cnt_time <= cnt_time + 1;
    end
end
assign  add_cnt_time = 1;
assign  end_cnt_time = add_cnt_time &&(cnt_time == TIME); */
//数字计数器
/* always @(posedge clk or negedge rst) begin
    if(!rst)
        en <= 0;
    else if(cnt_num == 0)
        en <= 0;
    else if(cnt_num == 9)
        en <= 1;
end */
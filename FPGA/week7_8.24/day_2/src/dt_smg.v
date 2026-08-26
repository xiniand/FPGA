module dt_smg (
    input               rst ,
    input               clk ,
    input      [23:0]   data,
    output reg [7:0]    dig ,
    output reg [5:0]    sel
);
parameter delay = 49_999;

reg [4:0]   bcd_sel;
reg [15:0]  cnt_delay   ;

wire [4:0]  bcd0                , 
            bcd1                ,
            bcd2                ,
            bcd4                ,
            bcd5                ;
wire [4:0]  bcd3                ;   
assign  bcd0 = data[3:0]        ;
assign  bcd1 = data[7:4]        ;
assign  bcd2 = data[11:8]       ;
assign  bcd3 = data[15:12]      ;
assign  bcd4 = data[19:16]      ;
assign  bcd5 = data[23:20]      ;

//5ms计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_delay <= 0;
    else if(cnt_delay == delay)
        cnt_delay <= 0;
    else
        cnt_delay <= cnt_delay + 1  ;
//sel变化模块
always @(posedge clk or negedge rst) begin
    if(!rst)
        sel <= 6'b111110            ;
    else if(cnt_delay == delay)
        sel <= {sel[4:0],sel[5]}    ;
end
//位数选择器
always @(*) begin
    case (sel)
        6'b111110: bcd_sel = bcd0       ;
        6'b111101: bcd_sel = bcd1       ;
        6'b111011: bcd_sel = bcd2       ;
        6'b110111: bcd_sel = bcd3  +10  ;
        6'b101111: bcd_sel = bcd4       ;
        6'b011111: bcd_sel = bcd5       ;
        default:   bcd_sel = 0          ;
    endcase
end
//数字选择器
always @(*) begin
    case (bcd_sel)
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
        10: dig = 8'b0100_0000;//0.
        11: dig = 8'b0111_1001;//1.
        12: dig = 8'b0010_0100;//2.
        13: dig = 8'b0011_0000;//3.
        14: dig = 8'b0001_1001;//4.
        15: dig = 8'b0001_0010;//5.
        16: dig = 8'b0000_0010;//6.
        17: dig = 8'b0111_1000;//7.
        18: dig = 8'b0000_0000;//8.
        19: dig = 8'b0001_0000;//9.
        default: dig = 8'b1100_0000;//0
    endcase
end
endmodule

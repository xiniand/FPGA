module dt_smg (
    input               rst     ,
    input               clk     ,
    input       [3:0]   bcd0    ,
    input       [3:0]   bcd1    ,
    input       [3:0]   bcd2    ,
    input       [3:0]   bcd3    ,
    input       [3:0]   bcd4    ,
    input       [3:0]   bcd5    ,
    output  reg [7:0]   dig     ,
    output  reg [5:0]   sel
);
//数码管动态扫描显示：接收 6 位 BCD 值，循环点亮对应位
//BCD 值为 15(0xf) 时显示空白
parameter delay = 49_999;   //扫描一位 5ms（50MHz）

reg [4:0]   bcd_sel ;
reg [15:0]  cnt_delay;

//5ms 分频计数
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_delay <= 0;
    else if(cnt_delay == delay)
        cnt_delay <= 0;
    else
        cnt_delay <= cnt_delay + 1;

//位选环形移位
always @(posedge clk or negedge rst) begin
    if(!rst)
        sel <= 6'b111110;
    else if(cnt_delay == delay)
        sel <= {sel[4:0], sel[5]};
end

//位数选择器
always @(*) begin
    case (sel)
        6'b111110: bcd_sel = bcd0;
        6'b111101: bcd_sel = bcd1;
        6'b111011: bcd_sel = bcd2;
        6'b110111: bcd_sel = bcd3;
        6'b101111: bcd_sel = bcd4;
        6'b011111: bcd_sel = bcd5;
        default:   bcd_sel = bcd0;
    endcase
end

//数字选择器（共阳极数码管，低电平点亮）
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
        default: dig = 8'b1111_1111;//空白
    endcase
end

endmodule

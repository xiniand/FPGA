module dt_smg (
    input               rst ,
    input               clk ,
    input      [7:0]    data,
    output reg [7:0]    dig ,
    output reg [5:0]    sel
);
parameter delay = 49_999;

reg [4:0]   bcd_sel;
reg [15:0]  cnt_delay   ;

wire [4:0]  bcd0, bcd1;
assign  bcd0 = data[3:0]            ;
assign  bcd1 = data[7:4]            ;

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
        6'b111110: bcd_sel = bcd0   ;
        6'b111101: bcd_sel = bcd1   ;
        default:   bcd_sel = 0      ;
    endcase
end
//数字选择器
always @(*) begin
    case (bcd_sel)
          0: dig = 8'b1100_0000     ;//0
          1: dig = 8'b1111_1001     ;//1
          2: dig = 8'b1010_0100     ;//2
          3: dig = 8'b1011_0000     ;//3
          4: dig = 8'b1001_1001     ;//4
          5: dig = 8'b1001_0010     ;//5
          6: dig = 8'b1000_0010     ;//6
          7: dig = 8'b1111_1000     ;//7
          8: dig = 8'b1000_0000     ;//8
          9: dig = 8'b1001_0000     ;//9
        'hA: dig = 8'b1000_1000     ;
        'hB: dig = 8'b1000_0011     ; 
        'hC: dig = 8'b1100_0110     ; 
        'hD: dig = 8'b1010_0001     ; 
        'hE: dig = 8'b1000_0110     ; 
        'hF: dig = 8'b1000_1110     ; 
        default: dig = 8'b1100_0000 ;//0
    endcase
end
endmodule

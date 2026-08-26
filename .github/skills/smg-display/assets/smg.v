// ============================================================
// 6 位数码管动态扫描显示
// 接口: clk(50MHz), rst_n, data(6个BCD位/每4位一数字, 可含小数点偏移),
//       dig(8位段码), sel(6位位选,低有效)
// 扫描: 每位约1ms, 6位轮流点亮, 视觉暂留
// 小数: data的某一位BCD若+10(如bcd3+10), 则显示"该数字带小数点"
// ============================================================
module smg (
    input               clk   ,
    input               rst   ,
    input      [23:0]   data  ,   // 6位数据, data[3:0]=一位(低位), 依此类推
    output reg [7:0]    dig   ,   // 段码(共阳,低电平点亮)
    output reg [5:0]    sel     // 位选(低有效)
);

// 扫描分频: 50MHz/50_000 = 1kHz => 每位1ms
parameter delay = 49_999;

reg [4:0]   bcd_sel;
reg [15:0]  cnt_delay;

// 6位BCD(每4位一位数字)
wire [4:0] bcd0 = data[3:0];
wire [4:0] bcd1 = data[7:4];
wire [4:0] bcd2 = data[11:8];
wire [4:0] bcd3 = data[15:12];
wire [4:0] bcd4 = data[19:16];
wire [4:0] bcd5 = data[23:20];

// ---- 位选刷新计数 (1ms) ----
always @(posedge clk or negedge rst)
    if(!rst) cnt_delay <= 0;
    else if(cnt_delay == delay) cnt_delay <= 0;
    else cnt_delay <= cnt_delay + 1;

// ---- 位选循环左移 (低有效) ----
always @(posedge clk or negedge rst) begin
    if(!rst) sel <= 6'b111110;
    else if(cnt_delay == delay) sel <= {sel[4:0], sel[5]};
end

// ---- 当前位对应的数据 ----
always @(*) begin
    case(sel)
        6'b111110: bcd_sel = bcd0;
        6'b111101: bcd_sel = bcd1;
        6'b111011: bcd_sel = bcd2;
        6'b110111: bcd_sel = bcd3 + 10;   // 给bcd3位加10 => 显示带小数点
        6'b101111: bcd_sel = bcd4;
        6'b011111: bcd_sel = bcd5;
        default:   bcd_sel = 0;
    endcase
end

// ---- 7段码表 (共阳, 低电平点亮; 13~19为带小数点的0~9) ----
always @(*) begin
    case(bcd_sel)
         0: dig = 8'b1100_0000;   // 0
         1: dig = 8'b1111_1001;   // 1
         2: dig = 8'b1010_0100;   // 2
         3: dig = 8'b1011_0000;   // 3
         4: dig = 8'b1001_1001;   // 4
         5: dig = 8'b1001_0010;   // 5
         6: dig = 8'b1000_0010;   // 6
         7: dig = 8'b1111_1000;   // 7
         8: dig = 8'b1000_0000;   // 8
         9: dig = 8'b1001_0000;   // 9
        10: dig = 8'b0100_0000;   // 0.
        11: dig = 8'b0111_1001;   // 1.
        12: dig = 8'b0010_0100;   // 2.
        13: dig = 8'b0011_0000;   // 3.
        14: dig = 8'b0001_1001;   // 4.
        15: dig = 8'b0001_0010;   // 5.
        16: dig = 8'b0000_0010;   // 6.
        17: dig = 8'b0111_1000;   // 7.
        18: dig = 8'b0000_0000;   // 8.
        19: dig = 8'b0001_0000;   // 9.
        default: dig = 8'b1100_0000;   // 0
    endcase
end
endmodule

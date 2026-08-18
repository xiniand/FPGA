// ****************************************************************************
// 数码管驱动模块 seg_driver
// 功能：4位7段数码管动态扫描显示，刷新频率1kHz
// 显示内容：
//   物理排列  S1(SEL0) S2(SEL1) S3(SEL2) S4(SEL3)
//   显示内容  NS十位    NS个位    EW十位    EW个位
// 段码/位选：共阳极（低有效），适配 AWC_C4 DVK 开发板
// ****************************************************************************

module seg_driver (
    input  wire        clk_1khz ,
    input  wire        rst_n    ,
    input  wire [5:0]  time_ns  ,   // NS 倒计时 (0~59)
    input  wire [5:0]  time_ew  ,   // EW 倒计时 (0~59)
    output reg  [7:0]  seg      ,   // 段码 {dp,g,f,e,d,c,b,a}（低有效）
    output reg  [3:0]  dig          // 位选 {SEL3,SEL2,SEL1,SEL0}（低有效）
);

    // ================================================================
    // 扫描计数器 (0~3)，1kHz 刷新
    // ================================================================
    reg [1:0] scan_cnt;
    always @(posedge clk_1khz or negedge rst_n) begin
        if (!rst_n) scan_cnt <= 0;
        else        scan_cnt <= scan_cnt + 2'd1;
    end

    // ================================================================
    // 数码管数据分离：将 0~59 的值拆分为十位 BCD 和个位 BCD
    // 用 if-else + 减法，仅综合出比较器和减法器
    // ================================================================
    wire [3:0] ns_tens, ns_ones, ew_tens, ew_ones;

    assign {ns_tens, ns_ones} = (time_ns >= 6'd50) ? {4'd5, time_ns - 6'd50} :
                                (time_ns >= 6'd40) ? {4'd4, time_ns - 6'd40} :
                                (time_ns >= 6'd30) ? {4'd3, time_ns - 6'd30} :
                                (time_ns >= 6'd20) ? {4'd2, time_ns - 6'd20} :
                                (time_ns >= 6'd10) ? {4'd1, time_ns - 6'd10} :
                                                     {4'd0, time_ns[3:0]};

    assign {ew_tens, ew_ones} = (time_ew >= 6'd50) ? {4'd5, time_ew - 6'd50} :
                                (time_ew >= 6'd40) ? {4'd4, time_ew - 6'd40} :
                                (time_ew >= 6'd30) ? {4'd3, time_ew - 6'd30} :
                                (time_ew >= 6'd20) ? {4'd2, time_ew - 6'd20} :
                                (time_ew >= 6'd10) ? {4'd1, time_ew - 6'd10} :
                                                     {4'd0, time_ew[3:0]};

    // ================================================================
    // 动态扫描：根据 scan_cnt 选择当前显示的数码管及其数据
    // 物理布局（左→右）：S1(SEL0) S2(SEL1) S3(SEL2) S4(SEL3)
    // 显示内容（左→右）：NS十位    NS个位    EW十位    EW个位
    // 共阳极：位选低有效，即 dig[x]=0 时该位点亮
    // ================================================================
    reg [3:0] bcd_data;

    always @(*) begin
        case (scan_cnt)
            2'd0: begin dig = 4'b1110; bcd_data = ns_tens; end  // S1 ← NS十位
            2'd1: begin dig = 4'b1101; bcd_data = ns_ones; end  // S2 ← NS个位
            2'd2: begin dig = 4'b1011; bcd_data = ew_tens; end  // S3 ← EW十位
            2'd3: begin dig = 4'b0111; bcd_data = ew_ones; end  // S4 ← EW个位
        endcase
    end

    // ================================================================
    // BCD→7段码译码（共阳极，低有效）
    // seg = {dp, g, f, e, d, c, b, a}
    // ================================================================
    always @(*) begin
        case (bcd_data)
            4'd0: seg = 8'b1100_0000;
            4'd1: seg = 8'b1111_1001;
            4'd2: seg = 8'b1010_0100;
            4'd3: seg = 8'b1011_0000;
            4'd4: seg = 8'b1001_1001;
            4'd5: seg = 8'b1001_0010;
            4'd6: seg = 8'b1000_0010;
            4'd7: seg = 8'b1111_1000;
            4'd8: seg = 8'b1000_0000;
            4'd9: seg = 8'b1001_0000;
            default: seg = 8'b1111_1111;
        endcase
    end

endmodule

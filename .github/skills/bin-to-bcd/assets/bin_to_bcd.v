// ============================================================
// 二进制 -> 8421 BCD 转换
// 双 dabble(加3移位)算法, 阻塞赋值, 时钟内一段式, 可直接综合。
//
// 整数(+小数放大): 输入 8 位整数 -> 输出 3 个 BCD 位(12位)
//                 输入14位(如小数*625放大) -> 输出 5 个 BCD 位(20位)
// 说明:
//   - repeat(T) 次数 = 二进制位数 T
//   - 移位前对每个 BCD 位 >=5 则 +3
//   - 必须用阻塞赋值 '=', 否则非阻塞会造成每轮读旧值、只移位一次而算错
// ============================================================
module bin_to_bcd (
    input               clk      ,
    input               rst_n    ,
    input      [7:0]    data_zs_in,   // 整数部分(二进制)
    input      [13:0]   data_xs_in,   // 小数部分(放大后, 二进制)
    output reg [11:0]   data_bcd_zs,  // 整数 BCD(3 位: 百/十/个)
    output reg [11:0]   data_bcd_xs   // 小数 BCD(低位3~4位)
);

// 内部工作寄存器: 高位预留 BCD 位, 低位放二进制
reg [19:0] work_zs;     // 8位二进制 + 3个BCD位(12) + 余量
reg [29:0] work_xs;     // 14位二进制 + 4~5个BCD位(16~20) + 余量

// ------------------------------------------------------------
// 整数转换: 8 位 -> 3 个 BCD 位, 移 8 次
// ------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        work_zs <= 20'd0;
    end
    else begin
        work_zs = {12'b0, data_zs_in};          // BCD 位放高位, 二进制在低 8 位
        repeat(8) begin                          // 8 位二进制, 移 8 次
            // 逐个 BCD 位判断 >=5 加 3 (这里预留 3 个 BCD 位: 12/16/19~)
            if(work_zs[11:8]  >= 4'd5) work_zs[11:8]  = work_zs[11:8]  + 4'd3;
            if(work_zs[15:12] >= 4'd5) work_zs[15:12] = work_zs[15:12] + 4'd3;
            if(work_zs[19:16] >= 4'd5) work_zs[19:16] = work_zs[19:16] + 4'd3;
            work_zs = work_zs << 1;              // 左移一位
        end
    end
end

// ------------------------------------------------------------
// 小数转换: 14 位 -> 4~5 个 BCD 位, 移 14 次
// ------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        work_xs <= 30'd0;
    end
    else begin
        work_xs = {16'b0, data_xs_in};          // BCD 位放高位, 二进制在低 14 位
        repeat(14) begin                         // 14 位二进制, 移 14 次
            if(work_xs[17:14] >= 4'd5) work_xs[17:14] = work_xs[17:14] + 4'd3;
            if(work_xs[21:18] >= 4'd5) work_xs[21:18] = work_xs[21:18] + 4'd3;
            if(work_xs[25:22] >= 4'd5) work_xs[25:22] = work_xs[25:22] + 4'd3;
            if(work_xs[29:26] >= 4'd5) work_xs[29:26] = work_xs[29:26] + 4'd3;
            work_xs = work_xs << 1;
        end
    end
end

// ------------------------------------------------------------
// 输出 BCD: 取高位的 BCD 部分
// ------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_bcd_zs <= 12'd0;
        data_bcd_xs <= 12'd0;
    end
    else begin
        data_bcd_zs <= work_zs[19:8];    // 3 个 BCD 位(百/十/个)
        data_bcd_xs <= work_xs[29:18];   // 低位数 BCD
    end
end

endmodule

`timescale 1ns/1ns
//================================================================
// 乒乓缓存 pp_fifo 模块的 testbench
//
// 验证思路:
//   1. 复位后持续写入递增数据(0,1,2,... 8bit回绕), 同时持续读出
//   2. 乒乓缓存先写满 fifo_a(256个) 再切换写入 fifo_b,
//      同时从 fifo_a 读出, 实现读写并行、数据连续
//   3. 用期望计数器逐字节比对读出数据, 统计错误
//   4. 统计乒乓切换次数, 验证确实发生了乒乓切换
//================================================================
module test_pp_fifo;
reg         clk         ;
reg         rst_n       ;
wire [7:0]  data_in     ;
reg         wr_en       ;
reg         rd_en       ;
wire [7:0]  data_out    ;
wire        rd_valid    ;
wire        wr_full     ;
wire        rd_empty    ;
wire        ping_pong   ;
wire        full_a      ;
wire        full_b      ;
wire        empty_a     ;
wire        empty_b     ;

reg  [7:0]  wr_cnt      ;//写入的数据(递增, 8bit回绕)
reg  [7:0]  exp_cnt     ;//期望读出的数据
reg         ping_pong_r ;//ping_pong打拍, 用于检测切换边沿
integer     err_cnt     ;//数据错误计数
integer     rd_num      ;//读出数据个数
integer     sw_num      ;//乒乓切换次数

//待测模块
pp_fifo pp_fifo_u(
    .clk        (clk       ),
    .rst_n      (rst_n     ),
    .data_in    (data_in   ),
    .wr_en      (wr_en     ),
    .rd_en      (rd_en     ),
    .data_out   (data_out  ),
    .rd_valid   (rd_valid  ),
    .wr_full    (wr_full   ),
    .rd_empty   (rd_empty  ),
    .ping_pong  (ping_pong ),
    .full_a     (full_a    ),
    .full_b     (full_b    ),
    .empty_a    (empty_a   ),
    .empty_b    (empty_b   )
);

//50MHz时钟
initial clk = 0;
always #10 clk = ~clk;

//主测试流程
initial begin
    rst_n   = 0;
    wr_en   = 0;
    rd_en   = 0;
    #100;
    rst_n   = 1;
    #20;
    //连续写入+读出, 读满512个数据(跨2个fifo)后停止
    wr_en = 1;
    rd_en = 1;
    wait(rd_num >= 512);
    #100;
    wr_en = 0;
    rd_en = 0;
    #1000;
    $display("========================================");
    $display("乒乓缓存仿真结束");
    $display("写入数据个数 : %0d", wr_cnt);
    $display("读出数据个数 : %0d", rd_num);
    $display("乒乓切换次数 : %0d", sw_num);
    $display("数据错误个数 : %0d", err_cnt);
    if(err_cnt == 0 && rd_num >= 512)
        $display(">>> 仿真通过: 乒乓缓存读写数据完全一致 <<<");
    else
        $display(">>> 仿真失败 <<<");
    $stop;
end

//写入数据计数(递增, 8bit回绕)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_cnt <= 0;
    else if(wr_en)
        wr_cnt <= wr_cnt + 1;
end
assign data_in = wr_cnt;

//读出数据校验
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exp_cnt <= 0;
        err_cnt <= 0;
        rd_num  <= 0;
    end
    else if(rd_valid) begin
        if(data_out != exp_cnt) begin
            err_cnt <= err_cnt + 1;
            $display("时间%0t: 数据错误! 期望=%0d 实际=%0d",
                     $time, exp_cnt, data_out);
        end
        exp_cnt <= exp_cnt + 1;
        rd_num  <= rd_num + 1;
    end
end

//乒乓切换次数统计
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ping_pong_r <= 0;
        sw_num      <= 0;
    end
    else begin
        ping_pong_r <= ping_pong;
        if(ping_pong != ping_pong_r)
            sw_num <= sw_num + 1;
    end
end
endmodule

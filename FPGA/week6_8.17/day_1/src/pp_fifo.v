//================================================================
// 乒乓缓存模块 pp_fifo
//
// 说明:
//   例化两个 fifo_data(256x8, FIFO IP核) 组成乒乓缓存。
//   ping_pong=0 时: 数据写入 fifo_a, 同时从 fifo_b 读出
//   ping_pong=1 时: 数据写入 fifo_b, 同时从 fifo_a 读出
//   当当前写入的 fifo 写满时, 乒乓方向自动切换,
//   从而实现读写并行、数据连续无间断地输入输出。
//
// 端口:
//   data_in   写入数据
//   wr_en     写使能当前写fifo满时内部自动屏蔽, 防止溢出
//   rd_en     读使能当前读fifo空时内部自动屏蔽, 防止读空
//   data_out  读出的数据
//   rd_valid  读有效, 此周期 data_out 有效
//   wr_full   当前写入的 fifo 满
//   rd_empty  当前读出的 fifo 空
//   ping_pong 乒乓切换标志(0: 写A读B, 1: 写B读A)
//   full_a/full_b/empty_a/empty_b 两个fifo的满空状态(便于观察)
//================================================================
module pp_fifo (
    input           clk         ,
    input           rst_n       ,
    input   [7:0]   data_in     ,
    input           wr_en       ,
    input           rd_en       ,
    output  [7:0]   data_out    ,
    output          rd_valid    ,
    output          wr_full     ,
    output          rd_empty    ,
    output          ping_pong   ,
    output          full_a      ,
    output          full_b      ,
    output          empty_a     ,
    output          empty_b
);
reg             flag            ;//乒乓切换标志
reg             rd_valid_r      ;//读有效打拍(与data_out对齐)
reg  [7:0]      data_out_r      ;//读出数据打拍(与rd_valid对齐)
wire [7:0]      q_a             ,
                q_b             ;
wire [7:0]      usedw_a         ,
                usedw_b         ;
wire            wrreq_a         ,
                wrreq_b         ,
                rdreq_a         ,
                rdreq_b         ;
wire            need_switch     ;

//写侧: 根据flag选择写入的fifo, 满则不写(防止溢出)
assign  wrreq_a = wr_en & ~flag & ~full_a ;
assign  wrreq_b = wr_en &  flag & ~full_b ;
//读侧: 根据flag选择读出的fifo(读写方向相反), 空则不读(防止读空)
assign  rdreq_a = rd_en &  flag & ~empty_a;
assign  rdreq_b = rd_en & ~flag & ~empty_b;
//scfifo为non-showahead模式: rdreq有效后一拍q才输出有效数据,
//故data_out与rd_valid同步打一拍, 保证rd_valid=1时data_out有效
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_valid_r <= 0;
        data_out_r <= 0;
    end
    else begin
        rd_valid_r <= rdreq_a | rdreq_b;
        data_out_r  <= flag ? q_a : q_b;//flag=0读B选q_b, flag=1读A选q_a
    end
end
assign  rd_valid = rd_valid_r;
assign  data_out = data_out_r;
//乒乓切换: 当前写入的fifo写满时切换
assign  need_switch = flag ? full_b : full_a;
//当前写fifo满 / 当前读fifo空 (供外部使用)
assign  wr_full   = flag ? full_b  : full_a ;
assign  rd_empty  = flag ? empty_a : empty_b;
assign  ping_pong = flag;

//乒乓切换控制
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        flag <= 0;
    else if(need_switch)
        flag <= ~flag;
end

//fifo_a
fifo_data fifo_data_a_inst (
    .aclr           ( ~rst_n        ),
    .clock          ( clk           ),
    .data           ( data_in       ),
    .rdreq          ( rdreq_a       ),
    .wrreq          ( wrreq_a       ),
    .almost_full    (               ),
    .empty          ( empty_a       ),
    .full           ( full_a        ),
    .q              ( q_a           ),
    .usedw          ( usedw_a       )
);
//fifo_b
fifo_data fifo_data_b_inst (
    .aclr           ( ~rst_n        ),
    .clock          ( clk           ),
    .data           ( data_in       ),
    .rdreq          ( rdreq_b       ),
    .wrreq          ( wrreq_b       ),
    .almost_full    (               ),
    .empty          ( empty_b       ),
    .full           ( full_b        ),
    .q              ( q_b           ),
    .usedw          ( usedw_b       )
);
endmodule

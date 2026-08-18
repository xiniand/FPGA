`timescale 1ns/1ns
//================================================================
// 单 fifo_data IP 读写时序实验
// 写入 0,1,2 后读出, 观察 rdreq/empty/q 的关系, 确认 scfifo 读时序
//================================================================
module test_fifo_single;
reg         clk  ;
reg         rst_n;
reg         wrreq;
reg         rdreq;
reg  [7:0]  data ;
wire [7:0]  q    ;
wire        empty;
wire        full ;
wire [7:0]  usedw;

fifo_data fifo_data_inst(
    .aclr       (~rst_n ),
    .clock      (clk    ),
    .data       (data   ),
    .rdreq      (rdreq  ),
    .wrreq      (wrreq  ),
    .almost_full(),
    .empty      (empty  ),
    .full       (full   ),
    .q          (q      ),
    .usedw      (usedw  )
);

always #10 clk = ~clk;

initial begin
    clk=0; rst_n=0; wrreq=0; rdreq=0; data=0;
    #100; rst_n=1;
    //写 0,1,2
    @(posedge clk); wrreq=1; data=0;
    @(posedge clk); data=1;
    @(posedge clk); data=2;
    @(posedge clk); wrreq=0;
    $display("写完3个: usedw=%0d empty=%b full=%b q=%0d", usedw, empty, full, q);
    //读 3 个, 每拍打印
    @(posedge clk); rdreq=1;
    #10; $display("T1 rdreq=%b empty=%b q=%0d usedw=%0d", rdreq, empty, q, usedw);
    @(posedge clk);
    #10; $display("T2 rdreq=%b empty=%b q=%0d usedw=%0d", rdreq, empty, q, usedw);
    @(posedge clk);
    #10; $display("T3 rdreq=%b empty=%b q=%0d usedw=%0d", rdreq, empty, q, usedw);
    @(posedge clk);
    #10; $display("T4 rdreq=%b empty=%b q=%0d usedw=%0d", rdreq, empty, q, usedw);
    rdreq=0;
    $stop;
end
endmodule

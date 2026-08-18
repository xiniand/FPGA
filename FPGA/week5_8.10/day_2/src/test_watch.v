/* `timescale 1ns/1ns
module test_watch;
reg                      clk;
reg                      rst;
reg                      key;
wire    [5:0]            sel;
wire    [7:0]            seg;
always #10 clk = ~clk;

initial begin
    clk = 0;
    rst = 0;
    key = 1;
    #20
    rst = 1;
    #20
    key = 0;
    #3000
    key = 1;
    #3000
    key = 0;
    #3000
    key = 1;
    #3000
    key = 0;
    #3000
    key = 1;
    #3000
    key = 0;
    #3000
    key = 1;
    #3000
    key = 0;
    #3000
    key = 1;
    #3000
    key = 0;
    #3000
    $stop;
end

watch_top #(
    .TIME           (99),
    .TIME_SMG       (9)
) watch_top(
    .clk         (clk),
    .rst         (rst),
    .key         (key),
    .sel         (sel),   //位选
    .seg         (seg)    //段选
);
endmodule */

`timescale 1ns/1ns
module test_watch;
reg                      clk;
reg                      rst;
wire    [5:0]            sel;
wire    [7:0]            seg;
always #10 clk = ~clk;

initial begin
    clk = 0;
    rst = 0;
    #20
    rst = 1;
    #6000
    $stop;
end

smg_watch #(
    .TIME       (24)
) smg_watch_inst(
    .clk     (clk),
    .rst     (rst),
    .sel     (sel),   //位选
    .seg     (seg)    //段选
);
endmodule

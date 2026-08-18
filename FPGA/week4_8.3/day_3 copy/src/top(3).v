module top (
    input                       clk     ,
    input                       rst     ,
    input                       key_1   ,   //控制加
    input                       key_2   ,   //控制减
    output          [5:0]       sel     ,   //位选
    output          [6:0]       seg         //段选
);
wire    [1:0]   key_out     ;
key key_inst1(
    .clk         (clk),
    .rst         (rst),
    .key         (key_1),   //未消抖按键信号
    .key_out     (key_out[0])    //已消抖按键信号
);
key key_inst2(
    .clk         (clk),
    .rst         (rst),
    .key         (key_2),   //未消抖按键信号
    .key_out     (key_out[1])    //已消抖按键信号
);
smg_7_0 smg_7_0_inst(
    .clk         (clk),
    .rst         (rst),
    .key_1       (key_out[0]),   //控制加
    .key_2       (key_out[1]),   //控制减
    .sel         (sel),   //位选
    .seg         (seg)    //段选
);
endmodule
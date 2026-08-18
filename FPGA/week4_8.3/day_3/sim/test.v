`timescale 1ns/1ns
module test;
reg                 rst;
reg                 clk;
wire [7:0]          dig;
wire [5:0]          sel;

initial begin
    clk <= 0;
    rst <= 0;
    #20
    rst <= 1;
    #1000000
    $stop;
end
always #10 clk = ~clk;

dt_smg #(
    .delay (3),
    .TIME  (2)
) dt_smg_u(
    .rst    (rst),
    .clk    (clk),
    .dig    (dig),
    .sel    (sel)
);
endmodule
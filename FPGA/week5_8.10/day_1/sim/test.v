`timescale 1ns/1ns
module test;
reg                 rst;
reg                 clk;
reg  [1:0]           key;
wire [7:0]          dig;
wire [5:0]          sel;

initial begin
    clk <= 0;
    rst <= 0;
    key[0] <= 1;
    key[1] <= 1;
    #20
    rst <= 1;
    repeat(20) begin
        key[0] <= ~key[0];
        #1000;
    end
    repeat(20) begin
        key[1] <= ~key[1];
        #1000;
    end
    $stop;
end
always #10 clk = ~clk;

top #(
    .delay_1(5),
    .TIME  (2)
) top_u(
    .rst    (rst),
    .clk    (clk),
    .key    (key),
    .dig    (dig),
    .sel    (sel)
);
endmodule
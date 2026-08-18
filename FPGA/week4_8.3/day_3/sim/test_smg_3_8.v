`timescale 1ns/1ns
module test_smg_3_8;
reg                 rst;
reg                 clk;
wire    [5:0]       sel;
wire    [6:0]       dig;

initial begin
    clk <= 0;
    rst <= 0;
    #40
    rst <= 1;
    #100000
    $stop;
end

always #10 clk = ~clk;

ziyima3_8 #(
    .TIME(10)
)ziyima3_8_inst(
    .rst    (rst),
    .clk    (clk),
    .dig    (dig), 
    .sel    (sel)
);
endmodule
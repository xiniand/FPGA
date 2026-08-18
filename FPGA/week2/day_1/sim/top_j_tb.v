`timescale 1ns/1ps      //宽度/精度
module top_j_tb ();
    reg       clk ;
    reg       X   ;
    reg       Y   ;
    wire      C   ;
    wire      S   ;

initial begin
    X   = 0;
    Y   = 0;
    clk = 0;
    #40

    repeat(10)begin//循环10次
        X = {$random}   ;
        Y = {$random}   ;
        #40;
    end
end

always  #10 clk = ~clk;//10ns翻转时钟


top_j top_j_u(
.X   (X),
.Y   (Y),
.C   (C),
.S   (S)

);
endmodule
`timescale 1ns/1ps      
module men_test ();
    reg       X   ;
    reg       Y   ;
    wire      C   ;
    wire      S   ;
    wire      Z   ;

initial begin
    X   = 0;
    Y   = 0;
    #40
    repeat(10)begin//循环10次
        X = {$random}   ;
        Y = {$random}   ;
        #40;
    end
    $stop;
end



men men_u(
.X   (X),
.Y   (Y),
.C   (C),
.S   (S),
.Z   (Z)

);
endmodule
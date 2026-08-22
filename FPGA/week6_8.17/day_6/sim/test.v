`timescale 1ns/1ps
module test ();
    reg     clk;
    reg     rst_n;
    reg     en;
    wire    dout;

initial begin
    clk <= 0;
    rst_n <= 0;
    #10
    rst_n <= 1;
end
always #10 clk = ~clk;

initial begin
    #10
    en <= 0;
    #20
    en <= 1;
    #20
    en<=0;
    #120
    en<=1;
    #20
    en<=0;
    #120
    en<=1;
    #20
    en<=0;
    #120
    $stop;
end

s  s_u(
    .clk        (clk  ),
    .rst_n      (rst_n),
    .en         (en   ),
    .dout       (dout )
);    
endmodule
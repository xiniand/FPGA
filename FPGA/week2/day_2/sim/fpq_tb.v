`timescale 1ns/1ps

module fpq_tb ();
    reg   clk;
    reg   rst;
    wire   clk_fp;

initial begin
    clk = 0;
    rst = 0; 
    #100
    rst = 1;
end
always  #10 clk=~clk;

top_fpq top_fpq_u(
.clk     (clk),
.rst     (rst),
.clk_fp  (clk_fp)
);




endmodule
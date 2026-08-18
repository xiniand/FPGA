`timescale 1ns/1ps

module fpj_tb ();

reg     clk     ;
reg     rst     ;
wire     clk_fpj ;


initial begin
    clk = 0;
    rst = 0;
    #100
    rst = 1;
end


always  #10 clk = ~clk;


top_fpj top_fpj_u(
.clk     (clk),
.rst     (rst),
.clk_fpj (clk_fpj)
);
    
endmodule
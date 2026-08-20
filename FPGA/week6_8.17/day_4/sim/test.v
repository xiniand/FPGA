`timescale 1ns/1ps

module test ();
    
reg     clk     ,
        rst_n   ;
wire    tx      ;

initial begin
    clk = 0;
    rst_n = 0;
    #10
    rst_n = 1;
end
always #10 clk = ~clk;

top  top_u(
    .clk        (clk    ),
    .rst_n      (rst_n  ),
    .tx         (tx     )
);

endmodule
`timescale 1ns/1ns

module fpq_test ();
    reg   clk;
    reg   rst;
    wire  clk_out;
initial begin
    clk <= 0;
    rst <= 0;
    #20
    rst <= 1;
    #100_000;
    $stop;
end

always #10 clk = ~clk;

fpq_top fpq_u(
    .rst        (rst    ) ,
    .clk        (clk    ) ,
    .clk_out    (clk_out) 
);
    

endmodule
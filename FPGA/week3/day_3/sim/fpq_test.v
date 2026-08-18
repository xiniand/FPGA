`timescale 1ns/1ns

module fpq_test();
    reg      rst        ;
    reg      clk        ;
    wire    [3:0]   led ;

parameter   NUM = 125;

initial begin
    clk <= 0;
    rst <= 0;
    #20
    rst <= 1;
    #500_00
    $stop;
end

always #10 clk = ~clk;

top_fpq #(
    .delay_1    (NUM    )
)top_fpq_u(
    .rst        (rst    ) ,
    .clk        (clk    ) ,
    .led        (led    ) 
);


endmodule
/* `timescale 1s/1s

module fpq_test();
    reg      rst        ;
    reg      clk        ;
    wire     clk_out    ;
    wire    [3:0]   led ;

initial begin
    clk <= 0;
    rst <= 0;
    #20
    rst <= 1;
    #100_000_000;

end

always #10 clk = ~clk;

top_fpq top_fpq_u(
    .rst        (rst    ) ,
    .clk        (clk    ) ,
    .clk_out    (clk_out) ,
    .led        (led    ) 
);


endmodule */
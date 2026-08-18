`timescale 1ns/1ns

module test_ztj ();
    reg         clk;
    reg         rst;
    wire [3:0]  led;

parameter delay = 20;
parameter delay_1 = 4;

initial begin
    clk <= 0;
    rst <= 0;
    #20
    rst <= 1;
    #10000
    $stop;

end
always #10 clk = ~clk;

ztj #(
    .TIME_STATE (delay),
    .TIME_LED (delay_1)
) ztj_u (
    .clk    (clk),
    .rst    (rst),
    .led    (led)
);
endmodule
`timescale 1ns/1ns

module test_ztj_led ();
    reg         clk;
    reg         rst;
    wire [3:0]  led;

parameter delay = 4;
parameter delay_1 = 20;

initial begin
    clk <= 0;
    rst <= 0;
    #20
    rst <= 1;
    #10000
    $stop;

end
always #10 clk = ~clk;

top_led #(
    .TIME_STATE (delay_1),
    .delay      (delay)
) top_led_u (
    .clk    (clk),
    .rst    (rst),
    .led    (led)
);
endmodule
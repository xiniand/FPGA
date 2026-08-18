`timescale 1ns/1ns

module led_test ();
    reg         clk;
    reg         rst;
    reg         key;
    wire [3:0]  led;
    wire        flag;

parameter delay = 5;
parameter delay_1 = 5;

initial begin
    clk <= 0;
    rst <= 0;
    key <= 0;
    #20
    rst <= 1;
    repeat(5)begin
        key <= ~key;
        #30;
    end
    repeat(10) begin
        key <= ~key;
        #500;
    end
    repeat(5)begin
        key <= ~key;
        #30;
    end
    $stop;
end
always #10 clk = ~clk;

top_led #(
    .delay (delay),
    .delay_1 (delay_1)
) top_led_u (
    .clk    (clk),
    .rst    (rst),
    .key    (key),
    .led    (led),
    .flag   (flag)
);
endmodule
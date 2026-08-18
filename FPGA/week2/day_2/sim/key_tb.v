`timescale 1ns/1ps

module  key_tb  ();

    reg     key;
    reg     clk;
    reg     rst;
    wire [3:0]   led;

parameter delay_ns = 30000;


initial begin
    clk = 0;
    rst = 0;
    key = 1;
    #100
    repeat(10)begin
    rst = 1;
    #100
    key = 0;
    #100;
    end

    key = 0;

    #delay_ns

    repeat(10)begin
    rst = 1;
    #100
    key = 0;
    #100;
    end


end
always #10 clk = ~clk;


top_key top_key_u(
    .key    (key),
    .clk    (clk),
    .rst    (rst),
    .led    (led)
);



endmodule
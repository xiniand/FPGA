`timescale 1ns/1ns
module test;
reg                 rst_n;
reg                 clk;
reg  [1:0]          key;
wire [7:0]          seg;
wire [5:0]          sel;

initial begin
    clk <= 0;
    rst_n <= 0;
    key[0] <= 1;
    key[1] <= 1;
    #20
    rst_n <= 1;
    repeat(20) begin
        key[0] <= ~key[0];
        #1000;
    end
    repeat(20) begin
        key[1] <= ~key[1];
        #1000;
    end
    $stop;
end
always #10 clk = ~clk;

top_ip #(
    .TIME_key(5),
    .TIME    (5)
) top_u(
    .rst_n  (rst_n),
    .clk    (clk),
    .key    (key),
    .sel    (sel),
    .seg    (seg)
);
endmodule
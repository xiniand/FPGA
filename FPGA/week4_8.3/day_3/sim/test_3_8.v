`timescale 1ns/1ns
module test_3_8;
reg                 rst ;
reg                 clk ;
reg     [1:0]       sw  ;
wire    [5:0]       sel ;
wire    [6:0]       dig ;

initial begin
    clk <= 0;
    rst <= 0;
    sw[1:0]  <= 0;
    #20
    rst <= 1;
    repeat(20) begin
        sw[1] <= ~sw[1];
        #500;
    end
    repeat(20) begin
        sw[1]<=0;
        sw[0] <= ~sw[0];
        #500;
    end
    $stop;
end
always #10 clk = ~clk;

top_3_8 #(
    .delay(5)
)top_3_8_inst(
    .rst    (rst),
    .clk    (clk),
    .dig    (dig),
    .sw     (sw ), 
    .sel    (sel)
);
endmodule
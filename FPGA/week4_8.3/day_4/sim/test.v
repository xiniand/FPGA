`timescale 1ns/1ns
module test;
reg                 rst ;
reg                 clk ;
reg     [1:0]       key ;
wire    [5:0]       sel ;
wire    [6:0]       seg ;

initial begin
    clk <= 0;
    rst <= 0;
    key[1:0]  <= 0;
    #20
    rst <= 1;
    repeat(20) begin
        key[1] <= ~key[1];
        #500;
    end
    repeat(20) begin
        key[1]<=0;
        key[0] <= ~key[0];
        #500;
    end
    $stop;
end
always #10 clk = ~clk;

top #(
    .delay(5),
    .shua_0  (4),
    .shua_1  (5),
    .shua_2  (6),
    .shua_3  (7),
    .shua_4  (8),
    .shua_5  (9),
    .shua_6  (10),
    .shua_7  (11),
    .shua_8  (12),
    .shua_9  (13),
    .shua_10 (14),
    .shua_11 (15),
    .shua_12 (16),
    .shua_13 (17),
    .shua_14 (18),
    .shua_15 (19),
    .shua_16 (20),
    .shua_17 (21),
    .shua_18 (22),
    .shua_19 (23),
    .shua_20 (24) 
)top_inst(
    .rst    (rst),
    .clk    (clk),
    .seg    (seg),
    .key    (key), 
    .sel    (sel)
);
endmodule
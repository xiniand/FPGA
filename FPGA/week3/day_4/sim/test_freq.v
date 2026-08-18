`timescale 1ns/1ns
module test_freq;
reg         clk     ;
reg         rst     ;
wire        clk_out ;
//产生50MHz
always #10 clk = ~clk;
//激励
initial begin
    clk = 0;
    rst = 0;
    #1
    rst = 1;
    #500
    $stop;
end
//例化
freq_top freq_top_inst(
    .clk     (clk    ),
    .rst     (rst    ),
    .clk_out (clk_out)       
);
endmodule 
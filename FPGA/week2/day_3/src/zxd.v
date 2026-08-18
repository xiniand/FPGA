module zxd (
    input                   clk,
    input                   rst,
    input           [4:0]   key,
    output  reg     [3:0]   led
);
    parameter   TIME=125_000_00;

always@(posedge clk)
    if(!rst)
        





endmodule
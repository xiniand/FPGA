module led_fx (
    input               clk     ,
    input               rst     ,
    input               sw      ,
    output  reg [3:0]   led     
);
reg  [1:0]      sw_in;
wire            sw_negedge;
always @(posedge clk) begin
    if(rst == 0)
        sw_in <= 0;
    else
        sw_in <= {sw_in[0],sw};
end
assign  sw_negedge = sw_in[1] & ~sw_in[0];

always @(posedge clk) begin
    if(rst == 0)
        led <= 4'b0001;
    else if(sw_negedge)
        led <= {led[2:0],~led[3]};
end
endmodule
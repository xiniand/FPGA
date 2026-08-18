module top_d (
    input   clk     ,
    input   rst     ,
    input   D       ,
    output  reg Q       
);

always @(posedge clk or negedge rst) begin
    if(!rst)
        Q <= 0;
    else
        Q <= D;    
end
endmodule
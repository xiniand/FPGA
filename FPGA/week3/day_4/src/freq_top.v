module freq_top (
    input               clk     ,
    input               rst     ,
    output              clk_out        
);
parameter       NUMBER  =   4   ;
wire            out_o           ,
                out_j           ;
freq_o #(
    .NUMBER     (NUMBER)
) freq_o_inst(
    .clk         (clk),     
    .rst         (rst),
    .clk_out     (out_o)     
);
freq_j #(
    .NUMBER     (NUMBER)
) freq_j_inst(
    .clk         (clk),     
    .rst         (rst),
    .clk_out     (out_j)     
);
assign clk_out = (NUMBER % 2) ? out_j : out_o;
endmodule 
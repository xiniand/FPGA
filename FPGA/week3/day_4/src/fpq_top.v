module fpq_top #(parameter delay = 4)(
    input       clk         ,
    input       rst         ,
    output      clk_out
);

generate
    if(delay%2 == 1)begin
        fpq_j #(.delay(delay))  fpq_j_u(
            .clk        (clk    )    ,
            .rst        (rst    )    ,
            .clk_out    (clk_out)
        );
    end
    else if(delay%2 == 0) begin
        fpq_o #(.delay(delay))  fpq_o_u(
            .clk        (clk    )    ,
            .rst        (rst    )    ,
            .clk_out    (clk_out)
        );
    end
endgenerate

endmodule
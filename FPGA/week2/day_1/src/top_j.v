module top_j (
    input       X   ,
    input       Y   ,
    output      C   ,
    output      S   
);

assign  C = X & Y   ;
assign  S = X ^ Y   ;


//assign  {C,S} = X + Y;
endmodule
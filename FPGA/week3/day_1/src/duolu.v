module duolu (
    input  wire     in_a    ,
    input  wire     in_b    ,
    input  wire     sel     ,
    output reg      out 
);

always@(*)
    case (sel)
        0: out = in_a;
        1: out = in_b;
        default: ;
    endcase
endmodule
module decode2_4 (
    input           [1:0]   A   ,   //A1 SW9,A0 SW10
    output  reg     [3:0]   led     
);
always @(*) 
    case (A)
        2'b00:led  = 4'b0001;
        2'b01:led  = 4'b0010;
        2'b10:led  = 4'b0100;
        2'b11:led  = 4'b1000;
        default: ;
    endcase
endmodule
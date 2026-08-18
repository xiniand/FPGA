module men (
    input       X   ,
    input       Y   ,
    output      C   ,
    output      S   ,
    output      Z
);

assign  C = X & Y   ;//与门
assign  S = X | Y   ;//或门
assign  Z = ~X   ;//非门


endmodule